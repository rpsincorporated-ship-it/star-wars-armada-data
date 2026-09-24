param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop';$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$P=Get-Content -LiteralPath (Join-Path $Repo 'data\ship-card\rebel-alliance\providence-class-carrier.json') -Raw|ConvertFrom-Json
if([int]$P.points -ne 95){throw 'Providence points mismatch.'}
if([int]$P.'max-speed' -ne 2){throw 'Providence max-speed must be 2.'}
$Keys=@($P.'speed-chart'.PSObject.Properties.Name)
if(($Keys -join ',') -ne '1,2'){throw ('Unexpected Providence speed-chart keys: '+($Keys -join ','))}
$R=Get-Content -LiteralPath (Join-Path $Repo 'reports\rr1-providence-max-speed-correction-5.5d.json') -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-PRODUCTION-CORRECTION'){throw '5.5d correction report invalid.'}
if(@($R.changed_production_files).Count -ne 1){throw '5.5d production change boundary invalid.'}
Write-Host '[OK] Milestone 5.5d verifier PASS'
Write-Host '[OK] Providence points 95 / max speed 2 / speed-chart rows 1,2'
Write-Host '[OK] Correction provenance present'
Write-Host '[INFO] RR variant metadata remains separately gated'
