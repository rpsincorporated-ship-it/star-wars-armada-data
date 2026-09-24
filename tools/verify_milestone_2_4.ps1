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
function Read-MilestoneJsonRecords([string]$Path){
  return @(Read-MilestoneJson $Path)
}
function Write-MilestoneJsonRecords([string]$Path,[object[]]$Rows){
  $Json=ConvertTo-Json -InputObject @($Rows) -Depth 40
  Set-Content -LiteralPath $Path -Value $Json -Encoding UTF8
}
function Merge-MilestoneJsonByName([string]$Target,[string]$Payload,[string[]]$Names){
  $Existing=@()
  if(Test-Path -LiteralPath $Target){$Existing=@(Read-MilestoneJsonRecords $Target)}
  $Incoming=@(Read-MilestoneJsonRecords $Payload)
  $Keep=@($Existing|Where-Object{$Names -notcontains [string]$_.name})
  Write-MilestoneJsonRecords $Target (@($Keep)+@($Incoming))
  $Check=@(Read-MilestoneJsonRecords $Target)
  foreach($Name in $Names){
    $Matches=@($Check|Where-Object{$_.name -eq $Name})
    Assert-Milestone ($Matches.Count -eq 1) ($Name+' must exist exactly once after merge; found '+$Matches.Count+'.')
  }
}

Write-MilestoneSection 'Milestone 2.4 preflight'
$Meta42=Join-Path $Repo 'metadata\products\swm42.json'
$Verifier23=Join-Path $Repo 'tools\verify_milestone_2_3.ps1'
Assert-Milestone (Test-Path -LiteralPath $Meta42) 'SWM42 metadata is missing.'
Assert-Milestone (Test-Path -LiteralPath $Verifier23) 'Milestone 2.3 verifier is missing.'
$Baseline=Read-MilestoneJson $Meta42
Assert-Milestone ($Baseline.code -eq 'SWM42') 'SWM42 baseline metadata is invalid.'
Write-Host '[OK] Verified Milestone 2.3 Providence baseline detected'

$ShipDir=Join-Path $Repo 'data\ship-card\separatist-alliance'
$UpgradeDir=Join-Path $Repo 'data\upgrade-card'
$MetaDir=Join-Path $Repo 'metadata\products'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $ShipDir,$UpgradeDir,$MetaDir,$ToolsDir -Force|Out-Null

Write-MilestoneSection 'Backup existing Milestone 2.4 targets'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_2_4_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$Targets=@(
 'data\ship-card\separatist-alliance\recusant-class-light-destroyer.json',
 'data\ship-card\separatist-alliance\recusant-class-support-destroyer.json',
 'data\upgrade-card\commander.json',
 'data\upgrade-card\officer.json',
 'data\upgrade-card\title.json',
 'metadata\products\swm43.json',
 'tools\verify_milestone_2_4.ps1'
)
foreach($Relative in $Targets){
  $SourcePath=Join-Path $Repo $Relative
  if(Test-Path -LiteralPath $SourcePath){
    $BackupPath=Join-Path $Backup $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $BackupPath) -Force|Out-Null
    Copy-Item -LiteralPath $SourcePath -Destination $BackupPath -Force
  }
}
Write-Host ('[OK] Backup created: '+$Backup)

Write-MilestoneSection 'Install SWM43 Recusant ship designs'
foreach($FileName in @('recusant-class-light-destroyer.json','recusant-class-support-destroyer.json')){
  $Payload=Join-Path $PackageRoot ('patch\data\ship-card\separatist-alliance\'+$FileName)
  Assert-Milestone (Test-Path -LiteralPath $Payload) ('Bundled ship payload missing: '+$FileName)
  Copy-Item -LiteralPath $Payload -Destination (Join-Path $ShipDir $FileName) -Force
  Write-Host ('[OK] Installed '+$FileName)
}

Write-MilestoneSection 'Merge 8 new SWM43-origin upgrade designs'
$UpgradeMap=@{
 'commander.json'=@('Mar Tuuk','TF-1726')
 'officer.json'=@('Passel Argente','San Hill','Shu Mai')
 'title.json'=@('Gilded Aegis','Nova Defiant','Patriot Fist')
}
foreach($FileName in $UpgradeMap.Keys){
  $Payload=Join-Path $PackageRoot ('patch\upgrades\'+$FileName)
  Merge-MilestoneJsonByName (Join-Path $UpgradeDir $FileName) $Payload @($UpgradeMap[$FileName])
  Write-Host ('[OK] '+$FileName+': merged '+@($UpgradeMap[$FileName]).Count+' SWM43 design(s)')
}

Write-MilestoneSection 'Validate three SWM43 reprint designs'
$Reprints=@(
  @('B2 Rocket Troopers','offensive-retrofit.json',7,'SWM42'),
  @('Flak Guns','offensive-retrofit.json',3,'SWM41'),
  @('DBY-827 Heavy Turbolasers','turbolasers.json',3,'SWM41')
)
foreach($Item in $Reprints){
  $Name=[string]$Item[0]
  $FileName=[string]$Item[1]
  $ExpectedPoints=[int]$Item[2]
  $ExpectedOrigin=[string]$Item[3]
  $Rows=@(Read-MilestoneJsonRecords (Join-Path $UpgradeDir $FileName))
  $Matches=@($Rows|Where-Object{$_.name -eq $Name})
  Assert-Milestone ($Matches.Count -eq 1) ($Name+' must already exist exactly once; found '+$Matches.Count+'.')
  Assert-Milestone ([int]$Matches[0].points -eq $ExpectedPoints) ($Name+' expected '+$ExpectedPoints+' points.')
  Assert-Milestone ($Matches[0].source.'product-code' -eq $ExpectedOrigin) ($Name+' origin must remain '+$ExpectedOrigin+'.')
  Write-Host ('[OK] '+$Name+' represented once at '+$ExpectedPoints+' pts with '+$ExpectedOrigin+' origin preserved')
}

Write-MilestoneSection 'Install SWM43 product metadata'
$MetadataPayload=Join-Path $PackageRoot 'patch\metadata\products\swm43.json'
Assert-Milestone (Test-Path -LiteralPath $MetadataPayload) 'Bundled SWM43 metadata is missing.'
Copy-Item -LiteralPath $MetadataPayload -Destination (Join-Path $MetaDir 'swm43.json') -Force
Write-Host '[OK] Installed SWM43 product metadata'

Write-MilestoneSection 'Validate Recusant ship records'
$ShipExpected=@{
 'recusant-class-light-destroyer.json'=@('Recusant-class Light Destroyer',85,'black')
 'recusant-class-support-destroyer.json'=@('Recusant-class Support Destroyer',90,'red')
}
foreach($FileName in $ShipExpected.Keys){
  $Rows=@(Read-MilestoneJsonRecords (Join-Path $ShipDir $FileName))
  Assert-Milestone ($Rows.Count -eq 1) ($FileName+' must contain one top-level record.')
  $Record=$Rows[0]
  $Expected=$ShipExpected[$FileName]
  Assert-Milestone ($Record.name -eq $Expected[0]) ($FileName+' name mismatch.')
  Assert-Milestone ([int]$Record.points -eq [int]$Expected[1]) ($Record.name+' points mismatch.')
  Assert-Milestone ([int]$Record.hull -eq 8) ($Record.name+' hull mismatch.')
  Assert-Milestone ([int]$Record.command -eq 3 -and [int]$Record.squadron -eq 3 -and [int]$Record.engineering -eq 3) ($Record.name+' command/squadron/engineering mismatch.')
  Assert-Milestone ($Record.source.'product-code' -eq 'SWM43') ($Record.name+' product provenance mismatch.')
  Write-Host ('[OK] '+$Record.name+' ('+$Record.points+' pts)')
}

Write-MilestoneSection 'Validate all 8 SWM43-origin upgrade designs'
$ExpectedPoints=@{
 'Mar Tuuk'=28;'TF-1726'=26;'Passel Argente'=6;'San Hill'=3;'Shu Mai'=4;
 'Gilded Aegis'=5;'Nova Defiant'=4;'Patriot Fist'=6
}
$Count=0
foreach($FileName in $UpgradeMap.Keys){
  $Rows=@(Read-MilestoneJsonRecords (Join-Path $UpgradeDir $FileName))
  foreach($Name in @($UpgradeMap[$FileName])){
    $Matches=@($Rows|Where-Object{$_.name -eq $Name})
    Assert-Milestone ($Matches.Count -eq 1) ($Name+' missing or duplicated.')
    Assert-Milestone ([int]$Matches[0].points -eq [int]$ExpectedPoints[$Name]) ($Name+' points mismatch.')
    Assert-Milestone ($Matches[0].source.'product-code' -eq 'SWM43') ($Name+' SWM43 provenance mismatch.')
    $Count++
    Write-Host ('[OK] '+$Name+' ('+$Matches[0].points+' pts)')
  }
}
Assert-Milestone ($Count -eq 8) ('Expected 8 new SWM43-origin upgrades; validated '+$Count+'.')

Write-MilestoneSection 'Validate SWM43 inventory and official-final boundary'
$Meta=Read-MilestoneJson (Join-Path $MetaDir 'swm43.json')
Assert-Milestone ($Meta.code -eq 'SWM43') 'SWM43 metadata code mismatch.'
Assert-Milestone ([int]$Meta.contents.'ship-miniatures' -eq 1) 'SWM43 miniature count mismatch.'
Assert-Milestone ([int]$Meta.contents.'ship-cards' -eq 2) 'SWM43 ship-card count mismatch.'
Assert-Milestone ([int]$Meta.contents.'upgrade-cards' -eq 14) 'SWM43 physical upgrade-card count mismatch.'
Assert-Milestone ([int]$Meta.'database-designs'.'unique-upgrade-designs-in-product' -eq 11) 'SWM43 unique upgrade-design count mismatch.'
Assert-Milestone ([int]$Meta.'database-designs'.'new-swm43-origin-upgrade-designs' -eq 8) 'SWM43 new-origin count mismatch.'
Assert-Milestone ([int]$Meta.'database-designs'.'reprinted-designs' -eq 3) 'SWM43 reprint count mismatch.'
Write-Host '[OK] SWM43 inventory: 1 miniature / 2 ship cards / 14 physical upgrades / 11 unique upgrade designs'
Write-Host '[OK] 8 new SWM43-origin upgrades / 3 prior-product reprints'
Write-Host '[OK] Official-final AMG values retained; later ARC/Legacy/community revisions excluded'

Write-MilestoneSection 'Install reusable verifier'
$VerifierPath=Join-Path $ToolsDir 'verify_milestone_2_4.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $VerifierPath -Force
Write-Host ('[OK] Installed '+$VerifierPath)

Write-Host ''
Write-Host '[OK] Milestone 2.4 complete.'
Write-Host '[OK] Recusant-class Destroyer Expansion Pack data is installed and fully verified.'
Write-Host '[OK] 2 ship designs / 8 new SWM43-origin upgrade designs installed.'
Write-Host '[OK] B2 Rocket Troopers, Flak Guns, and DBY-827 Heavy Turbolasers preserved as single reprint records.'
Write-Host ('[OK] Backup: '+$Backup)
