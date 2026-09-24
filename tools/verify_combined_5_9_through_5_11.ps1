param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=Read-J (Join-Path $Repo 'reports\official-errata-5.5-reconciliation-5.9.json')
if($A.status -ne 'PASS-ERRATA-5.5-RECONCILIATION-GATE' -or [int]$A.candidate_total -ne 117 -or [int]$A.direct_source_review_remaining -ne 116){throw '5.9 verification failed.'}
$B=Read-J (Join-Path $Repo 'reports\legacy-rebel-imperial-final-value-inventory-5.10.json')
if($B.status -ne 'PASS-LEGACY-FINAL-VALUE-INVENTORY' -or [int]$B.total_records -ne 128){throw '5.10 verification failed.'}
if([int]$B.rebel_ships -ne 23 -or [int]$B.imperial_ships -ne 25 -or [int]$B.rebel_squadrons -ne 39 -or [int]$B.imperial_squadrons -ne 41){throw '5.10 faction totals failed.'}
$C=Read-J (Join-Path $Repo 'reports\global-release-readiness-5.11.json')
if($C.status -ne 'PASS-GLOBAL-READINESS-GATE' -or [int]$C.production_json_changed_in_resume_run -ne 0){throw '5.11 verification failed.'}
$V=@(Read-J (Join-Path $Repo 'data\ship-card\galactic-empire\venator-ii-class-star-destroyer.json'))[0]
$P=@(Read-J (Join-Path $Repo 'data\ship-card\rebel-alliance\providence-class-carrier.json'))[0]
if($V.legality.faction -ne 'Galactic Empire'){throw 'Venator regression.'}
if($P.legality.faction -ne 'Rebel Alliance' -or [int]$P.points -ne 95 -or [int]$P.'max-speed' -ne 2){throw 'Providence regression.'}
Write-Host '[OK] Combined 5.9-through-5.11 verifier PASS'
Write-Host '[OK] 5.9: 117 candidates / 1 resolved / 116 direct-review'
Write-Host '[OK] 5.10: 128 legacy Rebel/Imperial ship+squadron records'
Write-Host '[OK] 5.11: zero production JSON changes during resume'
