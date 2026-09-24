param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$ScriptRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
function Write-MilestoneSection([string]$t){Write-Host '';Write-Host ('='*60);Write-Host ('=> '+$t);Write-Host ('='*60)}
function Assert-Milestone([bool]$c,[string]$m){if(-not $c){throw $m}}
function Read-JsonValue([string]$p){if(-not(Test-Path -LiteralPath $p)){throw('Missing JSON: '+$p)};$r=Get-Content -LiteralPath $p -Raw;try{return($r|ConvertFrom-Json)}catch{throw('Invalid JSON in '+$p+': '+$_.Exception.Message)}}
function Read-JsonRecords([string]$p){return @(Read-JsonValue $p)}
function Write-JsonRecords([string]$p,[object[]]$x){Set-Content -LiteralPath $p -Value (ConvertTo-Json -InputObject @($x) -Depth 40) -Encoding UTF8}
function Merge-JsonRecordsByName([string]$target,[string]$payload,[string[]]$names){
 $old=@();if(Test-Path -LiteralPath $target){$old=@(Read-JsonRecords $target)}
 $new=@(Read-JsonRecords $payload);$keep=@($old|Where-Object{$names -notcontains [string]$_.name});Write-JsonRecords $target (@($keep)+@($new))
 $chk=@(Read-JsonRecords $target);foreach($n in $names){Assert-Milestone (@($chk|Where-Object{$_.name -eq $n}).Count -eq 1) ($n+' not unique after merge.')}
}

Write-MilestoneSection 'Milestone 2.3 preflight'
$SqMeta=Join-Path $Repo 'metadata\products\swm37.json'
$V22=Join-Path $Repo 'tools\verify_milestone_2_2.ps1'
Assert-Milestone (Test-Path -LiteralPath $SqMeta) 'SWM37 metadata missing.'
Assert-Milestone (Test-Path -LiteralPath $V22) 'Milestone 2.2 verifier missing.'
Assert-Milestone ((Read-JsonValue $SqMeta).code -eq 'SWM37') 'SWM37 baseline invalid.'
Write-Host '[OK] Verified Milestone 2.2 Separatist fighter baseline detected'

$PartialShip1=Join-Path $Repo 'data\ship-card\separatist-alliance\providence-class-carrier.json'
$PartialShip2=Join-Path $Repo 'data\ship-card\separatist-alliance\providence-class-dreadnought.json'
if((Test-Path -LiteralPath $PartialShip1) -and (Test-Path -LiteralPath $PartialShip2)){
  Write-Host '[OK] Partial Milestone 2.3 ship payload detected from prior run; ships will be validated/reinstalled idempotently'
}


$ShipDir=Join-Path $Repo 'data\ship-card\separatist-alliance'
$UpDir=Join-Path $Repo 'data\upgrade-card'
$MetaDir=Join-Path $Repo 'metadata\products'
New-Item -ItemType Directory -Path $ShipDir,$UpDir,$MetaDir -Force|Out-Null

Write-MilestoneSection 'Backup existing Milestone 2.3 targets'
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss';$bak=Join-Path $Repo ('.milestone_2_3_backup_'+$stamp);New-Item -ItemType Directory -Path $bak -Force|Out-Null
$targets=@(
 'data\ship-card\separatist-alliance\providence-class-carrier.json',
 'data\ship-card\separatist-alliance\providence-class-dreadnought.json',
 'data\upgrade-card\commander.json','data\upgrade-card\fleet-command.json','data\upgrade-card\ion-cannons.json',
 'data\upgrade-card\offensive-retrofit.json','data\upgrade-card\officer.json','data\upgrade-card\title.json',
 'metadata\products\swm42.json','tools\verify_milestone_2_3.ps1'
)
foreach($rel in $targets){$p=Join-Path $Repo $rel;if(Test-Path -LiteralPath $p){$d=Join-Path $bak $rel;New-Item -ItemType Directory -Path (Split-Path -Parent $d) -Force|Out-Null;Copy-Item -LiteralPath $p -Destination $d -Force}}
Write-Host ('[OK] Backup created: '+$bak)

Write-MilestoneSection 'Install SWM42 Providence ship data'
foreach($f in @('providence-class-carrier.json','providence-class-dreadnought.json')){
 Copy-Item -LiteralPath (Join-Path $ScriptRoot ('patch\data\ship-card\separatist-alliance\'+$f)) -Destination (Join-Path $ShipDir $f) -Force
 Write-Host ('[OK] Installed '+$f)
}

Write-MilestoneSection 'Merge 10 SWM42-origin upgrade designs'
$map=@{
 'commander.json'=@('General Grievous','Admiral Trench')
 'fleet-command.json'=@('Jedi Hostage')
 'ion-cannons.json'=@('Point Defense Ion Cannons')
 'offensive-retrofit.json'=@('B2 Rocket Troopers')
 'officer.json'=@('TI-99','Tikkes')
 'title.json'=@('Invincible','Invisible Hand','Lucid Voice')
}
foreach($f in $map.Keys){Merge-JsonRecordsByName (Join-Path $UpDir $f) (Join-Path $ScriptRoot ('patch\upgrades\'+$f)) @($map[$f]);Write-Host ('[OK] '+$f+': merged '+@($map[$f]).Count+' SWM42 design(s)')}

Write-MilestoneSection 'Validate two SWM42 reprint designs'
$rep=@{'Thermal Shields'=@('defensive-retrofit.json',5);'Hot Landing'=@('fleet-command.json',3)}
foreach($n in $rep.Keys){$f=[string]$rep[$n][0];$pts=[int]$rep[$n][1];$m=@(Read-JsonRecords (Join-Path $UpDir $f)|Where-Object{$_.name -eq $n});Assert-Milestone ($m.Count -eq 1) ($n+' expected exactly once; found '+$m.Count);Assert-Milestone ([int]$m[0].points -eq $pts) ($n+' expected '+$pts+' points.');Write-Host ('[OK] '+$n+' represented once at '+$pts+' pts')}

Write-MilestoneSection 'Install SWM42 product metadata'
Copy-Item -LiteralPath (Join-Path $ScriptRoot 'patch\metadata\products\swm42.json') -Destination (Join-Path $MetaDir 'swm42.json') -Force
Write-Host '[OK] Installed SWM42 metadata'

Write-MilestoneSection 'Validate Providence final ship values'
$se=@{'providence-class-carrier.json'=@('Providence-class Carrier',102,105);'providence-class-dreadnought.json'=@('Providence-class Dreadnought',97,105)}
foreach($f in $se.Keys){$r=@(Read-JsonRecords (Join-Path $ShipDir $f))[0];$e=$se[$f];Assert-Milestone ($r.name -eq $e[0]) ($f+' name mismatch.');Assert-Milestone ([int]$r.points -eq [int]$e[1]) ($r.name+' final points mismatch.');Assert-Milestone ([int]$r.'points-history'.printed -eq [int]$e[2]) ($r.name+' printed provenance mismatch.');Assert-Milestone ($r.source.'product-code' -eq 'SWM42') ($r.name+' product provenance mismatch.');Write-Host ('[OK] '+$r.name+' final '+$r.points+' / printed '+$r.'points-history'.printed)}

Write-MilestoneSection 'Validate all 10 SWM42-origin upgrades'
$pts=@{'General Grievous'=20;'Admiral Trench'=32;'Jedi Hostage'=3;'Point Defense Ion Cannons'=6;'B2 Rocket Troopers'=7;'TI-99'=4;'Tikkes'=2;'Invincible'=5;'Invisible Hand'=8;'Lucid Voice'=8}
$c=0
foreach($f in $map.Keys){$rows=@(Read-JsonRecords (Join-Path $UpDir $f));foreach($n in @($map[$f])){$m=@($rows|Where-Object{$_.name -eq $n});Assert-Milestone ($m.Count -eq 1) ($n+' missing/duplicated.');Assert-Milestone ([int]$m[0].points -eq [int]$pts[$n]) ($n+' points mismatch.');Assert-Milestone ($m[0].source.'product-code' -eq 'SWM42') ($n+' provenance mismatch.');$c++;Write-Host ('[OK] '+$n+' ('+$m[0].points+' pts)')}}
Assert-Milestone ($c -eq 10) 'Expected 10 SWM42-origin upgrades.'

Write-MilestoneSection 'Validate final point provenance and SWM42 inventory'
$checks=@(
 @('Admiral Trench','commander.json',36,32),
 @('Point Defense Ion Cannons','ion-cannons.json',4,6),
 @('Invisible Hand','title.json',9,8)
)
foreach($x in $checks){$m=@(Read-JsonRecords (Join-Path $UpDir $x[1])|Where-Object{$_.name -eq $x[0]})[0];Assert-Milestone ([int]$m.'points-history'.printed -eq [int]$x[2] -and [int]$m.'points-history'.current -eq [int]$x[3]) ($x[0]+' point history mismatch.');Write-Host ('[OK] '+$x[0]+' final '+$x[3]+' / printed '+$x[2]+' provenance verified')}
$meta=Read-JsonValue (Join-Path $MetaDir 'swm42.json')
Assert-Milestone ([int]$meta.contents.'ship-cards' -eq 2) 'SWM42 ship-card count mismatch.'
Assert-Milestone ([int]$meta.contents.'upgrade-cards' -eq 14) 'SWM42 upgrade-card count mismatch.'
Assert-Milestone ([int]$meta.'database-designs'.'unique-upgrade-designs-in-product' -eq 12) 'SWM42 unique upgrade count mismatch.'
Assert-Milestone ([int]$meta.'database-designs'.'new-swm42-origin-upgrade-designs' -eq 10) 'SWM42 origin count mismatch.'
Write-Host '[OK] SWM42 inventory: 1 miniature / 2 ship cards / 14 physical upgrades / 12 unique upgrade designs'
Write-Host '[OK] Providence Carrier 105 -> 102 and Dreadnought 105 -> 97 final provenance verified'

Write-MilestoneSection 'Install reusable verifier snapshot'
$td=Join-Path $Repo 'tools';New-Item -ItemType Directory -Path $td -Force|Out-Null;$v=Join-Path $td 'verify_milestone_2_3.ps1';Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $v -Force;Write-Host ('[OK] Installed '+$v)

Write-Host ''
Write-Host '[OK] Milestone 2.3 complete.'
Write-Host '[OK] Invisible Hand / Providence-class expansion data is installed and verified.'
Write-Host '[OK] 2 ship designs / 10 SWM42-origin upgrade designs installed.'
Write-Host '[OK] Thermal Shields and Hot Landing reprints represented without duplication.'
Write-Host ('[OK] Backup: '+$bak)
