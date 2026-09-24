param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop';$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$R=Get-Content -LiteralPath (Join-Path $Repo 'reports\rr1-providence-official-visual-correction-plan-5.5c.json') -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-CORRECTION-PLAN'){throw '5.5c status invalid.'}
if([int]$R.factual_resolution.official_max_speed -ne 2){throw 'Official max-speed resolution invalid.'}
if(@($R.confirmed_corrections).Count -ne 1){throw 'Expected exactly one confirmed correction.'}
if($R.confirmed_corrections[0].field -ne 'max-speed'){throw 'Unexpected correction field.'}
if([int]$R.confirmed_corrections[0].proposed -ne 2){throw 'Unexpected proposed max-speed.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.5c verifier PASS'
Write-Host '[OK] Official Rebel Providence maximum speed resolved to 2'
Write-Host '[OK] Exact production correction candidate: max-speed 3 -> 2'
Write-Host '[OK] Metadata remains separately gated'
Write-Host '[OK] No production card data was modified'
