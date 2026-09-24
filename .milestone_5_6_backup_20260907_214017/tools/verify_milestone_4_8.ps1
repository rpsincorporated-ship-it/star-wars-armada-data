param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-canonicalization-4.8.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.8 report missing.'}
$R=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($R.status -notin @('PASS-CANONICALIZER-READY','PASS-INPUT-CANONICALIZABLE')){throw 'Invalid 4.8 status.'}
if([int]$R.live_baseline_records -ne 36){throw 'Expected baseline 36.'}
if([int]$R.campaign_records -ne 19){throw 'Expected campaign 19.'}
if([int]$R.final_target_records -ne 55){throw 'Expected target 55.'}
if([int]$R.base_defense_product_version_records -ne 6){throw 'Expected six Base Defense versions.'}
if(@($R.required_fields).Count -ne 7){throw 'Expected seven required production fields.'}
if(@($R.optional_fields).Count -ne 2){throw 'Expected two optional production fields.'}
if($R.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
if(-not(Test-Path -LiteralPath (Join-Path $Repo 'tools\canonicalize_campaign_objective_payload.ps1'))){throw 'Canonicalizer missing.'}
Write-Host '[OK] Milestone 4.8 verifier PASS'
Write-Host ('[OK] Status: '+$R.status)
Write-Host '[OK] Live schema contract and canonicalization gate installed'
Write-Host '[OK] 19 campaign records / 55 final target'
Write-Host '[OK] No production card data was modified'
