param(
  [Parameter(Mandatory=$true)][string]$RepoPath
)
$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path -LiteralPath $RepoPath).Path

function Header([string]$Text){
  Write-Host ''
  Write-Host ('='*60)
  Write-Host ('=> ' + $Text)
  Write-Host ('='*60)
}
function Assert([bool]$Condition,[string]$Message){ if(-not $Condition){ throw $Message } }
function Read-JsonRecords([string]$Path){
  $raw = Get-Content -LiteralPath $Path -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw ('Empty JSON file: ' + $Path) }
  try { $parsed = $raw | ConvertFrom-Json } catch { throw ('Invalid JSON in ' + $Path + ': ' + $_.Exception.Message) }
  # IMPORTANT: Windows PowerShell 5.1 unwraps one-element JSON arrays.
  # Callers MUST use @(Read-JsonRecords ...) to normalize scalar/array output.
  Write-Output $parsed
}

Header 'Milestone 1.2a preflight'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'data')) 'Missing data folder.'
$SqDir = Join-Path $Repo 'data\squadron-card\galactic-republic'
Assert (Test-Path -LiteralPath $SqDir) 'Galactic Republic squadron folder is missing.'
$MetaPath = Join-Path $Repo 'metadata\products\swm36.json'
Assert (Test-Path -LiteralPath $MetaPath) 'SWM36 metadata is missing.'

$Expected = @{
 'arc-170-squadron.json' = @('ARC-170 Squadron',15,2,7)
 'odd-ball.json' = @('Odd Ball',20,2,7)
 'btl-b-y-wing-squadron.json' = @('BTL-B Y-wing Squadron',10,3,6)
 'anakin-skywalker-btl-b-y-wing.json' = @('Anakin Skywalker',18,3,6)
 'delta-7-aethersprite-squadron.json' = @('Delta-7 Aethersprite Squadron',17,4,4)
 'ahsoka-tano.json' = @('Ahsoka Tano',23,4,4)
 'kit-fisto.json' = @('Kit Fisto',24,4,4)
 'luminara-unduli.json' = @('Luminara Unduli',23,4,4)
 'plo-koon.json' = @('Plo Koon',24,4,4)
 'kickback.json' = @('Kickback',16,3,5)
}

foreach($file in $Expected.Keys){
  Assert (Test-Path -LiteralPath (Join-Path $SqDir $file)) ('Installed Milestone 1.2 file missing: ' + $file)
}
$V19 = Join-Path $SqDir 'v-19-torrent-squadron.json'
Assert (Test-Path -LiteralPath $V19) 'Milestone 1.1 V-19 Torrent Squadron is missing.'
Write-Host '[OK] Installed Milestone 1.2 payload detected'

Header 'Validate installed squadron records with PowerShell 5.1 normalization'
foreach($file in $Expected.Keys | Sort-Object){
  $path = Join-Path $SqDir $file
  $rows = @(Read-JsonRecords $path)
  Assert ($rows.Count -eq 1) ($file + ' must contain exactly one top-level squadron record; found ' + $rows.Count + '.')
  $r = $rows[0]
  $e = $Expected[$file]
  Assert ($r.name -eq $e[0]) ($file + ' name mismatch.')
  Assert ([int]$r.points -eq [int]$e[1]) ($file + ' points mismatch.')
  Assert ([int]$r.speed -eq [int]$e[2]) ($file + ' speed mismatch.')
  Assert ([int]$r.hull -eq [int]$e[3]) ($file + ' hull mismatch.')
  Assert ($r.faction -eq 'Galactic Republic') ($file + ' faction mismatch.')
  Assert ($r.source.'product-code' -eq 'SWM36') ($file + ' source product-code mismatch.')
  Write-Host ('[OK] ' + $r.name + ' (' + $r.points + ' pts)')
}

Header 'Validate V-19 SWM36 reprint and product metadata'
$v19Rows = @(Read-JsonRecords $V19)
Assert ($v19Rows.Count -eq 1) ('V-19 baseline file must contain exactly one record; found ' + $v19Rows.Count + '.')
$v19 = $v19Rows[0]
Assert ($v19.name -eq 'V-19 Torrent Squadron' -and [int]$v19.points -eq 12) 'V-19 Torrent Squadron baseline/reprint check failed.'
Write-Host '[OK] V-19 Torrent Squadron reprint represented by existing SWM34 record (12 pts)'

$meta = Get-Content -LiteralPath $MetaPath -Raw | ConvertFrom-Json
Assert ($meta.code -eq 'SWM36') 'SWM36 metadata code mismatch.'
Assert ([int]$meta.contents.'squadron-cards' -eq 11) 'SWM36 metadata squadron-card count mismatch.'
Assert ([int]$meta.'database-records-added'.'new-squadron-designs' -eq 10) 'SWM36 metadata new-design count mismatch.'
Write-Host '[OK] SWM36 metadata: 11 physical cards / 10 new designs / 1 verified reprint'

Header 'Cross-record uniqueness check'
$Names = @{}
Get-ChildItem -LiteralPath $SqDir -Filter '*.json' -File | ForEach-Object {
  $records = @(Read-JsonRecords $_.FullName)
  foreach($r in $records){
    if($null -ne $r.name){
      $key = [string]$r.name
      if(-not $Names.ContainsKey($key)){ $Names[$key] = 0 }
      $Names[$key]++
    }
  }
}
foreach($e in $Expected.GetEnumerator()){
  $name = [string]$e.Value[0]
  Assert ($Names[$name] -eq 1) ($name + ' expected exactly once across Republic squadron data; found ' + $Names[$name] + '.')
}
Assert ($Names['V-19 Torrent Squadron'] -eq 1) ('V-19 Torrent Squadron must remain one database design; found ' + $Names['V-19 Torrent Squadron'] + '.')
Write-Host '[OK] All Milestone 1.2 card designs are unique'

Header 'Install reusable verifier'
$ToolsDir = Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$VerifierPath = Join-Path $ToolsDir 'verify_milestone_1_2.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $VerifierPath -Force
Write-Host ('[OK] Installed ' + $VerifierPath)

Write-Host ''
Write-Host '[OK] Milestone 1.2a complete.'
Write-Host '[OK] Milestone 1.2 Republic Fighter Squadrons data is installed and verified.'
Write-Host '[OK] No squadron data files were rewritten by this hotfix.'
