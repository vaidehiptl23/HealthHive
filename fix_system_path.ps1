$essentialPaths = @(
    "C:\Windows\System32",
    "C:\Windows",
    "C:\Windows\System32\Wbem",
    "C:\Windows\System32\WindowsPowerShell\v1.0",
    "C:\Program Files\Git\cmd"
)

# Get current User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$pathElements = if ($userPath) { $userPath -split ';' } else { @() }

$addedPaths = @()
foreach ($path in $essentialPaths) {
    # Check case-insensitively if path is already present
    $exists = $false
    foreach ($el in $pathElements) {
        if ($el.Trim().ToLower() -eq $path.ToLower()) {
            $exists = $true
            break
        }
    }
    if (-not $exists) {
        $pathElements += $path
        $addedPaths += $path
    }
}

if ($addedPaths.Count -gt 0) {
    $newUserPath = $pathElements -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, [EnvironmentVariableTarget]::User)
    Write-Host "Successfully added the following missing paths to your User PATH:"
    foreach ($ap in $addedPaths) {
        Write-Host " - $ap"
    }
    Write-Host "IMPORTANT: You MUST completely restart VS Code and any open terminals for this to take effect."
} else {
    Write-Host "All essential Windows paths and Git are already in your User PATH."
}
