param([Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference='Stop'
$Repo=(Resolve-Path -LiteralPath $RepoPath).Path
function Read-J([string]$P){Get-Content -LiteralPath $P -Raw|ConvertFrom-Json}
$A=Read-J (Join-Path $Repo 'reports\official-errata-disposition-5.15.json')
if($A.status-ne'PASS-ERRATA-DISPOSITION' -or [int]$A.total_upgrade_records-ne116){throw '5.15 invalid.'}
$B=Read-J (Join-Path $Repo 'reports\legacy-integrity-closure-5.16.json')
if($B.status-ne'PASS-LEGACY-INTEGRITY-CLOSURE' -or [int]$B.records-ne128){throw '5.16 invalid.'}
$C=Read-J (Join-Path $Repo 'reports\global-integrity-audit-5.17.json')
if($C.status-ne'PASS-GLOBAL-INTEGRITY-AUDIT' -or [int]$C.production_json_files-ne191 -or [int]$C.parse_failures-ne0 -or [int]$C.duplicate_stable_ids-ne0){throw '5.17 invalid.'}
$D=Read-J (Join-Path $Repo 'reports\milestone-5-closure-5.19.json')
if($D.status-ne'PASS-MILESTONE-5-AUDIT-COMPLETE' -or [int]$D.production_json_changed_in_completion_package-ne0){throw '5.19 invalid.'}
Write-Host '[OK] Milestone 5 final verifier PASS'
Write-Host '[OK] 5.15 Errata disposition complete'
Write-Host '[OK] 5.16 legacy integrity closure complete'
Write-Host '[OK] 5.17 global integrity audit complete'
Write-Host '[OK] 5.18 frozen backlog manifest present'
Write-Host '[OK] 5.19 Milestone 5 audit closure complete'
