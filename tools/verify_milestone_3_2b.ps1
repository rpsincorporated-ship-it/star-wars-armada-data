param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-Records([string]$Relative){
  $Path=Join-Path $Repo $Relative
  if(-not(Test-Path -LiteralPath $Path)){throw ('Missing RR1 file: '+$Relative)}
  return @((Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json))
}
$Expected=@(
 @('data\squadron-card\galactic-empire\darth-vader-tie-defender.json','Darth Vader','Galactic Empire','TIE Defender Squadron',25),
 @('data\squadron-card\rebel-alliance\hera-syndulla-x-wing.json','Hera Syndulla','Rebel Alliance','X-wing Squadron',23),
 @('data\squadron-card\galactic-republic\anakin-skywalker-delta-7.json','Anakin Skywalker','Galactic Republic','Delta-7 Aethersprite Squadron',24),
 @('data\squadron-card\separatist-alliance\jango-fett.json','Jango Fett','Separatist Alliance','Modified Firespray-31',22),
 @('data\ship-card\galactic-empire\venator-ii-class-star-destroyer.json','Venator II-class Star Destroyer','Galactic Empire','',100),
 @('data\ship-card\rebel-alliance\providence-class-carrier.json','Providence-class Carrier','Rebel Alliance','',95),
 @('data\ship-card\galactic-republic\victory-i-class-star-destroyer.json','Victory I-class Star Destroyer','Galactic Republic','',73),
 @('data\ship-card\separatist-alliance\gozanti-class-cruisers.json','Gozanti-class Cruisers','Separatist Alliance','',24)
)
$Ids=@{}
foreach($Item in $Expected){
  $Rows=@(Read-Records $Item[0])
  if($Rows.Count -ne 1){throw ($Item[0]+' must contain exactly one record.')}
  $R=$Rows[0]
  $Sub=if($null -ne $R.PSObject.Properties['subname']){[string]$R.subname}else{''}
  if($R.name -ne $Item[1]){throw ($Item[0]+' name mismatch.')}
  if($R.faction -ne $Item[2]){throw ($Item[0]+' faction mismatch.')}
  if($Sub -ne $Item[3]){throw ($Item[0]+' subname mismatch.')}
  if([int]$R.points -ne [int]$Item[4]){throw ($Item[0]+' points mismatch.')}
  if($R.supplement -ne 'Rapid Reinforcements I'){throw ($Item[0]+' supplement provenance missing.')}
  if($R.'supplement-revision' -ne '2.0'){throw ($Item[0]+' supplement revision mismatch.')}
  $Id=[string]$R.'stable-id'
  if([string]::IsNullOrWhiteSpace($Id)){throw ($Item[0]+' stable-id missing.')}
  if($Ids.ContainsKey($Id)){throw ('Duplicate RR1 stable-id: '+$Id)}
  $Ids[$Id]=$true
}
$ManifestPath=Join-Path $Repo 'metadata\releases\rapid-reinforcements-i-2025.01-final.json'
if(-not(Test-Path -LiteralPath $ManifestPath)){throw 'RR1 release manifest missing.'}
$Manifest=(Get-Content -LiteralPath $ManifestPath -Raw|ConvertFrom-Json)
if($Manifest.status -ne 'complete-supplement'){throw 'RR1 release status is not complete-supplement.'}
if([int]$Manifest.records -ne 8){throw 'RR1 manifest must contain 8 records.'}
Write-Host '[OK] Milestone 3.2b verifier PASS'
Write-Host '[OK] 8 / 8 RR1 production records present with unique stable IDs'
Write-Host '[OK] RR1 release manifest: complete-supplement'
