param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path

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
function Read-MilestoneJsonRecords([string]$Path){ return @(Read-MilestoneJson $Path) }
function Write-MilestoneJsonObject([string]$Path,[object]$Object){
  $Parent=Split-Path -Parent $Path
  if($Parent){New-Item -ItemType Directory -Path $Parent -Force|Out-Null}
  $Json=ConvertTo-Json -InputObject $Object -Depth 50
  Set-Content -LiteralPath $Path -Value $Json -Encoding UTF8
}
function Find-RecordByName([string]$Directory,[string]$Name){
  $Found=@()
  foreach($File in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File)){
    foreach($Record in @(Read-MilestoneJsonRecords $File.FullName)){
      if($Record.name -eq $Name){
        $Found+=,[pscustomobject]@{File=$File.Name;Path=$File.FullName;Record=$Record}
      }
    }
  }
  return @($Found)
}
function Test-ExpectedRecord([string]$Directory,[string]$Name,[int]$Points,[string]$ProductCode){
  $Found=@(Find-RecordByName $Directory $Name)
  Assert-Milestone ($Found.Count -eq 1) ($Name+' expected exactly once; found '+$Found.Count+'.')
  Assert-Milestone ([int]$Found[0].Record.points -eq $Points) ($Name+' expected '+$Points+' points; found '+$Found[0].Record.points+'.')
  Assert-Milestone ($Found[0].Record.source.'product-code' -eq $ProductCode) ($Name+' expected '+$ProductCode+' provenance; found '+$Found[0].Record.source.'product-code'+'.')
  return $Found[0]
}

Write-MilestoneSection 'Milestone 2.5 preflight'
foreach($Code in @('swm35','swm37','swm42','swm43')){
  $MetaPath=Join-Path $Repo ('metadata\products\'+$Code+'.json')
  Assert-Milestone (Test-Path -LiteralPath $MetaPath) ('Missing '+$Code.ToUpper()+' metadata.')
}
foreach($N in 1..4){
  $Verifier=Join-Path $Repo ('tools\verify_milestone_2_'+$N+'.ps1')
  Assert-Milestone (Test-Path -LiteralPath $Verifier) ('Missing Milestone 2.'+$N+' verifier.')
}
Write-Host '[OK] Verified Milestones 2.1 through 2.4 baselines and all four Separatist product metadata files'

Write-MilestoneSection 'Backup Milestone 2.5 audit outputs'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_2_5_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$AuditTargets=@(
 'reports\separatist-completeness-2.5.json',
 'reports\separatist-completeness-2.5.md',
 'metadata\audits\separatist-product-origin-2.5.json',
 'tools\verify_milestone_2_5.ps1'
)
foreach($Relative in $AuditTargets){
  $Source=Join-Path $Repo $Relative
  if(Test-Path -LiteralPath $Source){
    $Dest=Join-Path $Backup $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $Dest) -Force|Out-Null
    Copy-Item -LiteralPath $Source -Destination $Dest -Force
  }
}
Write-Host ('[OK] Backup created: '+$Backup)

$ShipDir=Join-Path $Repo 'data\ship-card\separatist-alliance'
$SquadDir=Join-Path $Repo 'data\squadron-card\separatist-alliance'
$UpgradeDir=Join-Path $Repo 'data\upgrade-card'

$Ships=@(
 @('Munificent-class Comms Frigate',70,'SWM35'),
 @('Munificent-class Star Frigate',73,'SWM35'),
 @('Hardcell-class Transport',47,'SWM35'),
 @('Hardcell-class Battle Refit',50,'SWM35'),
 @('Providence-class Carrier',102,'SWM42'),
 @('Providence-class Dreadnought',97,'SWM42'),
 @('Recusant-class Light Destroyer',85,'SWM43'),
 @('Recusant-class Support Destroyer',90,'SWM43')
)
$Squadrons=@(
 @('Vulture-class Droid Fighter Squadron',8,'SWM35'),
 @('Haor Chall Prototypes',16,'SWM35'),
 @('Belbullab-22 Squadron',15,'SWM37'),
 @('General Grievous',22,'SWM37'),
 @('Droid Tri-fighter Squadron',11,'SWM37'),
 @('Phlac-Arphocc Prototypes',18,'SWM37'),
 @('DIS-T81',17,'SWM37'),
 @('Hyena-class Droid Bomber Squadron',11,'SWM37'),
 @('Baktoid Prototypes',16,'SWM37'),
 @('DBS-404',17,'SWM37'),
 @('DFS-311',16,'SWM37')
)
$Upgrades=@(
 @('Count Dooku',27,'SWM35'),@('Kraken',30,'SWM35'),
 @('Hyperwave Signal Boost',3,'SWM35'),@('Rune Haako',4,'SWM35'),
 @('Wat Tambor',9,'SWM35'),@('T-Series Tactical Droid',4,'SWM35'),
 @('Battle Droid Reserves',4,'SWM35'),@('Beast of Burden',6,'SWM35'),
 @("Foreman's Labor",5,'SWM35'),@('Sa Nalaor',5,'SWM35'),@('Tide of Progress XII',2,'SWM35'),
 @('General Grievous',20,'SWM42'),@('Admiral Trench',32,'SWM42'),
 @('Jedi Hostage',3,'SWM42'),@('Point Defense Ion Cannons',6,'SWM42'),
 @('B2 Rocket Troopers',7,'SWM42'),@('TI-99',4,'SWM42'),@('Tikkes',2,'SWM42'),
 @('Invincible',5,'SWM42'),@('Invisible Hand',8,'SWM42'),@('Lucid Voice',8,'SWM42'),
 @('Mar Tuuk',28,'SWM43'),@('TF-1726',26,'SWM43'),@('Passel Argente',6,'SWM43'),
 @('San Hill',3,'SWM43'),@('Shu Mai',4,'SWM43'),@('Gilded Aegis',5,'SWM43'),
 @('Nova Defiant',4,'SWM43'),@('Patriot Fist',6,'SWM43')
)

Write-MilestoneSection 'Audit 8 Separatist product-origin ship designs'
$ShipAudit=@()
foreach($E in $Ships){
  $Hit=Test-ExpectedRecord $ShipDir ([string]$E[0]) ([int]$E[1]) ([string]$E[2])
  $ShipAudit+=,[pscustomobject]@{name=$E[0];points=[int]$E[1];product=$E[2];file=$Hit.File}
  Write-Host ('[OK] '+$E[0]+' ('+$E[1]+' pts / '+$E[2]+')')
}
Assert-Milestone ($ShipAudit.Count -eq 8) 'Ship audit count mismatch.'

Write-MilestoneSection 'Audit 11 Separatist product-origin squadron designs'
$SquadAudit=@()
foreach($E in $Squadrons){
  $Hit=Test-ExpectedRecord $SquadDir ([string]$E[0]) ([int]$E[1]) ([string]$E[2])
  $SquadAudit+=,[pscustomobject]@{name=$E[0];points=[int]$E[1];product=$E[2];file=$Hit.File}
  Write-Host ('[OK] '+$E[0]+' ('+$E[1]+' pts / '+$E[2]+')')
}
Assert-Milestone ($SquadAudit.Count -eq 11) 'Squadron audit count mismatch.'

Write-MilestoneSection 'Audit 29 Separatist product-origin upgrade designs'
$UpgradeAudit=@()
foreach($E in $Upgrades){
  $Hit=Test-ExpectedRecord $UpgradeDir ([string]$E[0]) ([int]$E[1]) ([string]$E[2])
  $UpgradeAudit+=,[pscustomobject]@{name=$E[0];points=[int]$E[1];product=$E[2];file=$Hit.File}
  Write-Host ('[OK] '+$E[0]+' ('+$E[1]+' pts / '+$E[2]+')')
}
Assert-Milestone ($UpgradeAudit.Count -eq 29) 'Upgrade audit count mismatch.'

Write-MilestoneSection 'Validate product-origin totals and duplicate boundaries'
$All=@($ShipAudit)+@($SquadAudit)+@($UpgradeAudit)
Assert-Milestone ($All.Count -eq 48) ('Expected 48 product-origin records; found '+$All.Count+'.')
$ShipDupes=@($ShipAudit|Group-Object name|Where-Object{$_.Count -ne 1})
$SquadDupes=@($SquadAudit|Group-Object name|Where-Object{$_.Count -ne 1})
Assert-Milestone ($ShipDupes.Count -eq 0) 'Duplicate product-origin ship names detected.'
Assert-Milestone ($SquadDupes.Count -eq 0) 'Duplicate product-origin squadron names detected.'
Write-Host '[OK] 48 / 48 unique Separatist product-origin design records accounted for'
Write-Host '[OK] 8 ships / 11 squadron designs / 29 upgrades'
Write-Host '[OK] No duplicate Separatist product-origin ship or squadron names'

Write-MilestoneSection 'Validate cross-product reprints and neutral/shared designs'
$Reprints=@(
 @('Vulture-class Droid Fighter Squadron',$SquadDir,8,'SWM35','SWM37 squadron-card reprint'),
 @('Reactive Gunnery',$UpgradeDir,4,'SWM34','SWM35 shared/reprint'),
 @('Heavy Ion Emplacements',$UpgradeDir,9,'','SWM35 legacy neutral reprint'),
 @('Munitions Resupply',$UpgradeDir,3,'SWM34','SWM35 shared/reprint'),
 @('Parts Resupply',$UpgradeDir,3,'SWM34','SWM35 shared/reprint'),
 @('Reserve Hangar Deck',$UpgradeDir,4,'','SWM35 neutral reprint'),
 @('Swivel-Mount Batteries',$UpgradeDir,8,'SWM34','SWM35 shared/reprint'),
 @('Thermal Shields',$UpgradeDir,5,'SWM41','SWM42 reprint'),
 @('Hot Landing',$UpgradeDir,3,'SWM41','SWM42 reprint'),
 @('Flak Guns',$UpgradeDir,3,'SWM41','SWM43 reprint'),
 @('DBY-827 Heavy Turbolasers',$UpgradeDir,3,'SWM41','SWM43 reprint')
)
foreach($R in $Reprints){
  $Found=@(Find-RecordByName ([string]$R[1]) ([string]$R[0]))
  Assert-Milestone ($Found.Count -eq 1) ($R[0]+' reprint/shared design expected once; found '+$Found.Count+'.')
  Assert-Milestone ([int]$Found[0].Record.points -eq [int]$R[2]) ($R[0]+' point mismatch.')
  if(-not [string]::IsNullOrWhiteSpace([string]$R[3])){
    Assert-Milestone ($Found[0].Record.source.'product-code' -eq [string]$R[3]) ($R[0]+' original provenance mismatch.')
  }
  Write-Host ('[OK] '+$R[0]+' represented once ('+$R[4]+')')
}

Write-MilestoneSection 'Validate official-final point provenance'
$Provenance=@(
 @('Hardcell-class Battle Refit',$ShipDir,52,50),
 @('Count Dooku',$UpgradeDir,30,27),
 @('Wat Tambor',$UpgradeDir,5,9),
 @('Reserve Hangar Deck',$UpgradeDir,3,4),
 @('Phlac-Arphocc Prototypes',$SquadDir,19,18),
 @('DFS-311',$SquadDir,18,16),
 @('Providence-class Carrier',$ShipDir,105,102),
 @('Providence-class Dreadnought',$ShipDir,105,97),
 @('Admiral Trench',$UpgradeDir,36,32),
 @('Point Defense Ion Cannons',$UpgradeDir,4,6),
 @('Invisible Hand',$UpgradeDir,9,8)
)
$ProvAudit=@()
foreach($P in $Provenance){
  $Found=@(Find-RecordByName ([string]$P[1]) ([string]$P[0]))
  Assert-Milestone ($Found.Count -eq 1) ($P[0]+' provenance record missing/duplicated.')
  Assert-Milestone ([int]$Found[0].Record.points -eq [int]$P[3]) ($P[0]+' final point mismatch.')
  $ProvAudit+=,[pscustomobject]@{name=$P[0];printed=[int]$P[2];final=[int]$P[3]}
  Write-Host ('[OK] '+$P[0]+' '+$P[2]+' -> '+$P[3])
}

Write-MilestoneSection 'Validate four-product Separatist coverage'
$Products=@()
foreach($Code in @('swm35','swm37','swm42','swm43')){
  $M=Read-MilestoneJson (Join-Path $Repo ('metadata\products\'+$Code+'.json'))
  $Products+=,[pscustomobject]@{code=$M.code;name=$M.name}
  Write-Host ('[OK] '+$M.code+' metadata present: '+$M.name)
}
Assert-Milestone ($Products.Count -eq 4) 'Expected four Separatist product metadata records.'

Write-MilestoneSection 'Write Milestone 2.5 audit artifacts'
$ReportDir=Join-Path $Repo 'reports'
$AuditDir=Join-Path $Repo 'metadata\audits'
New-Item -ItemType Directory -Path $ReportDir,$AuditDir -Force|Out-Null
$Audit=[ordered]@{
 milestone='2.5'
 faction='Separatist Alliance'
 scope='official physical product-origin completeness'
 status='PASS'
 rules_baseline='AMG final Armada update, January 2025'
 totals=[ordered]@{records=48;ships=8;squadrons=11;upgrades=29;products=4}
 products=$Products
 ships=$ShipAudit
 squadrons=$SquadAudit
 upgrades=$UpgradeAudit
 final_point_provenance=$ProvAudit
 boundary=[ordered]@{
   product_origin_complete=$true
   neutral_cross_faction_legality_complete=$false
   rapid_reinforcements_included=$false
   campaign_objectives_included=$false
   community_arc_legacy_included=$false
   note='Neutral/shared reprints are validated for product representation but are not counted as Separatist-origin designs. Cross-faction legality remains a later compatibility layer.'
 }
}
Write-MilestoneJsonObject (Join-Path $ReportDir 'separatist-completeness-2.5.json') $Audit
Write-MilestoneJsonObject (Join-Path $AuditDir 'separatist-product-origin-2.5.json') $Audit

$Md=@"
# Separatist Alliance Product-Origin Completeness Audit — Milestone 2.5

**Status:** PASS
**Rules baseline:** AMG final Armada update, January 2025

## Totals
- 48 / 48 product-origin design records
- 8 ship designs
- 11 squadron designs
- 29 upgrade designs
- 4 physical Separatist products: SWM35, SWM37, SWM42, SWM43

## Boundary
This audit establishes product-origin completeness only. Neutral/shared reprints are checked for single-record representation but are not counted as Separatist-origin designs. Rapid Reinforcements, campaign objectives, community ARC/Legacy content, and the later cross-faction legality/compatibility layer are outside Milestone 2.5.

## Final-point provenance checks
$($ProvAudit|ForEach-Object{"- $($_.name): $($_.printed) -> $($_.final)"}|Out-String)
"@
Set-Content -LiteralPath (Join-Path $ReportDir 'separatist-completeness-2.5.md') -Value $Md -Encoding UTF8
Write-Host '[OK] Wrote reports\separatist-completeness-2.5.json'
Write-Host '[OK] Wrote reports\separatist-completeness-2.5.md'
Write-Host '[OK] Wrote metadata\audits\separatist-product-origin-2.5.json'

Write-MilestoneSection 'Install reusable verifier'
$Verifier=Join-Path $Repo 'tools\verify_milestone_2_5.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed '+$Verifier)

Write-Host ''
Write-Host '[OK] Milestone 2.5 complete.'
Write-Host '[OK] Separatist product-origin dataset is complete: 48 / 48 records.'
Write-Host '[OK] 8 ships / 11 squadron designs / 29 upgrades / 4 products verified.'
Write-Host '[OK] Product-origin completeness is ready for Milestone 2.6 normalization/release gate.'
Write-Host ('[OK] Backup: '+$Backup)
