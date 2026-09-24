param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-construction-4.3.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.3 report missing.'}
$R=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($R.status -ne 'PASS'){throw 'Milestone 4.3 status is not PASS.'}
if([int]$R.live_baseline_records -ne 36){throw 'Expected 36 live standard objectives.'}
if([int]$R.live_schema.property_count -ne 9){throw 'Expected 9 objective properties.'}
if([int]$R.live_schema.shape_count -ne 4){throw 'Expected 4 objective record shapes.'}
if([int]$R.construction.records -ne 19){throw 'Expected 19 constructed records.'}
if([int]$R.construction.unique_titles -ne 16){throw 'Expected 16 unique titles.'}
if([int]$R.construction.swm25_records -ne 8){throw 'Expected 8 SWM25 records.'}
if([int]$R.construction.swm31_records -ne 11){throw 'Expected 11 SWM31 records.'}
if([int]$R.construction.base_defense_product_version_records -ne 6){throw 'Expected 6 Base Defense records.'}
if([int]$R.construction.unique_stable_ids -ne 19){throw 'Expected 19 unique stable IDs.'}
if(@($R.construction.skeletons).Count -ne 19){throw 'Expected 19 skeletons.'}
if(@($R.construction.skeletons|Where-Object{$_.ready_for_production -eq $true}).Count -ne 0){throw '4.3 skeletons must remain source-gated.'}
if($R.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 4.3 verifier PASS'
Write-Host '[OK] Live schema: 36 records / 9 properties / 4 shapes'
Write-Host '[OK] Construction manifest: 19 records / 16 titles / 19 unique stable IDs'
Write-Host '[OK] Product split: SWM25=8 / SWM31=11'
Write-Host '[OK] All text remains source-gated; production install is blocked'
Write-Host '[OK] No production card data was modified'
