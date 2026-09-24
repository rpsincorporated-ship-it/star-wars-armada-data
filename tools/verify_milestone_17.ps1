param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path $RepoPath).Path
$S=Get-Content (Join-Path $Repo 'reports\milestone-17-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-17-CAMPAIGN-SOURCE-CAPTURE-READY'){throw 'Milestone 17 invalid.'}
if([int]$S.physical_campaign_cards-ne19){throw 'Campaign physical-card count mismatch.'}
if([int]$S.unique_campaign_titles-ne16){throw 'Campaign unique-title count mismatch.'}
Write-Host '[OK] MILESTONE 17 FINAL VERIFIER PASS'
Write-Host '[INFO] Next gate: authorized campaign source artifacts'
