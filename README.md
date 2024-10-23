# Genshin Impact check in auto claimer
With this powershell script you can claim check-in rewards in Genshin Impact, and configure task scheduler to auto-claim everytime you turn-on the computer.
It also can send a message on telegram by configuring a bot

## Install
To install the program you simply need to download the file 'daily_checkin.ps1' and put it in a folder

## Configuration 
By opening the file with a text editor you need to edit those options.
1. To find the values of your profile you need to log-in on [Hoyolab](https://www.hoyolab.com)
2. Open DevTools (by CTRL+SHIFT+I, or from the options)
3. On the top select "Application"
4. Under the storage tab select "Cookies"
5. Select "https://www.hoyolab.com" from the dropdown option.
6. Copy the values to the file
    
|**Option**|**Example value**|
|----------|-----------------|
|ltmid_v2  |0xxxxx000x_xx    |
|ltuid_v2  |   123456789     |
|ltoken_v2 |a very long string| 

### Optional configuration for telegram bot
1. To create a Telegram bot you need to write to [BotFather](https://telegram.me/BotFather)
2. From there you sould get an API token
3. To get the chat ID write to [IDBot](https://t.me/myidbot)
4. copy the values to the file

   
|**Option**            |**Example value**|
|----------------------|-----------------|
|notify_me_telegram    |"yes" or "no"|
|telegram_chat_id      | 123456789 |
|telegram_bot_API_Token|123456:XXXXXXXXXX|

## Automation With Windows Task Scheduler
Example:
Run at boot every day

- Open Task Scheduler
- Action -> Crate Task
- **General Menu**
  - Name: daily_genshin_impact
  - Run whether user is logged on or not
- **Trigger**
  - New...
  - Begin the task: At startup
  - Delay task for: 1 day
  - Repeat task every: 1 day
  - for duration of: indefinitely
  - Enabled
- **Actions**
  - New...
  - Action: Start a Program
  - Program/script: _C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe_
  - Add arguments: _-ExecutionPolicy Bypass -File "your program file"_
- **Conditions**
  - Power: Uncheck - [x] Start the task only if the computer is on AC power
- Press ok
- Enter your user's password when prompted (the user password can be the password to the microsoft account)
