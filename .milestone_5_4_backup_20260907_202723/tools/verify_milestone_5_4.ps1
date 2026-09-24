param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$P=Join-Path $Repo 'reports\official-errata-candidates-5.4.json'
if(-not(Test-Path $P)){throw '5.4 report missing.'}
$R=Get-Content $P -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-CANDIDATE-MAP'){throw '5.4 status invalid.'}
if([int]$R.evidence_identities -ne 244){throw 'Evidence identity count mismatch.'}
if([int]$R.confirmed_numeric_corrections -ne 0 -or [int]$R.confirmed_structural_corrections -ne 0){throw '5.4 must not pre-confirm corrections.'}
$I=Join-Path $Repo 'input\official-errata-candidates-5.4.json'
$Rows=@(Get-Content $I -Raw|ConvertFrom-Json)
if($Rows.Count -ne [int]$R.candidate_records){throw 'Candidate count mismatch.'}
$Prov=@($Rows|Where-Object{$_.candidate_reason -eq 'RR1-PROVIDENCE-NAVIGATION-VISUAL-CROSSCHECK'})
if($Prov.Count -lt 1){throw 'Providence visual gate missing.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
Write-Host '[OK] Milestone 5.4 verifier PASS'
Write-Host ('[OK] Official comparison candidate queue: '+$Rows.Count)
Write-Host '[OK] No correction was pre-confirmed without record-level source comparison'
Write-Host '[OK] RR1 Rebel Providence visual gate retained'
Write-Host '[OK] No production card data was modified'
