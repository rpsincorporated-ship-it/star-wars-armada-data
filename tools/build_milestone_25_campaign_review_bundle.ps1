param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path

$Scanner=Join-Path $Repo 'tools\scan_milestone_25_final_campaign_sources.ps1'
& $Scanner -RepoPath $Repo

$ScanPath=Join-Path $Repo 'reports\milestone-25-source-scan.json'
$Scan=Get-Content -LiteralPath $ScanPath -Raw|ConvertFrom-Json

$Root=Join-Path $Repo 'input\campaign-authorized\milestone-25-final-source-capture'
$Review=Join-Path $Repo 'milestone-25-final-campaign-source-review'
if(Test-Path -LiteralPath $Review){Remove-Item -LiteralPath $Review -Recurse -Force}
New-Item -ItemType Directory -Path $Review -Force|Out-Null

Copy-Item -LiteralPath $ScanPath -Destination (Join-Path $Review 'source-scan.json') -Force
Copy-Item -LiteralPath (Join-Path $Repo 'data\objective-card.json') -Destination (Join-Path $Review 'current-objective-card.json') -Force

foreach($R in $Scan.records){
    if(-not$R.ready){continue}
    $Safe=([string]$R.title).ToLowerInvariant() -replace '[^a-z0-9]+','-'
    $Safe=$Safe.Trim('-')
    $Dest=Join-Path $Review ('{0:D2}-{1}-{2}' -f [int]$R.sequence,[string]$R.product_code.ToLowerInvariant(),$Safe)
    New-Item -ItemType Directory -Path $Dest -Force|Out-Null
    foreach($A in $R.artifacts){
        Copy-Item -LiteralPath ([string]$A.path) -Destination (Join-Path $Dest ([string]$A.name)) -Force
    }
}

$Zip=Join-Path $Repo 'armada-milestone-25-final-campaign-source-review.zip'
if(Test-Path -LiteralPath $Zip){Remove-Item -LiteralPath $Zip -Force}
Compress-Archive -Path (Join-Path $Review '*') -DestinationPath $Zip -CompressionLevel Optimal
$Hash=(Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash

Write-Host ('[OK] Review bundle: '+$Zip)
Write-Host ('[OK] Review bundle SHA256: '+$Hash)
Write-Host ('[INFO] Ready source slots: '+$Scan.ready)
Write-Host ('[INFO] Missing source slots: '+$Scan.missing)
