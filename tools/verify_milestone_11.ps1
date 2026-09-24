param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-11-final-status.json') -Raw|ConvertFrom-Json
if($S.status -ne 'PASS-MILESTONE-11-FINAL-POINT-RESOLUTION-COMPLETE'){throw 'Milestone 11 invalid.'}
$Files=@(Get-ChildItem -LiteralPath (Join-Path $Repo 'data') -Recurse -File -Filter '*.json')
if($Files.Count -ne 191){throw ('Expected 191 JSON files; found '+$Files.Count)}
$Count=0
foreach($F in $Files){$X=Get-Content -LiteralPath $F.FullName -Raw|ConvertFrom-Json;if($X -is [System.Array]){$Count+=@($X).Count}elseif($null-ne$X){$Count++}}
if($Count -ne 349){throw ('Expected 349 records; found '+$Count)}
Write-Host '[OK] MILESTONE 11 FINAL VERIFIER PASS'
Write-Host ('[INFO] Official point confirmations remaining: '+$S.official_point_confirmations_remaining)
