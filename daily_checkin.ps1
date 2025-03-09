# Check if SQLite assembly is loaded, if not, load it
if (-not [System.Reflection.Assembly]::LoadWithPartialName("System.Data.SQLite")) {
    # SQLite .NET library must be in the same directory as the script or available in the system's PATH
    $sqlitePath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "System.Data.SQLite.dll"

    if (Test-Path $sqlitePath) {
        Add-Type -Path $sqlitePath
    } else {
        Write-Host "SQLite .NET library not found. Please ensure 'System.Data.SQLite.dll' is present in the same directory as this script."
        Exit
    }
}

# Get the path of the cookie database based on the browser type
function Get-CookieDbPath {
    param (
        [string]$browser
    )

    # Default paths for each browser
    switch ($browser) {
        "Chrome" {
            return "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Cookies"
        }
        "Edge" {
            return "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Cookies"
        }
        "Opera" {
            return "$env:USERPROFILE\AppData\Roaming\Opera Software\Opera Stable\Cookies"
        }
        default {
            Write-Host "Unsupported browser: $browser"
            return $null
        }
    }
}

# Extract cookies from the specified browser's SQLite database
function Get-CookiesFromBrowser {
    param (
        [string]$browser
    )

    $cookieDbPath = Get-CookieDbPath -browser $browser

    # Check if the cookie file exists
    if (Test-Path $cookieDbPath) {
        try {
            # Create SQLite connection
            $connectionString = "Data Source=$cookieDbPath;Version=3;"
            $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $connection.Open()

            # Query for specific cookies from 'hoyolab.com'
            $query = "SELECT name, value FROM cookies WHERE domain = 'hoyolab.com'"
            $command = $connection.CreateCommand()
            $command.CommandText = $query
            $reader = $command.ExecuteReader()

            # Collect cookies
            $cookies = @{}
            while ($reader.Read()) {
                $cookies[$reader["name"]] = $reader["value"]
            }

            $connection.Close()

            # Return cookies if the required ones are found
            if ($cookies["ltmid_v2"] -and $cookies["ltuid_v2"] -and $cookies["ltoken_v2"]) {
                return @($cookies["ltmid_v2"], $cookies["ltuid_v2"], $cookies["ltoken_v2"])
            } else {
                return $null
            }
        } catch {
            Write-Host "Error reading cookies: $_"
            return $null
        }
    } else {
        Write-Host "Browser cookie database not found. Please ensure $browser is closed and the path is correct."
        return $null
    }
}

# Prompt user to choose a browser if automatic detection fails
$browser = Read-Host "Enter your browser (Chrome, Edge, or Opera)"

# Try to automatically extract cookies from the selected browser
$cookies = Get-CookiesFromBrowser -browser $browser

if (-not $cookies) {
    # If cookie extraction fails, prompt the user for cookies
    Write-Host "Automatic cookie extraction failed. Please input your cookies manually."
    $ltmid_v2 = Read-Host "Please enter your ltmid_v2 cookie"
    $ltuid_v2 = Read-Host "Please enter your ltuid_v2 cookie"
    $ltoken_v2 = Read-Host "Please enter your ltoken_v2 cookie"
} else {
    # If cookies are extracted successfully, use them
    $ltmid_v2 = $cookies[0]
    $ltuid_v2 = $cookies[1]
    $ltoken_v2 = $cookies[2]
}

# Telegram notification setup (if applicable)
$notify_me_telegram = "no"
$telegram_chat_id = ""
$telegram_bot_API_Token = ""

$allCookies = "ltmid_v2=$ltmid_v2; ltoken_v2=$ltoken_v2; ltuid_v2=$ltuid_v2"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$uri = "https://sg-hk4e-api.hoyolab.com/event/sol/sign?act_id=e202102251931481"

foreach ($cookiePair in $allCookies.Split((";"))) {
    $cookieValues = $cookiePair.Trim().Split("=")
    $cookie = New-Object System.Net.Cookie
    $cookie.Name = $cookieValues[0]
    $cookie.Value = $cookieValues[1]
    $cookie.Domain = "hoyolab.com"
    $session.Cookies.Add($cookie)
}

# Send the request to the server
$response = Invoke-WebRequest -Method Post -WebSession $session -Uri $uri
$response_json = $response.Content | ConvertFrom-Json
$retcode = $response_json.retcode

# Telegram notification
if ($notify_me_telegram -eq "no") {
    Exit
}

if ($retcode -eq "-5003") {
    $text = "Already claimed daily for today"
} else {
    $text = "Claimed daily"
}

if ($notify_me_telegram -eq "yes") {
    $telegram_notification = @{
        Uri    = "https://api.telegram.org/bot$telegram_bot_API_Token/sendMessage?chat_id=$telegram_chat_id&text=$text"
        Method = 'GET'
    }

    $telegram_notification_response = Invoke-RestMethod @telegram_notification
    if ($telegram_notification_response.ok -ne $true) {
        Write-Output "Error! Telegram notification failed"
        Exit
    }
}
