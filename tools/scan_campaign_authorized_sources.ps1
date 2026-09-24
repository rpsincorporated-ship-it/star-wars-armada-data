param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path

function Read-MilestoneJsonRecords([string]$Path){
    if(-not(Test-Path -LiteralPath $Path)){throw ('Missing JSON: '+$Path)}
    $Parsed=Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if($null -eq $Parsed){return}
    if($Parsed -is [System.Array]){
        foreach($Item in $Parsed){Write-Output $Item}
        return
    }
    Write-Output $Parsed
}

$Root=Join-Path $Repo 'input\campaign-authorized'
$IndexPath=Join-Path $Root 'campaign-source-index.json'
$Index=@(Read-MilestoneJsonRecords $IndexPath)
if($Index.Count-ne19){throw ('Expected 19 campaign source slots; found '+$Index.Count)}

$Allowed=@('.png','.jpg','.jpeg','.pdf','.txt')
foreach($R in $Index){
    $CampaignSlug=(($R.campaign -replace '[^A-Za-z0-9]+','-').Trim('-').ToLowerInvariant())
    $Dir=Join-Path -Path $Root -ChildPath $CampaignSlug
    $Prefix=('{0:D2}-{1}' -f [int]$R.sequence,[string]$R.slug)
    $Hits=@(
        Get-ChildItem -LiteralPath $Dir -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.BaseName -eq $Prefix -and $Allowed -contains $_.Extension.ToLowerInvariant()
        }
    )

    if($Hits.Count-gt1){throw ('Multiple source artifacts found for '+$R.title)}
    if($Hits.Count-eq1){
        $R.source_status='PRESENT'
        $R.source_path=$Hits[0].FullName.Substring($Repo.Length+1)
        $R.source_sha256=(Get-FileHash -LiteralPath $Hits[0].FullName -Algorithm SHA256).Hash
    }else{
        $R.source_status='MISSING'
        $R.source_path=$null
        $R.source_sha256=$null
    }
}

Set-Content -LiteralPath $IndexPath -Value (ConvertTo-Json -InputObject $Index -Depth 20) -Encoding UTF8
$Present=@($Index|Where-Object{$_.source_status-eq'PRESENT'}).Count
$Missing=@($Index|Where-Object{$_.source_status-ne'PRESENT'}).Count
Write-Host ('[OK] Campaign sources present: '+$Present)
Write-Host ('[INFO] Campaign sources missing: '+$Missing)
if($Missing-eq0){Write-Host '[OK] ALL 19 CAMPAIGN SOURCE ARTIFACTS PRESENT'}
