param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path

function Read-MilestoneJsonRecords([string]$Path){
    $Parsed=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
    if($null-eq$Parsed){return}
    if($Parsed-is[System.Array]){
        foreach($Item in $Parsed){Write-Output $Item}
        return
    }
    Write-Output $Parsed
}

$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-18-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-18-OFFICIAL-CAMPAIGN-SOURCE-ACQUISITION-COMPLETE'){throw 'Milestone 18 invalid.'}
if([int]$S.campaign_sources_present-ne10){throw 'Expected 10 campaign sources present.'}
if([int]$S.campaign_sources_remaining-ne9){throw 'Expected 9 campaign sources remaining.'}

$Index=@(Read-MilestoneJsonRecords (Join-Path $Repo 'input\campaign-authorized\campaign-source-index.json'))
if($Index.Count-ne19){throw ('Expected 19 campaign source slots; found '+$Index.Count)}
$Present=@($Index|Where-Object{$_.source_status-eq'PRESENT'}).Count
$Missing=@($Index|Where-Object{$_.source_status-ne'PRESENT'}).Count
if($Present-ne10-or$Missing-ne9){throw 'Campaign source index counts do not match final milestone status.'}

Write-Host '[OK] MILESTONE 18 FINAL VERIFIER PASS'
Write-Host '[OK] Campaign sources present: 10'
Write-Host '[INFO] Campaign sources remaining: 9'
