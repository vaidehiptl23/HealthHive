# This script will add the Git cmd folder to your User PATH environment variable.

$gitPaths = @(
    "C:\Program Files\Git\cmd",
    "C:\Program Files (x86)\Git\cmd",
    "$env:LOCALAPPDATA\Programs\Git\cmd"
)

$foundPath = $null
foreach ($path in $gitPaths) {
    if (Test-Path "$path\git.exe") {
        $foundPath = $path
        break
    }
}

if ($null -eq $foundPath) {
    Write-Error "Could not find Git installation. Please install Git for Windows (https://git-scm.com/) first."
    exit 1
}

Write-Host "Found Git at: $foundPath"

# Retrieve current User PATH environment variable
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

# Check if it's already there
$pathElements = $userPath -split ';'
if ($pathElements -contains $foundPath) {
    Write-Host "Git is already in your User PATH."
    Write-Host "Please close and reopen all terminal windows / VS Code for changes to take effect."
    exit 0
}

# Append the Git path
$newUserPath = $userPath
if ($userPath -and -not $userPath.EndsWith(';')) {
    $newUserPath += ";"
}
$newUserPath += $foundPath

# Save the updated User PATH
[Environment]::SetEnvironmentVariable("Path", $newUserPath, [EnvironmentVariableTarget]::User)

Write-Host "Successfully added Git to your User PATH!"
Write-Host "IMPORTANT: You must restart your VS Code, PowerShell, or command prompt for the new PATH to load."
