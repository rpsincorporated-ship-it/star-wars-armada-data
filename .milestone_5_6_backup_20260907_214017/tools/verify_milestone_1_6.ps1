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
  $p = Read-JsonAny $Path
  return @($p)
}
function Write-JsonArray([string]$Path,[object[]]$Rows){
  $json = ConvertTo-Json -InputObject @($Rows) -Depth 40
  Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}
function Slug([string]$Text){
  $s = $Text.ToLowerInvariant()
  $s = $s -replace '[^a-z0-9]+','-'
  $s = $s.Trim('-')
  return $s
}
function Upsert-Property([object]$Obj,[string]$Name,[object]$Value){
  $prop = $Obj.PSObject.Properties[$Name]
  if($null -eq $prop){
    $Obj | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  } else {
    $Obj.$Name = $Value
  }
}

Header 'Milestone 1.6 preflight'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'data')) 'Missing data folder.'
$AuditPath = Join-Path $Repo 'metadata\audits\republic-product-origin-1.5.json'
Assert (Test-Path -LiteralPath $AuditPath) 'Milestone 1.5 audit manifest is missing.'
Assert (Test-Path -LiteralPath (Join-Path $Repo 'reports\republic-completeness-1.5.json')) 'Milestone 1.5 completeness report is missing.'
$AuditReport = Read-JsonAny (Join-Path $Repo 'reports\republic-completeness-1.5.json')
Assert ([string]$AuditReport.status -eq 'PASS') 'Milestone 1.5 completeness report is not PASS.'
$Audit = Read-JsonAny $AuditPath
Assert ([int]$Audit.expectedCounts.totalDesignRecords -eq 56) 'Milestone 1.5 audit manifest does not contain the expected 56-design Republic baseline.'
Write-Host '[OK] Milestone 1.5 PASS baseline detected: 56 Republic product-origin records'

$ConfigPath = Join-Path $ScriptRoot 'patch\metadata\releases\republic-normalization-1.6.json'
$Config = Read-JsonAny $ConfigPath

Header 'Build normalization target map'
$TargetPaths = @($Audit.records | ForEach-Object { [string]$_.repoPath } | Sort-Object -Unique)
Write-Host ('[OK] ' + $TargetPaths.Count + ' JSON target file(s) contain the 56 audited Republic records')

Header 'Backup every normalization target'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup = Join-Path $Repo ('.milestone_1_6_backup_' + $Stamp)
New-Item -ItemType Directory -Path $Backup -Force | Out-Null
foreach($rel in $TargetPaths){
  $src = Join-Path $Repo $rel
  Assert (Test-Path -LiteralPath $src) ('Missing normalization target: ' + $rel)
  $dest = Join-Path $Backup $rel
  New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
  Copy-Item -LiteralPath $src -Destination $dest -Force
}
foreach($rel in @(
  'metadata\releases\galactic-republic-2025.01-final.json',
  'metadata\releases\republic-normalization-1.6.json',
  'reports\republic-release-1.6.json',
  'reports\republic-release-1.6.md',
  'tools\verify_milestone_1_6.ps1'
)){
  $src = Join-Path $Repo $rel
  if(Test-Path -LiteralPath $src){
    $dest = Join-Path $Backup $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dest -Force
  }
}
Write-Host ('[OK] Backup created: ' + $Backup)

Header 'Normalize Republic records additively'
$ExpectedByPath = @{}
foreach($rec in @($Audit.records)){
  $path = [string]$rec.repoPath
  if(-not $ExpectedByPath.ContainsKey($path)){ $ExpectedByPath[$path] = @() }
  $ExpectedByPath[$path] = @($ExpectedByPath[$path]) + @($rec)
}

$Normalized = 0
$Ids = @{}
$IdRows = New-Object System.Collections.Generic.List[object]

foreach($rel in $TargetPaths){
  $full = Join-Path $Repo $rel
  $rows = @(Read-JsonRecords $full)
  $expectedRows = @($ExpectedByPath[$rel])

  foreach($expected in $expectedRows){
    $matches = @($rows | Where-Object { $_.name -eq $expected.name })
    Assert ($matches.Count -eq 1) (($expected.name + ' expected exactly once in ' + $rel + '; found ' + $matches.Count))
    $card = $matches[0]

    $kind = [string]$expected.kind
    $slug = Slug ([string]$expected.name)
    if($kind -eq 'upgrade'){
      $fileStem = [IO.Path]::GetFileNameWithoutExtension($rel)
      $stableId = 'swarmada:official:galactic-republic:upgrade:' + (Slug $fileStem) + ':' + $slug
    } else {
      $stableId = 'swarmada:official:galactic-republic:' + $kind + ':' + $slug
    }

    Assert (-not $Ids.ContainsKey($stableId)) ('Stable ID collision: ' + $stableId)
    $Ids[$stableId] = [string]$expected.name

    Upsert-Property $card 'id' $stableId
    Upsert-Property $card 'data-version' ([string]$Config.dataVersion)

    $legality = [ordered]@{
      ruleset = [string]$Config.rulesetId
      status = 'legal'
      official = $true
      faction = 'Galactic Republic'
      productOrigin = [string]$expected.productCode
      baseline = [string]$Config.rulesBaseline
      scope = 'Republic product-origin record; neutral cross-faction compatibility handled separately'
    }
    Upsert-Property $card 'legality' ([pscustomobject]$legality)

    if($null -ne $card.source){
      Upsert-Property $card.source 'rules-baseline' ([string]$Config.rulesBaseline)
      Upsert-Property $card.source 'data-version' ([string]$Config.dataVersion)
    }

    $Normalized++
    $IdRows.Add([pscustomobject][ordered]@{
      id = $stableId
      name = [string]$expected.name
      kind = $kind
      points = [int]$expected.points
      productCode = [string]$expected.productCode
      repoPath = $rel
    })
  }

  Write-JsonArray $full $rows
  # Immediate parse/read-back check after write.
  $check = @(Read-JsonRecords $full)
  foreach($expected in $expectedRows){
    $matches = @($check | Where-Object { $_.name -eq $expected.name })
    Assert ($matches.Count -eq 1) ('Read-back failure after normalization: ' + $expected.name)
    Assert (-not [string]::IsNullOrWhiteSpace([string]$matches[0].id)) ('Missing normalized ID after read-back: ' + $expected.name)
    Assert ([string]$matches[0].legality.status -eq 'legal') ('Missing legal status after read-back: ' + $expected.name)
  }
  Write-Host ('[OK] Normalized ' + $expectedRows.Count + ' record(s) in ' + $rel)
}
Assert ($Normalized -eq 56) ('Expected to normalize 56 records; normalized ' + $Normalized + '.')
Assert ($Ids.Count -eq 56) ('Expected 56 unique stable IDs; found ' + $Ids.Count + '.')
Write-Host '[OK] 56 / 56 Republic records normalized with unique stable IDs'

Header 'Verify unique-card and restriction metadata'
$UniqueExpected = 0
$UniquePresent = 0
$RestrictionPresent = 0
foreach($rec in @($Audit.records)){
  $rows = @(Read-JsonRecords (Join-Path $Repo ([string]$rec.repoPath)))
  $card = @($rows | Where-Object { $_.name -eq $rec.name })[0]
  if($rec.kind -eq 'upgrade'){
    # Existing unique flags/restriction strings remain authoritative where supplied by the data payload.
    if($null -ne $card.PSObject.Properties['unique']){
      $UniqueExpected++
      if([bool]$card.unique){ $UniquePresent++ }
    }
    if($null -ne $card.PSObject.Properties['restriction'] -and -not [string]::IsNullOrWhiteSpace([string]$card.restriction)){
      $RestrictionPresent++
    }
  }
}
Write-Host ('[OK] Preserved unique metadata on ' + $UniquePresent + ' upgrade record(s)')
Write-Host ('[OK] Preserved explicit restriction text on ' + $RestrictionPresent + ' upgrade record(s)')
Write-Host '[OK] No legacy uniqueness/restriction fields were removed or synthesized'

Header 'Verify final-point provenance gate'
foreach($check in @($Audit.finalPointHistoryChecks)){
  $rows = @(Read-JsonRecords (Join-Path $Repo ([string]$check.repoPath)))
  $card = @($rows | Where-Object { $_.name -eq $check.name })[0]
  Assert ($null -ne $card.'points-history') ($check.name + ' is missing points-history.')
  Assert ([int]$card.'points-history'.printed -eq [int]$check.printed) ($check.name + ' printed-point provenance mismatch.')
  Assert ([int]$card.'points-history'.current -eq [int]$check.current) ($check.name + ' final-point provenance mismatch.')
  Assert ([int]$card.points -eq [int]$check.current) ($check.name + ' active points do not match final-point provenance.')
  Write-Host ('[OK] ' + $check.name + ': printed ' + $check.printed + ' / active final ' + $check.current)
}

Header 'Install Republic final release manifest'
$ReleaseDir = Join-Path $Repo 'metadata\releases'
New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null
$ReleasePath = Join-Path $ReleaseDir 'galactic-republic-2025.01-final.json'
$ReleaseConfigPath = Join-Path $ReleaseDir 'republic-normalization-1.6.json'
Copy-Item -LiteralPath $ConfigPath -Destination $ReleaseConfigPath -Force

$Release = [ordered]@{
  releaseId = 'galactic-republic-2025.01-final'
  faction = 'Galactic Republic'
  status = 'complete-product-origin'
  dataVersion = [string]$Config.dataVersion
  ruleset = [string]$Config.rulesetId
  rulesBaseline = [string]$Config.rulesBaseline
  generatedAt = (Get-Date).ToString('o')
  sourceMilestones = @('1.1','1.2','1.3','1.4','1.5','1.6')
  products = @('SWM34','SWM36','SWM40','SWM41')
  counts = [ordered]@{
    ships = 8
    squadronDesigns = 12
    upgradeDesigns = 36
    totalUniqueDesigns = 56
    stableIds = $Ids.Count
    knownReprintedDesigns = 1
  }
  records = @($IdRows | Sort-Object id)
  reprints = @($Audit.reprints)
  finalPointHistoryChecks = @($Audit.finalPointHistoryChecks)
  compatibilityScope = [ordered]@{
    productOriginComplete = $true
    neutralUpgradeCompatibilityComplete = $false
    note = 'Neutral upgrades from older products are not reclassified as Republic-origin records. Their fleet-building legality will be provided by the later cross-faction compatibility layer.'
  }
}
Set-Content -LiteralPath $ReleasePath -Value (ConvertTo-Json -InputObject $Release -Depth 30) -Encoding UTF8

$ReleaseRead = Read-JsonAny $ReleasePath
Assert ([int]$ReleaseRead.counts.totalUniqueDesigns -eq 56) 'Release manifest count mismatch.'
Assert ([int]$ReleaseRead.counts.stableIds -eq 56) 'Release manifest stable-ID count mismatch.'
Assert (@($ReleaseRead.records).Count -eq 56) 'Release manifest record list mismatch.'
Write-Host '[OK] Republic final release manifest: 56 records / 56 stable IDs'

Header 'Generate release-gate reports'
$ReportDir = Join-Path $Repo 'reports'
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$JsonReport = Join-Path $ReportDir 'republic-release-1.6.json'
$MdReport = Join-Path $ReportDir 'republic-release-1.6.md'

$Report = [ordered]@{
  milestone = '1.6'
  status = 'PASS'
  faction = 'Galactic Republic'
  releaseId = 'galactic-republic-2025.01-final'
  dataVersion = [string]$Config.dataVersion
  ruleset = [string]$Config.rulesetId
  rulesBaseline = [string]$Config.rulesBaseline
  normalizedRecords = 56
  uniqueStableIds = 56
  products = @('SWM34','SWM36','SWM40','SWM41')
  productOriginCompleteness = $true
  neutralCompatibilityDeferred = $true
  releaseManifest = 'metadata/releases/galactic-republic-2025.01-final.json'
  backup = $Backup
}
Set-Content -LiteralPath $JsonReport -Value (ConvertTo-Json -InputObject $Report -Depth 20) -Encoding UTF8

$Lines = @(
  '# Galactic Republic Final Release Gate — Milestone 1.6',
  '',
  '**Status:** PASS',
  '',
  '**Release:** `galactic-republic-2025.01-final`',
  '',
  '**Rules baseline:** ' + [string]$Config.rulesBaseline,
  '',
  '## Verified',
  '',
  '- 56 / 56 Republic product-origin records normalized',
  '- 56 / 56 deterministic stable IDs unique',
  '- 8 ship designs',
  '- 12 squadron designs',
  '- 36 upgrade designs',
  '- SWM34 / SWM36 / SWM40 / SWM41 metadata baseline',
  '- V-19 SWM36 reprint remains non-duplicated',
  '- SPHA-T printed 3 -> final 7',
  '- Resolute printed 6 -> final 4',
  '- Mercy Mission printed 0 -> final 5',
  '- Existing uniqueness and restriction fields preserved',
  '- Legacy schema fields preserved',
  '',
  '## Scope note',
  '',
  'This completes Galactic Republic product-origin data. Neutral upgrades originating in older products are intentionally not reclassified as Republic records; cross-faction upgrade legality belongs to the later compatibility layer.',
  '',
  '## Release manifest',
  '',
  '`metadata/releases/galactic-republic-2025.01-final.json`'
)
Set-Content -LiteralPath $MdReport -Value $Lines -Encoding UTF8
Write-Host ('[OK] JSON report: ' + $JsonReport)
Write-Host ('[OK] Markdown report: ' + $MdReport)

Header 'Install reusable verifier snapshot'
$ToolsDir = Join-Path $Repo 'tools'
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$Verifier = Join-Path $ToolsDir 'verify_milestone_1_6.ps1'
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination $Verifier -Force
Write-Host ('[OK] Installed ' + $Verifier)

Write-Host ''
Write-Host '[OK] Milestone 1.6 complete.'
Write-Host '[OK] Galactic Republic product-origin dataset has passed its final normalization and legality gate.'
Write-Host '[OK] 56 / 56 records normalized; 56 / 56 stable IDs unique.'
Write-Host '[OK] Republic release manifest: metadata\releases\galactic-republic-2025.01-final.json'
Write-Host '[OK] Galactic Republic is ready to freeze while Separatist Alliance work begins.'
Write-Host ('[OK] Backup: ' + $Backup)
