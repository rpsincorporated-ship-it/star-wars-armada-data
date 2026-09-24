param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\type-aware-official-confirmation-summary-7.27.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-TYPE-AWARE-OFFICIAL-CONFIRMATION-QUEUE'){throw '7.27 invalid.'}
if([int]$S.candidates-ne6){throw 'Candidate count invalid.'}
Write-Host '[OK] Combined Milestones 7.25-7.27 verifier PASS'
Write-Host ('[INFO] Same-card plausible disagreements: '+$S.same_card_plausible_disagreements)
Write-Host ('[INFO] Cross-class name collisions: '+$S.cross_class_name_collisions)
Write-Host ('[INFO] Ambiguous same-class: '+$S.ambiguous_same_class)
Write-Host ('[INFO] No compatible exact match: '+$S.no_compatible_exact_match)
