param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-payload-contract-4.7.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.7 report missing.'}
$R=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($R.status -ne 'PASS'){throw 'Milestone 4.7 status is not PASS.'}
if([int]$R.live_objective_records -ne 36){throw 'Expected 36 live objectives.'}
if(@($R.field_contract).Count -ne 9){throw 'Expected 9 field-contract entries.'}
if([int]$R.payload_rules.identity.records -ne 19){throw 'Expected 19 campaign records.'}
if([int]$R.payload_rules.identity.unique_stable_ids -ne 19){throw 'Expected 19 unique stable IDs.'}
if([int]$R.payload_rules.identity.swm25_records -ne 8){throw 'Expected 8 SWM25 records.'}
if([int]$R.payload_rules.identity.swm31_records -ne 11){throw 'Expected 11 SWM31 records.'}
if([int]$R.payload_rules.merge.production_after -ne 55){throw 'Expected final total of 55.'}
if($R.payload_rules.text.official_final_cutoff -ne '2025-01-21'){throw 'Cutoff mismatch.'}
if($R.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
$Validator=Join-Path $Repo 'tools\validate_campaign_objective_payload.ps1'
if(-not(Test-Path -LiteralPath $Validator)){throw 'Reusable payload validator missing.'}
Write-Host '[OK] Milestone 4.7 verifier PASS'
Write-Host '[OK] Live field contract: 9 properties'
Write-Host '[OK] Campaign payload contract: 19 records / 55 final total'
Write-Host '[OK] Reusable payload validator installed'
Write-Host '[OK] No production card data was modified'
