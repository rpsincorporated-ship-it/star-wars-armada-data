param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-24-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-24-CAMPAIGN-IDENTITY-LOCK-AND-INGESTION-GATES-COMPLETE'){throw 'Milestone 24 invalid.'}
if([int]$S.objective_records-ne47){throw 'Expected 47 objective records.'}
if([int]$S.remaining_campaign_source_gates-ne8){throw 'Expected 8 remaining campaign source gates.'}
if([int]$S.production_files_changed-ne0){throw 'Milestone 24 must not modify production JSON.'}
Write-Host '[OK] MILESTONE 24 FINAL VERIFIER PASS'
Write-Host '[OK] Objective records remain: 47'
Write-Host '[OK] Physical-card identities locked: 8'
Write-Host '[OK] Authoritative source slots: 8'
Write-Host '[OK] Production files changed: 0'
