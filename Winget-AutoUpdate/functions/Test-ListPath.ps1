#Function to check Black/White List External Path

function Test-ListPath ($ListPath, $UseWhiteList, $WingetUpdatePath) {
    # URL, UNC or Local Path
    if ($UseWhiteList) {
        $ListType = "included_apps.txt"
    }
    else {
        $ListType = "excluded_apps.txt"
    }

    # Get local and external list paths
    $LocalList = -join ($WingetUpdatePath, "\", $ListType)
    $ExternalList = -join ($ListPath, "\", $ListType)

    # Check if a list exists
    if (Test-Path "$LocalList") {
        $dateLocal = (Get-Item "$LocalList").LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }

    # If path is URL
    if ($ListPath -like "http*") {
        $ExternalList = -join ($ListPath, "/", $ListType)
        $wc = New-Object System.Net.WebClient
        try {
            $wc.OpenRead("$ExternalList").Close() | Out-Null
            $dateExternal = ([DateTime]$wc.ResponseHeaders['Last-Modified']).ToString("yyyy-MM-dd HH:mm:ss")
            if ($dateExternal -gt $dateLocal) {
                try {
                    $wc.DownloadFile($ExternalList, $LocalList)
                }
                catch {
                    $Script:ReachNoPath = $True
                    return $False
                }
                return $true
            }
        }
        catch {
            try {
                $content = $wc.DownloadString("$ExternalList")
                if ($null -ne $content -and $content -match "\w\.\w") {
                    $wc.DownloadFile($ExternalList, $LocalList)
                    return $true
                }
                else {
                    $Script:ReachNoPath = $True
                    return $False
                }
            }
            catch {
                $Script:ReachNoPath = $True
                return $False
            }
        }
    }
    # If path is UNC or local
    else {
        if (Test-Path -Path $ExternalList) {
            try {
                $dateExternal = (Get-Item "$ExternalList").LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
            catch {
                $Script:ReachNoPath = $True
                return $False
            }
            if ($dateExternal -gt $dateLocal) {
                try {
                    Copy-Item $ExternalList -Destination $LocalList -Force
                }
                catch {
                    $Script:ReachNoPath = $True
                    return $False
                }
                return $True
            }
        }
        else {
            $Script:ReachNoPath = $True
        }
        return $False
    }
}
