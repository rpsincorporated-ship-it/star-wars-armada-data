param(
  [Parameter(Mandatory=$true)][string]$RepoPath
)
$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path -LiteralPath $RepoPath).Path
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
function Header([string]$Text){ Write-Host ''; Write-Host ('='*60); Write-Host ('=> ' + $Text); Write-Host ('='*60) }
function Assert([bool]$Condition,[string]$Message){ if(-not $Condition){ throw $Message } }
function Read-JsonRecords([string]$Path){
  $raw = Get-Content -LiteralPath $Path -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw ('Empty JSON file: ' + $Path) }
  try { $parsed = $raw | ConvertFrom-Json } catch { throw ('Invalid JSON in ' + $Path + ': ' + $_.Exception.Message) }
  Write-Output $parsed
}
function Write-JsonArray([string]$Path,[object[]]$Rows){
  $json = ConvertTo-Json -InputObject @($Rows) -Depth 30
  Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

Header 'Milestone 1.4 preflight'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'data')) 'Missing data folder.'
$ShipDir = Join-Path $Repo 'data\ship-card\galactic-republic'
$SqDir = Join-Path $Repo 'data\squadron-card\galactic-republic'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'metadata\products\swm41.json')) 'Milestone 1.3 SWM41 metadata is missing.'
Assert (Test-Path -LiteralPath (Join-Path $ShipDir 'venator-i-class-star-destroyer.json')) 'Milestone 1.3 Venator baseline is missing.'
Assert (Test-Path -LiteralPath (Join-Path $SqDir 'arc-170-squadron.json')) 'Milestone 1.2 Republic fighter baseline is missing.'
Write-Host '[OK] Milestones 1.1 through 1.3 Republic baseline detected'

Header 'Backup existing Milestone 1.4 targets'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup = Join-Path $Repo ('.milestone_1_4_backup_' + $Stamp)
New-Item -ItemType Directory -Path $Backup -Force | Out-Null
$ShipTargets = @('pelta-class-transport-frigate.json','pelta-class-medical-frigate.json')
foreach($file in $ShipTargets){ $p=Join-Path $ShipDir $file; if(Test-Path -LiteralPath $p){ Copy-Item -LiteralPath $p -Destination (Join-Path $Backup $file) -Force } }
$UpgradeDir = Join-Path $Repo 'data\upgrade-card'
$UpgradeTargets = @('commander.json','fleet-command.json','officer.json','title.json')
foreach($file in $UpgradeTargets){ $p=Join-Path $UpgradeDir $file; if(Test-Path -LiteralPath $p){ Copy-Item -LiteralPath $p -Destination (Join-Path $Backup $file) -Force } }
$MetaDir = Join-Path $Repo 'metadata\products'
$MetaPath = Join-Path $MetaDir 'swm40.json'
if(Test-Path -LiteralPath $MetaPath){ Copy-Item -LiteralPath $MetaPath -Destination (Join-Path $Backup 'swm40.json') -Force }
Write-Host ('[OK] Backup created: ' + $Backup)

Header 'Install SWM40 Pelta ship data'
New-Item -ItemType Directory -Path $ShipDir -Force | Out-Null
foreach($file in $ShipTargets){
  $src=Join-Path $ScriptRoot ('patch\data\ship-card\galactic-republic\' + $file)
  Assert (Test-Path -LiteralPath $src) ('Package ship file missing: ' + $file)
  Copy-Item -LiteralPath $src -Destination (Join-Path $ShipDir $file) -Force
  Write-Host ('[OK] Installed ' + $file)
}

Header 'Merge SWM40 upgrades idempotently'
$ExpectedByFile = @{
 'commander.json'=@('Admiral Tarkin','Admiral Yularen')
 'fleet-command.json'=@('Mercy Mission')
 'officer.json'=@('Adi Gallia','Clone Captain Silver')
 'title.json'=@('TB-73','FB-88')
}
New-Item -ItemType Directory -Path $UpgradeDir -Force | Out-Null
foreach($file in $UpgradeTargets){
  $target=Join-Path $UpgradeDir $file
  $payloadPath=Join-Path $ScriptRoot ('patch\upgrades\' + $file)
  Assert (Test-Path -LiteralPath $payloadPath) ('Package upgrade file missing: ' + $file)
  $existing=@()
  if(Test-Path -LiteralPath $target){ $existing=@(Read-JsonRecords $target) }
  $incoming=@(Read-JsonRecords $payloadPath)
  $names=@($ExpectedByFile[$file])
  $filtered=@($existing | Where-Object { $names -notcontains [string]$_.name })
  $merged=@($filtered) + @($incoming)
  Write-JsonArray $target $merged
  $check=@(Read-JsonRecords $target)
  foreach($expectedName in $names){
    $count=@($check | Where-Object { $_.name -eq $expectedName }).Count
    Assert ($count -eq 1) (('{0}: {1} expected once after merge; found {2}.' -f $file,$expectedName,$count))
  }
  Write-Host ('[OK] ' + $file + ': merged ' + $incoming.Count + ' SWM40 design(s)')
}

Header 'Install SWM40 product metadata'
New-Item -ItemType Directory -Path $MetaDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $ScriptRoot 'patch\metadata\products\swm40.json') -Destination $MetaPath -Force
Write-Host '[OK] Installed SWM40 metadata'

Header 'Validate Pelta ship records'
$ShipExpected=@{
 'pelta-class-transport-frigate.json'=@('Pelta-class Transport Frigate',45,1,5,2)
 'pelta-class-medical-frigate.json'=@('Pelta-class Medical Frigate',49,2,5,2)
}
foreach($file in $ShipTargets){
  $rows=@(Read-JsonRecords (Join-Path $ShipDir $file))
  Assert ($rows.Count -eq 1) ($file + ' must contain exactly one ship record; found ' + $rows.Count + '.')
  $r=$rows[0]; $e=$ShipExpected[$file]
  Assert ($r.name -eq $e[0]) ($file + ' name mismatch.')
  Assert ([int]$r.points -eq [int]$e[1]) ($file + ' points mismatch.')
  Assert ([int]$r.squadron -eq [int]$e[2]) ($file + ' squadron value mismatch.')
  Assert ([int]$r.hull -eq [int]$e[3]) ($file + ' hull mismatch.')
  Assert ([int]$r.'max-speed' -eq [int]$e[4]) ($file + ' max-speed mismatch.')
  Assert ($r.faction -eq 'Galactic Republic') ($file + ' faction mismatch.')
  Assert ($r.source.'product-code' -eq 'SWM40') ($file + ' source product-code mismatch.')
  Write-Host ('[OK] ' + $r.name + ' (' + $r.points + ' pts)')
}

Header 'Validate all 7 SWM40 upgrade designs'
$PointChecks=@{
 'Admiral Tarkin'=30; 'Admiral Yularen'=24; 'Mercy Mission'=5;
 'Adi Gallia'=3; 'Clone Captain Silver'=4; 'TB-73'=5; 'FB-88'=4
}
$Found=0
foreach($file in $UpgradeTargets){
  $rows=@(Read-JsonRecords (Join-Path $UpgradeDir $file))
  foreach($name in @($ExpectedByFile[$file])){
    $matches=@($rows | Where-Object { $_.name -eq $name })
    Assert ($matches.Count -eq 1) ($name + ' expected exactly once in ' + $file + '; found ' + $matches.Count + '.')
    $card=$matches[0]
    Assert ([int]$card.points -eq [int]$PointChecks[$name]) ($name + ' points mismatch.')
    Assert ($card.source.'product-code' -eq 'SWM40') ($name + ' source product-code mismatch.')
    $Found++
    Write-Host ('[OK] ' + $name + ' (' + $card.points + ' pts)')
  }
}
Assert ($Found -eq 7) ('Expected 7 SWM40 upgrade designs; validated ' + $Found + '.')

Header 'Validate final-cost provenance and SWM40 metadata'
$fleetRows=@(Read-JsonRecords (Join-Path $UpgradeDir 'fleet-command.json'))
$mercy=@($fleetRows | Where-Object { $_.name -eq 'Mercy Mission' })[0]
Assert ([int]$mercy.'points-history'.printed -eq 0 -and [int]$mercy.'points-history'.current -eq 5) 'Mercy Mission points-history mismatch.'
$meta=Get-Content -LiteralPath $MetaPath -Raw | ConvertFrom-Json
Assert ($meta.code -eq 'SWM40') 'SWM40 metadata code mismatch.'
Assert ([int]$meta.contents.'ship-cards' -eq 2) 'SWM40 ship card count mismatch.'
Assert ([int]$meta.contents.'upgrade-cards' -eq 7) 'SWM40 upgrade card count mismatch.'
Assert ([int]$meta.'database-records-added'.'unique-upgrade-designs' -eq 7) 'SWM40 unique upgrade design count mismatch.'
Write-Host '[OK] Mercy Mission final 5 / printed 0 provenance verified'
Write-Host '[OK] SWM40 metadata: 2 ship cards / 7 unique upgrade designs'

Header 'Install reusable verifier snapshot'
$ToolsDir=Join-Path $Repo 'tools'; New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$Verifier=Join-Path $ToolsDir 'verify_milestone_1_4.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed ' + $Verifier)

Write-Host ''
Write-Host '[OK] Milestone 1.4 complete.'
Write-Host '[OK] Pelta-class Frigate Expansion Pack data is installed and verified.'
Write-Host ('[OK] Backup: ' + $Backup)
