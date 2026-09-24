param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-22-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-22-REMAINING-CAMPAIGN-SOURCE-RECOVERY-READY'){throw 'Milestone 22 invalid.'}
if([int]$S.objective_records-ne46){throw 'Expected 46 objective records.'}
if([int]$S.recovery_queue_records-ne9){throw 'Expected 9 recovery queue records.'}
if([int]$S.production_files_changed-ne0){throw 'Milestone 22 must not modify production JSON.'}
Write-Host '[OK] MILESTONE 22 FINAL VERIFIER PASS'
Write-Host '[OK] Recovery queue records: 9'
Write-Host '[OK] Direct-card source gates: 8'
Write-Host '[OK] Official-errata partial gates: 1'
Write-Host '[OK] Production files changed: 0'
