param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path $RepoPath).Path
$S=Get-Content (Join-Path $Repo 'reports\milestone-15-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-15-TEXT-SENSITIVE-RECORD-CAPTURE-COMPLETE'){throw 'Milestone 15 invalid.'}
if(-not(Test-Path $S.bundle)){throw 'Review bundle missing.'}
if((Get-FileHash $S.bundle -Algorithm SHA256).Hash-ne$S.bundle_sha256){throw 'Review bundle hash mismatch.'}
Write-Host '[OK] MILESTONE 15 FINAL VERIFIER PASS'
