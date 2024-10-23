##list of cookies
$ltmid_v2 = ""
$ltuid_v2 = ""
$ltoken_v2 = ""

## "yes" if you want message via telegram "no" if you don't want
##to find chat id use https://t.me/myidbot
$notify_me_telegram = "no"
## Telegram Chat ID
$telegram_chat_id = ""
## Telegram Bot API Key
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
  $session.Cookies.Add($cookie);
}
$response = Invoke-WebRequest -Method Post -WebSession $session -Uri $uri 
	
$response_json = $response.Content | ConvertFrom-Json
$retcode = $response_json.retcode

if ($notify_me_telegram -eq "no")   {
  Exit
}

if ($retcode -eq "-5003"){
$text = "Already claimed daily for today"
}

else {
$text = "Claimed daily"
}

if ($notify_me_telegram -eq "yes") {
  $telegram_notification = @{
    Uri    = "https://api.telegram.org/bot$telegram_bot_API_Token/sendMessage?chat_id=$telegram_chat_id&text=$text"
    Method = 'GET'
  } 
  
  $telegram_notification_response = Invoke-RestMethod @telegram_notification
  if ($telegram_notification_response.ok -ne "True") {
    Write-Output "Error! Telegram notification failed"
    Exit
  }
}
