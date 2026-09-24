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

Header 'Milestone 2.2 preflight'
$SqDir=Join-Path $Repo 'data\squadron-card\separatist-alliance'
$MetaDir=Join-Path $Repo 'metadata\products'
$Verifier21=Join-Path $Repo 'tools\verify_milestone_2_1.ps1'
$Meta21=Join-Path $MetaDir 'swm35.json'
Assert (Test-Path -LiteralPath $Verifier21) 'Milestone 2.1 verified baseline is missing.'
Assert (Test-Path -LiteralPath $Meta21) 'SWM35 product metadata is missing.'
$m21=Read-JsonAny $Meta21
Assert ($m21.code -eq 'SWM35') 'SWM35 metadata baseline is invalid.'
Write-Host '[OK] Verified Milestone 2.1 Separatist Fleet Starter baseline detected'

Header 'Backup existing Milestone 2.2 targets'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_2_2_backup_' + $Stamp)
New-Item -ItemType Directory -Path $Backup -Force | Out-Null

$Files=@(
 'belbullab-22-squadron.json',
 'general-grievous-belbullab-22.json',
 'droid-tri-fighter-squadron.json',
 'phlac-arphocc-prototypes.json',
 'dis-t81.json',
 'hyena-class-droid-bomber-squadron.json',
 'baktoid-prototypes.json',
 'dbs-404.json',
 'dfs-311.json'
)
foreach($file in $Files){
  $p=Join-Path $SqDir $file
  if(Test-Path -LiteralPath $p){
    $rel=$p.Substring($Repo.Length).TrimStart('\')
    $dest=Join-Path $Backup $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $p -Destination $dest -Force
  }
}
foreach($p in @(
  (Join-Path $MetaDir 'swm37.json'),
  (Join-Path $Repo 'tools\verify_milestone_2_2.ps1')
)){
  if(Test-Path -LiteralPath $p){
    $rel=$p.Substring($Repo.Length).TrimStart('\')
    $dest=Join-Path $Backup $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $p -Destination $dest -Force
  }
}
Write-Host ('[OK] Backup created: ' + $Backup)

Header 'Install nine new SWM37 squadron designs'
New-Item -ItemType Directory -Path $SqDir -Force | Out-Null
foreach($file in $Files){
  $src=Join-Path $ScriptRoot ('patch\data\squadron-card\separatist-alliance\' + $file)
  Assert (Test-Path -LiteralPath $src) ('Bundled squadron payload missing: ' + $file)
  Copy-Item -LiteralPath $src -Destination (Join-Path $SqDir $file) -Force
  Write-Host ('[OK] Installed ' + $file)
}

Header 'Validate Vulture SWM37 reprint policy'
$VulturePath=Join-Path $SqDir 'vulture-class-droid-fighter-squadron.json'
Assert (Test-Path -LiteralPath $VulturePath) 'Existing SWM35 Vulture-class Droid Fighter Squadron record is missing.'
$v=@(Read-JsonRecords $VulturePath | Where-Object { $_.name -eq 'Vulture-class Droid Fighter Squadron' })
Assert ($v.Count -eq 1) ('Vulture-class Droid Fighter Squadron must be represented exactly once; found ' + $v.Count + '.')
Assert ([int]$v[0].points -eq 8) 'Vulture-class Droid Fighter Squadron must remain at 8 points in the official-final dataset.'
Write-Host '[OK] Vulture-class Droid Fighter Squadron represented once at 8 pts via existing SWM35 record'

Header 'Install SWM37 product metadata'
New-Item -ItemType Directory -Path $MetaDir -Force | Out-Null
$MetaPath=Join-Path $MetaDir 'swm37.json'
Copy-Item -LiteralPath (Join-Path $ScriptRoot 'patch\metadata\products\swm37.json') -Destination $MetaPath -Force
Write-Host '[OK] Installed SWM37 metadata'

Header 'Validate all nine new SWM37 squadron designs'
$Expected=@{
 'belbullab-22-squadron.json'=@('Belbullab-22 Squadron',15)
 'general-grievous-belbullab-22.json'=@('General Grievous',22)
 'droid-tri-fighter-squadron.json'=@('Droid Tri-fighter Squadron',11)
 'phlac-arphocc-prototypes.json'=@('Phlac-Arphocc Prototypes',18)
 'dis-t81.json'=@('DIS-T81',17)
 'hyena-class-droid-bomber-squadron.json'=@('Hyena-class Droid Bomber Squadron',11)
 'baktoid-prototypes.json'=@('Baktoid Prototypes',16)
 'dbs-404.json'=@('DBS-404',17)
 'dfs-311.json'=@('DFS-311',16)
}
foreach($file in $Files){
  $rows=@(Read-JsonRecords (Join-Path $SqDir $file))
  Assert ($rows.Count -eq 1) ($file + ' must contain exactly one top-level squadron record.')
  $r=$rows[0]
  $e=$Expected[$file]
  Assert ($r.name -eq $e[0]) ($file + ' name mismatch.')
  Assert ([int]$r.points -eq [int]$e[1]) ($r.name + ' point mismatch; expected ' + $e[1] + '.')
  Assert ($r.faction -eq 'Separatist Alliance') ($r.name + ' faction mismatch.')
  Assert ($r.source.'product-code' -eq 'SWM37') ($r.name + ' SWM37 product provenance mismatch.')
  Write-Host ('[OK] ' + $r.name + ' (' + $r.points + ' pts)')
}

Header 'Validate final AMG point provenance'
$dfs=@(Read-JsonRecords (Join-Path $SqDir 'dfs-311.json'))[0]
Assert ([int]$dfs.'points-history'.printed -eq 18 -and [int]$dfs.'points-history'.current -eq 16) 'DFS-311 point history mismatch.'
$phlac=@(Read-JsonRecords (Join-Path $SqDir 'phlac-arphocc-prototypes.json'))[0]
Assert ([int]$phlac.'points-history'.printed -eq 19 -and [int]$phlac.'points-history'.current -eq 18) 'Phlac-Arphocc Prototypes point history mismatch.'
Write-Host '[OK] DFS-311 final 16 / printed 18 provenance verified'
Write-Host '[OK] Phlac-Arphocc Prototypes final 18 / printed 19 provenance verified'
Write-Host '[OK] Belbullab-22 Squadron remains official-final AMG 15 pts (later community ARC changes excluded)'

Header 'Validate SWM37 inventory and uniqueness'
$meta=Read-JsonAny $MetaPath
Assert ($meta.code -eq 'SWM37') 'SWM37 metadata code mismatch.'
Assert ([int]$meta.contents.'squadron-miniatures' -eq 8) 'SWM37 miniature count mismatch.'
Assert ([int]$meta.contents.'squadron-cards' -eq 10) 'SWM37 physical squadron-card count mismatch.'
Assert ([int]$meta.'database-designs'.'new-designs' -eq 9) 'SWM37 new-design count mismatch.'
Assert ([int]$meta.'database-designs'.'reprinted-designs' -eq 1) 'SWM37 reprint count mismatch.'

$Names=@()
foreach($file in $Files){
  $Names += [string](@(Read-JsonRecords (Join-Path $SqDir $file))[0].name)
}
$Names += 'Vulture-class Droid Fighter Squadron'
$dupes=@($Names | Group-Object | Where-Object { $_.Count -gt 1 })
Assert ($dupes.Count -eq 0) 'SWM37 product design list contains duplicate names.'
Assert ($Names.Count -eq 10) ('Expected 10 SWM37 design names; found ' + $Names.Count + '.')
Write-Host '[OK] SWM37 inventory: 8 miniatures / 10 physical cards / 9 new designs / 1 verified reprint'

Header 'Install reusable verifier snapshot'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$Verifier=Join-Path $ToolsDir 'verify_milestone_2_2.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed ' + $Verifier)

Write-Host ''
Write-Host '[OK] Milestone 2.2 complete.'
Write-Host '[OK] Separatist Fighter Squadrons Expansion Pack data is installed and verified.'
Write-Host '[OK] 9 new SWM37 squadron designs installed; generic Vulture reprint represented once.'
Write-Host '[OK] Final AMG points provenance verified for DFS-311 and Phlac-Arphocc Prototypes.'
Write-Host ('[OK] Backup: ' + $Backup)
