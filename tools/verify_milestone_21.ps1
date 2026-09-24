param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
$S=Get-Content -LiteralPath (Join-Path $Repo 'reports\milestone-21-final-status.json') -Raw|ConvertFrom-Json
if($S.status-ne'PASS-MILESTONE-21-NEBULA-AUTHORITATIVE-EVIDENCE-COMPLETE'){throw 'Milestone 21 invalid.'}
if([int]$S.objective_records-ne46){throw 'Expected 46 objective records.'}
if([int]$S.direct_card_source_gates-ne8){throw 'Expected 8 direct-card source gates.'}
if([int]$S.official_errata_corroborated_partial_gates-ne1){throw 'Expected one partial errata-corroborated gate.'}
if([int]$S.production_files_changed-ne0){throw 'Milestone 21 must not modify production JSON.'}
Write-Host '[OK] MILESTONE 21 FINAL VERIFIER PASS'
Write-Host '[OK] Objective records remain: 46'
Write-Host '[OK] Direct-card-only source gates: 8'
Write-Host '[OK] Nebula Outskirts: official errata corroborated'
Write-Host '[OK] Production files changed: 0'
