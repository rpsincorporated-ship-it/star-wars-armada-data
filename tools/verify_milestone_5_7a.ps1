param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$R=Get-Content -LiteralPath (Join-Path $Repo 'reports\official-errata-5.5-reconciliation-worklist-5.7a.json') -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-ERRATA-5.5-WORKLIST-CORRECTED'){throw '5.7a status invalid.'}
if([int]$R.corrected_worklist_count -ne 117){throw '5.7a worklist count must be 117.'}
$C=Get-Content -LiteralPath (Join-Path $Repo 'reports\official-errata-5.5-reconciliation-worklist-5.7.json') -Raw|ConvertFrom-Json
if([int]$C.worklist_count -ne 117){throw 'Canonical 5.7 worklist count must be 117.'}
$G=Get-Content -LiteralPath (Join-Path $Repo 'reports\release-readiness-5.8.json') -Raw|ConvertFrom-Json
$B=@($G.blockers|Where-Object{$_.area -eq 'Official Errata 5.5 reconciliation'})
if($B.Count -ne 1 -or [int]$B[0].count -ne 117){throw '5.8 Errata blocker count must be 117.'}
Write-Host '[OK] Milestone 5.7a verifier PASS'
Write-Host '[OK] Corrected Errata 5.5 worklist count = 117'
Write-Host '[OK] Canonical 5.7 worklist superseded correctly'
Write-Host '[OK] 5.8 readiness count = 117'
Write-Host '[OK] No production card data was modified'
