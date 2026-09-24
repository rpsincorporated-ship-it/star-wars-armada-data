param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Meta=Join-Path $Repo 'metadata\supplements\rapid-reinforcements-ii-official-audit.json'
$ReportPath=Join-Path $Repo 'reports\rapid-reinforcements-ii-audit-3.3.json'
if(-not(Test-Path -LiteralPath $Meta)){throw 'RRII audit metadata missing.'}
if(-not(Test-Path -LiteralPath $ReportPath)){throw 'RRII audit report missing.'}
$Audit=(Get-Content -LiteralPath $Meta -Raw|ConvertFrom-Json)
$Report=(Get-Content -LiteralPath $ReportPath -Raw|ConvertFrom-Json)
if(@($Audit.records).Count -ne 8){throw 'RRII audit inventory must contain 8 records.'}
if($Report.status -ne 'PASS'){throw 'Milestone 3.3 report is not PASS.'}
if([int]$Report.total_cards -ne 8){throw 'Milestone 3.3 report total is not 8.'}
if([int]$Report.upgrades -ne 4 -or [int]$Report.squadrons -ne 4){throw 'RRII must contain 4 upgrades and 4 squadrons.'}
if([int]$Report.revision_2_1_cards -ne 7 -or [int]$Report.revision_2_0_cards -ne 1){throw 'RRII revision distribution mismatch.'}
if($Report.revision_2_0_exception -ne 'Governor Pryce'){throw 'Governor Pryce revision exception missing.'}
if($Report.production_card_data_modified -ne $false){throw 'Milestone 3.3 production-write boundary failed.'}
Write-Host '[OK] Milestone 3.3 verifier PASS'
Write-Host '[OK] RRII official inventory: 8 cards / 4 upgrades / 4 squadrons'
Write-Host '[OK] Governor Pryce correctly retained as the RRII revision-2.0 exception'
Write-Host '[OK] No production card data was modified by Milestone 3.3'
