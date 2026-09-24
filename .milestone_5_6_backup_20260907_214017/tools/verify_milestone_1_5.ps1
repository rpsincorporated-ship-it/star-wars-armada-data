param(
  [Parameter(Mandatory=$true)][string]$RepoPath
)
$ErrorActionPreference = 'Stop'

$Repo = (Resolve-Path -LiteralPath $RepoPath).Path
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Header([string]$Text){
  Write-Host ''
  Write-Host ('=' * 60)
  Write-Host ('=> ' + $Text)
  Write-Host ('=' * 60)
}
function Assert([bool]$Condition,[string]$Message){
  if(-not $Condition){ throw $Message }
}
function Read-JsonAny([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){ throw ('Missing JSON file: ' + $Path) }
  $raw = Get-Content -LiteralPath $Path -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw ('Empty JSON file: ' + $Path) }
  try { return ($raw | ConvertFrom-Json) }
  catch { throw ('Invalid JSON in ' + $Path + ': ' + $_.Exception.Message) }
}
function Read-JsonRecords([string]$Path){
  $parsed = Read-JsonAny $Path
  return @($parsed)
}

Header 'Milestone 1.5 preflight'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'data')) 'Missing data folder.'
$RequiredMeta = @('swm34.json','swm36.json','swm40.json','swm41.json')
foreach($file in $RequiredMeta){
  $p = Join-Path $Repo ('metadata\products\' + $file)
  Assert (Test-Path -LiteralPath $p) ('Missing prerequisite product metadata: ' + $file)
}
Assert (Test-Path -LiteralPath (Join-Path $Repo 'tools\verify_milestone_1_4.ps1')) 'Milestone 1.4 verifier is missing.'
Write-Host '[OK] Milestones 1.1 through 1.4 baseline detected'

Header 'Backup existing audit outputs'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup = Join-Path $Repo ('.milestone_1_5_backup_' + $Stamp)
New-Item -ItemType Directory -Path $Backup -Force | Out-Null
$ReportDir = Join-Path $Repo 'reports'
$AuditMetaDir = Join-Path $Repo 'metadata\audits'
$ToolsDir = Join-Path $Repo 'tools'
$Targets = @(
  (Join-Path $ReportDir 'republic-completeness-1.5.json'),
  (Join-Path $ReportDir 'republic-completeness-1.5.md'),
  (Join-Path $AuditMetaDir 'republic-product-origin-1.5.json'),
  (Join-Path $ToolsDir 'verify_milestone_1_5.ps1')
)
foreach($p in $Targets){
  if(Test-Path -LiteralPath $p){
    Copy-Item -LiteralPath $p -Destination (Join-Path $Backup ([IO.Path]::GetFileName($p))) -Force
  }
}
Write-Host ('[OK] Backup created: ' + $Backup)

Header 'Install audit manifest'
New-Item -ItemType Directory -Path $AuditMetaDir -Force | Out-Null
$PackageManifest = Join-Path $ScriptRoot 'patch\metadata\audits\republic-product-origin-1.5.json'
Assert (Test-Path -LiteralPath $PackageManifest) 'Packaged audit manifest is missing.'
$InstalledManifest = Join-Path $AuditMetaDir 'republic-product-origin-1.5.json'
Copy-Item -LiteralPath $PackageManifest -Destination $InstalledManifest -Force
$Manifest = Read-JsonAny $InstalledManifest
Write-Host ('[OK] Installed audit manifest with ' + $Manifest.records.Count + ' expected unique design records')

Header 'Audit Republic product-origin records'
$Failures = New-Object System.Collections.ArrayList
$Warnings = New-Object System.Collections.ArrayList
$Validated = 0
$ByKind = @{ ship=0; squadron=0; upgrade=0 }

foreach($expected in @($Manifest.records)){
  $target = Join-Path $Repo ([string]$expected.repoPath)
  if(-not (Test-Path -LiteralPath $target)){
    [void]$Failures.Add(('Missing file for ' + $expected.name + ': ' + $expected.repoPath))
    Write-Host ('[FAIL] Missing file: ' + $expected.repoPath)
    continue
  }

  try { $rows = @(Read-JsonRecords $target) }
  catch {
    [void]$Failures.Add($_.Exception.Message)
    Write-Host ('[FAIL] ' + $_.Exception.Message)
    continue
  }

  $matches = @($rows | Where-Object { $_.name -eq $expected.name })
  if($matches.Count -ne 1){
    [void]$Failures.Add(($expected.name + ' expected exactly once in ' + $expected.repoPath + '; found ' + $matches.Count))
    Write-Host ('[FAIL] ' + $expected.name + ': expected once, found ' + $matches.Count)
    continue
  }

  $card = $matches[0]
  if([int]$card.points -ne [int]$expected.points){
    [void]$Failures.Add(($expected.name + ' points mismatch: expected ' + $expected.points + ', found ' + $card.points))
    Write-Host ('[FAIL] ' + $expected.name + ': points mismatch')
    continue
  }

  if($null -eq $card.source -or [string]$card.source.'product-code' -ne [string]$expected.productCode){
    [void]$Failures.Add(($expected.name + ' source product-code mismatch: expected ' + $expected.productCode))
    Write-Host ('[FAIL] ' + $expected.name + ': source product-code mismatch')
    continue
  }

  if([string]::IsNullOrWhiteSpace([string]$card.source.'rules-baseline')){
    [void]$Warnings.Add(($expected.name + ' has no source.rules-baseline field'))
  }

  $Validated++
  $ByKind[[string]$expected.kind] = [int]$ByKind[[string]$expected.kind] + 1
  Write-Host ('[OK] ' + $expected.name + ' (' + $expected.points + ' pts, ' + $expected.productCode + ')')
}

Header 'Validate product metadata and reprint policy'
foreach($code in @('SWM34','SWM36','SWM40','SWM41')){
  $metaPath = Join-Path $Repo ('metadata\products\' + $code.ToLower() + '.json')
  $meta = Read-JsonAny $metaPath
  if([string]$meta.code -ne $code){
    [void]$Failures.Add(($code + ' metadata code mismatch'))
    Write-Host ('[FAIL] ' + $code + ' metadata code mismatch')
  } else {
    Write-Host ('[OK] ' + $code + ' metadata')
  }
}

$V19Path = Join-Path $Repo 'data\squadron-card\galactic-republic\v-19-torrent-squadron.json'
$V19 = @(Read-JsonRecords $V19Path | Where-Object { $_.name -eq 'V-19 Torrent Squadron' })
if($V19.Count -ne 1){
  [void]$Failures.Add(('V-19 Torrent Squadron reprint policy failed; expected one design record, found ' + $V19.Count))
  Write-Host ('[FAIL] V-19 Torrent Squadron reprint policy: found ' + $V19.Count)
} else {
  Write-Host '[OK] V-19 Torrent Squadron represented once; SWM36 remains a metadata reprint'
}

Header 'Validate final-point provenance'
foreach($check in @($Manifest.finalPointHistoryChecks)){
  $rows = @(Read-JsonRecords (Join-Path $Repo ([string]$check.repoPath)))
  $matches = @($rows | Where-Object { $_.name -eq $check.name })
  if($matches.Count -ne 1){
    [void]$Failures.Add(($check.name + ' final-point provenance record missing or duplicated'))
    Write-Host ('[FAIL] ' + $check.name + ' provenance record')
    continue
  }
  $card = $matches[0]
  if($null -eq $card.'points-history' -or
     [int]$card.'points-history'.printed -ne [int]$check.printed -or
     [int]$card.'points-history'.current -ne [int]$check.current){
    [void]$Failures.Add(($check.name + ' points-history mismatch'))
    Write-Host ('[FAIL] ' + $check.name + ' points-history mismatch')
  } else {
    Write-Host ('[OK] ' + $check.name + ': printed ' + $check.printed + ' / final ' + $check.current)
  }
}

Header 'Scan for duplicate names in Republic ship and squadron folders'
$Seen = @{}
foreach($folder in @(
  (Join-Path $Repo 'data\ship-card\galactic-republic'),
  (Join-Path $Repo 'data\squadron-card\galactic-republic')
)){
  if(Test-Path -LiteralPath $folder){
    Get-ChildItem -LiteralPath $folder -Filter '*.json' -File | ForEach-Object {
      try { $rows = @(Read-JsonRecords $_.FullName) }
      catch {
        [void]$Failures.Add($_.Exception.Message)
        return
      }
      foreach($row in $rows){
        $key = [string]$row.name
        if([string]::IsNullOrWhiteSpace($key)){ continue }
        if($Seen.ContainsKey($key)){
          [void]$Failures.Add(('Duplicate Republic ship/squadron name across files: ' + $key))
        } else {
          $Seen[$key] = $_.FullName
        }
      }
    }
  }
}
if(@($Failures | Where-Object { $_ -like 'Duplicate Republic ship/squadron name*' }).Count -eq 0){
  Write-Host '[OK] No duplicate Republic ship/squadron names detected'
}

Header 'Generate Republic completeness report'
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$JsonReport = Join-Path $ReportDir 'republic-completeness-1.5.json'
$MdReport = Join-Path $ReportDir 'republic-completeness-1.5.md'

$Status = if($Failures.Count -eq 0){ 'PASS' } else { 'FAIL' }
$Report = [ordered]@{
  milestone = '1.5'
  title = 'Galactic Republic Product-Origin Completeness Audit'
  status = $Status
  generatedAt = (Get-Date).ToString('o')
  rulesBaseline = [string]$Manifest.rulesBaseline
  scope = $Manifest.scope
  counts = [ordered]@{
    expectedDesignRecords = [int]$Manifest.expectedCounts.totalDesignRecords
    validatedDesignRecords = $Validated
    ships = [int]$ByKind.ship
    squadronDesigns = [int]$ByKind.squadron
    upgradeDesigns = [int]$ByKind.upgrade
    failures = $Failures.Count
    warnings = $Warnings.Count
  }
  productMetadata = @('SWM34','SWM36','SWM40','SWM41')
  reprintPolicy = $Manifest.reprints
  failures = @($Failures)
  warnings = @($Warnings)
  note = 'Neutral upgrades from older non-Republic products are intentionally outside this product-origin audit and will be handled by a later legality/compatibility milestone.'
}
Set-Content -LiteralPath $JsonReport -Value (ConvertTo-Json -InputObject $Report -Depth 20) -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Galactic Republic Completeness Report — Milestone 1.5')
$lines.Add('')
$lines.Add('**Status:** ' + $Status)
$lines.Add('')
$lines.Add('**Rules baseline:** ' + [string]$Manifest.rulesBaseline)
$lines.Add('')
$lines.Add('## Scope')
$lines.Add('')
$lines.Add('This audit covers unique database designs originating in SWM34, SWM36, SWM40, and SWM41.')
$lines.Add('Neutral upgrades from older non-Republic products that are merely Republic-legal are intentionally excluded from this product-origin audit.')
$lines.Add('')
$lines.Add('## Counts')
$lines.Add('')
$lines.Add('- Expected unique design records: ' + $Manifest.expectedCounts.totalDesignRecords)
$lines.Add('- Validated unique design records: ' + $Validated)
$lines.Add('- Ships: ' + $ByKind.ship)
$lines.Add('- Squadron designs: ' + $ByKind.squadron)
$lines.Add('- Upgrade designs: ' + $ByKind.upgrade)
$lines.Add('- Failures: ' + $Failures.Count)
$lines.Add('- Warnings: ' + $Warnings.Count)
$lines.Add('')
$lines.Add('## Reprint handling')
$lines.Add('')
$lines.Add('- V-19 Torrent Squadron remains one database design record; its SWM36 appearance is represented as reprint/product metadata.')
$lines.Add('')
$lines.Add('## Final-point provenance checks')
$lines.Add('')
$lines.Add('- SPHA-T: printed 3 → final 7')
$lines.Add('- Resolute: printed 6 → final 4')
$lines.Add('- Mercy Mission: printed 0 → final 5')
$lines.Add('')
if($Failures.Count -gt 0){
  $lines.Add('## Failures')
  $lines.Add('')
  foreach($f in $Failures){ $lines.Add('- ' + $f) }
  $lines.Add('')
}
if($Warnings.Count -gt 0){
  $lines.Add('## Warnings')
  $lines.Add('')
  foreach($w in $Warnings){ $lines.Add('- ' + $w) }
  $lines.Add('')
}
$lines.Add('## Result')
$lines.Add('')
if($Status -eq 'PASS'){
  $lines.Add('Republic product-origin content installed by Milestones 1.1–1.4 is complete and internally consistent for this audit scope.')
} else {
  $lines.Add('Republic product-origin content is not yet complete. Resolve the failures above and rerun Milestone 1.5.')
}
Set-Content -LiteralPath $MdReport -Value $lines -Encoding UTF8
Write-Host ('[OK] JSON report: ' + $JsonReport)
Write-Host ('[OK] Markdown report: ' + $MdReport)

Header 'Install reusable verifier snapshot'
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$Verifier = Join-Path $ToolsDir 'verify_milestone_1_5.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed ' + $Verifier)

if($Failures.Count -gt 0){
  throw ('Milestone 1.5 audit failed with ' + $Failures.Count + ' failure(s). See reports\republic-completeness-1.5.md')
}

Write-Host ''
Write-Host '[OK] Milestone 1.5 complete.'
Write-Host ('[OK] Republic product-origin audit passed: ' + $Validated + ' / ' + $Manifest.expectedCounts.totalDesignRecords + ' unique design records verified.')
Write-Host ('[OK] Ships: ' + $ByKind.ship + ' | Squadron designs: ' + $ByKind.squadron + ' | Upgrade designs: ' + $ByKind.upgrade)
Write-Host '[OK] Republic product-origin dataset is ready for the final Republic normalization/completeness gate.'
Write-Host ('[OK] Backup: ' + $Backup)
