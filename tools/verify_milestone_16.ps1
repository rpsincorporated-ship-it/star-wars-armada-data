param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path $RepoPath).Path
$S=Get-Content (Join-Path $Repo 'reports\milestone-16-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-16-TEXT-SENSITIVE-ERRATA-CLOSED'){throw 'Milestone 16 invalid.'}
if([int]$S.text_sensitive_errata_remaining-ne0){throw 'Text-sensitive backlog is not zero.'}
if([int]$S.official_point_confirmations_remaining-ne0){throw 'Point backlog is not zero.'}
Write-Host '[OK] MILESTONE 16 FINAL VERIFIER PASS'
Write-Host '[OK] Official point backlog: 0'
Write-Host '[OK] Text-sensitive Errata backlog: 0'
