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

Header 'Milestone 1.3 preflight'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'data')) 'Missing data folder.'
$ShipDir = Join-Path $Repo 'data\ship-card\galactic-republic'
$SqDir = Join-Path $Repo 'data\squadron-card\galactic-republic'
Assert (Test-Path -LiteralPath $ShipDir) 'Milestone 1.1 Republic ship baseline is missing.'
Assert (Test-Path -LiteralPath $SqDir) 'Milestone 1.2 Republic squadron baseline is missing.'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'metadata\products\swm36.json')) 'Milestone 1.2 SWM36 metadata is missing.'
Assert (Test-Path -LiteralPath (Join-Path $SqDir 'arc-170-squadron.json')) 'Milestone 1.2 ARC-170 Squadron is missing.'
Write-Host '[OK] Milestones 1.1 and 1.2 Republic baseline detected'

Header 'Backup existing Milestone 1.3 targets'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup = Join-Path $Repo ('.milestone_1_3_backup_' + $Stamp)
New-Item -ItemType Directory -Path $Backup -Force | Out-Null
$ShipTargets = @('venator-i-class-star-destroyer.json','venator-ii-class-star-destroyer.json')
foreach($file in $ShipTargets){ $p=Join-Path $ShipDir $file; if(Test-Path -LiteralPath $p){ Copy-Item -LiteralPath $p -Destination (Join-Path $Backup $file) -Force } }
$UpgradeDir = Join-Path $Repo 'data\upgrade-card'
$UpgradeTargets = @('commander.json','defensive-retrofit.json','fleet-command.json','offensive-retrofit.json','officer.json','title.json','turbolasers.json')
foreach($file in $UpgradeTargets){ $p=Join-Path $UpgradeDir $file; if(Test-Path -LiteralPath $p){ Copy-Item -LiteralPath $p -Destination (Join-Path $Backup $file) -Force } }
$MetaDir = Join-Path $Repo 'metadata\products'; $MetaPath=Join-Path $MetaDir 'swm41.json'
if(Test-Path -LiteralPath $MetaPath){ Copy-Item -LiteralPath $MetaPath -Destination (Join-Path $Backup 'swm41.json') -Force }
Write-Host ('[OK] Backup created: ' + $Backup)

Header 'Install SWM41 Venator ship data'
New-Item -ItemType Directory -Path $ShipDir -Force | Out-Null
foreach($file in $ShipTargets){
  $src=Join-Path $ScriptRoot ('patch\data\ship-card\galactic-republic\' + $file)
  Assert (Test-Path -LiteralPath $src) ('Package ship file missing: ' + $file)
  Copy-Item -LiteralPath $src -Destination (Join-Path $ShipDir $file) -Force
  Write-Host ('[OK] Installed ' + $file)
}

Header 'Merge SWM41 upgrades idempotently'
$ExpectedByFile = @{
 'commander.json'=@('Luminara Unduli','Plo Koon')
 'defensive-retrofit.json'=@('Thermal Shields')
 'fleet-command.json'=@('Hot Landing')
 'offensive-retrofit.json'=@('Flak Guns','SPHA-T')
 'officer.json'=@('Barriss Offee','Ahsoka Tano','Clone Commander Wolffe')
 'title.json'=@('Resolute','Tranquility','Triumphant')
 'turbolasers.json'=@('DBY-827 Heavy Turbolasers')
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
    Assert ($count -eq 1) (('${0}: {1} expected once after merge; found {2}.' -f $file,$expectedName,$count))
  }
  Write-Host ('[OK] ' + $file + ': merged ' + $incoming.Count + ' SWM41 design(s)')
}

Header 'Install SWM41 product metadata'
New-Item -ItemType Directory -Path $MetaDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $ScriptRoot 'patch\metadata\products\swm41.json') -Destination $MetaPath -Force
Write-Host '[OK] Installed SWM41 metadata'

Header 'Validate Venator ship records'
$ShipExpected=@{
 'venator-i-class-star-destroyer.json'=@('Venator I-class Star Destroyer',90,3,9,3)
 'venator-ii-class-star-destroyer.json'=@('Venator II-class Star Destroyer',100,5,9,3)
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
  Assert ($r.source.'product-code' -eq 'SWM41') ($file + ' source product-code mismatch.')
  Write-Host ('[OK] ' + $r.name + ' (' + $r.points + ' pts)')
}

Header 'Validate all 13 SWM41 upgrade designs'
$PointChecks=@{
 'Luminara Unduli'=25; 'Plo Koon'=26; 'Thermal Shields'=5; 'Hot Landing'=3; 'Flak Guns'=3; 'SPHA-T'=7;
 'Barriss Offee'=6; 'Ahsoka Tano'=6; 'Clone Commander Wolffe'=6; 'Resolute'=4; 'Tranquility'=7; 'Triumphant'=5; 'DBY-827 Heavy Turbolasers'=3
}
$Found=0
foreach($file in $UpgradeTargets){
  $rows=@(Read-JsonRecords (Join-Path $UpgradeDir $file))
  foreach($name in @($ExpectedByFile[$file])){
    $matches=@($rows | Where-Object { $_.name -eq $name })
    Assert ($matches.Count -eq 1) ($name + ' expected exactly once in ' + $file + '; found ' + $matches.Count + '.')
    $card=$matches[0]
    Assert ([int]$card.points -eq [int]$PointChecks[$name]) ($name + ' points mismatch.')
    Assert ($card.source.'product-code' -eq 'SWM41') ($name + ' source product-code mismatch.')
    $Found++
    Write-Host ('[OK] ' + $name + ' (' + $card.points + ' pts)')
  }
}
Assert ($Found -eq 13) ('Expected 13 SWM41 upgrade designs; validated ' + $Found + '.')

Header 'Validate final-cost provenance and SWM41 metadata'
$offRows=@(Read-JsonRecords (Join-Path $UpgradeDir 'offensive-retrofit.json'))
$spha=@($offRows | Where-Object { $_.name -eq 'SPHA-T' })[0]
Assert ([int]$spha.'points-history'.printed -eq 3 -and [int]$spha.'points-history'.current -eq 7) 'SPHA-T points-history mismatch.'
$titleRows=@(Read-JsonRecords (Join-Path $UpgradeDir 'title.json'))
$res=@($titleRows | Where-Object { $_.name -eq 'Resolute' })[0]
Assert ([int]$res.'points-history'.printed -eq 6 -and [int]$res.'points-history'.current -eq 4) 'Resolute points-history mismatch.'
$meta=Get-Content -LiteralPath $MetaPath -Raw | ConvertFrom-Json
Assert ($meta.code -eq 'SWM41') 'SWM41 metadata code mismatch.'
Assert ([int]$meta.contents.'ship-cards' -eq 2) 'SWM41 ship card count mismatch.'
Assert ([int]$meta.contents.'upgrade-cards' -eq 16) 'SWM41 physical upgrade card count mismatch.'
Assert ([int]$meta.'database-records-added'.'unique-upgrade-designs' -eq 13) 'SWM41 unique upgrade design count mismatch.'
Write-Host '[OK] SPHA-T final 7 / printed 3 provenance verified'
Write-Host '[OK] Resolute final 4 / printed 6 provenance verified'
Write-Host '[OK] SWM41 metadata: 2 ship cards / 16 physical upgrades / 13 unique upgrade designs'

Header 'Install reusable verifier snapshot'
$ToolsDir=Join-Path $Repo 'tools'; New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$Verifier=Join-Path $ToolsDir 'verify_milestone_1_3.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed ' + $Verifier)

Write-Host ''
Write-Host '[OK] Milestone 1.3 complete.'
Write-Host '[OK] Venator-class Star Destroyer Expansion Pack data is installed and verified.'
Write-Host ('[OK] Backup: ' + $Backup)
