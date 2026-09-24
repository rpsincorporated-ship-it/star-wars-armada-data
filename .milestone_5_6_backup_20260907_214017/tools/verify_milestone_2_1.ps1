param(
  [Parameter(Mandatory=$true)][string]$RepoPath
)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$ScriptRoot=Split-Path -Parent $MyInvocation.MyCommand.Path

function Header([string]$Text){ Write-Host ''; Write-Host ('='*60); Write-Host ('=> ' + $Text); Write-Host ('='*60) }
function Assert([bool]$Condition,[string]$Message){ if(-not $Condition){ throw $Message } }
function Read-JsonAny([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){ throw ('Missing JSON file: ' + $Path) }
  $raw=Get-Content -LiteralPath $Path -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw ('Empty JSON file: ' + $Path) }
  try { return ($raw | ConvertFrom-Json) } catch { throw ('Invalid JSON in ' + $Path + ': ' + $_.Exception.Message) }
}
function Read-JsonRecords([string]$Path){ return @(Read-JsonAny $Path) }
function Write-JsonArray([string]$Path,[object[]]$Rows){
  Set-Content -LiteralPath $Path -Value (ConvertTo-Json -InputObject @($Rows) -Depth 40) -Encoding UTF8
}

Header 'Milestone 2.1a preflight'
$ShipDir=Join-Path $Repo 'data\ship-card\separatist-alliance'
$SqDir=Join-Path $Repo 'data\squadron-card\separatist-alliance'
$UpgradeDir=Join-Path $Repo 'data\upgrade-card'
$MetaDir=Join-Path $Repo 'metadata\products'

foreach($file in @(
 'munificent-class-comms-frigate.json',
 'munificent-class-star-frigate.json',
 'hardcell-class-transport.json',
 'hardcell-class-battle-refit.json'
)){
  Assert (Test-Path -LiteralPath (Join-Path $ShipDir $file)) ('Partial Milestone 2.1 ship payload missing: ' + $file)
}
foreach($file in @('vulture-class-droid-fighter-squadron.json','haor-chall-prototypes.json')){
  Assert (Test-Path -LiteralPath (Join-Path $SqDir $file)) ('Partial Milestone 2.1 squadron payload missing: ' + $file)
}
Write-Host '[OK] Partial Milestone 2.1 SWM35 ship/squadron payload detected'

$ExpectedNew=@{
 'commander.json'=@('Count Dooku','Kraken')
 'offensive-retrofit.json'=@('Hyperwave Signal Boost')
 'officer.json'=@('Rune Haako','Wat Tambor','T-Series Tactical Droid')
 'support-team.json'=@('Battle Droid Reserves')
 'title.json'=@('Beast of Burden',"Foreman's Labor",'Sa Nalaor','Tide of Progress XII')
}
foreach($file in $ExpectedNew.Keys){
  $rows=@(Read-JsonRecords (Join-Path $UpgradeDir $file))
  foreach($name in @($ExpectedNew[$file])){
    Assert (@($rows | Where-Object { $_.name -eq $name }).Count -eq 1) ('Partial Milestone 2.1 upgrade missing or duplicated: ' + $name)
  }
}
Write-Host '[OK] All 11 new SWM35 Separatist upgrades are already installed exactly once'

Header 'Backup hotfix targets'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_2_1a_backup_' + $Stamp)
New-Item -ItemType Directory -Path $Backup -Force | Out-Null
foreach($p in @(
  (Join-Path $UpgradeDir 'offensive-retrofit.json'),
  (Join-Path $MetaDir 'swm35.json'),
  (Join-Path $Repo 'tools\verify_milestone_2_1.ps1')
)){
  if(Test-Path -LiteralPath $p){
    $rel=$p.Substring($Repo.Length).TrimStart('\')
    $dest=Join-Path $Backup $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $p -Destination $dest -Force
  }
}
Write-Host ('[OK] Backup created: ' + $Backup)

Header 'Repair Reserve Hangar Deck shared neutral record'
$Target=Join-Path $UpgradeDir 'offensive-retrofit.json'
$rows=@()
if(Test-Path -LiteralPath $Target){ $rows=@(Read-JsonRecords $Target) }
$existing=@($rows | Where-Object { $_.name -eq 'Reserve Hangar Deck' })
if($existing.Count -eq 0){
  $payload=@(Read-JsonRecords (Join-Path $ScriptRoot 'patch\upgrades\offensive-retrofit.json'))
  $rows=@($rows)+@($payload)
  Write-JsonArray $Target $rows
  Write-Host '[OK] Installed missing Reserve Hangar Deck neutral design'
} elseif($existing.Count -eq 1) {
  $card=$existing[0]
  $card.points=4
  if($null -eq $card.PSObject.Properties['points-history']){
    $card | Add-Member -NotePropertyName 'points-history' -NotePropertyValue ([pscustomobject]@{printed=3;current=4})
  } else {
    $card.'points-history'.printed=3
    $card.'points-history'.current=4
  }
  if($null -eq $card.PSObject.Properties['text']){
    $payload=@(Read-JsonRecords (Join-Path $ScriptRoot 'patch\upgrades\offensive-retrofit.json'))[0]
    $card | Add-Member -NotePropertyName text -NotePropertyValue $payload.text
  }
  Write-JsonArray $Target $rows
  Write-Host '[OK] Existing Reserve Hangar Deck normalized to final 4-point state'
} else {
  throw ('Reserve Hangar Deck is duplicated; found ' + $existing.Count + ' records.')
}
$check=@(Read-JsonRecords $Target | Where-Object { $_.name -eq 'Reserve Hangar Deck' })
Assert ($check.Count -eq 1) 'Reserve Hangar Deck repair did not produce exactly one record.'
Assert ([int]$check[0].points -eq 4) 'Reserve Hangar Deck active point cost is not 4.'
Assert ([int]$check[0].'points-history'.printed -eq 3 -and [int]$check[0].'points-history'.current -eq 4) 'Reserve Hangar Deck point history is not 3 -> 4.'
Write-Host '[OK] Reserve Hangar Deck final 4 / printed 3 provenance verified'

Header 'Validate all six SWM35 neutral/reprinted designs'
$Reprints=@{
 'Reactive Gunnery'=@('defensive-retrofit.json',4)
 'Heavy Ion Emplacements'=@('ion-cannons.json',9)
 'Munitions Resupply'=@('fleet-support.json',3)
 'Parts Resupply'=@('fleet-support.json',3)
 'Reserve Hangar Deck'=@('offensive-retrofit.json',4)
 'Swivel-Mount Batteries'=@('turbolasers.json',8)
}
foreach($name in $Reprints.Keys){
  $file=[string]$Reprints[$name][0]
  $pts=[int]$Reprints[$name][1]
  $path=Join-Path $UpgradeDir $file
  Assert (Test-Path -LiteralPath $path) ('Required reprint source file missing: ' + $file)
  $m=@(Read-JsonRecords $path | Where-Object { $_.name -eq $name })
  Assert ($m.Count -eq 1) ($name + ' expected exactly once; found ' + $m.Count + '.')
  Assert ([int]$m[0].points -eq $pts) ($name + ' point mismatch; expected final ' + $pts + '.')
  Write-Host ('[OK] ' + $name + ' represented once at final ' + $pts + ' pts')
}

Header 'Install corrected SWM35 product metadata'
New-Item -ItemType Directory -Path $MetaDir -Force | Out-Null
$MetaPath=Join-Path $MetaDir 'swm35.json'
Copy-Item -LiteralPath (Join-Path $ScriptRoot 'patch\metadata\products\swm35.json') -Destination $MetaPath -Force
$meta=Read-JsonAny $MetaPath
$rhdMeta=@($meta.reprints | Where-Object { $_.name -eq 'Reserve Hangar Deck' })
Assert ($rhdMeta.Count -eq 1 -and [int]$rhdMeta[0].'expected-points' -eq 4) 'Corrected SWM35 Reserve Hangar Deck metadata is invalid.'
Write-Host '[OK] Installed corrected SWM35 metadata with Reserve Hangar Deck at final 4 pts'

Header 'Validate SWM35 ships, squadrons, and new upgrades'
$ShipExpected=@{
 'munificent-class-comms-frigate.json'=@('Munificent-class Comms Frigate',70)
 'munificent-class-star-frigate.json'=@('Munificent-class Star Frigate',73)
 'hardcell-class-transport.json'=@('Hardcell-class Transport',47)
 'hardcell-class-battle-refit.json'=@('Hardcell-class Battle Refit',50)
}
foreach($file in $ShipExpected.Keys){
  $r=@(Read-JsonRecords (Join-Path $ShipDir $file))[0]
  $e=$ShipExpected[$file]
  Assert ($r.name -eq $e[0] -and [int]$r.points -eq [int]$e[1]) ('Ship validation failed: ' + $file)
  Write-Host ('[OK] ' + $r.name + ' (' + $r.points + ' pts)')
}
$SqExpected=@{
 'vulture-class-droid-fighter-squadron.json'=@('Vulture-class Droid Fighter Squadron',8)
 'haor-chall-prototypes.json'=@('Haor Chall Prototypes',16)
}
foreach($file in $SqExpected.Keys){
  $r=@(Read-JsonRecords (Join-Path $SqDir $file))[0]
  $e=$SqExpected[$file]
  Assert ($r.name -eq $e[0] -and [int]$r.points -eq [int]$e[1]) ('Squadron validation failed: ' + $file)
  Write-Host ('[OK] ' + $r.name + ' (' + $r.points + ' pts)')
}
$PointChecks=@{
 'Count Dooku'=27;'Kraken'=30;'Hyperwave Signal Boost'=3;'Rune Haako'=4;'Wat Tambor'=9;
 'T-Series Tactical Droid'=4;'Battle Droid Reserves'=4;'Beast of Burden'=6;"Foreman's Labor"=5;
 'Sa Nalaor'=5;'Tide of Progress XII'=2
}
$Validated=0
foreach($file in $ExpectedNew.Keys){
  $rows=@(Read-JsonRecords (Join-Path $UpgradeDir $file))
  foreach($name in @($ExpectedNew[$file])){
    $m=@($rows | Where-Object { $_.name -eq $name })
    Assert ($m.Count -eq 1) ($name + ' missing or duplicated.')
    Assert ([int]$m[0].points -eq [int]$PointChecks[$name]) ($name + ' point mismatch.')
    $Validated++
  }
}
Assert ($Validated -eq 11) 'Expected 11 new SWM35 upgrade designs.'
Write-Host '[OK] All 11 new SWM35 Separatist upgrade designs validated'

Header 'Validate final-point provenance and SWM35 inventory'
$battle=@(Read-JsonRecords (Join-Path $ShipDir 'hardcell-class-battle-refit.json'))[0]
Assert ([int]$battle.'points-history'.printed -eq 52 -and [int]$battle.'points-history'.current -eq 50) 'Hardcell Battle Refit point history mismatch.'
$cmd=@(Read-JsonRecords (Join-Path $UpgradeDir 'commander.json'))
$dooku=@($cmd | Where-Object { $_.name -eq 'Count Dooku' })[0]
Assert ([int]$dooku.'points-history'.printed -eq 30 -and [int]$dooku.'points-history'.current -eq 27) 'Count Dooku point history mismatch.'
$off=@(Read-JsonRecords (Join-Path $UpgradeDir 'officer.json'))
$wat=@($off | Where-Object { $_.name -eq 'Wat Tambor' })[0]
Assert ([int]$wat.'points-history'.printed -eq 5 -and [int]$wat.'points-history'.current -eq 9) 'Wat Tambor point history mismatch.'
Assert ([int]$meta.contents.'ship-cards' -eq 6) 'SWM35 ship-card inventory mismatch.'
Assert ([int]$meta.contents.'upgrade-cards' -eq 20) 'SWM35 upgrade-card inventory mismatch.'
Assert ([int]$meta.'database-designs'.'unique-upgrade-designs-in-product' -eq 17) 'SWM35 unique upgrade count mismatch.'
Write-Host '[OK] Hardcell Battle Refit final 50 / printed 52 provenance verified'
Write-Host '[OK] Count Dooku final 27 / printed 30 provenance verified'
Write-Host '[OK] Wat Tambor final 9 / printed 5 provenance verified'
Write-Host '[OK] Reserve Hangar Deck final 4 / printed 3 provenance verified'
Write-Host '[OK] SWM35 inventory: 6 physical ship cards / 2 squadron cards / 20 physical upgrades / 17 unique upgrade designs'

Header 'Install repaired reusable verifier'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$Verifier=Join-Path $ToolsDir 'verify_milestone_2_1.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed repaired verifier: ' + $Verifier)

Write-Host ''
Write-Host '[OK] Milestone 2.1a complete.'
Write-Host '[OK] Milestone 2.1 Separatist Alliance Fleet Starter foundation is repaired and fully verified.'
Write-Host '[OK] Existing SWM35 CIS data was preserved; only the missing/stale shared Reserve Hangar Deck layer was repaired.'
Write-Host ('[OK] Backup: ' + $Backup)
