param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-dry-run-merge-4.6.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.6 report missing.'}
$R=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($R.status -ne 'PASS'){throw 'Milestone 4.6 status is not PASS.'}
if([int]$R.baseline_records -ne 36){throw 'Expected 36 baseline records.'}
if([int]$R.dry_run_campaign_records -ne 19){throw 'Expected 19 campaign records.'}
if([int]$R.simulated_post_install_records -ne 55){throw 'Expected simulated total of 55 records.'}
if([int]$R.product_split.SWM25 -ne 8){throw 'Expected 8 SWM25 records.'}
if([int]$R.product_split.SWM31 -ne 11){throw 'Expected 11 SWM31 records.'}
if([int]$R.base_defense_product_version_records -ne 6){throw 'Expected six Base Defense product-version records.'}
if([int]$R.unique_campaign_stable_ids -ne 19){throw 'Expected 19 unique campaign stable IDs.'}
if([int]$R.powershell51_array_roundtrip_records -ne 55){throw 'PowerShell 5.1 round-trip count mismatch.'}
if($R.top_level_array_serialization -ne $true){throw 'Top-level array serialization check failed.'}
if($R.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 4.6 verifier PASS'
Write-Host '[OK] Dry-run merge: 36 + 19 = 55 records'
Write-Host '[OK] SWM25=8 / SWM31=11 / Base Defense product versions=6'
Write-Host '[OK] PowerShell 5.1 top-level array serialization validated'
Write-Host '[OK] No production card data was modified'
