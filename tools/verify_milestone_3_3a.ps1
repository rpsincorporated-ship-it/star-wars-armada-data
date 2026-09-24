param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$AuditPath=Join-Path $Repo 'metadata\supplements\rapid-reinforcements-ii-official-audit.json'
$ReportPath=Join-Path $Repo 'reports\rapid-reinforcements-ii-audit-3.3a.json'
if(-not(Test-Path -LiteralPath $AuditPath)){throw 'Corrected canonical RRII audit missing.'}
if(-not(Test-Path -LiteralPath $ReportPath)){throw 'Milestone 3.3a report missing.'}
$Audit=(Get-Content -LiteralPath $AuditPath -Raw|ConvertFrom-Json)
$Report=(Get-Content -LiteralPath $ReportPath -Raw|ConvertFrom-Json)
if(@($Audit.records).Count -ne 8){throw 'Corrected RRII inventory must contain 8 cards.'}
$Draven=@($Audit.records|Where-Object{$_.name -eq 'General Draven'})
if($Draven.Count -ne 1){throw 'Expected one General Draven.'}
if($Draven[0].upgrade_type -ne 'Commander'){throw 'General Draven is not classified as Commander.'}
if([int]$Draven[0].points -ne 20){throw 'General Draven points mismatch.'}
if($Report.status -ne 'PASS'){throw '3.3a report is not PASS.'}
if([int]$Report.commanders -ne 2 -or [int]$Report.officers -ne 2 -or [int]$Report.squadrons -ne 4){throw 'RRII type distribution mismatch.'}
if($Report.production_card_data_modified -ne $false){throw '3.3a production-write boundary failed.'}
Write-Host '[OK] Milestone 3.3a verifier PASS'
Write-Host '[OK] General Draven = Rebel Alliance Commander / 20 pts'
Write-Host '[OK] RRII = 2 commanders / 2 officers / 4 squadrons'
Write-Host '[OK] No production card data was modified'
