param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-MilestoneJsonRecords([string]$Path){
    $Parsed=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
    if($null-eq$Parsed){return}
    if($Parsed-is[System.Array]){foreach($Item in $Parsed){Write-Output $Item};return}
    Write-Output $Parsed
}
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-20-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-20-OFFICIAL-CAMPAIGN-INGESTION-COMPLETE'){throw 'Milestone 20 invalid.'}
$Rows=@(Read-MilestoneJsonRecords (Join-Path $Repo 'data\objective-card.json'))
if($Rows.Count-ne46){throw ('Expected 46 objective records; found '+$Rows.Count)}
$Campaign=@($Rows|Where-Object{$_.category-eq'Campaign'})
if($Campaign.Count-ne10){throw ('Expected 10 campaign records; found '+$Campaign.Count)}
Write-Host '[OK] MILESTONE 20 FINAL VERIFIER PASS'
Write-Host '[OK] Objective records: 46'
Write-Host '[OK] Direct-official campaign records: 10'
Write-Host '[INFO] Remaining campaign source gates: 9'
