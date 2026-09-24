param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path

function Read-MilestoneJsonObject([string]$Path){
    Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
}

$Root=Join-Path $Repo 'input\campaign-authorized\milestone-25-final-source-capture'
if(-not(Test-Path -LiteralPath $Root)){throw 'Milestone 25 capture root is missing.'}

$Slots=@(Get-ChildItem -LiteralPath $Root -Directory|Sort-Object Name)
if($Slots.Count-ne8){throw ('Expected 8 capture slots; found '+$Slots.Count)}

$Allowed=@('.png','.jpg','.jpeg','.pdf','.webp')
$Rows=@()
foreach($S in $Slots){
    $Meta=Read-MilestoneJsonObject (Join-Path $S.FullName 'slot.json')
    $Files=@(Get-ChildItem -LiteralPath $S.FullName -File|Where-Object{$Allowed-contains$_.Extension.ToLowerInvariant()}|Sort-Object Name)
    $Artifacts=@()
    foreach($F in $Files){
        $Artifacts += [pscustomobject][ordered]@{
            name=$F.Name
            path=$F.FullName
            extension=$F.Extension.ToLowerInvariant()
            bytes=$F.Length
            sha256=(Get-FileHash -LiteralPath $F.FullName -Algorithm SHA256).Hash
        }
    }
    $Rows += [pscustomobject][ordered]@{
        sequence=[int]$Meta.sequence
        product_code=[string]$Meta.product_code
        title=[string]$Meta.title
        identity_key=[string]$Meta.identity_key
        artifact_count=$Artifacts.Count
        ready=($Artifacts.Count-gt0)
        artifacts=$Artifacts
    }
}

$Ready=@($Rows|Where-Object{$_.ready}).Count
$Missing=@($Rows|Where-Object{-not$_.ready}).Count

$Report=[ordered]@{
    scan_time_utc=(Get-Date).ToUniversalTime().ToString('o')
    slots=8
    ready=$Ready
    missing=$Missing
    records=$Rows
}

$Out=Join-Path $Repo 'reports\milestone-25-source-scan.json'
Set-Content -LiteralPath $Out -Value (ConvertTo-Json -InputObject $Report -Depth 100) -Encoding UTF8

foreach($R in $Rows){
    if($R.ready){
        Write-Host ('[OK] SOURCE PRESENT: {0:D2} {1} ({2} artifact(s))' -f $R.sequence,$R.title,$R.artifact_count)
        foreach($A in $R.artifacts){
            Write-Host ('     '+$A.name+' SHA256='+$A.sha256)
        }
    }else{
        Write-Host ('[INFO] SOURCE MISSING: {0:D2} {1}' -f $R.sequence,$R.title)
    }
}

Write-Host ('[OK] Source-ready slots: '+$Ready)
Write-Host ('[INFO] Source-missing slots: '+$Missing)
Write-Host ('[OK] Scan report: '+$Out)
