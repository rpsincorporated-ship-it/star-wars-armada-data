param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\official-visual-source-registry-7.16.json')
$B=J (Join-Path $Repo 'reports\official-high-priority-page-localization-summary-7.17.json')
$C=J (Join-Path $Repo 'reports\official-visual-review-summary-7.18.json')
if($A.status-ne'PASS-OFFICIAL-VISUAL-SOURCES-LOCKED'){throw '7.16 invalid.'}
if($B.status-ne'PASS-HIGH-PRIORITY-OFFICIAL-PAGE-LOCALIZATION'){throw '7.17 invalid.'}
if($C.status-ne'PASS-OFFICIAL-VISUAL-REVIEW-PACKETS-BUILT'){throw '7.18 invalid.'}
if([int]$C.candidates-ne6){throw '7.18 candidate count invalid.'}
Write-Host '[OK] Combined Milestones 7.16-7.18 verifier PASS'
Write-Host ('[OK] Visual review ready: '+$C.visual_review_ready)
Write-Host ('[INFO] Manual targeting required: '+$C.manual_targeting_required)
