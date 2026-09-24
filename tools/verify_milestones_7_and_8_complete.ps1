param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$R=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-8-release-readiness.json') -Raw|ConvertFrom-Json
$M7=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-7-final-status.json') -Raw|ConvertFrom-Json
if($M7.status-ne'PASS-MILESTONE-7-COMPLETE'){throw 'Milestone 7 final status invalid.'}
if($R.status-ne'PASS-MILESTONE-8-RELEASE-AUDIT-COMPLETE'){throw 'Milestone 8 final status invalid.'}
$Files=@(Get-ChildItem -LiteralPath (Join-Path $Repo 'data') -Recurse -File -Filter '*.json')
if($Files.Count-ne191){throw ('Expected 191 production JSON files; found '+$Files.Count)}
foreach($F in $Files){$null=Get-Content -LiteralPath $F.FullName -Raw|ConvertFrom-Json}
Write-Host '[OK] Milestone 7 final verifier PASS'
Write-Host '[OK] Milestone 8 final verifier PASS'
Write-Host ('[INFO] Release classification: '+$R.release_classification)
Write-Host ('[INFO] Official point confirmations open: '+$R.official_point_confirmations_open)
Write-Host ('[INFO] Campaign exact-text items open: '+$R.campaign_exact_text_open)
Write-Host ('[INFO] Text-sensitive Errata items open: '+$R.text_sensitive_errata_open)
