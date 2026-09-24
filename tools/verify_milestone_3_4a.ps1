param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\rapid-reinforcements-ii-schema-3.4a.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 3.4a schema report is missing.'}
$Report=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($Report.status -ne 'PASS'){throw 'Milestone 3.4a status is not PASS.'}
if([int]$Report.rr2_inventory_count -ne 8){throw 'Milestone 3.4a RRII inventory count is not 8.'}
if(@($Report.upgrade_files).Count -ne 2){throw 'Milestone 3.4a must capture officer and commander shared files.'}
if(@($Report.squadron_sources).Count -lt 4){throw 'Milestone 3.4a captured fewer than four squadron source records.'}
if($Report.production_card_data_modified -ne $false){throw 'Milestone 3.4a production-write boundary failed.'}
Write-Host '[OK] Milestone 3.4a verifier PASS'
Write-Host '[OK] Shared upgrade schemas and four RRII squadron chassis captured'
Write-Host '[OK] No production card data was modified by Milestone 3.4a'
