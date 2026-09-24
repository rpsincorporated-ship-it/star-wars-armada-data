param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$ReportPath=Join-Path $Repo 'reports\rr1-cross-faction-metadata-audit-5.6.json'
if(-not(Test-Path -LiteralPath $ReportPath)){throw 'Missing Milestone 5.6 report.'}
$Report=Get-Content -LiteralPath $ReportPath -Raw|ConvertFrom-Json
if($Report.status -ne 'PASS-RR1-METADATA-AUDIT'){throw 'Milestone 5.6 status invalid.'}
if([int]$Report.rr1_ship_variant_count -ne 4){throw 'Expected four RR1 cross-faction ship variants.'}
if($Report.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
$Providence=@($Report.ships|Where-Object{$_.key -eq 'rebel-providence-carrier'})
if($Providence.Count -ne 1){throw 'Providence audit row missing.'}
if([int]$Providence[0].points -ne 95 -or [int]$Providence[0].max_speed -ne 2){throw 'Providence corrected baseline mismatch.'}
Write-Host '[OK] Milestone 5.6 verifier PASS'
Write-Host '[OK] Four RR1 cross-faction ship variants audited'
Write-Host '[OK] Providence corrected baseline remains points 95 / max-speed 2'
Write-Host ('[INFO] Metadata findings: '+@($Report.findings).Count)
Write-Host '[OK] No production card data was modified'
