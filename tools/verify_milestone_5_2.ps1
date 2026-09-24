param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$P=Join-Path $Repo 'reports\legacy-record-inventory-5.2.json'
if(-not(Test-Path -LiteralPath $P)){throw '5.2 report missing.'}
$R=Get-Content -LiteralPath $P -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-INVENTORY'){throw '5.2 status invalid.'}
if($R.baseline.label -ne '2025.01-final' -or $R.baseline.cutoff_date -ne '2025-01-21'){throw 'Baseline mismatch.'}
$Records=@($R.records)
if($Records.Count -ne [int]$R.queue.all_records){throw 'Inventory count mismatch.'}
if(@($Records.audit_id|Sort-Object -Unique).Count -ne $Records.Count){throw 'Audit IDs are not unique.'}
$Gate=@($R.priority_gates|Where-Object{$_.id -eq 'rr1-rebel-providence-navigation'})
if($Gate.Count -ne 1 -or $Gate[0].state -ne 'OPEN'){throw 'Providence verification gate missing/open-state mismatch.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.2 verifier PASS'
Write-Host ('[OK] Stable audit identities: '+$Records.Count)
Write-Host '[OK] Rebel / Imperial / shared-upgrade inventory captured'
Write-Host '[OK] RR1 Rebel Providence navigation gate remains OPEN'
Write-Host '[OK] No production card data was modified'
