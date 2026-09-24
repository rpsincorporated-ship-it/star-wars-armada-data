param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$ReportPath=Join-Path $Repo 'reports\rapid-reinforcements-i-schema-3.2a.json'
if(-not(Test-Path -LiteralPath $ReportPath)){throw 'Milestone 3.2a schema report is missing.'}
$Report=(Get-Content -LiteralPath $ReportPath -Raw|ConvertFrom-Json)
if($Report.status -ne 'PASS'){throw 'Milestone 3.2a report is not PASS.'}
if([int]$Report.rr1_inventory_count -ne 8){throw 'Milestone 3.2a RR1 inventory count is not 8.'}
if(@($Report.source_candidates).Count -lt 8){throw 'Milestone 3.2a captured fewer than 8 source candidates.'}
if(@($Report.same_name_existing_aces).Count -lt 3){throw 'Milestone 3.2a did not capture all same-name ace protections.'}
if($Report.production_card_data_modified -ne $false){throw 'Milestone 3.2a production-write boundary failed.'}
Write-Host '[OK] Milestone 3.2a verifier PASS'
Write-Host ('[OK] Source candidates captured: '+@($Report.source_candidates).Count)
Write-Host ('[OK] Same-name ace records captured: '+@($Report.same_name_existing_aces).Count)
Write-Host '[OK] No production card writes were performed by Milestone 3.2a'
