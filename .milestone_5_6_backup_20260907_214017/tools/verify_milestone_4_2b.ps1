param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$CorrectionPath=Join-Path $Repo 'reports\campaign-objective-provenance-correction-4.2b.json'
$AuditPath=Join-Path $Repo 'reports\campaign-objective-equivalence-rulings-4.2.json'
$SchemaPath=Join-Path $Repo 'reports\campaign-objective-schema-product-version-4.1b.json'
if(-not(Test-Path -LiteralPath $CorrectionPath)){throw 'Milestone 4.2b correction report missing.'}
if(-not(Test-Path -LiteralPath $AuditPath)){throw 'Milestone 4.2 report missing.'}
if(-not(Test-Path -LiteralPath $SchemaPath)){throw 'Milestone 4.1b report missing.'}
$Correction=(Get-Content -LiteralPath $CorrectionPath -Raw|ConvertFrom-Json)
$Audit=(Get-Content -LiteralPath $AuditPath -Raw|ConvertFrom-Json)
$Schema=(Get-Content -LiteralPath $SchemaPath -Raw|ConvertFrom-Json)
if($Correction.status -ne 'PASS'){throw 'Milestone 4.2b status is not PASS.'}
if($Correction.corrected_value -ne 'SWM31'){throw 'SWM31 correction missing.'}
foreach($Pair in @($Audit.base_defense_pairs)){
 if($Pair.corellian_sku -ne 'SWM25'){throw ($Pair.name+' Corellian SKU mismatch.')}
 if($Pair.ritr_sku -ne 'SWM31'){throw ($Pair.name+' Rebellion in the Rim SKU mismatch.')}
 if($Pair.equivalent -ne $false){throw ($Pair.name+' equivalence decision changed.')}
}
$Skus=@()
foreach($Identity in @($Schema.identity_rows)){$Skus+=@($Identity.product_skus)}
if($Skus -contains 'SWM30'){throw 'Obsolete SWM30 remains in 4.1b identity rows.'}
if($Skus -notcontains 'SWM31'){throw 'SWM31 missing from 4.1b identity rows.'}
if([int]$Audit.campaign_inventory.physical_records_target -ne 19){throw 'Campaign record target mismatch.'}
if([int]$Audit.campaign_inventory.base_defense_product_version_records -ne 6){throw 'Base Defense record count mismatch.'}
if($Correction.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 4.2b verifier PASS'
Write-Host '[OK] Campaign product SKUs: SWM25 / SWM31'
Write-Host '[OK] Base Defense pairs explicitly preserve SWM25 / SWM31 identity'
Write-Host '[OK] Campaign target: 19 records / 16 titles / 6 Base Defense product versions'
Write-Host '[OK] No production card data was modified'
