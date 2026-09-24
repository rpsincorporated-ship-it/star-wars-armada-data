param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$R=Get-Content (Join-Path $Repo 'reports\rr1-providence-discrepancy-inspection-5.5a.json') -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-INSPECTION'){throw '5.5a status invalid.'}
if([int]$R.observed.points -ne 95){throw 'Providence points mismatch.'}
if([int]$R.observed.max_speed -ne 3){throw 'Providence max-speed mismatch.'}
if($R.providence_gate_state -ne 'OPEN-MANEUVER-ENCODING'){throw 'Providence gate state invalid.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.5a verifier PASS'
Write-Host '[OK] Providence points 95 / max speed 3'
Write-Host '[INFO] Maneuver/yaw encoding remains OPEN'
Write-Host '[OK] No production card data was modified'
