param(
 [Parameter(Mandatory=$true)][string]$RepoPath,
 [Parameter(Mandatory=$true)][string]$InputPath
)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Input=(Resolve-Path -LiteralPath $InputPath).Path
function Fail([string]$Message){throw $Message}
function ReadJson([string]$Path){
 $Raw=Get-Content -LiteralPath $Path -Raw
 if([string]::IsNullOrWhiteSpace($Raw)){Fail ('Empty JSON: '+$Path)}
 try{return ($Raw|ConvertFrom-Json)}catch{Fail ('Invalid JSON: '+$Path+' :: '+$_.Exception.Message)}
}
$R43=ReadJson (Join-Path $Repo 'reports\campaign-objective-construction-4.3.json')
$R44=ReadJson (Join-Path $Repo 'reports\campaign-objective-source-baseline-4.4.json')
$Doc=ReadJson $Input
$Rows=@($Doc.records)
if($Rows.Count -ne 19){Fail ('Expected 19 input records; found '+$Rows.Count+'.')}
$Expected=@($R43.construction.skeletons)
$ExpectedIds=@($Expected.stable_id|Sort-Object)
$ActualIds=@($Rows.stable_id|Sort-Object)
if(($ExpectedIds -join '|') -ne ($ActualIds -join '|')){Fail 'Stable-ID set does not match 4.3 manifest.'}
foreach($Row in $Rows){
 $Match=@($Expected|Where-Object{$_.stable_id -eq $Row.stable_id})
 if($Match.Count -ne 1){Fail ('Identity match failed: '+$Row.stable_id)}
 if($Row.title -ne $Match[0].title){Fail ($Row.stable_id+' title mismatch.')}
 if($Row.product_sku -ne $Match[0].product_sku){Fail ($Row.stable_id+' SKU mismatch.')}
 if($Row.authorized_text_confirmed -ne $true){Fail ($Row.stable_id+' authorized_text_confirmed must be true.')}
}
if(@($Rows|Where-Object{$_.product_sku -eq 'SWM25'}).Count -ne 8){Fail 'Expected 8 SWM25 records.'}
if(@($Rows|Where-Object{$_.product_sku -eq 'SWM31'}).Count -ne 11){Fail 'Expected 11 SWM31 records.'}
if($R44.baseline.cutoff_date -ne '2025-01-21'){Fail 'Official-final cutoff mismatch.'}
if($R44.baseline.post_cutoff_rulings_allowed -ne $false){Fail 'Post-cutoff ruling gate failed.'}
Write-Host '[OK] Campaign objective payload validator PASS'
Write-Host '[OK] 19 / 19 identities aligned'
Write-Host '[OK] SWM25=8 / SWM31=11'
Write-Host '[OK] Authorized-text confirmations: 19 / 19'
Write-Host '[OK] Official-final cutoff: 2025-01-21'
Write-Host '[OK] Payload is eligible for final production-write preflight'
