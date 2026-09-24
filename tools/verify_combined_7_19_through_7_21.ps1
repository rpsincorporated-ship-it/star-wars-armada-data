param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\official-review-bundle-summary-7.21.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-PORTABLE-OFFICIAL-VISUAL-REVIEW-BUNDLE'){throw '7.21 invalid.'}
$Zip=Join-Path $Repo ([string]$S.bundle_zip_path)
if(-not(Test-Path -LiteralPath $Zip)){throw 'Bundle ZIP missing.'}
if((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash-ne$S.bundle_zip_sha256){throw 'Bundle hash mismatch.'}
Write-Host '[OK] Combined Milestones 7.19-7.21 verifier PASS'
Write-Host ('[OK] Review bundle: '+$Zip)
Write-Host '[NEXT] Upload armada-official-review-bundle-7.21.zip to ChatGPT.'
