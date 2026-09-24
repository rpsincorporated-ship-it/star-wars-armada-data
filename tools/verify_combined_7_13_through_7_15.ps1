param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\bsdata-final-baseline-snapshot-7.13.json')
$B=J (Join-Path $Repo 'reports\bsdata-temporal-disagreement-summary-7.14.json')
$C=J (Join-Path $Repo 'reports\official-point-confirmation-queue-summary-7.15.json')
if($A.status-ne'PASS-BSDATA-FINAL-ERA-SNAPSHOT-ACQUIRED'){throw '7.13 invalid.'}
if($B.status-ne'PASS-BSDATA-TEMPORAL-DISAGREEMENT-ANALYSIS'){throw '7.14 invalid.'}
if($C.status-ne'PASS-PRIORITIZED-OFFICIAL-POINT-CONFIRMATION-QUEUE'){throw '7.15 invalid.'}
Write-Host '[OK] Combined Milestones 7.13-7.15 verifier PASS'
Write-Host ('[OK] High-priority official confirmations: '+$C.high_priority)
Write-Host ('[INFO] Medium priority: '+$C.medium_priority)
Write-Host ('[INFO] Low priority: '+$C.low_priority)
Write-Host ('[INFO] Community-reverted-to-local: '+$C.resolved_by_current_community_reversion)
