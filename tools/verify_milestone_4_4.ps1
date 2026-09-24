param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-source-baseline-4.4.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.4 report missing.'}
$R=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($R.status -ne 'PASS'){throw 'Milestone 4.4 status is not PASS.'}
if($R.baseline.cutoff_date -ne '2025-01-21'){throw 'Official-final cutoff mismatch.'}
if($R.baseline.release_label -ne '2025.01-final'){throw 'Release label mismatch.'}
if($R.baseline.post_cutoff_rulings_allowed -ne $false){throw 'Post-cutoff ruling gate failed.'}
if([int]$R.construction.records -ne 19){throw 'Expected 19 campaign records.'}
if([int]$R.construction.swm25_records -ne 8){throw 'Expected 8 SWM25 records.'}
if([int]$R.construction.swm31_records -ne 11){throw 'Expected 11 SWM31 records.'}
if([int]$R.readiness.records_verified_for_production -ne 0){throw '4.4 must not mark records production-ready.'}
if([int]$R.readiness.records_blocked_for_source_text -ne 19){throw 'Expected all 19 records source-gated.'}
if(@($R.readiness.records).Count -ne 19){throw 'Expected 19 readiness rows.'}
if(@($R.known_campaign_errata_flags|Where-Object{$_.title -eq 'Hyperlane Raid'}).Count -lt 1){throw 'Hyperlane Raid errata flag missing.'}
if(@($R.known_campaign_errata_flags|Where-Object{$_.title -eq 'Nebula Outskirts'}).Count -lt 1){throw 'Nebula Outskirts errata flag missing.'}
if($R.production_install_authorized -ne $false){throw 'Production install must remain blocked.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 4.4 verifier PASS'
Write-Host '[OK] Canonical cutoff: 2025-01-21 / 2025.01-final'
Write-Host '[OK] Campaign inventory: 19 records / SWM25=8 / SWM31=11'
Write-Host '[OK] Hyperlane Raid and Nebula Outskirts errata flags preserved'
Write-Host '[OK] 19 / 19 records remain source-gated'
Write-Host '[OK] No production card data was modified'
