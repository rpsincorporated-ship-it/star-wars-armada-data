param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$R=Get-Content -LiteralPath (Join-Path $Repo 'reports\authoritative-resolution-preflight-6.1.json') -Raw|ConvertFrom-Json
if($R.status-ne'PASS-AUTHORITATIVE-RESOLUTION-PREFLIGHT' -or [int]$R.upgrade_rows-ne116 -or [int]$R.legacy_rows-ne128 -or [int]$R.production_writes-ne0){throw '6.1 verification failed.'}
Write-Host '[OK] Milestone 6.1 verifier PASS'
Write-Host '[OK] Authoritative source hierarchy locked'
Write-Host '[OK] 244 direct-source resolution rows staged'
Write-Host '[OK] Zero production writes'
