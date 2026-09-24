param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\rapid-reinforcements-extraction-7.7.json')
$B=J (Join-Path $Repo 'reports\combined-official-source-summary-7.8.json')
$C=J (Join-Path $Repo 'reports\authoritative-change-backlog-summary-7.9.json')
if($A.status-ne'PASS-RR23-OFFICIAL-PDF-TEXT-EXTRACTION'){throw '7.7 invalid.'}
if($B.status-ne'PASS-CROSS-SOURCE-AUTHORITATIVE-RECONCILIATION'){throw '7.8 invalid.'}
if([int]$B.queue_total-ne244){throw '7.8 queue invalid.'}
if($C.status-ne'PASS-PRIORITIZED-AUTHORITATIVE-CHANGE-BACKLOG'){throw '7.9 invalid.'}
Write-Host '[OK] Combined Milestones 7.7-7.9 verifier PASS'
Write-Host ('[OK] RR2.3 mentions: '+$B.rr23_mentions)
Write-Host ('[OK] Any official source mentions: '+$B.any_official_source_mentions)
Write-Host ('[INFO] Critical numeric candidates: '+$C.critical_numeric_candidates)
Write-Host ('[INFO] High review items: '+$C.high_official_mentions_needing_review)
Write-Host ('[INFO] Low no-direct-change items: '+$C.low_no_direct_official_change_mentions)
