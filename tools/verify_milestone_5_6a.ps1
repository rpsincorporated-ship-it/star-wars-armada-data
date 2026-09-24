param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$PlanPath=Join-Path $Repo 'reports\rr1-metadata-correction-plan-5.6a.json'
if(-not(Test-Path -LiteralPath $PlanPath)){throw 'Missing Milestone 5.6a plan.'}
$Plan=Get-Content -LiteralPath $PlanPath -Raw|ConvertFrom-Json
if($Plan.status -ne 'PASS-RR1-METADATA-CORRECTION-PLAN'){throw '5.6a status invalid.'}
if(@($Plan.safe_corrections).Count -ne 2){throw 'Expected two safe RR1 metadata corrections.'}
$Fields=@($Plan.safe_corrections|ForEach-Object{$_.field})
if(@($Fields|Where-Object{$_ -ne 'legality.faction'}).Count -ne 0){throw 'Unexpected safe correction field.'}
if($Plan.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.6a verifier PASS'
Write-Host '[OK] Exactly two safe RR1 metadata corrections planned'
Write-Host '[OK] Both corrections are legality.faction only'
Write-Host ('[INFO] Deferred metadata items: '+@($Plan.deferred_items).Count)
Write-Host '[OK] No production card data was modified'
