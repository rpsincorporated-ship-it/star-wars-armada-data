param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-VerifyRecords([string]$Relative){return @((Get-Content -LiteralPath (Join-Path $Repo $Relative) -Raw|ConvertFrom-Json))}
function Test-VerifyArray([object]$Actual,[object[]]$Expected){$A=@($Actual);if($A.Count -ne $Expected.Count){return $false};for($I=0;$I -lt $Expected.Count;$I++){if([string]$A[$I] -ne [string]$Expected[$I]){return $false}};return $true}
function Get-VerifyUpgrade([string]$Path,[string]$Name,[string]$Faction){$M=@(Read-VerifyRecords $Path|Where-Object{$_.name -eq $Name -and $_.faction -eq $Faction});if($M.Count -ne 1){throw ('Expected one '+$Faction+' / '+$Name)};return $M[0]}
$Ids=@{}
$U=@(
 @('data\upgrade-card\commander.json','General Draven','Rebel Alliance',20,'upgrade:commander:rebel-alliance:general-draven'),
 @('data\upgrade-card\officer.json','Governor Pryce','Galactic Empire',6,'upgrade:officer:galactic-empire:governor-pryce'),
 @('data\upgrade-card\commander.json','Anakin Skywalker','Galactic Republic',27,'upgrade:commander:galactic-republic:anakin-skywalker'),
 @('data\upgrade-card\officer.json','Asajj Ventress','Separatist Alliance',2,'upgrade:officer:separatist-alliance:asajj-ventress')
)
foreach($C in $U){$X=Get-VerifyUpgrade $C[0] $C[1] $C[2];if([int]$X.points -ne [int]$C[3] -or $X.'stable-id' -ne $C[4]){throw ($C[1]+' validation failed.')};$Ids[$C[4]]=$true}
$S=@(
 @('data\squadron-card\rebel-alliance\fenn-rau.json','Fenn Rau',24,'squadron:rebel-alliance:fenn-rau:mandalorian-gauntlet-fighter'),
 @('data\squadron-card\galactic-empire\vult-skerris.json','Vult Skerris',18,'squadron:galactic-empire:vult-skerris:tie-interceptor-squadron'),
 @('data\squadron-card\galactic-republic\matchstick.json','Matchstick',16,'squadron:galactic-republic:matchstick:btl-b-y-wing-squadron'),
 @('data\squadron-card\separatist-alliance\wat-tambor-squadron.json','Wat Tambor',18,'squadron:separatist-alliance:wat-tambor:belbullab-22-starfighter-squadron')
)
foreach($C in $S){$Rows=@(Read-VerifyRecords $C[0]);if($Rows.Count -ne 1){throw ($C[0]+' must contain one record.')};$X=$Rows[0];if($X.name -ne $C[1] -or [int]$X.points -ne [int]$C[2] -or $X.'stable-id' -ne $C[3]){throw ($C[1]+' validation failed.')};$Ids[$C[3]]=$true}
$Wat=(Read-VerifyRecords 'data\squadron-card\separatist-alliance\wat-tambor-squadron.json')[0]
if(-not(Test-VerifyArray $Wat.'squadron-attack' @(0,2,0))){throw 'Wat Tambor anti-squadron dice mismatch.'}
if($Ids.Count -ne 8){throw 'Expected 8 unique RRII stable IDs.'}
$Release=(Get-Content -LiteralPath (Join-Path $Repo 'metadata\releases\rapid-reinforcements-ii-2025.01-final.json') -Raw|ConvertFrom-Json)
if($Release.status -ne 'complete-supplement' -or [int]$Release.totals.records -ne 8 -or [int]$Release.totals.stable_ids -ne 8){throw 'RRII release manifest gate failed.'}
Write-Host '[OK] Milestone 3.4b verifier PASS'
Write-Host '[OK] RRII production data: 8 / 8 cards'
Write-Host '[OK] Wat Tambor anti-squadron dice: two blue / [0,2,0]'
Write-Host '[OK] 8 / 8 stable IDs unique'
Write-Host '[OK] Release manifest status: complete-supplement'
