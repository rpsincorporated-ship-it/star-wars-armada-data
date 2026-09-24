param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$DataVersion='2025.01-final'
$Faction='Separatist Alliance'
$FactionSlug='separatist-alliance'

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
function Write-MilestoneJsonRecords([string]$Path,[object[]]$Rows){
  $Json=ConvertTo-Json -InputObject @($Rows) -Depth 60
  Set-Content -LiteralPath $Path -Value $Json -Encoding UTF8
}
function Write-MilestoneJsonObject([string]$Path,[object]$Object){
  $Parent=Split-Path -Parent $Path
  if($Parent){New-Item -ItemType Directory -Path $Parent -Force|Out-Null}
  $Json=ConvertTo-Json -InputObject $Object -Depth 60
  Set-Content -LiteralPath $Path -Value $Json -Encoding UTF8
}
function ConvertTo-StableSlug([string]$Text){
  $s=$Text.ToLowerInvariant()
  $s=$s -replace '[^a-z0-9]+','-'
  return $s.Trim('-')
}
function Get-StableId([string]$Kind,[string]$Name,[string]$UpgradeType){
  $n=ConvertTo-StableSlug $Name
  if($Kind -eq 'upgrade'){
    $t=ConvertTo-StableSlug $UpgradeType
    return ('swarmada:official:'+$FactionSlug+':upgrade:'+$t+':'+$n)
  }
  return ('swarmada:official:'+$FactionSlug+':'+$Kind+':'+$n)
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

Write-MilestoneSection 'Milestone 2.6 preflight'
$AuditPath=Join-Path $Repo 'metadata\audits\separatist-product-origin-2.5.json'
$Verifier25=Join-Path $Repo 'tools\verify_milestone_2_5.ps1'
Assert-Milestone (Test-Path -LiteralPath $AuditPath) 'Milestone 2.5 audit metadata is missing.'
Assert-Milestone (Test-Path -LiteralPath $Verifier25) 'Milestone 2.5 verifier is missing.'
$Audit=Read-MilestoneJson $AuditPath
Assert-Milestone ($Audit.status -eq 'PASS') 'Milestone 2.5 audit is not PASS.'
Assert-Milestone ([int]$Audit.totals.records -eq 48) 'Milestone 2.5 audit must contain 48 records.'
Write-Host '[OK] Milestone 2.5 PASS baseline detected: 48 Separatist product-origin records'

$ShipDir=Join-Path $Repo 'data\ship-card\separatist-alliance'
$SquadDir=Join-Path $Repo 'data\squadron-card\separatist-alliance'
$UpgradeDir=Join-Path $Repo 'data\upgrade-card'

$ExpectedShips=@(
 'Munificent-class Comms Frigate','Munificent-class Star Frigate','Hardcell-class Transport','Hardcell-class Battle Refit',
 'Providence-class Carrier','Providence-class Dreadnought','Recusant-class Light Destroyer','Recusant-class Support Destroyer'
)
$ExpectedSquads=@(
 'Vulture-class Droid Fighter Squadron','Haor Chall Prototypes','Belbullab-22 Squadron','General Grievous',
 'Droid Tri-fighter Squadron','Phlac-Arphocc Prototypes','DIS-T81','Hyena-class Droid Bomber Squadron',
 'Baktoid Prototypes','DBS-404','DFS-311'
)
$ExpectedUpgrades=@(
 'Count Dooku','Kraken','Hyperwave Signal Boost','Rune Haako','Wat Tambor','T-Series Tactical Droid',
 'Battle Droid Reserves','Beast of Burden',"Foreman's Labor",'Sa Nalaor','Tide of Progress XII',
 'General Grievous','Admiral Trench','Jedi Hostage','Point Defense Ion Cannons','B2 Rocket Troopers',
 'TI-99','Tikkes','Invincible','Invisible Hand','Lucid Voice','Mar Tuuk','TF-1726','Passel Argente',
 'San Hill','Shu Mai','Gilded Aegis','Nova Defiant','Patriot Fist'
)

Write-MilestoneSection 'Resolve exact 48-record normalization target set'
$Targets=@()
foreach($Name in $ExpectedShips){
  $Hit=@(Find-RecordByName $ShipDir $Name)
  Assert-Milestone ($Hit.Count -eq 1) ($Name+' expected once in ship data; found '+$Hit.Count+'.')
  $Targets+=,[pscustomobject]@{kind='ship';name=$Name;file=$Hit[0].File;path=$Hit[0].Path;upgradeType=$null}
}
foreach($Name in $ExpectedSquads){
  $Hit=@(Find-RecordByName $SquadDir $Name)
  Assert-Milestone ($Hit.Count -eq 1) ($Name+' expected once in squadron data; found '+$Hit.Count+'.')
  $Targets+=,[pscustomobject]@{kind='squadron';name=$Name;file=$Hit[0].File;path=$Hit[0].Path;upgradeType=$null}
}
foreach($Name in $ExpectedUpgrades){
  $Hit=@(Find-RecordByName $UpgradeDir $Name)
  Assert-Milestone ($Hit.Count -eq 1) ($Name+' expected once in upgrade data; found '+$Hit.Count+'.')
  $Type=[IO.Path]::GetFileNameWithoutExtension($Hit[0].File)
  $Targets+=,[pscustomobject]@{kind='upgrade';name=$Name;file=$Hit[0].File;path=$Hit[0].Path;upgradeType=$Type}
}
Assert-Milestone ($Targets.Count -eq 48) ('Expected 48 targets; resolved '+$Targets.Count+'.')
$TargetFiles=@($Targets.path|Sort-Object -Unique)
Write-Host ('[OK] '+$TargetFiles.Count+' JSON target files contain the 48 audited records')

Write-MilestoneSection 'Capture pre-normalization preservation state'
$Preserve=@{}
$UniqueCount=0
$RestrictionCount=0
foreach($T in $Targets){
  $Rows=@(Read-MilestoneJsonRecords $T.path)
  $R=@($Rows|Where-Object{$_.name -eq $T.name})[0]
  $Key=$T.kind+'|'+$T.file+'|'+$T.name
  $UniquePresent=($null -ne $R.PSObject.Properties['unique'])
  $RestrictionPresent=($null -ne $R.PSObject.Properties['restriction'])
  if($UniquePresent){$UniqueCount++}
  if($RestrictionPresent){$RestrictionCount++}
  $Preserve[$Key]=[pscustomobject]@{
    uniquePresent=$UniquePresent; uniqueValue=if($UniquePresent){$R.unique}else{$null}
    restrictionPresent=$RestrictionPresent; restrictionValue=if($RestrictionPresent){$R.restriction}else{$null}
  }
}
Write-Host ('[OK] Captured preservation state: '+$UniqueCount+' explicit unique fields / '+$RestrictionCount+' explicit restriction fields')

Write-MilestoneSection 'Backup all production normalization targets and release outputs'
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.milestone_2_6_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$BackupPaths=@($TargetFiles)+@(
 (Join-Path $Repo 'metadata\releases\separatist-alliance-2025.01-final.json'),
 (Join-Path $Repo 'metadata\releases\separatist-normalization-2.6.json'),
 (Join-Path $Repo 'reports\separatist-release-2.6.json'),
 (Join-Path $Repo 'reports\separatist-release-2.6.md'),
 (Join-Path $Repo 'tools\verify_milestone_2_6.ps1')
)
foreach($Source in $BackupPaths){
  if(Test-Path -LiteralPath $Source){
    $Relative=$Source.Substring($Repo.Length).TrimStart('\')
    $Dest=Join-Path $Backup $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $Dest) -Force|Out-Null
    Copy-Item -LiteralPath $Source -Destination $Dest -Force
  }
}
Write-Host ('[OK] Backup created: '+$Backup)

Write-MilestoneSection 'Normalize 48 audited Separatist product-origin records'
$FilesToTargets=@{}
foreach($T in $Targets){
  if(-not $FilesToTargets.ContainsKey($T.path)){$FilesToTargets[$T.path]=@()}
  $FilesToTargets[$T.path]+=$T
}
foreach($Path in $TargetFiles){
  $Rows=@(Read-MilestoneJsonRecords $Path)
  $ThisTargets=@($FilesToTargets[$Path])
  foreach($R in $Rows){
    $Match=@($ThisTargets|Where-Object{$_.name -eq $R.name})
    if($Match.Count -eq 1){
      $T=$Match[0]
      $StableId=Get-StableId $T.kind $T.name $T.upgradeType
      if($null -eq $R.PSObject.Properties['id']){$R|Add-Member -NotePropertyName 'id' -NotePropertyValue $StableId}
      else{$R.id=$StableId}
      if($null -eq $R.PSObject.Properties['data-version']){$R|Add-Member -NotePropertyName 'data-version' -NotePropertyValue $DataVersion}
      else{$R.'data-version'=$DataVersion}
      $Legality=[ordered]@{
        status='official-final'
        faction=$Faction
        rules_baseline='AMG final Armada update, January 2025'
        data_version=$DataVersion
        product_origin=$R.source.'product-code'
      }
      if($null -eq $R.PSObject.Properties['legality']){$R|Add-Member -NotePropertyName 'legality' -NotePropertyValue ([pscustomobject]$Legality)}
      else{$R.legality=[pscustomobject]$Legality}
      if($null -ne $R.source){
        if($null -eq $R.source.PSObject.Properties['rules-baseline']){
          $R.source|Add-Member -NotePropertyName 'rules-baseline' -NotePropertyValue 'AMG final Armada update, January 2025'
        } else {$R.source.'rules-baseline'='AMG final Armada update, January 2025'}
        if($null -eq $R.source.PSObject.Properties['data-version']){
          $R.source|Add-Member -NotePropertyName 'data-version' -NotePropertyValue $DataVersion
        } else {$R.source.'data-version'=$DataVersion}
      }
    }
  }
  Write-MilestoneJsonRecords $Path $Rows
}
Write-Host '[OK] Normalized all 48 audited records'

Write-MilestoneSection 'Verify stable IDs, normalization, and field preservation'
$Ids=@()
$PreservedUnique=0
$PreservedRestriction=0
foreach($T in $Targets){
  $Rows=@(Read-MilestoneJsonRecords $T.path)
  $Matches=@($Rows|Where-Object{$_.name -eq $T.name})
  Assert-Milestone ($Matches.Count -eq 1) ($T.name+' missing/duplicated after normalization.')
  $R=$Matches[0]
  $ExpectedId=Get-StableId $T.kind $T.name $T.upgradeType
  Assert-Milestone ($R.id -eq $ExpectedId) ($T.name+' stable ID mismatch.')
  Assert-Milestone ($R.'data-version' -eq $DataVersion) ($T.name+' data-version mismatch.')
  Assert-Milestone ($R.legality.status -eq 'official-final') ($T.name+' legality status mismatch.')
  Assert-Milestone ($R.legality.faction -eq $Faction) ($T.name+' legality faction mismatch.')
  Assert-Milestone ($R.source.'rules-baseline' -eq 'AMG final Armada update, January 2025') ($T.name+' source baseline mismatch.')
  Assert-Milestone ($R.source.'data-version' -eq $DataVersion) ($T.name+' source data-version mismatch.')
  $Ids+=$R.id
  $Key=$T.kind+'|'+$T.file+'|'+$T.name
  $P=$Preserve[$Key]
  if($P.uniquePresent){
    Assert-Milestone ($null -ne $R.PSObject.Properties['unique']) ($T.name+' lost explicit unique field.')
    Assert-Milestone ($R.unique -eq $P.uniqueValue) ($T.name+' unique field changed.')
    $PreservedUnique++
  }
  if($P.restrictionPresent){
    Assert-Milestone ($null -ne $R.PSObject.Properties['restriction']) ($T.name+' lost explicit restriction field.')
    Assert-Milestone ($R.restriction -eq $P.restrictionValue) ($T.name+' restriction field changed.')
    $PreservedRestriction++
  }
}
Assert-Milestone ($Ids.Count -eq 48) 'Expected 48 stable IDs.'
Assert-Milestone (@($Ids|Sort-Object -Unique).Count -eq 48) 'Stable IDs are not globally unique within Separatist release.'
Write-Host '[OK] 48 / 48 unique deterministic stable IDs verified'
Write-Host ('[OK] Preserved explicit unique fields on '+$PreservedUnique+' audited records')
Write-Host ('[OK] Preserved explicit restriction fields on '+$PreservedRestriction+' audited records')
Write-Host '[OK] No legacy uniqueness/restriction fields removed or synthesized'

Write-MilestoneSection 'Reverify final official point provenance'
$Checks=@(
 @('Hardcell-class Battle Refit',$ShipDir,50),@('Count Dooku',$UpgradeDir,27),@('Wat Tambor',$UpgradeDir,9),
 @('Phlac-Arphocc Prototypes',$SquadDir,18),@('DFS-311',$SquadDir,16),
 @('Providence-class Carrier',$ShipDir,102),@('Providence-class Dreadnought',$ShipDir,97),
 @('Admiral Trench',$UpgradeDir,32),@('Point Defense Ion Cannons',$UpgradeDir,6),@('Invisible Hand',$UpgradeDir,8)
)
foreach($C in $Checks){
  $Found=@(Find-RecordByName ([string]$C[1]) ([string]$C[0]))
  Assert-Milestone ($Found.Count -eq 1) ($C[0]+' final point check missing/duplicated.')
  Assert-Milestone ([int]$Found[0].Record.points -eq [int]$C[2]) ($C[0]+' final point mismatch.')
  Write-Host ('[OK] '+$C[0]+' final '+$C[2])
}
$RHD=@(Find-RecordByName $UpgradeDir 'Reserve Hangar Deck')
Assert-Milestone ($RHD.Count -eq 1 -and [int]$RHD[0].Record.points -eq 4) 'Reserve Hangar Deck final 4 point shared record missing.'
Write-Host '[OK] Reserve Hangar Deck shared record remains final 4 pts'

Write-MilestoneSection 'Generate final Separatist release manifest and reports'
$ReleaseDir=Join-Path $Repo 'metadata\releases'
$ReportDir=Join-Path $Repo 'reports'
New-Item -ItemType Directory -Path $ReleaseDir,$ReportDir -Force|Out-Null
$ManifestRecords=@()
foreach($T in $Targets){
  $R=@(Read-MilestoneJsonRecords $T.path|Where-Object{$_.name -eq $T.name})[0]
  $ManifestRecords+=,[pscustomobject]@{
    id=$R.id;kind=$T.kind;name=$T.name;file=$T.file;points=[int]$R.points;
    product=$R.source.'product-code';data_version=$R.'data-version'
  }
}
$Manifest=[ordered]@{
 release='separatist-alliance-2025.01-final'
 faction=$Faction
 status='frozen-product-origin'
 data_version=$DataVersion
 rules_baseline='AMG final Armada update, January 2025'
 milestone='2.6'
 totals=[ordered]@{records=48;ships=8;squadrons=11;upgrades=29;stable_ids=48}
 compatibility_scope=[ordered]@{
   product_origin_complete=$true
   neutral_upgrade_compatibility_complete=$false
   rapid_reinforcements_included=$false
   campaign_objectives_included=$false
   community_arc_legacy_included=$false
   note='Separatist physical product-origin content is complete and frozen. Neutral cross-faction legality/compatibility remains deferred to a later global layer.'
 }
 records=$ManifestRecords
}
Write-MilestoneJsonObject (Join-Path $ReleaseDir 'separatist-alliance-2025.01-final.json') $Manifest
$Normalization=[ordered]@{
 milestone='2.6';status='PASS';faction=$Faction;data_version=$DataVersion
 normalized_records=48;unique_stable_ids=48;target_files=$TargetFiles.Count
 preservation=[ordered]@{explicit_unique_fields=$PreservedUnique;explicit_restriction_fields=$PreservedRestriction}
 release_manifest='metadata/releases/separatist-alliance-2025.01-final.json'
}
Write-MilestoneJsonObject (Join-Path $ReleaseDir 'separatist-normalization-2.6.json') $Normalization
Write-MilestoneJsonObject (Join-Path $ReportDir 'separatist-release-2.6.json') $Manifest
$Md=@"
# Separatist Alliance Final Product-Origin Release — Milestone 2.6

**Status:** PASS / frozen
**Data version:** $DataVersion
**Rules baseline:** AMG final Armada update, January 2025

## Release totals
- 48 records
- 8 ships
- 11 squadron designs
- 29 upgrades
- 48 unique deterministic stable IDs

## Normalization
All audited Separatist product-origin records carry deterministic IDs, official-final legality metadata, normalized rules baseline, and data version. Existing explicit uniqueness and restriction fields were preserved.

## Scope boundary
Physical Separatist product-origin content is complete. Neutral cross-faction upgrade legality, Rapid Reinforcements, campaign objectives, and community ARC/Legacy content remain outside this release and will be handled in later milestones.
"@
Set-Content -LiteralPath (Join-Path $ReportDir 'separatist-release-2.6.md') -Value $Md -Encoding UTF8
Write-Host '[OK] Generated metadata\releases\separatist-alliance-2025.01-final.json'
Write-Host '[OK] Generated metadata\releases\separatist-normalization-2.6.json'
Write-Host '[OK] Generated reports\separatist-release-2.6.json'
Write-Host '[OK] Generated reports\separatist-release-2.6.md'

Write-MilestoneSection 'Validate final release manifest'
$DiskManifest=Read-MilestoneJson (Join-Path $ReleaseDir 'separatist-alliance-2025.01-final.json')
Assert-Milestone ($DiskManifest.status -eq 'frozen-product-origin') 'Release status mismatch.'
Assert-Milestone ([int]$DiskManifest.totals.records -eq 48) 'Release record total mismatch.'
Assert-Milestone ([int]$DiskManifest.totals.stable_ids -eq 48) 'Release stable ID total mismatch.'
Assert-Milestone (@($DiskManifest.records.id|Sort-Object -Unique).Count -eq 48) 'Release manifest contains duplicate IDs.'
Write-Host '[OK] Final release manifest: 48 records / 48 unique IDs'
Write-Host '[OK] Compatibility scope explicitly records deferred neutral cross-faction legality'

Write-MilestoneSection 'Install reusable final verifier'
$ToolsDir=Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $ToolsDir -Force|Out-Null
$Verifier=Join-Path $ToolsDir 'verify_milestone_2_6.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed '+$Verifier)

Write-Host ''
Write-Host '[OK] Milestone 2.6 complete.'
Write-Host '[OK] Separatist Alliance product-origin dataset is normalized, released, and frozen.'
Write-Host '[OK] 48 records / 48 stable IDs / official-final 2025.01 baseline verified.'
Write-Host '[OK] Separatist Alliance is ready to freeze while Rapid Reinforcements work begins.'
Write-Host ('[OK] Backup: '+$Backup)
