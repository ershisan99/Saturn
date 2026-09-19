<#
.SYNOPSIS
  Cut a Saturn release: bump versions, tag, push, build the mod zip and
  publish a GitHub release with notes taken from CHANGELOG.md.

.DESCRIPTION
  Before running, add a section to CHANGELOG.md for the new version:

      ## alpha-0.2.2-G - Short release title

      - What changed...

  The text after " - " becomes the release title and the section body becomes
  the release notes. Then run this script from anywhere inside the repo.

  Requires git and the GitHub CLI (gh), logged in with push access to origin.

.PARAMETER Version
  The tag to release, e.g. alpha-0.2.2-G or alpha-0.2.2-G-qf1.

.PARAMETER DryRun
  Run every check, print the notes and build the zip from HEAD, but do not
  modify files, commit, tag, push or publish anything.

.EXAMPLE
  .\scripts\release.ps1 alpha-0.2.2-G -DryRun
  .\scripts\release.ps1 alpha-0.2.2-G
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Version,

  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$Branch = "main"
$Remote = "origin"

function Fail($message) {
  Write-Host "error: $message" -ForegroundColor Red
  exit 1
}

function Step($message) {
  Write-Host "==> $message" -ForegroundColor Cyan
}

# Run a native command and stop the release if it fails.
function Run {
  $exe = $args[0]
  $rest = @($args | Select-Object -Skip 1)
  & $exe @rest
  if ($LASTEXITCODE -ne 0) {
    Fail "'$exe $($rest -join ' ')' exited with code $LASTEXITCODE"
  }
}

function Read-Text($path) {
  return [System.IO.File]::ReadAllText($path)
}

# Write UTF-8 without a BOM; Set-Content on Windows PowerShell 5.1 can't.
function Write-Text($path, $text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

# Replace the single match of $pattern in a file; anything else is an error.
function Set-VersionString($path, $pattern, $value) {
  $text = Read-Text $path
  $regex = New-Object System.Text.RegularExpressions.Regex($pattern)
  $count = $regex.Matches($text).Count
  if ($count -ne 1) {
    Fail "expected exactly one version string in $path, found $count"
  }
  Write-Text $path ($regex.Replace($text, ('${1}' + $value + '${2}')))
}

# --- Tools -----------------------------------------------------------------

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Fail "git was not found on PATH"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
  $gh = $gh.Source
} else {
  # The installer's PATH entry is only seen by shells started after it ran.
  $gh = Join-Path $env:ProgramFiles "GitHub CLI\gh.exe"
  if (-not (Test-Path $gh)) {
    Fail "GitHub CLI (gh) was not found. Install it from https://cli.github.com"
  }
}

$root = (& git -C $PSScriptRoot rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0) {
  Fail "$PSScriptRoot is not inside a git repository"
}
Set-Location $root

# --- Validate --------------------------------------------------------------

Step "Checking $Version"

# alpha-<major>.<minor>.<patch>-<LETTER>[-qf<N>], the scheme used upstream.
if ($Version -notmatch '^alpha-(\d+\.\d+\.\d+-[A-Z](-qf\d+)?)$') {
  Fail "version '$Version' must look like alpha-0.2.2-G or alpha-0.2.2-G-qf1"
}
# metadata.json wants the number first: alpha-0.2.2-G -> 0.2.2-G-ALPHA
$metadataVersion = "$($Matches[1])-ALPHA"

$current = (& git rev-parse --abbrev-ref HEAD)
if ($current -ne $Branch) {
  Fail "releases are cut from '$Branch', but '$current' is checked out"
}

if (& git status --porcelain) {
  Fail "the working tree has uncommitted changes; commit or stash them first"
}

Run git fetch --quiet --tags $Remote
$behind = (& git rev-list --count "HEAD..$Remote/$Branch")
if ($behind -ne "0") {
  Fail "'$Branch' is $behind commit(s) behind $Remote/$Branch; pull first"
}

& git rev-parse --quiet --verify "refs/tags/$Version" | Out-Null
if ($LASTEXITCODE -eq 0) {
  Fail "tag '$Version' already exists"
}

Run $gh auth status | Out-Null

# Publish to wherever $Remote points. This is passed to gh explicitly because
# inside a fork gh may otherwise pick the upstream repository.
$remoteUrl = (& git remote get-url $Remote)
if ($remoteUrl -notmatch 'github\.com[:/](.+?)(\.git)?/?$') {
  Fail "remote '$Remote' ($remoteUrl) is not a GitHub repository"
}
$repo = $Matches[1]

# --- Release notes ---------------------------------------------------------

$changelog = Join-Path $root "CHANGELOG.md"
$title = $null
$noteLines = New-Object System.Collections.Generic.List[string]
$inSection = $false
foreach ($line in [System.IO.File]::ReadAllLines($changelog)) {
  if ($line -match '^##\s+(\S+)(\s+-\s+(.+?))?\s*$') {
    if ($inSection) { break }
    if ($Matches[1] -eq $Version) {
      $inSection = $true
      $title = $Matches[3]
    }
    continue
  }
  if ($inSection) { $noteLines.Add($line) }
}
$notes = ($noteLines -join "`n").Trim()

if (-not $inSection) {
  Fail "CHANGELOG.md has no '## $Version - <title>' section; write the release notes first"
}
if (-not $notes) {
  Fail "the '$Version' section in CHANGELOG.md is empty"
}
if (-not $title) { $title = $Version }

Write-Host ""
Write-Host "Title: $title"
Write-Host "Notes:"
Write-Host $notes
Write-Host ""

# --- Bump, commit, tag, push -----------------------------------------------

if ($DryRun) {
  Step "Dry run: skipping version bump, commit, tag and push"
  $archiveRef = "HEAD"
} else {
  Step "Bumping version strings"
  Set-VersionString (Join-Path $root "metadata.json") '("version"\s*:\s*")[^"]*(")' $metadataVersion
  Set-VersionString (Join-Path $root "core\logic\main.lua") '(VERSION\s*=\s*")[^"]*(")' $Version

  Run git add metadata.json core/logic/main.lua
  # Nothing to commit if the versions were already bumped by hand.
  & git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    Run git commit --quiet -m "Release $Version"
  }
  Run git tag -a $Version -m "$Version - $title"

  Step "Pushing $Branch and $Version to $Remote"
  Run git push --quiet $Remote $Branch
  Run git push --quiet $Remote "refs/tags/$Version"
  $archiveRef = $Version
}

# --- Build the zip ---------------------------------------------------------

# Built with git archive so only committed files are shipped; dev-only files
# are excluded through export-ignore in .gitattributes. Everything sits in a
# top-level Saturn/ folder so the zip extracts straight into Balatro's Mods.
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist "Saturn-$Version.zip"
if (Test-Path $zip) { Remove-Item $zip }

Step "Building $zip"
Run git archive --format=zip --prefix=Saturn/ -o $zip $archiveRef

if ($DryRun) {
  Step "Dry run finished; nothing was pushed or published"
  exit 0
}

# --- Publish ---------------------------------------------------------------

Step "Publishing GitHub release"
$notesFile = Join-Path $dist "notes-$Version.md"
Write-Text $notesFile $notes

Run $gh release create $Version $zip --repo $repo --title $title --notes-file $notesFile --verify-tag --latest
Remove-Item $notesFile

Step "Released $Version"
