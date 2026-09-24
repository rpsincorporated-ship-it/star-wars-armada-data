param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-Records([string]$P){
    $X=Get-Content -LiteralPath $P -Raw|ConvertFrom-Json
    if($X -is [System.Array]){foreach($I in $X){Write-Output $I}}else{Write-Output $X}
}
function Read-Object([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$U=@(Read-Records (Join-Path $Repo 'input\authoritative-upgrade-resolution-input-6.1.json'))
$L=@(Read-Records (Join-Path $Repo 'input\authoritative-legacy-resolution-input-6.1.json'))
if($U.Count-ne116){throw ('Upgrade queue invalid: '+$U.Count)}
if($L.Count-ne128){throw ('Legacy queue invalid: '+$L.Count)}
$A=Read-Object (Join-Path $Repo 'reports\authoritative-evidence-resolution-6.2.json')
$B=Read-Object (Join-Path $Repo 'reports\authoritative-evidence-ingestion-6.3.json')
$C=Read-Object (Join-Path $Repo 'reports\safe-correction-transaction-plan-6.4.json')
if($A.status-ne'PASS-AUTHORITATIVE-EVIDENCE-PASS-A'){throw '6.2 invalid.'}
if($B.status-notin@('PASS-EVIDENCE-INGESTION-READY','PASS-EVIDENCE-INGESTION')){throw '6.3 invalid.'}
if($C.status-ne'PASS-SAFE-CORRECTION-STAGING'){throw '6.4 invalid.'}
if([int]$C.production_writes_performed-ne0){throw '6.4 must not mutate production.'}
Write-Host '[OK] Combined 6.2-6.4 v4 verifier PASS'
Write-Host '[OK] Queue records: 116 upgrades / 128 legacy'
Write-Host ('[OK] Evidence rows: '+$B.evidence_rows)
Write-Host ('[OK] Staged corrections: '+$C.confirmed_corrections)
