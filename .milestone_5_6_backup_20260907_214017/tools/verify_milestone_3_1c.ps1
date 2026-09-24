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
function Get-NormalizedFaction([object]$Record){
  if($null -ne $Record.PSObject.Properties['faction']){return [string]$Record.faction}
  if($null -ne $Record.PSObject.Properties['affiliation']){return [string]$Record.affiliation}
  return ''
}
function Find-MilestoneRecordsByNameAndFaction([string]$Directory,[string]$Name,[string]$Faction){
  $Found=@()
  if(-not(Test-Path -LiteralPath $Directory)){return @()}
  foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
    foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
      if($Record.name -eq $Name){
        $RecordFaction=Get-NormalizedFaction $Record
        if($RecordFaction -eq $Faction){
          $Found+=,[pscustomobject]@{file=$File.Name;path=$File.FullName;record=$Record}
        }
      }
    }
  }
  return @($Found)
}
function Find-MilestoneRecordsByName([string[]]$Directories,[string]$Name){
  $Found=@()
  foreach($Directory in $Directories){
    if(-not(Test-Path -LiteralPath $Directory)){continue}
    foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
      foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
        if($Record.name -eq $Name){
          $Found+=,[pscustomobject]@{file=$File.Name;path=$File.FullName;record=$Record;faction=(Get-NormalizedFaction $Record)}
        }
      }
    }
  }
  return @($Found)
}

Write-MilestoneSection 'Milestone 3.1c preflight - preserve completed faction releases'
$RepublicRelease=Join-Path $Repo 'metadata\releases\galactic-republic-2025.01-final.json'
$SeparatistRelease=Join-Path $Repo 'metadata\releases\separatist-alliance-2025.01-final.json'
Assert-Milestone (Test-Path -LiteralPath $RepublicRelease) 'Republic Milestone 1.6 release manifest is missing.'
Assert-Milestone (Test-Path -LiteralPath $SeparatistRelease) 'Separatist Milestone 2.6 release manifest is missing.'
$Republic=Read-MilestoneJson $RepublicRelease
$Separatist=Read-MilestoneJson $SeparatistRelease
Assert-Milestone (([string]$Republic.status -eq 'complete-product-origin') -or ([string]$Republic.status -eq 'frozen-product-origin')) ('Republic release status not recognized: '+$Republic.status)
Assert-Milestone (([string]$Separatist.status -eq 'frozen-product-origin') -or ([string]$Separatist.status -eq 'complete-product-origin')) ('Separatist release status not recognized: '+$Separatist.status)
Write-Host ('[OK] Republic release baseline accepted: '+$Republic.status)
Write-Host ('[OK] Separatist release baseline accepted: '+$Separatist.status)

Write-MilestoneSection 'Backup prior 3.1 audit artifacts before correction'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_3_1c_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$Targets=@(
 'metadata\supplements\rapid-reinforcements-i-audit.json',
 'metadata\supplements\rapid-reinforcements-i-official-audit.json',
 'reports\rapid-reinforcements-i-audit-3.1.json',
 'reports\rapid-reinforcements-i-audit-3.1.md',
 'reports\rapid-reinforcements-i-audit-3.1c.json',
 'reports\rapid-reinforcements-i-audit-3.1c.md',
 'tools\verify_milestone_3_1.ps1',
 'tools\verify_milestone_3_1c.ps1'
)
foreach($Relative in $Targets){
  $Source=Join-Path $Repo $Relative
  if(Test-Path -LiteralPath $Source){
    $Dest=Join-Path $Backup $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $Dest) -Force|Out-Null
    Copy-Item -LiteralPath $Source -Destination $Dest -Force
  }
}
Write-Host ('[OK] Backup created: '+$Backup)

Write-MilestoneSection 'Load corrected official Rapid Reinforcements I inventory'
$Payload=Join-Path $PackageRoot 'patch\metadata\supplements\rapid-reinforcements-i-official-audit.json'
$Audit=Read-MilestoneJson $Payload
Assert-Milestone ([int]$Audit.expected_total_designs -eq 8) 'Corrected RR1 inventory must contain exactly 8 entries.'
Assert-Milestone (@($Audit.records).Count -eq 8) 'Corrected RR1 packaged record count mismatch.'
foreach($Entry in @($Audit.records)){
  Assert-Milestone ([string]$Entry.rr_card_revision -eq '2.0') ($Entry.name+' is not marked RR revision 2.0.')
}
Write-Host '[OK] Official RR1 inventory: 8 cards, all revision 2.0'

Write-MilestoneSection 'Classify RR1 records by identity, not name alone'
$ShipRoots=@(
 (Join-Path $Repo 'data\ship-card\galactic-republic'),
 (Join-Path $Repo 'data\ship-card\separatist-alliance'),
 (Join-Path $Repo 'data\ship-card\rebel-alliance'),
 (Join-Path $Repo 'data\ship-card\galactic-empire')
)
$SquadRoots=@(
 (Join-Path $Repo 'data\squadron-card\galactic-republic'),
 (Join-Path $Repo 'data\squadron-card\separatist-alliance'),
 (Join-Path $Repo 'data\squadron-card\rebel-alliance'),
 (Join-Path $Repo 'data\squadron-card\galactic-empire')
)
$FactionFolders=@{
 'Galactic Republic'='galactic-republic'
 'Separatist Alliance'='separatist-alliance'
 'Rebel Alliance'='rebel-alliance'
 'Galactic Empire'='galactic-empire'
}
$Classification=@()
foreach($Entry in @($Audit.records)){
  $Folder=$FactionFolders[[string]$Entry.faction]
  Assert-Milestone (-not [string]::IsNullOrWhiteSpace($Folder)) ('Unsupported faction in audit: '+$Entry.faction)
  $IdentityRoot=if($Entry.kind -eq 'ship'){
    Join-Path $Repo ('data\ship-card\'+$Folder)
  }else{
    Join-Path $Repo ('data\squadron-card\'+$Folder)
  }
  $IdentityHits=@(Find-MilestoneRecordsByNameAndFaction $IdentityRoot ([string]$Entry.name) ([string]$Entry.faction))
  $AllRoots=if($Entry.kind -eq 'ship'){$ShipRoots}else{$SquadRoots}
  $NameHits=@(Find-MilestoneRecordsByName $AllRoots ([string]$Entry.name)
  )
  $Action=if($IdentityHits.Count -eq 0){'new-rr1-identity'}elseif($IdentityHits.Count -eq 1){'reconcile-existing-identity'}else{'duplicate-identity-error'}
  Assert-Milestone ($IdentityHits.Count -le 1) ($Entry.name+' / '+$Entry.faction+' has '+$IdentityHits.Count+' matching identities.')
  $Classification+=,[pscustomobject]@{
    name=$Entry.name
    kind=$Entry.kind
    faction=$Entry.faction
    chassis=$Entry.chassis
    expected_points=[int]$Entry.points
    rr_card_revision='2.0'
    same_name_any_faction=$NameHits.Count
    same_identity_matches=$IdentityHits.Count
    action=$Action
  }
  Write-Host ('[OK] '+$Entry.faction+' / '+$Entry.name+' -> '+$Action+' (same-name records anywhere: '+$NameHits.Count+')')
}

Write-MilestoneSection 'Validate RR1 official final point inventory'
$ExpectedPoints=@{
 'Galactic Empire|Darth Vader'=25
 'Rebel Alliance|Hera Syndulla'=23
 'Galactic Republic|Anakin Skywalker'=24
 'Separatist Alliance|Jango Fett'=22
 'Galactic Empire|Venator II-class Star Destroyer'=100
 'Rebel Alliance|Providence-class Carrier'=95
 'Galactic Republic|Victory I-class Star Destroyer'=73
 'Separatist Alliance|Gozanti-class Cruisers'=24
}
foreach($Entry in @($Audit.records)){
  $Key=[string]$Entry.faction+'|'+[string]$Entry.name
  Assert-Milestone ($ExpectedPoints.ContainsKey($Key)) ('Unexpected RR1 identity: '+$Key)
  Assert-Milestone ([int]$Entry.points -eq [int]$ExpectedPoints[$Key]) ($Key+' point mismatch in packaged audit.')
  Write-Host ('[OK] '+$Key+' = '+$Entry.points+' pts')
}

Write-MilestoneSection 'Replace incorrect 3.1 audit outputs with corrected official audit'
$MetaDir=Join-Path $Repo 'metadata\supplements'
$ReportDir=Join-Path $Repo 'reports'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $MetaDir,$ReportDir,$ToolsDir -Force|Out-Null
Copy-Item -LiteralPath $Payload -Destination (Join-Path $MetaDir 'rapid-reinforcements-i-official-audit.json') -Force

$Report=[ordered]@{
 milestone='3.1c'
 supplement='Rapid Reinforcements I'
 status='PASS'
 correction_of='3.1/3.1b incorrect 10-entry inventory'
 authoritative_document='Rapid Reinforcements v2.3 [01/10/25]'
 rr1_selector='card revision 2.0'
 total_inventory_entries=8
 classification=$Classification
 boundary=[ordered]@{
   production_card_data_modified=$false
   frozen_product_origin_data_modified=$false
   rr2_revision_2_1_cards_deferred=$true
   next_milestone='3.2 Rapid Reinforcements I installation/reconciliation'
 }
}
$Json=ConvertTo-Json -InputObject $Report -Depth 50
Set-Content -LiteralPath (Join-Path $ReportDir 'rapid-reinforcements-i-audit-3.1c.json') -Value $Json -Encoding UTF8

$NewCount=@($Classification|Where-Object{$_.action -eq 'new-rr1-identity'}).Count
$ExistingCount=@($Classification|Where-Object{$_.action -eq 'reconcile-existing-identity'}).Count
$Md=@"
# Rapid Reinforcements I Official Inventory Correction — Milestone 3.1c

**Status:** PASS
**Authoritative baseline:** Rapid Reinforcements v2.3 [01/10/25]
**RR1 identity rule:** the eight cards marked revision 2.0
**Production card writes:** none

## Corrected inventory
- 8 official RR1 cards
- $NewCount new RR1 faction/name identities detected
- $ExistingCount existing same-faction identities detected for reconciliation
- RR2 revision 2.1 cards are deferred

## Correction
The earlier 3.1 audit's 10-entry inventory was not the Armada Rapid Reinforcements I card set. This milestone supersedes that audit for all future 3.x work.

## Next step
Milestone 3.2 will install/reconcile these eight official RR1 identities while preserving physical-product records and avoiding name-only collisions across factions.
"@
Set-Content -LiteralPath (Join-Path $ReportDir 'rapid-reinforcements-i-audit-3.1c.md') -Value $Md -Encoding UTF8
Write-Host '[OK] Corrected RR1 metadata and reports written'
Write-Host '[OK] Prior incorrect 3.1 outputs preserved in rollback backup'

Write-MilestoneSection 'Install corrected reusable verifier'
$Verifier=Join-Path $ToolsDir 'verify_milestone_3_1c.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed '+$Verifier)

Write-Host ''
Write-Host '[OK] Milestone 3.1c complete.'
Write-Host '[OK] Official Rapid Reinforcements I inventory corrected to 8 revision-2.0 cards.'
Write-Host '[OK] RR1 identities were classified by faction + name, not name alone.'
Write-Host '[OK] No production card data was modified.'
Write-Host '[OK] Ready for Milestone 3.2 using the corrected official RR1 inventory.'
Write-Host ('[OK] Backup: '+$Backup)
