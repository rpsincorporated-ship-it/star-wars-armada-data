param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-VerifyJson([string]$Path){return (Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)}
$Path=Join-Path $Repo 'reports\campaign-objective-equivalence-rulings-4.2.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.2 report missing.'}
$Report=Read-VerifyJson $Path
if($Report.status -ne 'PASS'){throw 'Milestone 4.2 status is not PASS.'}
if([int]$Report.live_standard_objective_records -ne 36){throw 'Expected 36 standard objective records.'}
if([int]$Report.campaign_inventory.physical_records_target -ne 19){throw 'Expected 19 campaign production records.'}
if([int]$Report.campaign_inventory.unique_titles -ne 16){throw 'Expected 16 campaign titles.'}
if([int]$Report.campaign_inventory.base_defense_product_version_records -ne 6){throw 'Expected six Base Defense product-version records.'}
if(@($Report.base_defense_pairs).Count -ne 3){throw 'Expected three Base Defense pairs.'}
foreach($Pair in @($Report.base_defense_pairs)){if($Pair.equivalent -ne $false){throw ($Pair.name+' must remain non-equivalent.')}}
if($Report.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($Report.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 4.2 verifier PASS'
Write-Host '[OK] Live standard objectives: 36'
Write-Host '[OK] Campaign target: 19 records / 16 titles'
Write-Host '[OK] Base Defense: six distinct product-version records'
Write-Host '[OK] No production card data was modified'
