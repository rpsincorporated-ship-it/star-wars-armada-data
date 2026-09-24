param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\six-candidate-correction-readiness-summary-7.24.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-SIX-CANDIDATE-NO-GUESS-READINESS-MATRIX'){throw '7.24 invalid.'}
if([int]$S.candidates-ne6){throw 'Candidate count invalid.'}
Write-Host '[OK] Combined Milestones 7.22-7.24 verifier PASS'
Write-Host ('[INFO] Text numeric candidate review: '+$S.text_numeric_candidate_review)
Write-Host ('[INFO] Visual review required: '+$S.visual_review_required)
Write-Host ('[INFO] Image-only evidence required: '+$S.image_only_official_evidence_required)
