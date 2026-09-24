param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-25-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-25-FINAL-CAMPAIGN-SOURCE-CAPTURE-READY'){throw 'Milestone 25 invalid.'}
if([int]$S.objective_records-ne47){throw 'Expected 47 objective records.'}
if([int]$S.physical_card_capture_slots-ne8){throw 'Expected 8 physical-card capture slots.'}
if([int]$S.production_files_changed-ne0){throw 'Milestone 25 must not modify production JSON.'}
Write-Host '[OK] MILESTONE 25 FINAL VERIFIER PASS'
Write-Host '[OK] Objective records remain: 47'
Write-Host '[OK] Physical-card source slots: 8'
Write-Host ('[INFO] Source-ready slots: '+$S.source_ready_slots)
Write-Host ('[INFO] Source-missing slots: '+$S.source_missing_slots)
Write-Host '[OK] Production files changed: 0'
