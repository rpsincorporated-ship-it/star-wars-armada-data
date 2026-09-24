param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$P=Join-Path $Repo 'reports\official-evidence-map-5.3.json'
if(-not(Test-Path -LiteralPath $P)){throw '5.3 report missing.'}
$R=Get-Content -LiteralPath $P -Raw|ConvertFrom-Json
if($R.status -ne 'PASS-EVIDENCE-MAP-READY'){throw '5.3 status invalid.'}
if([int]$R.audit_identities -ne 244 -or [int]$R.evidence_rows -ne 244){throw 'Evidence-map count mismatch.'}
if(@($R.sources).Count -lt 5){throw 'Official source registry incomplete.'}
if(@($R.classification_contract).Count -ne 6){throw 'Classification contract mismatch.'}
if($R.providence_visual_gate.state -ne 'OPEN'){throw 'Providence visual gate must remain OPEN.'}
if($R.production_card_data_modified -ne $false){throw 'Production-write boundary failed.'}
$I=Join-Path $Repo 'input\official-evidence-map-input-5.3.json'
$Rows=@(Get-Content -LiteralPath $I -Raw|ConvertFrom-Json)
if($Rows.Count -ne 244){throw 'Evidence input template count mismatch.'}
if(@($Rows.audit_id|Sort-Object -Unique).Count -ne 244){throw 'Evidence input IDs are not unique.'}
Write-Host '[OK] Milestone 5.3 verifier PASS'
Write-Host '[OK] 244-row official-evidence map is ready'
Write-Host '[OK] Six-state correction classification contract is locked'
Write-Host '[OK] RR1 Rebel Providence official visual gate remains OPEN'
Write-Host '[OK] No production card data was modified'
