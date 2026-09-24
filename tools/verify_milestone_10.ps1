param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-10-final-status.json') -Raw|ConvertFrom-Json
if($S.status -ne 'PASS-MILESTONE-10-OFFICIAL-POINT-TRANSACTION-COMPLETE'){throw 'Milestone 10 invalid.'}
$Q=Get-ChildItem -LiteralPath (Join-Path $Repo 'data') -Recurse -File -Filter '*.json'
$Found=@()
foreach($F in $Q){
    $X=Get-Content -LiteralPath $F.FullName -Raw|ConvertFrom-Json
    if($X -is [System.Array]){$A=@($X)}else{$A=@($X)}
    foreach($R in @($A)){
        if($null -ne $R -and $R.name -eq 'Imperial I-class Star Destroyer'){$Found+=,$R}
    }
}
if($Found.Count -ne 1){throw ('Expected one Imperial I record; found '+$Found.Count)}
if([int]$Found[0].points -ne 110){throw ('Imperial I points invalid: '+$Found[0].points)}
$Zip=Join-Path $Repo ([string]$S.release_zip)
if(-not(Test-Path -LiteralPath $Zip)){throw 'Release ZIP missing.'}
if((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash -ne $S.release_zip_sha256){throw 'Release ZIP hash mismatch.'}
Write-Host '[OK] MILESTONE 10 FINAL VERIFIER PASS'
Write-Host '[OK] Imperial I-class Star Destroyer = 110'
Write-Host '[INFO] Remaining official point confirmations: 3'
