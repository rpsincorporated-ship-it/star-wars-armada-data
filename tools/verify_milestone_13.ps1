param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path $RepoPath).Path
$S=Get-Content (Join-Path $Repo 'reports\milestone-13-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-13-ONAGER-SOURCE-LOCALIZATION-READY'){throw 'Milestone 13 invalid.'}
if(-not(Test-Path $S.bundle)){throw 'Milestone 13 bundle missing.'}
if((Get-FileHash $S.bundle -Algorithm SHA256).Hash-ne$S.bundle_sha256){throw 'Bundle hash mismatch.'}
Write-Host '[OK] MILESTONE 13 FINAL VERIFIER PASS'
