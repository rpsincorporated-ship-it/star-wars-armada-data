param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$P=Join-Path $Repo 'reports\global-official-final-5.1.json'
if(-not(Test-Path -LiteralPath $P)){throw '5.1 report missing.'}
$R=Get-Content -LiteralPath $P -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-PREFLIGHT'){throw '5.1 status invalid.'}
if($R.baseline.label -ne '2025.01-final' -or $R.baseline.cutoff_date -ne '2025-01-21'){throw 'Baseline mismatch.'}
if($R.baseline.post_cutoff_rulings_allowed -ne $false){throw 'Post-cutoff gate failed.'}
if(@($R.sources).Count -lt 4){throw 'Source registry incomplete.'}
if(@($R.workstreams).Count -ne 9){throw 'Workstream inventory mismatch.'}
if($R.rr1_rebel_providence.verification_state -ne 'REQUIRES-OFFICIAL-CARD-VISUAL-CROSSCHECK'){throw 'Providence verification gate missing.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.1 verifier PASS'
Write-Host '[OK] January 21 2025 official-final baseline locked'
Write-Host '[OK] Nine global audit workstreams registered'
Write-Host '[OK] RR1 Rebel Providence navigation verification remains explicitly open'
Write-Host '[OK] No production card data was modified'
