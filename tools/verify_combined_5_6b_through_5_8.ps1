param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
function One([string]$P){$R=@(Read-J $P);if($R.Count-ne 1){throw "Unexpected record count in $P"};return $R[0]}
$V=One (Join-Path $Repo 'data\ship-card\galactic-empire\venator-ii-class-star-destroyer.json')
$P=One (Join-Path $Repo 'data\ship-card\rebel-alliance\providence-class-carrier.json')
if($V.name-ne 'Venator II-class Star Destroyer' -or $V.legality.faction-ne 'Galactic Empire'){throw 'Venator verification failed.'}
if($P.name-ne 'Providence-class Carrier' -or $P.legality.faction-ne 'Rebel Alliance'){throw 'Providence legality verification failed.'}
if([int]$P.points-ne 95 -or [int]$P.'max-speed'-ne 2){throw 'Providence gameplay baseline failed.'}
$W=Read-J (Join-Path $Repo 'reports\official-errata-5.5-reconciliation-worklist-5.7.json')
if($W.status-ne 'PASS-ERRATA-5.5-WORKLIST-READY'){throw '5.7 verification failed.'}
$R=Read-J (Join-Path $Repo 'reports\release-readiness-5.8.json')
if($R.status-ne 'PASS-RELEASE-READINESS-GATE'){throw '5.8 verification failed.'}
Write-Host '[OK] Combined 5.6b-through-5.8 recovery verifier PASS'
Write-Host '[OK] Imperial Venator legality.faction = Galactic Empire'
Write-Host '[OK] Rebel Providence legality.faction = Rebel Alliance'
Write-Host '[OK] Providence = 95 points / max-speed 2'
Write-Host ('[OK] Errata 5.5 worklist rows: '+$W.worklist_count)
Write-Host '[OK] Release-readiness gate complete'
