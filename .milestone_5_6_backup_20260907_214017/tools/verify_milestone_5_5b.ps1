param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$R=Get-Content -LiteralPath (Join-Path $Repo 'reports\rr1-providence-schema-metadata-audit-5.5b.json') -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-SCHEMA-METADATA-AUDIT'){throw '5.5b audit status invalid.'}
if([int]$R.providence.max_speed -ne 3){throw 'Providence max-speed mismatch.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.5b.1 verifier PASS'
Write-Host ('[INFO] Ship files scanned: '+$R.ship_files)
Write-Host ('[INFO] Providence speed-3 row present: '+$R.providence.has_speed_3)
Write-Host ('[INFO] Missing-top-speed records: '+@($R.repository_records_missing_top_speed).Count)
Write-Host ('[INFO] RR ship variants: '+@($R.rr_ship_variants).Count)
Write-Host '[OK] No production card data was modified'
