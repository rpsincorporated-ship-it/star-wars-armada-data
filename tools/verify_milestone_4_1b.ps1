param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-schema-product-version-4.1b.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.1b report missing.'}
$Report=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($Report.status -ne 'PASS'){throw 'Milestone 4.1b status is not PASS.'}
if($Report.live_objective_store -ne 'data\objective-card.json'){throw 'Live objective store mismatch.'}
if([int]$Report.live_objective_records -ne 36){throw 'Expected 36 existing standard objectives.'}
if([int]$Report.campaign_inventory.physical_cards -ne 19){throw 'Expected 19 physical campaign objective cards.'}
if([int]$Report.campaign_inventory.unique_names -ne 16){throw 'Expected 16 unique campaign objective names.'}
if([int]$Report.campaign_inventory.single_product_design_candidates -ne 13){throw 'Expected 13 single-product design candidates.'}
if([int]$Report.campaign_inventory.cross_product_same_name_pairs -ne 3){throw 'Expected 3 repeated Base Defense pairs.'}
if($Report.policy.production_install_authorized -ne $false){throw 'Production-install boundary failed.'}
if($Report.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
if(@($Report.identity_rows).Count -ne 16){throw 'Expected 16 identity rows.'}
Write-Host '[OK] Milestone 4.1b verifier PASS'
Write-Host '[OK] Live objective store: data\objective-card.json / 36 standard records'
Write-Host '[OK] Campaign inventory: 19 physical cards / 16 unique names'
Write-Host '[OK] Identity boundary: 13 single-product + 3 Base Defense review pairs'
Write-Host '[OK] No production card data was modified'
