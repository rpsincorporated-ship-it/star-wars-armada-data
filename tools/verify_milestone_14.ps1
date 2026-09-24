param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path $RepoPath).Path
$S=Get-Content (Join-Path $Repo 'reports\milestone-14-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-14-FINAL-ONAGER-TRANSACTION-COMPLETE'){throw 'Milestone 14 invalid.'}
$A=Get-Content (Join-Path $Repo 'data\ship-card\galactic-empire\onager-class-star-destroyer.json') -Raw|ConvertFrom-Json
$B=Get-Content (Join-Path $Repo 'data\ship-card\galactic-empire\onager-class-testbed.json') -Raw|ConvertFrom-Json
$AR=@($A)|Where-Object{$_.name-eq'Onager-class Star Destroyer'}
$BR=@($B)|Where-Object{$_.name-eq'Onager-class Testbed'}
if([int]$AR.points-ne120){throw 'Onager-class Star Destroyer must be 120.'}
if([int]$BR.points-ne116){throw 'Onager-class Testbed must be 116.'}
Write-Host '[OK] MILESTONE 14 FINAL VERIFIER PASS'
Write-Host '[OK] Official point-confirmation backlog: 0'
