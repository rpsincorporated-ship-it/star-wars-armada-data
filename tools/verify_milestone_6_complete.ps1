param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop';$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\official-source-acquisition-6.6.json')
$B=J (Join-Path $Repo 'reports\authoritative-reconciliation-6.7.json')
$C=J (Join-Path $Repo 'reports\authoritative-transaction-6.8.json')
$D=J (Join-Path $Repo 'reports\milestone-6-release-gate-6.9.json')
if($A.status-ne'PASS-OFFICIAL-SOURCES-ACQUIRED'){throw '6.6 invalid.'}
if($B.status-notin@('PASS-AUTHORITATIVE-RECONCILIATION-COMPLETE','PASS-AUTHORITATIVE-RECONCILIATION-PARTIAL')){throw '6.7 invalid.'}
if($C.status-ne'PASS-PROVEN-CORRECTION-TRANSACTION'){throw '6.8 invalid.'}
if($D.status-notin@('PASS-MILESTONE-6-AUTHORITATIVE-QUEUE-CLOSED','PASS-MILESTONE-6-SOURCE-PIPELINE-COMPLETE-WITH-BACKLOG')){throw '6.9 invalid.'}
Write-Host '[OK] Milestone 6 complete verifier PASS'
Write-Host ('[OK] Authoritative rows resolved: '+$D.authoritative_rows_resolved+'/244')
Write-Host ('[INFO] Authoritative rows open: '+$D.authoritative_rows_open)
Write-Host ('[INFO] Campaign exact-text rows open: '+$D.campaign_exact_text_rows_open)
Write-Host ('[INFO] GitHub release ready: '+$D.github_release_ready)
