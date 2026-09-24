param([Parameter(Mandatory=$false)][string]$RepoPath = ".")
$ErrorActionPreference = "Stop"
$Repo = (Resolve-Path $RepoPath).Path
$Failures = 0

function Ok([string]$Message) { Write-Host "[OK] $Message" }
function Fail([string]$Message) { Write-Host "[FAIL] $Message" -ForegroundColor Red; $script:Failures++ }
function Read-Json([string]$Path) {
    try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
    catch { Fail "$Path`: $($_.Exception.Message)"; return $null }
}
function Validate-SingleCard([string]$Path,[string]$ExpectedName,[int]$ExpectedPoints,[string]$ExpectedFaction) {
    $d = @(Read-Json $Path)
    if ($null -eq $d -or $d.Count -ne 1) { Fail "$(Split-Path $Path -Leaf) must contain exactly one record"; return }
    $x = $d[0]
    if ([string]$x.name -ne $ExpectedName) { Fail "$(Split-Path $Path -Leaf): name mismatch (found '$($x.name)')" }
    if ($ExpectedFaction -and [string]$x.faction -ne $ExpectedFaction) { Fail "$(Split-Path $Path -Leaf): faction mismatch (found '$($x.faction)')" }
    if ([int]$x.points -ne $ExpectedPoints) { Fail "$(Split-Path $Path -Leaf): expected $ExpectedPoints points, found $($x.points)" }
    else { Ok "$ExpectedName ($ExpectedPoints)" }
}

if (-not (Test-Path (Join-Path $Repo "data"))) { throw "Not an Armada data repository: missing data folder at $Repo" }

$shipBase = Join-Path $Repo "data/ship-card/galactic-republic"
Validate-SingleCard (Join-Path $shipBase "acclamator-i-class-assault-ship.json") "Acclamator I-class Assault Ship" 64 "Galactic Republic"
Validate-SingleCard (Join-Path $shipBase "acclamator-ii-class-assault-ship.json") "Acclamator II-class Assault Ship" 71 "Galactic Republic"
Validate-SingleCard (Join-Path $shipBase "consular-class-charger-c70.json") "Consular-class Charger c70" 42 "Galactic Republic"
Validate-SingleCard (Join-Path $shipBase "consular-class-armed-cruiser.json") "Consular-class Armed Cruiser" 37 "Galactic Republic"

$sqBase = Join-Path $Repo "data/squadron-card/galactic-republic"
Validate-SingleCard (Join-Path $sqBase "v-19-torrent-squadron.json") "V-19 Torrent Squadron" 12 "Galactic Republic"
Validate-SingleCard (Join-Path $sqBase "axe.json") "Axe" 17 "Galactic Republic"

$ExpectedUpgrades = [ordered]@{
    "commander.json" = @("Obi-Wan Kenobi","Bail Organa")
    "defensive-retrofit.json" = @("Reactive Gunnery")
    "fleet-support.json" = @("Munitions Resupply","Parts Resupply")
    "offensive-retrofit.json" = @("Hyperspace Rings")
    "officer.json" = @("Clone Captain Zak","Clone Navigation Officer")
    "ordnance.json" = @("Assault Concussion Missiles")
    "support-team.json" = @("Auxiliary Shields Team")
    "title.json" = @("Implacable","Nevoota Bee","Radiant VII","Swift Return")
    "turbolasers.json" = @("Swivel-Mount Batteries")
    "weapons-team.json" = @("Clone Gunners")
}
$upgradeBase = Join-Path $Repo "data/upgrade-card"
foreach ($file in $ExpectedUpgrades.Keys) {
    $path = Join-Path $upgradeBase $file
    if (-not (Test-Path $path)) { Fail "$file missing"; continue }
    $cards = @(Read-Json $path)
    foreach ($name in $ExpectedUpgrades[$file]) {
        $count = @($cards | Where-Object { [string]$_.name -ieq $name }).Count
        if ($count -eq 1) { Ok "$name present once" }
        else { Fail "$name`: expected once, found $count" }
    }
}

$metaPath = Join-Path $Repo "metadata/products/swm34.json"
if (Test-Path $metaPath) {
    $meta = Read-Json $metaPath
    if ($null -ne $meta -and [string]$meta.code -eq "SWM34") { Ok "SWM34 metadata" }
    else { Fail "SWM34 metadata missing/invalid" }
} else { Fail "SWM34 metadata missing/invalid" }

# Parse every JSON file introduced/touched by Milestone 1.1 as an additional syntax check.
$syntaxTargets = @()
if (Test-Path $shipBase) { $syntaxTargets += Get-ChildItem $shipBase -Filter *.json -File }
if (Test-Path $sqBase) { $syntaxTargets += Get-ChildItem $sqBase -Filter *.json -File }
foreach ($file in $ExpectedUpgrades.Keys) { $p = Join-Path $upgradeBase $file; if (Test-Path $p) { $syntaxTargets += Get-Item $p } }
if (Test-Path $metaPath) { $syntaxTargets += Get-Item $metaPath }
foreach ($f in $syntaxTargets) {
    try { $null = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json }
    catch { Fail "Invalid JSON: $($f.FullName) -- $($_.Exception.Message)" }
}
if ($Failures -gt 0) { throw "Milestone 1.1 verification failed with $Failures failure(s)." }
Write-Host "`n[OK] Milestone 1.1 verification passed without Node.js."
