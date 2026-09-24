param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$Root=Join-Path $Repo 'input\campaign-authorized\milestone-24-authoritative-full-card-drop'
if(-not(Test-Path -LiteralPath $Root)){throw 'Milestone 24 source-drop root is missing.'}
$Slots=@(Get-ChildItem -LiteralPath $Root -Directory|Sort-Object Name)
if($Slots.Count-ne8){throw ('Expected 8 source slots; found '+$Slots.Count)}
$Ext=@('.png','.jpg','.jpeg','.pdf')
$Ready=0;$Missing=0
foreach($S in $Slots){
    $Artifacts=@(Get-ChildItem -LiteralPath $S.FullName -File|Where-Object{$Ext-contains$_.Extension.ToLowerInvariant()})
    if($Artifacts.Count-gt0){
        $Ready++
        Write-Host ('[OK] Source present: '+$S.Name)
        foreach($A in $Artifacts){
            $H=(Get-FileHash -LiteralPath $A.FullName -Algorithm SHA256).Hash
            Write-Host ('     '+$A.Name+'  SHA256='+$H)
        }
    }else{
        $Missing++
        Write-Host ('[INFO] Source missing: '+$S.Name)
    }
}
Write-Host ('[OK] Authoritative full-card sources present: '+$Ready)
Write-Host ('[INFO] Authoritative full-card sources missing: '+$Missing)
