param(
 [Parameter(Mandatory=$true)][string]$RepoPath,
 [Parameter(Mandatory=$true)][string]$InputPath,
 [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Input=(Resolve-Path -LiteralPath $InputPath).Path
function Fail([string]$M){throw $M}
function ReadJson([string]$P){try{return (Get-Content -LiteralPath $P -Raw|ConvertFrom-Json)}catch{Fail ('Invalid JSON: '+$P)}}
$R43=ReadJson (Join-Path $Repo 'reports\campaign-objective-construction-4.3.json')
$R44=ReadJson (Join-Path $Repo 'reports\campaign-objective-source-baseline-4.4.json')
$R47=ReadJson (Join-Path $Repo 'reports\campaign-objective-payload-contract-4.7.json')
$Doc=ReadJson $Input
$Rows=@($Doc.records)
if($Rows.Count -ne 19){Fail 'Expected exactly 19 records.'}
$Expected=@($R43.construction.skeletons)
if((@($Rows.stable_id|Sort-Object)-join '|') -ne (@($Expected.stable_id|Sort-Object)-join '|')){Fail 'Stable-ID set mismatch.'}
if($R44.baseline.cutoff_date -ne '2025-01-21'){Fail 'Official-final cutoff mismatch.'}
$Output=@()
foreach($Row in $Rows){
 $Match=@($Expected|Where-Object{$_.stable_id -eq $Row.stable_id})
 if($Match.Count -ne 1){Fail ('Identity mismatch: '+$Row.stable_id)}
 if($Row.authorized_text_confirmed -ne $true){Fail ($Row.stable_id+' is not authorized-text confirmed.')}
 foreach($F in @('title','category','points','setup','special-rule','end-of-round','end-of-game')){
  if($null -eq $Row.PSObject.Properties[$F] -or $null -eq $Row.$F){Fail ($Row.stable_id+' missing required field '+$F)}
 }
 $Record=[ordered]@{
  category=$Row.category
  'end-of-game'=$Row.'end-of-game'
  'end-of-round'=$Row.'end-of-round'
 }
 if($null -ne $Row.PSObject.Properties['errata'] -and $null -ne $Row.errata){$Record.errata=$Row.errata}
 if($null -ne $Row.PSObject.Properties['image'] -and $null -ne $Row.image){$Record.image=$Row.image}
 $Record.points=$Row.points
 $Record.setup=$Row.setup
 $Record.'special-rule'=$Row.'special-rule'
 $Record.title=$Row.title
 $Output+=,[pscustomobject]$Record
}
$Parent=Split-Path -Parent $OutputPath
if(-not [string]::IsNullOrWhiteSpace($Parent)){New-Item -ItemType Directory -Path $Parent -Force|Out-Null}
Set-Content -LiteralPath $OutputPath -Value (ConvertTo-Json -InputObject @($Output) -Depth 100) -Encoding UTF8
$RoundTrip=@(Get-Content -LiteralPath $OutputPath -Raw|ConvertFrom-Json)
if($RoundTrip.Count -ne 19){Fail 'Canonical output round-trip did not contain 19 records.'}
Write-Host '[OK] Canonical campaign objective payload written'
Write-Host '[OK] Records: 19'
Write-Host '[OK] Production schema only; milestone metadata stripped from card records'
Write-Host '[OK] Output is still a staging payload, not an installed production file'
