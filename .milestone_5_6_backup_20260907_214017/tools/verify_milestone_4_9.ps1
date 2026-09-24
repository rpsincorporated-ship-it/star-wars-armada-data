param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$P=Join-Path $Repo 'reports\campaign-objective-transaction-harness-4.9.json'
if(-not(Test-Path -LiteralPath $P)){throw '4.9 report missing.'}
$R=Get-Content -LiteralPath $P -Raw|ConvertFrom-Json
if($R.status -ne 'PASS'){throw '4.9 not PASS.'}
if([int]$R.baseline_records -ne 36 -or [int]$R.synthetic_campaign_records -ne 19 -or [int]$R.staged_candidate_records -ne 55){throw 'Record-count contract failed.'}
if($R.rollback_test -ne 'PASS' -or $R.rollback_byte_identical -ne $true){throw 'Rollback proof failed.'}
if($R.installer_default_mode -ne 'PREVIEW' -or $R.commit_requires_explicit_switch -ne $true){throw 'Installer safety gate failed.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
if(-not(Test-Path -LiteralPath (Join-Path $Repo 'tools\install_campaign_objective_payload.ps1'))){throw 'Guarded installer missing.'}
Write-Host '[OK] Milestone 4.9 verifier PASS'
Write-Host '[OK] Staged transaction: 36 + 19 = 55'
Write-Host '[OK] Rollback proof: byte-identical 36-record restoration'
Write-Host '[OK] Guarded installer defaults to PREVIEW'
Write-Host '[OK] No production card data was modified'
