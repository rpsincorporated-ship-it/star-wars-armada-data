param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-authorized-text-4.5.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.5 report missing.'}
$R=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($R.status -notin @('PASS-TEMPLATE-READY','PASS-INPUT-COMPLETE')){throw 'Milestone 4.5 status invalid.'}
if([int]$R.identity_validation.expected_records -ne 19){throw 'Expected 19 records.'}
if([int]$R.identity_validation.matched_records -ne 19){throw 'Expected 19 matched identities.'}
if([int]$R.identity_validation.stable_ids_unique -ne 19){throw 'Expected 19 unique stable IDs.'}
if([int]$R.identity_validation.swm25_records -ne 8){throw 'Expected 8 SWM25 records.'}
if([int]$R.identity_validation.swm31_records -ne 11){throw 'Expected 11 SWM31 records.'}
if($R.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 4.5 verifier PASS'
Write-Host ('[OK] Status: '+$R.status)
Write-Host '[OK] 19 / 19 campaign identities aligned'
Write-Host ('[OK] Authorized confirmations: '+$R.text_readiness.authorized_records+' / 19')
Write-Host '[OK] Production install remains blocked'
