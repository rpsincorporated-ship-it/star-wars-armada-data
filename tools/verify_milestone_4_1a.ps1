param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Path=Join-Path $Repo 'reports\campaign-objective-path-discovery-4.1a.json'
if(-not(Test-Path -LiteralPath $Path)){throw 'Milestone 4.1a report missing.'}
$Report=(Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json)
if($Report.status -ne 'PASS'){throw 'Milestone 4.1a status is not PASS.'}
if([int]$Report.campaign_unique_names -ne 16){throw 'Expected 16 unique campaign objective names.'}
if(@($Report.classifications).Count -ne 16){throw 'Expected 16 campaign-name classifications.'}
if($Report.production_card_data_modified -ne $false){throw 'Milestone 4.1a production-write boundary failed.'}
Write-Host '[OK] Milestone 4.1a verifier PASS'
Write-Host ('[OK] Candidate files: '+@($Report.candidate_files).Count)
Write-Host ('[OK] Candidate records: '+@($Report.candidate_records).Count)
Write-Host '[OK] 16 campaign objective names classified'
Write-Host '[OK] No production card data was modified'
