param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$PackageRoot=Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-MilestoneSection([string]$Text){
  Write-Host ''
  Write-Host ('='*60)
  Write-Host ('=> '+$Text)
  Write-Host ('='*60)
}
function Assert-Milestone([bool]$Condition,[string]$Message){
  if(-not $Condition){throw $Message}
}
function Read-MilestoneJson([string]$Path){
  if(-not(Test-Path -LiteralPath $Path)){throw ('Missing JSON file: '+$Path)}
  $Raw=Get-Content -LiteralPath $Path -Raw
  if([string]::IsNullOrWhiteSpace($Raw)){throw ('Empty JSON file: '+$Path)}
  try{return ($Raw|ConvertFrom-Json)}catch{throw ('Invalid JSON in '+$Path+': '+$_.Exception.Message)}
}
function Read-MilestoneJsonRecords([string]$Path){return @(Read-MilestoneJson $Path)}
function Find-MilestoneSquadronIdentity([string]$Directory,[string]$Name,[string]$Subname,[string]$Faction){
  $Found=@()
  if(-not(Test-Path -LiteralPath $Directory)){return @()}
  foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
    foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
      if(($Record.name -eq $Name) -and ($Record.faction -eq $Faction) -and ($Record.subname -eq $Subname)){
        $Found+=,[pscustomobject]@{file=$File.Name;path=$File.FullName;record=$Record}
      }
    }
  }
  return @($Found)
}
function Find-MilestoneShipIdentity([string]$Directory,[string]$Name,[string]$Faction){
  $Found=@()
  if(-not(Test-Path -LiteralPath $Directory)){return @()}
  foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
    foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
      if(($Record.name -eq $Name) -and ($Record.faction -eq $Faction)){
        $Found+=,[pscustomobject]@{file=$File.Name;path=$File.FullName;record=$Record}
      }
    }
  }
  return @($Found)
}
function Find-MilestoneSquadronSameName([string]$Directory,[string]$Name,[string]$Faction){
  $Found=@()
  if(-not(Test-Path -LiteralPath $Directory)){return @()}
  foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
    foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
      if(($Record.name -eq $Name) -and ($Record.faction -eq $Faction)){
        $Found+=,[pscustomobject]@{file=$File.Name;subname=$Record.subname;points=$Record.points}
      }
    }
  }
  return @($Found)
}

Write-MilestoneSection 'Milestone 3.1d preflight - corrected RR1 source gate'
$PriorAudit=Join-Path $Repo 'metadata\supplements\rapid-reinforcements-i-official-audit.json'
Assert-Milestone (Test-Path -LiteralPath $PriorAudit) 'Milestone 3.1c corrected RR1 audit metadata is missing.'
$Prior=Read-MilestoneJson $PriorAudit
Assert-Milestone ([int]$Prior.expected_total_designs -eq 8) 'Milestone 3.1c baseline must contain 8 RR1 entries.'
Write-Host '[OK] Milestone 3.1c eight-card RR1 inventory baseline detected'

Write-MilestoneSection 'Backup prior 3.1c audit outputs'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_3_1d_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$Outputs=@(
 'metadata\supplements\rapid-reinforcements-i-official-audit.json',
 'metadata\supplements\rapid-reinforcements-i-official-audit-3.1d.json',
 'reports\rapid-reinforcements-i-audit-3.1c.json',
 'reports\rapid-reinforcements-i-audit-3.1c.md',
 'reports\rapid-reinforcements-i-audit-3.1d.json',
 'reports\rapid-reinforcements-i-audit-3.1d.md',
 'tools\verify_milestone_3_1c.ps1',
 'tools\verify_milestone_3_1d.ps1'
)
foreach($Relative in $Outputs){
  $Source=Join-Path $Repo $Relative
  if(Test-Path -LiteralPath $Source){
    $Dest=Join-Path $Backup $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $Dest) -Force|Out-Null
    Copy-Item -LiteralPath $Source -Destination $Dest -Force
  }
}
Write-Host ('[OK] Backup created: '+$Backup)

Write-MilestoneSection 'Load chassis-aware official RR1 inventory'
$Payload=Join-Path $PackageRoot 'patch\metadata\supplements\rapid-reinforcements-i-official-audit-3.1d.json'
$Audit=Read-MilestoneJson $Payload
Assert-Milestone (@($Audit.records).Count -eq 8) 'RR1 must contain exactly 8 revision-2.0 cards.'
Write-Host '[OK] Loaded 8 official RR1 revision-2.0 cards'

$FactionFolders=@{
 'Galactic Republic'='galactic-republic'
 'Separatist Alliance'='separatist-alliance'
 'Rebel Alliance'='rebel-alliance'
 'Galactic Empire'='galactic-empire'
}

Write-MilestoneSection 'Reclassify squadron identities using faction + name + chassis'
$Classification=@()
foreach($Entry in @($Audit.records|Where-Object{$_.kind -eq 'squadron'})){
  $Folder=$FactionFolders[[string]$Entry.faction]
  $Dir=Join-Path $Repo ('data\squadron-card\'+$Folder)
  $Exact=@(Find-MilestoneSquadronIdentity $Dir ([string]$Entry.name) ([string]$Entry.subname) ([string]$Entry.faction))
  $SameName=@(Find-MilestoneSquadronSameName $Dir ([string]$Entry.name) ([string]$Entry.faction))
  Assert-Milestone ($Exact.Count -le 1) ($Entry.faction+' / '+$Entry.name+' / '+$Entry.subname+' duplicated in database.')
  $Action=if($Exact.Count -eq 0){'new-rr1-identity'}else{'reconcile-exact-existing-identity'}
  $ExistingChassis=@($SameName|ForEach-Object{$_.subname})
  $Classification+=,[pscustomobject]@{
    name=$Entry.name;kind='squadron';faction=$Entry.faction;subname=$Entry.subname;
    points=[int]$Entry.points;exact_identity_matches=$Exact.Count;same_name_matches=$SameName.Count;
    existing_same_name_chassis=$ExistingChassis;action=$Action
  }
  if($SameName.Count -gt 0 -and $Exact.Count -eq 0){
    Write-Host ('[OK] '+$Entry.faction+' / '+$Entry.name+' / '+$Entry.subname+' -> NEW RR1 identity; same-name card exists on different chassis: '+($ExistingChassis -join ', '))
  }else{
    Write-Host ('[OK] '+$Entry.faction+' / '+$Entry.name+' / '+$Entry.subname+' -> '+$Action)
  }
}

Write-MilestoneSection 'Reclassify cross-faction ship identities using faction + ship name'
foreach($Entry in @($Audit.records|Where-Object{$_.kind -eq 'ship'})){
  $Folder=$FactionFolders[[string]$Entry.faction]
  $Dir=Join-Path $Repo ('data\ship-card\'+$Folder)
  $Exact=@(Find-MilestoneShipIdentity $Dir ([string]$Entry.name) ([string]$Entry.faction))
  Assert-Milestone ($Exact.Count -le 1) ($Entry.faction+' / '+$Entry.name+' duplicated in database.')
  $Action=if($Exact.Count -eq 0){'new-rr1-identity'}else{'reconcile-exact-existing-identity'}
  $Classification+=,[pscustomobject]@{
    name=$Entry.name;kind='ship';faction=$Entry.faction;subname=$null;
    points=[int]$Entry.points;exact_identity_matches=$Exact.Count;same_name_matches=$null;
    existing_same_name_chassis=@();action=$Action
  }
  Write-Host ('[OK] '+$Entry.faction+' / '+$Entry.name+' -> '+$Action)
}

Write-MilestoneSection 'Validate corrected identity result'
$New=@($Classification|Where-Object{$_.action -eq 'new-rr1-identity'})
$Existing=@($Classification|Where-Object{$_.action -eq 'reconcile-exact-existing-identity'})
Assert-Milestone ($New.Count -eq 8) ('Expected all 8 RR1 cards to be distinct new identities; found '+$New.Count+' new and '+$Existing.Count+' existing.')
Write-Host '[OK] 8 / 8 official RR1 cards are distinct new faction/chassis identities'
Write-Host '[OK] Darth Vader TIE Defender is distinct from existing Darth Vader TIE Advanced'
Write-Host '[OK] Hera Syndulla X-wing is distinct from existing Hera Syndulla Ghost'
Write-Host '[OK] Anakin Skywalker Delta-7 is distinct from existing Anakin Skywalker BTL-B Y-wing'
Write-Host '[OK] Four RR1 ships are distinct cross-faction ship identities'

Write-MilestoneSection 'Write corrected 3.1d audit artifacts'
$MetaDir=Join-Path $Repo 'metadata\supplements'
$ReportDir=Join-Path $Repo 'reports'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $MetaDir,$ReportDir,$ToolsDir -Force|Out-Null
Copy-Item -LiteralPath $Payload -Destination (Join-Path $MetaDir 'rapid-reinforcements-i-official-audit-3.1d.json') -Force
Copy-Item -LiteralPath $Payload -Destination (Join-Path $MetaDir 'rapid-reinforcements-i-official-audit.json') -Force

$Report=[ordered]@{
 milestone='3.1d'
 supplement='Rapid Reinforcements I'
 status='PASS'
 supersedes='3.1c identity classification'
 authoritative_document='Rapid Reinforcements v2.3 [01/10/25]'
 rr1_selector='revision 2.0 cards'
 identity_rule=[ordered]@{
   squadron='faction + name + subname/chassis'
   ship='faction + ship-card name'
 }
 total_inventory_entries=8
 new_rr1_identities=8
 existing_exact_rr1_identities=0
 classification=$Classification
 production_card_data_modified=$false
 next_milestone='3.2 Rapid Reinforcements I eight-card installation'
}
$Json=ConvertTo-Json -InputObject $Report -Depth 50
Set-Content -LiteralPath (Join-Path $ReportDir 'rapid-reinforcements-i-audit-3.1d.json') -Value $Json -Encoding UTF8

$Md=@"
# Rapid Reinforcements I Chassis-Aware Identity Correction — Milestone 3.1d

**Status:** PASS
**Authoritative source:** Rapid Reinforcements v2.3 [01/10/25]
**RR1 selector:** cards marked revision 2.0
**Production card writes:** none

## Correct identity result
All 8 RR1 cards are distinct new identities.

Squadron identity is faction + name + subname/chassis, which prevents same-name characters on different squadron chassis from being merged:
- Darth Vader / TIE Defender Squadron is not Darth Vader / TIE Advanced Squadron.
- Hera Syndulla / X-wing Squadron is not Hera Syndulla / Ghost.
- Anakin Skywalker / Delta-7 Aethersprite Squadron is not Anakin Skywalker / BTL-B Y-wing Squadron.

The four RR1 ships are also new identities because each is printed for a different faction than the physical-product version of that chassis.

## Next
Milestone 3.2 should install all 8 official RR1 cards as distinct supplement records while preserving every physical-product record.
"@
Set-Content -LiteralPath (Join-Path $ReportDir 'rapid-reinforcements-i-audit-3.1d.md') -Value $Md -Encoding UTF8
Write-Host '[OK] Corrected official RR1 metadata and reports installed'

Write-MilestoneSection 'Install reusable chassis-aware verifier'
$Verifier=Join-Path $ToolsDir 'verify_milestone_3_1d.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed '+$Verifier)

Write-Host ''
Write-Host '[OK] Milestone 3.1d complete.'
Write-Host '[OK] RR1 identity model corrected to faction + name + chassis where required.'
Write-Host '[OK] All 8 official RR1 cards are confirmed as distinct new identities.'
Write-Host '[OK] No production card data was modified.'
Write-Host '[OK] Ready for Milestone 3.2 eight-card RR1 installation.'
Write-Host ('[OK] Backup: '+$Backup)
