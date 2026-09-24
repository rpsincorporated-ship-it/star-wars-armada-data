param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$R=J (Join-Path $Repo 'reports\authoritative-source-ingestion-6.5.json')
if($R.status-notin@('PASS-AUTHORITATIVE-SOURCE-READY','PASS-AUTHORITATIVE-SOURCE-PRESENT','PASS-AUTHORITATIVE-SOURCE-INGESTION')){throw '6.5 status invalid.'}
if([int]$R.queue_rows-ne244){throw '6.5 queue count invalid.'}
if([int]$R.production_writes-ne0){throw '6.5 must not write production.'}
Write-Host '[OK] Milestone 6.5 verifier PASS'
Write-Host ('[OK] Status: '+$R.status)
Write-Host ('[OK] Direct resolution rows: '+$R.direct_resolution_rows)
Write-Host ('[OK] Official Errata 5.5 local PDF present: '+$R.official_errata_pdf_present)
