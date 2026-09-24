param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-MilestoneJsonRecords([string]$Path){
    $Parsed=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
    if($null-eq$Parsed){return}
    if($Parsed-is[System.Array]){foreach($Item in $Parsed){Write-Output $Item};return}
    Write-Output $Parsed
}
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-23-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-23-NEBULA-OUTSKIRTS-OFFICIAL-INGESTION-COMPLETE'){throw 'Milestone 23 invalid.'}
$Rows=@(Read-MilestoneJsonRecords (Join-Path $Repo 'data\objective-card.json'))
if($Rows.Count-ne47){throw ('Expected 47 objective records; found '+$Rows.Count)}
$Neb=@($Rows|Where-Object{$_.title-eq'Nebula Outskirts' -and $_.'product-code'-eq'SWM25'})
if($Neb.Count-ne1){throw ('Expected exactly one Nebula Outskirts record; found '+$Neb.Count)}
if([int]$S.remaining_campaign_source_gates-ne8){throw 'Expected eight remaining campaign source gates.'}
Write-Host '[OK] MILESTONE 23 FINAL VERIFIER PASS'
Write-Host '[OK] Objective records: 47'
Write-Host '[OK] Nebula Outskirts official updated-card record present'
Write-Host '[INFO] Remaining campaign source gates: 8'
