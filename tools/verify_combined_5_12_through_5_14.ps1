param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-J([string]$Path){Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json}
$A=Read-J (Join-Path $Repo 'reports\upgrade-direct-review-narrowing-5.12.json')
if($A.status -ne 'PASS-UPGRADE-QUEUE-NARROWING' -or [int]$A.upgrade_records -ne 116){throw '5.12 verification failed.'}
$B=Read-J (Join-Path $Repo 'reports\numeric-structural-correction-candidates-5.13.json')
if($B.status -ne 'PASS-CORRECTION-CANDIDATE-PLAN' -or [int]$B.legacy_ship_squadron_review_rows -ne 128){throw '5.13 verification failed.'}
$C=Read-J (Join-Path $Repo 'reports\transaction-ready-factual-correction-gate-5.14.json')
if($C.status -ne 'PASS-TRANSACTION-READY' -or [int]$C.production_json_count -ne 191 -or [int]$C.production_json_changed -ne 0){throw '5.14 verification failed.'}
Write-Host '[OK] Combined 5.12-through-5.14 verifier PASS'
Write-Host ('[OK] 5.12 upgrade records: '+$A.upgrade_records)
Write-Host ('[OK] 5.13 numeric candidates: '+$B.upgrade_internal_numeric_discrepancies)
Write-Host '[OK] 5.14 transaction-ready with zero production writes'
