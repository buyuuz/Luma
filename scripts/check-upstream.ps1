<#
.SYNOPSIS
  Read-only upstream WinShun update report, optionally create a local review branch.
.DESCRIPTION
  Fetches LingCore/WinShun/main and compares it with Luma/main.
  NEVER auto-merges, installs, rebases, publishes, or changes Luma/main.
.EXAMPLE
  .\scripts\check-upstream.ps1
  .\scripts\check-upstream.ps1 -Prepare
#>
param([switch] $Prepare)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $remotes = @(& git remote)
    if ($LASTEXITCODE -ne 0) { throw 'Could not list Git remotes' }
    $upstreamUrl = 'https://github.com/LingCore/WinShun.git'
    if ($remotes -notcontains 'upstream') {
        & git remote add upstream $upstreamUrl
        if ($LASTEXITCODE -ne 0) { throw 'Cannot add upstream remote' }
    } else {
        $existingUrl = (& git remote get-url upstream).Trim()
        if ($existingUrl -ne $upstreamUrl) {
            throw "Existing upstream remote is $existingUrl; refusing to overwrite it."
        }
    }

    Write-Host 'Fetching upstream/main (read only)...'
    & git fetch upstream main --no-tags
    if ($LASTEXITCODE -ne 0) { throw 'Fetch failed' }

    # Main is always compared, irrespective of the currently checked-out branch.
    $common = (& git merge-base main upstream/main)
    if ($LASTEXITCODE -ne 0 -or -not $common) {
        throw 'No shared Git history: stop. Do not force a merge.'
    }
    $counts = (& git rev-list --left-right --count main...upstream/main).Trim() -split '\s+'
    $localAhead = [int]$counts[0]
    $upstreamAhead = [int]$counts[1]
    $tip = (& git rev-parse --short upstream/main).Trim()
    $base = (& git rev-parse --short $common).Trim()
    Write-Host ''
    Write-Host "Luma main:       $localAhead own commits since divergence"
    Write-Host "WinShun main:    $upstreamAhead upstream commits since divergence"
    Write-Host "Upstream HEAD:   $tip (common ancestor $base)"
    Write-Host ''
    if ($upstreamAhead -eq 0) {
        Write-Host 'No new upstream commits to review.'
        return
    }

    Write-Host 'Recent incoming changes:'
    & git log --date=short --pretty=format:'%h %ad %s' --max-count=15 main..upstream/main
    Write-Host ''

    $incoming = @(& git diff --name-only $common upstream/main)
    $customized = @(& git diff --name-only $common main)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect file differences' }
    $customSet = @{}
    foreach ($file in $customized) { $customSet[$file] = $true }
    $overlap = @($incoming | Where-Object { $customSet.ContainsKey($_) })
    Write-Host ''
    Write-Host "Changed upstream paths: $($incoming.Count)"
    Write-Host "Paths also customized by Luma: $($overlap.Count)"
    foreach ($file in ($overlap | Select-Object -First 35)) {
        Write-Host "  REVIEW $file"
    }
    if ($overlap.Count -gt 35) { Write-Host "  ...and $($overlap.Count - 35) more" }
    Write-Host ''
    Write-Host 'Important: even paths without textual conflicts may change runtime behavior.'
    Write-Host 'Keep branding, Win32 service/pipe contracts, MCP permissions, Win10 alpha corners,'
    Write-Host 'installer AppId, and the buyuuz/Luma updater feed intact.'
    Write-Host 'See docs/UPSTREAM_MAINTENANCE.md before integrating.'
    if ($Prepare) {
        $dirty = @(& git status --porcelain=v1)
        if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) {
            throw 'Working tree is not clean; review branch was NOT created.'
        }
        $name = 'sync/winshun-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
        & git branch $name main
        if ($LASTEXITCODE -ne 0) { throw 'Failed to create review branch' }
        Write-Host "Created LOCAL branch $name from main."
        Write-Host "To review: git switch $name"
        Write-Host 'No upstream code has been merged into it yet.'
    }
} finally {
    Pop-Location
}
