#Requires -Version 7

# Version 1.1.0

# check if newer version
$gitUrl = "https://raw.githubusercontent.com/mikepowell/powershell/main/profile.ps1"
$latestVersionFile = [System.IO.Path]::Combine("$HOME",'.latest_psprofileversion')
$versionRegEx = "# Version (?<version>\d+\.\d+\.\d+)"

$null = Start-ThreadJob -Name "Get version profile.ps1 from github" -ArgumentList $gitUrl, $latestVersionFile, $versionRegEx -ScriptBlock {
  param ($gitUrl, $latestVersionFile, $versionRegEx)
  try {
    $profileContent = (Invoke-WebRequest $gitUrl -ErrorAction Stop).Content

    [version]$githubVersion = "0.0.0"
    if ($profileContent -match $versionRegEx) {
      $githubVersion = $matches.Version
      Set-Content -Path $latestVersionFile -Value $githubVersion
    }
  }
  catch {
    # we can hit rate limit issue with GitHub since we're using anonymous
    Write-Verbose -Verbose "Was not able to download profile.ps1 from GitHub to check for newer version."
  }
}

if ([System.IO.File]::Exists($latestVersionFile)) {
  $latestVersion = [System.IO.File]::ReadAllText($latestVersionFile)
  $currentProfile = [System.IO.File]::ReadAllText($profile)
  [version]$currentVersion = "0.0.0"
  if ($currentProfile -match $versionRegEx) {
    $currentVersion = $matches.Version
  }

  if ([version]$latestVersion -gt $currentVersion) {
    Write-Verbose "Current profile.ps1 version: $currentVersion" -Verbose
    Write-Verbose "New profile.ps1 version: $latestVersion" -Verbose
    $choice = Read-Host -Prompt "Found newer profile, install? (Y)"
    if ($choice -eq "Y" -or $choice -eq "") {
      try {
        $newProfile = (Invoke-WebRequest $gitUrl -ErrorAction Stop).Content
        Set-Content -Path $profile -Value $newProfile
        Write-Verbose "Installed newer version of profile." -Verbose
        . $profile
        return
      }
      catch {
        # we can hit rate limit issue with GitHub since we're using anonymous
        Write-Verbose -Verbose "Was not able to download profile.ps1 from GitHub, try again next time."
      }
    }
  }
}

Import-Module 'posh-git'
Import-Module 'Terminal-Icons'
Import-Module 'oh-my-posh'

Set-PoshPrompt -Theme "$HOME\.oh-my-posh.json"

# setup psdrives
if (!(Test-Path git:)) {
    New-PSDrive -Root 'c:\git' -Name git -PSProvider FileSystem > $Null
}


