param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop';$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=J (Join-Path $Repo 'reports\bsdata-snapshot-7.10.json')
$B=J (Join-Path $Repo 'reports\bsdata-normalization-summary-7.11.json')
$C=J (Join-Path $Repo 'reports\bsdata-queue-comparison-summary-7.12.json')
if($A.status-ne'PASS-BSDATA-SNAPSHOT-ACQUIRED'){throw '7.10 invalid.'}
if($A.role-ne'COMMUNITY-CORROBORATION-NOT-AUTHORITY'){throw '7.10 authority role invalid.'}
if($B.status-ne'PASS-BSDATA-POINT-EVIDENCE-NORMALIZED'){throw '7.11 invalid.'}
if($C.status-ne'PASS-COMMUNITY-CORROBORATION-DELTA-MAP'){throw '7.12 invalid.'}
if([int]$C.queue_total-ne244){throw '7.12 queue invalid.'}
Write-Host '[OK] Combined Milestones 7.10-7.12 verifier PASS'
Write-Host ('[OK] BSData corroborates current points: '+$C.corroborates_current_points)
Write-Host ('[INFO] Disagreements needing official confirmation: '+$C.point_disagreements_requiring_official_confirmation)
Write-Host ('[INFO] Ambiguous BSData values: '+$C.ambiguous_bsdata_values)
Write-Host ('[INFO] No BSData name match: '+$C.no_bsdata_name_match)
