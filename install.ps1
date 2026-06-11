<#
.SYNOPSIS
    Install the latest airnity CLI on Windows.
.DESCRIPTION
    irm https://raw.githubusercontent.com/airnity/airnity-cli-releases/main/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"

$Base = if ($env:BASE) { $env:BASE } else { "https://github.com/airnity/airnity-cli-releases/releases/latest/download" }
$Dest = Join-Path $env:LOCALAPPDATA "airnity\bin"

switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { $Arch = "amd64" }
    default { throw "unsupported architecture: $($env:PROCESSOR_ARCHITECTURE) (only AMD64 is supported)" }
}

$Asset = "airnity-windows-$Arch.exe"
$Tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("airnity-" + [System.Guid]::NewGuid().ToString())) -Force
$BinPath = Join-Path $Tmp "airnity.exe"

try {
    Write-Host "Downloading $Asset..."
    Invoke-WebRequest -Uri "$Base/$Asset" -OutFile $BinPath -UseBasicParsing

    # Verify checksum. checksums.txt lists versioned names (airnity_X.Y.Z_os_arch),
    # so match the line by its _windows_arch.exe suffix.
    try {
        $ChecksumsPath = Join-Path $Tmp "checksums.txt"
        Invoke-WebRequest -Uri "$Base/checksums.txt" -OutFile $ChecksumsPath -UseBasicParsing
        $Line = Select-String -Path $ChecksumsPath -Pattern "_windows_$Arch\.exe$" | Select-Object -First 1
        if ($Line) {
            $Expected = ($Line.Line -split '\s+')[0].ToLower()
            $Actual = (Get-FileHash -Path $BinPath -Algorithm SHA256).Hash.ToLower()
            if ($Expected -ne $Actual) {
                throw "checksum mismatch (expected $Expected, got $Actual)"
            }
            Write-Host "Checksum verified."
        }
        else {
            Write-Warning "no checksum entry for windows_$Arch; skipping verification"
        }
    }
    catch [System.Net.WebException] {
        Write-Warning "could not fetch checksums.txt; skipping verification"
    }

    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    Move-Item -Path $BinPath -Destination (Join-Path $Dest "airnity.exe") -Force

    Write-Host "Installed airnity to $(Join-Path $Dest 'airnity.exe')"

    # Add the install dir to the user PATH if it is missing.
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (($UserPath -split ';') -notcontains $Dest) {
        $NewPath = if ([string]::IsNullOrEmpty($UserPath)) { $Dest } else { "$UserPath;$Dest" }
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        $env:PATH = "$env:PATH;$Dest"
        Write-Host "Added $Dest to your user PATH. Restart your terminal for it to take effect in new sessions."
    }

    & (Join-Path $Dest "airnity.exe") version
}
finally {
    Remove-Item -Path $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}
