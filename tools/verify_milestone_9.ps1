param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-9-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-9-RELEASE-CANDIDATE-COMPLETE'){throw 'Milestone 9 status invalid.'}
$Zip=Join-Path $Repo ([string]$S.release_zip)
if(-not(Test-Path -LiteralPath $Zip)){throw 'Release ZIP missing.'}
if((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash-ne$S.release_zip_sha256){throw 'Release ZIP hash mismatch.'}
& (Join-Path $Repo 'release-candidate\verify_release_candidate.ps1')
Write-Host '[OK] MILESTONE 9 FINAL VERIFIER PASS'
