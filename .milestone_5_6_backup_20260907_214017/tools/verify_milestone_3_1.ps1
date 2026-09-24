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
function Find-RecordByName([string]$Directory,[string]$Name){
  $Found=@()
  if(-not(Test-Path -LiteralPath $Directory)){return @()}
  foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
    foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
      if($Record.name -eq $Name){$Found+=,[pscustomobject]@{file=$File.Name;record=$Record}}
    }
  }
  return @($Found)
}

Write-MilestoneSection 'Milestone 3.1b preflight - schema-compatible Clone Wars release baselines'
$RepublicRelease=Join-Path $Repo 'metadata\releases\galactic-republic-2025.01-final.json'
$SeparatistRelease=Join-Path $Repo 'metadata\releases\separatist-alliance-2025.01-final.json'
Assert-Milestone (Test-Path -LiteralPath $RepublicRelease) 'Frozen Republic release manifest is missing.'
Assert-Milestone (Test-Path -LiteralPath $SeparatistRelease) 'Frozen Separatist release manifest is missing.'
$Republic=Read-MilestoneJson $RepublicRelease
$Separatist=Read-MilestoneJson $SeparatistRelease
$RepublicStatus = [string]$Republic.status
$RepublicReleaseName = [string]$Republic.release
$RepublicFaction = [string]$Republic.faction
$RepublicDataVersion = [string]$Republic.data_version
if([string]::IsNullOrWhiteSpace($RepublicDataVersion) -and $null -ne $Republic.PSObject.Properties['data-version']){
  $RepublicDataVersion = [string]$Republic.'data-version'
}
$RepublicBaselineAccepted = (
  ($RepublicStatus -eq 'complete-product-origin') -or
  ($RepublicStatus -eq 'frozen-product-origin')
)
Assert-Milestone $RepublicBaselineAccepted ('Republic Milestone 1.6 release baseline not recognized. status=' + $RepublicStatus)

$SeparatistStatus = [string]$Separatist.status
$SeparatistRecordCount = if($null -ne $Separatist.totals -and $null -ne $Separatist.totals.records){[int]$Separatist.totals.records}else{0}
$SeparatistStableIdCount = if($null -ne $Separatist.totals -and $null -ne $Separatist.totals.stable_ids){[int]$Separatist.totals.stable_ids}else{0}
$SeparatistBaselineAccepted = (
  ($SeparatistStatus -eq 'frozen-product-origin') -or
  ($SeparatistStatus -eq 'complete-product-origin') -or
  ($SeparatistRecordCount -eq 48 -and $SeparatistStableIdCount -eq 48)
)
Assert-Milestone $SeparatistBaselineAccepted ('Separatist Milestone 2.6 release baseline not recognized. status=' + $SeparatistStatus + '; records=' + $SeparatistRecordCount + '; stable_ids=' + $SeparatistStableIdCount)

Write-Host ('[OK] Republic Milestone 1.6 baseline accepted: status=' + $RepublicStatus)
if(-not [string]::IsNullOrWhiteSpace($RepublicDataVersion)){Write-Host ('[OK] Republic data version: ' + $RepublicDataVersion)}
Write-Host ('[OK] Separatist Milestone 2.6 baseline accepted: status=' + $SeparatistStatus + ' / records=' + $SeparatistRecordCount + ' / stable IDs=' + $SeparatistStableIdCount)

Write-MilestoneSection 'Backup Milestone 3.1 audit outputs'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_3_1_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$Outputs=@(
 'metadata\supplements\rapid-reinforcements-i-audit.json',
 'reports\rapid-reinforcements-i-audit-3.1.json',
 'reports\rapid-reinforcements-i-audit-3.1.md',
 'tools\verify_milestone_3_1.ps1'
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

Write-MilestoneSection 'Load packaged Rapid Reinforcements I inventory'
$Payload=Join-Path $PackageRoot 'patch\metadata\supplements\rapid-reinforcements-i-audit.json'
$Audit=Read-MilestoneJson $Payload
Assert-Milestone ([int]$Audit.expected_total_designs -eq 10) 'RR1 inventory must contain 10 audited entries.'
Assert-Milestone (@($Audit.records).Count -eq 10) 'RR1 packaged record count mismatch.'
Write-Host '[OK] Packaged RR1 audit inventory contains 10 entries'

Write-MilestoneSection 'Classify existing database overlap'
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
$Classification=@()
foreach($Entry in @($Audit.records)){
  $Roots=if($Entry.kind -eq 'ship'){$ShipRoots}else{$SquadRoots}
  $Hits=@()
  foreach($Root in $Roots){$Hits+=@(Find-RecordByName $Root $Entry.name)}
  $Classification+=,[pscustomobject]@{
    name=$Entry.name;kind=$Entry.kind;faction=$Entry.faction;expected_points=[int]$Entry.points;
    existing_matches=$Hits.Count;
    action=if($Hits.Count -gt 0){'reconcile-existing'}else{'candidate-new-record'}
  }
  Write-Host ('[OK] '+$Entry.name+' -> '+$(if($Hits.Count -gt 0){'existing record detected; reconcile in 3.2'}else{'not currently detected; candidate for 3.2'}))
}

Write-MilestoneSection 'Validate known frozen Clone Wars overlaps'
$RepSquad=Join-Path $Repo 'data\squadron-card\galactic-republic'
$CisSquad=Join-Path $Repo 'data\squadron-card\separatist-alliance'
$RepShip=Join-Path $Repo 'data\ship-card\galactic-republic'
$CisShip=Join-Path $Repo 'data\ship-card\separatist-alliance'
$Known=@(
 @('Axe',$RepSquad,17),
 @('DIS-T81',$CisSquad,17),
 @('DBS-404',$CisSquad,17),
 @('Providence-class Carrier',$CisShip,102),
 @('Venator II-class Star Destroyer',$RepShip,100)
)
foreach($K in $Known){
  $Hits=@(Find-RecordByName ([string]$K[1]) ([string]$K[0]))
  Assert-Milestone ($Hits.Count -eq 1) ($K[0]+' frozen overlap expected exactly once; found '+$Hits.Count+'.')
  Assert-Milestone ([int]$Hits[0].record.points -eq [int]$K[2]) ($K[0]+' frozen overlap point mismatch.')
  Write-Host ('[OK] '+$K[0]+' existing frozen record preserved at '+$K[2]+' pts')
}

Write-MilestoneSection 'Write Milestone 3.1 audit artifacts'
$MetaDir=Join-Path $Repo 'metadata\supplements'
$ReportDir=Join-Path $Repo 'reports'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $MetaDir,$ReportDir,$ToolsDir -Force|Out-Null
Copy-Item -LiteralPath $Payload -Destination (Join-Path $MetaDir 'rapid-reinforcements-i-audit.json') -Force
$Report=[ordered]@{
 milestone='3.1'
 supplement='Rapid Reinforcements I'
 status='PASS'
 audit_only=$true
 total_inventory_entries=10
 classification=$Classification
 boundary=[ordered]@{
   production_card_data_modified=$false
   frozen_product_origin_data_modified=$false
   next_milestone='3.2 Rapid Reinforcements I installation/reconciliation'
 }
}
$Json=ConvertTo-Json -InputObject $Report -Depth 50
Set-Content -LiteralPath (Join-Path $ReportDir 'rapid-reinforcements-i-audit-3.1.json') -Value $Json -Encoding UTF8
$Existing=@($Classification|Where-Object{$_.action -eq 'reconcile-existing'}).Count
$New=@($Classification|Where-Object{$_.action -eq 'candidate-new-record'}).Count
$Md=@"
# Rapid Reinforcements I Inventory Audit — Milestone 3.1

**Status:** PASS
**Mode:** Audit only; no production card-data writes.

## Inventory
- 10 audited RR1 entries
- $Existing existing-name records detected for reconciliation
- $New candidate new records detected

## Boundary
Milestone 3.1 does not alter frozen Republic or Separatist product-origin card data. Milestone 3.2 will reconcile existing records and install any genuinely new RR1 records after this inventory gate passes.
"@
Set-Content -LiteralPath (Join-Path $ReportDir 'rapid-reinforcements-i-audit-3.1.md') -Value $Md -Encoding UTF8
Write-Host '[OK] Wrote RR1 audit metadata and JSON/Markdown reports'

Write-MilestoneSection 'Install reusable verifier'
$Verifier=Join-Path $ToolsDir 'verify_milestone_3_1.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed '+$Verifier)

Write-Host ''
Write-Host '[OK] Milestone 3.1b complete.'
Write-Host '[OK] Rapid Reinforcements I inventory audit passed: 10 entries classified.'
Write-Host '[OK] No production card data was modified.'
Write-Host '[OK] Frozen Republic and Separatist product-origin datasets remain untouched.'
Write-Host '[OK] Ready for Milestone 3.2 RR1 installation/reconciliation.'
Write-Host ('[OK] Backup: '+$Backup)
