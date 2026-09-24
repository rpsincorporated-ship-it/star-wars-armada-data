param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-12-final-status.json') -Raw|ConvertFrom-Json
if($S.status -ne 'PASS-MILESTONE-12-ONAGER-VISUAL-EVIDENCE-READY'){throw 'Milestone 12 invalid.'}
if(-not(Test-Path -LiteralPath $S.bundle)){throw 'Milestone 12 review bundle missing.'}
if((Get-FileHash -LiteralPath $S.bundle -Algorithm SHA256).Hash -ne $S.bundle_sha256){throw 'Milestone 12 bundle hash mismatch.'}
Write-Host '[OK] MILESTONE 12 FINAL VERIFIER PASS'
Write-Host '[INFO] Next gate: direct visual confirmation'
