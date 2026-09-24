param(
 [Parameter(Mandatory=$true)][string]$RepoPath,
 [Parameter(Mandatory=$true)][string]$CanonicalPayloadPath,
 [switch]$Commit
)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Payload=(Resolve-Path -LiteralPath $CanonicalPayloadPath).Path
function Fail([string]$M){throw $M}
function Rows([string]$P){try{return @(Get-Content -LiteralPath $P -Raw|ConvertFrom-Json)}catch{Fail ('Invalid JSON: '+$P)}}
$Objective=Join-Path $Repo 'data\objective-card.json'
$Base=@(Rows $Objective)
if($Base.Count -ne 36){Fail ('Protected baseline must contain 36 records; found '+$Base.Count+'.')}
$Campaign=@(Rows $Payload)
if($Campaign.Count -ne 19){Fail ('Canonical payload must contain 19 records; found '+$Campaign.Count+'.')}
foreach($R in $Campaign){
 foreach($F in @('category','end-of-game','end-of-round','points','setup','special-rule','title')){
  if($null -eq $R.PSObject.Properties[$F] -or $null -eq $R.$F){Fail ('Canonical payload missing required field '+$F)}
 }
}
$Merged=@($Base)+@($Campaign)
if($Merged.Count -ne 55){Fail 'Merged payload must contain exactly 55 records.'}
if(-not $Commit){
 Write-Host '[OK] Production transaction PREVIEW PASS'
 Write-Host '[OK] Baseline: 36 / campaign: 19 / final: 55'
 Write-Host '[OK] No production write performed; rerun with -Commit only after final approval'
 exit 0
}
$Stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup=Join-Path $Repo ('.campaign_objective_install_backup_'+$Stamp)
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$BackupFile=Join-Path $Backup 'objective-card.json'
Copy-Item -LiteralPath $Objective -Destination $BackupFile -Force
$Temp=Join-Path (Split-Path -Parent $Objective) ('objective-card.install-'+$Stamp+'.tmp')
try{
 Set-Content -LiteralPath $Temp -Value (ConvertTo-Json -InputObject @($Merged) -Depth 100) -Encoding UTF8
 $Check=@(Rows $Temp)
 if($Check.Count -ne 55){Fail 'Temporary install file failed 55-record reread.'}
 Move-Item -LiteralPath $Temp -Destination $Objective -Force
 $Final=@(Rows $Objective)
 if($Final.Count -ne 55){Fail 'Installed production file failed 55-record reread.'}
 Write-Host '[OK] Campaign objective production transaction COMMITTED'
 Write-Host '[OK] Final production objective count: 55'
 Write-Host ('[OK] Rollback backup: '+$Backup)
}catch{
 if(Test-Path -LiteralPath $Temp){Remove-Item -LiteralPath $Temp -Force}
 Copy-Item -LiteralPath $BackupFile -Destination $Objective -Force
 throw
}
