param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-19-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-19-CAMPAIGN-OFFICIAL-REVIEW-BUNDLE-COMPLETE'){throw 'Milestone 19 invalid.'}
if([int]$S.official_campaign_images_in_bundle-ne10){throw 'Expected 10 official campaign images.'}
if([int]$S.remaining_campaign_source_gates-ne9){throw 'Expected 9 remaining source gates.'}
Write-Host '[OK] MILESTONE 19 FINAL VERIFIER PASS'
Write-Host '[OK] Official campaign review images: 10'
Write-Host '[INFO] Remaining campaign source gates: 9'
