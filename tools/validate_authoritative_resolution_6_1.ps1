param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$R=J (Join-Path $Repo 'reports\authoritative-resolution-preflight-6.1.json')
if($R.status-ne'PASS-AUTHORITATIVE-RESOLUTION-PREFLIGHT'){throw '6.1 report status invalid.'}
$U=@(J (Join-Path $Repo 'input\authoritative-upgrade-resolution-input-6.1.json'))
$L=@(J (Join-Path $Repo 'input\authoritative-legacy-resolution-input-6.1.json'))
if($U.Count-ne116){throw ('Expected 116 upgrade rows; found '+$U.Count)}
if($L.Count-ne128){throw ('Expected 128 legacy rows; found '+$L.Count)}
$Allowed=@('ALREADY-CURRENT','CONFIRMED-NUMERIC-CORRECTION','CONFIRMED-STRUCTURAL-CORRECTION','TEXT-SENSITIVE-SOURCE-GATED','NEEDS-FURTHER-VERIFICATION','OUTSIDE-2025.01-FINAL','NEEDS-DIRECT-OFFICIAL-COMPARISON')
foreach($Row in @($U)+@($L)){
 if($Allowed -notcontains [string]$Row.classification){throw ('Invalid classification: '+$Row.classification)}
 if([bool]$Row.production_write_authorized -and @('CONFIRMED-NUMERIC-CORRECTION','CONFIRMED-STRUCTURAL-CORRECTION') -notcontains [string]$Row.classification){
   throw ('Unauthorized write classification: '+$Row.audit_id)
 }
}
Write-Host '[OK] Milestone 6.1 resolution contract validator PASS'
Write-Host '[OK] 116 upgrade rows + 128 legacy rows validated'
