param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\official-errata-text-extraction-7.1.json')
$B=J (Join-Path $Repo 'reports\official-errata-mention-summary-7.2.json')
$C=J (Join-Path $Repo 'reports\review-ready-evidence-candidates-7.3.json')
if($A.status-ne'PASS-OFFICIAL-PDF-TEXT-EXTRACTION'){throw '7.1 invalid.'}
if($A.backend-ne'verified-poppler-pdftotext'){throw '7.1 backend invalid.'}
if($B.status-ne'PASS-244-ROW-OFFICIAL-MENTION-RECONCILIATION'){throw '7.2 invalid.'}
if([int]$B.queue_total-ne244){throw '7.2 queue invalid.'}
if($C.status-ne'PASS-REVIEW-READY-EVIDENCE-CANDIDATES'){throw '7.3 invalid.'}
Write-Host '[OK] Combined 7.1-7.3 Poppler v3 verifier PASS'
Write-Host ('[OK] Official mentions: '+$B.mentioned)
Write-Host ('[OK] Review-ready candidates: '+$C.candidate_rows)
