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

$IndexPath=Join-Path $Repo 'input\campaign-authorized\campaign-source-index.json'
$Index=@(Read-MilestoneJsonRecords $IndexPath)
if($Index.Count-ne19){throw ('Expected 19 campaign source slots; found '+$Index.Count)}

$Wanted=@(6,7,8,9,10,11,14,16,19)
$Found=0
$Missing=0
foreach($Seq in $Wanted){
    $S=@($Index|Where-Object{[int]$_.sequence-eq$Seq})
    if($S.Count-ne1){throw ('Source slot '+$Seq+' not uniquely found.')}
    if([string]$S[0].source_status-eq'PRESENT'){
        $Found++
        Write-Host ('[OK] Present: {0:D2} {1}' -f $Seq,[string]$S[0].title)
    }else{
        $Missing++
        Write-Host ('[INFO] Missing: {0:D2} {1}' -f $Seq,[string]$S[0].title)
    }
}
Write-Host ('[OK] Remaining-nine artifacts present: '+$Found)
Write-Host ('[INFO] Remaining-nine artifacts still missing: '+$Missing)
