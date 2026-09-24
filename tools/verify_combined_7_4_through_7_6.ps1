param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\official-page-localization-summary-7.4.json')
$B=J (Join-Path $Repo 'reports\official-factual-inference-summary-7.5.json')
$C=J (Join-Path $Repo 'reports\official-evidence-transaction-summary-7.6.json')
if($A.status-ne'PASS-PAGE-LEVEL-OFFICIAL-LOCALIZATION'){throw '7.4 invalid.'}
if($B.status-ne'PASS-CONSERVATIVE-FACTUAL-INFERENCE'){throw '7.5 invalid.'}
if($B.record_resolution-ne'exact-name-first'){throw '7.5 record-resolution contract invalid.'}
if($C.status-ne'PASS-OFFICIAL-EVIDENCE-PROMOTION-AND-SAFE-TRANSACTION'){throw '7.6 invalid.'}
Write-Host '[OK] Milestones 7.5-7.6 resume v2 verifier PASS'
Write-Host ('[OK] Confirmed numeric corrections: '+$B.confirmed_numeric_corrections)
Write-Host ('[OK] Applied corrections: '+$C.newly_applied_numeric_corrections)
Write-Host ('[INFO] Text-sensitive candidates remaining: '+$C.remaining_text_sensitive_candidates)
Write-Host ('[INFO] Non-mentioned queue rows remaining: '+$C.unresolved_nonmentioned_queue_rows)
