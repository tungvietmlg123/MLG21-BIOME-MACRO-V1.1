; <=======================================================================>
; SAVE INSTRUCTIONS: Open Notepad -> Paste code -> Click File > Save As 
; Select Encoding as "UTF-8 with BOM" and save your .ahk file!
; <=======================================================================>

#Requires AutoHotkey v1.1
#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

global IniFile          := A_ScriptDir . "\config.ini"
global iniFilePath      := A_ScriptDir . "\..\settings.ini"
global WebhookURL       := ""
global PSLink           := ""
global IsRunning        := false
global MacroStartTime   := 0
global AntiAfkEnabled   := 0
global AutoFishEnabled  := 0
global MerchantEnabled  := 0

global prevBiome    := "None"
global prevState    := "None"
global prevMerchant := ""
global biomeColors  := { "NORMAL":16777215, "SAND STORM":16040572, "HELL":6033945, "STARFALL":6784224, "CORRUPTION":9454335, "NULL":0, "GLITCHED":6684517, "WINDY":9566207, "SNOWY":12908022, "RAINY":4425215, "DREAMSPACE":16743935, "PUMPKIN MOON":13983497, "GRAVEYARD":16777215, "BLOOD RAIN":16711680, "CYBERSPACE":2904999, "EGGLAND":65535, "SINGULARITY":14716000, "INCINERATOR":16736031, "BLAZING SUN":16760650}

EnvGet, LocalAppData, LOCALAPPDATA

OnExit("ExitHandler")

IniRead, SavedWebhook, %IniFile%, Settings, WebhookURL, %A_Space%
IniRead, SavedPSLink, %IniFile%, Settings, PSLink, %A_Space%
IniRead, SavedAntiAfk, %IniFile%, Settings, AntiAfk, 0
IniRead, SavedAutoFish, %IniFile%, Settings, AutoFish, 0
IniRead, SavedMerchant, %IniFile%, Settings, Merchant, 0

if (SavedWebhook = "ERROR" || InStr(SavedWebhook, "http") = 0)
    SavedWebhook := ""
if (SavedPSLink = "ERROR" || InStr(SavedPSLink, "http") = 0)
    SavedPSLink := ""

; ==============================================================================
; USER INTERFACE (MODERN DARK GAMER STYLE + ADDITIONAL FEATURES)
; ==============================================================================
Gui, Color, 0x0A0B0E, 0x15171E
Gui, +Resize -MaximizeBox

; Header Title & Accent Bar
Gui, Font, s15 Bold, Segoe UI
Gui, Add, Text, x20 y12 w430 h28 +Center c0x00FFC8, MLG21 MACRO
Gui, Font, s8 Italic, Segoe UI
Gui, Add, Text, x20 y36 w430 h18 +Center c0x6C727D, Sol's RNG Biome Detector v1.2 (F1: Start | F2: Stop)

; CONNECTION SETTINGS SECTION
Gui, Font, s9 Bold, Segoe UI
Gui, Add, GroupBox, x20 y58 w430 h155 c0x2A2E3D,  NETWORK & CONFIGURATION  

Gui, Font, s9 Normal, Segoe UI
Gui, Add, Text, x35 y82 w400 h16 c0xA2A6B0, Discord Webhook URL:
Gui, Add, Edit, x35 y98 w400 h24 vtxtWebhook c0xFFFFFF Background0x1C1F2B, %SavedWebhook%

Gui, Add, Text, x35 y128 w400 h16 c0xA2A6B0, Roblox Private Server (PS) Link:
Gui, Add, Edit, x35 y144 w400 h24 vtxtPSLink c0xFFFFFF Background0x1C1F2B, %SavedPSLink%

; EXTRA FEATURES SECTION (ANTI-AFK, AUTO FISH, MERCHANT NOTIFICATION)
Gui, Font, s9 Bold, Segoe UI
Gui, Add, GroupBox, x20 y218 w430 h94 c0x2A2E3D,  ADDITIONAL FEATURES  
Gui, Font, s9 Normal, Segoe UI
isCheckedAntiAfk := SavedAntiAfk ? "Checked" : ""
isCheckedAutoFish := SavedAutoFish ? "Checked" : ""
isCheckedMerchant := SavedMerchant ? "Checked" : ""

Gui, Add, CheckBox, x35 y238 w400 h18 vchkAntiAfk %isCheckedAntiAfk% c0x00FFC8, Enable Anti-AFK (Auto click every 2s)
Gui, Add, CheckBox, x35 y260 w400 h18 vchkAutoFish %isCheckedAutoFish% c0x00FFC8, Enable Auto Fishing (not currently working)
Gui, Add, CheckBox, x35 y282 w400 h18 vchkMerchant %isCheckedMerchant% c0x00FFC8, PingMerchant(In coding)

; STATUS SECTION
Gui, Font, s9 Bold, Segoe UI
Gui, Add, GroupBox, x20 y318 w430 h52 c0x2A2E3D,  SYSTEM STATUS  
Gui, Font, s9 Italic Bold, Segoe UI
Gui, Add, Text, x30 y338 w410 h20 vtxtStatus +Center c0xF1C40F, Status: Waiting to start... (Press F1 / F2)

; CONTROL BUTTONS SECTION
Gui, Font, s9 Bold, Segoe UI
Gui, Add, Button, x20 y380 w132 h36 vBtnTest gTestWebhook c0xFFFFFF, TEST WEBHOOK
Gui, Add, Button, x169 y380 w132 h40 vBtnStart +Default gStartMacro c0x2ECC71, START [F1]
Gui, Add, Button, x318 y380 w132 h40 vBtnStop gStopManage c0xE74C3C, STOP [F2]

; CREDIT & COMMUNITY SECTION
Gui, Font, s8 Bold, Segoe UI
Gui, Add, GroupBox, x20 y428 w430 h125 c0x2A2E3D,  CREDIT & COMMUNITY  

Gui, Font, s8 Normal, Segoe UI
Gui, Add, Text, x30 y446 w410 h15 c0x00FFC8, • Developer: Made By Tungvietmlg_21 (mlg21)
Gui, Add, Text, x30 y462 w410 h15 c0xA2A6B0, • Tester: Mouche (Discord: Iamnotmrbeast0364_02386)
Gui, Add, Text, x30 y478 w410 h15 c0x3498DB, • Updates: MLG21 Lounge (discord.gg/8UpxCvT8QH)
Gui, Add, Text, x30 y494 w410 h15 c0xE67E22, • Community: Glitch Hunter (discord.gg/pzZxAdkYdE)

Gui, Show, w470 h564, MLG21 Biome Macro V1.2

SetTimer, CheckBiomeTask, Off
SetTimer, UpdateGuiTimer, Off
SetTimer, AntiAfkTask, Off
SetTimer, AutoFishTask, Off
SetTimer, MerchantTask, Off
return

GuiClose:
ExitApp

ExitHandler(ExitReason, ExitCode) {
    global WebhookURL, IsRunning
    if (IsRunning && WebhookURL != "" && InStr(WebhookURL, "discord.com/api/webhooks/") > 0) {
        SendStopStatusAlert("Application Closed")
    }
    return 0
}

; ==============================================================================
; HOTKEYS (F1 to Start, F2 to Stop)
; ==============================================================================
F1::
    Gosub, StartMacro
return

F2::
    Gosub, StopMacro
return

; ==============================================================================
; BUTTON ANIMATION HELPER
; ==============================================================================
AnimateButton(ctrlHwnd) {
    SoundBeep, 700, 40
    SendMessage, 0xF3, 1, 0,, ahk_id %ctrlHwnd%
    Sleep, 100
    SendMessage, 0xF3, 0, 0,, ahk_id %ctrlHwnd%
}

; ==============================================================================
; CONTROL BUTTONS
; ==============================================================================
StartMacro:
    GuiControlGet, hBtn, Hwnd, BtnStart
    AnimateButton(hBtn)
    Gui, Submit, NoHide

    if (IsRunning) {
        return
    }

    ; Kiểm tra xem Roblox đã bật hay chưa
    if (!ProcessExist("RobloxPlayerBeta.exe")) {
        MsgBox, 16, MLG21 Macro Error, You do not have Roblox open! How can the macro function without it? =))
        return
    }

    WebhookURL      := txtWebhook
    PSLink          := txtPSLink
    AntiAfkEnabled  := chkAntiAfk
    AutoFishEnabled := chkAutoFish
    MerchantEnabled := chkMerchant

    if (WebhookURL = "" || InStr(WebhookURL, "discord.com/api/webhooks/") == 0) {
        MsgBox, 48, MLG21 Macro Warning, Please enter a valid Discord Webhook URL first!
        return
    }

    IniWrite, %WebhookURL%, %IniFile%, Settings, WebhookURL
    IniWrite, %PSLink%, %IniFile%, Settings, PSLink
    IniWrite, %AntiAfkEnabled%, %IniFile%, Settings, AntiAfk
    IniWrite, %AutoFishEnabled%, %IniFile%, Settings, AutoFish
    IniWrite, %MerchantEnabled%, %IniFile%, Settings, Merchant

    IsRunning := true
    MacroStartTime := A_TickCount
    prevBiome := "None"
    prevState := "None"
    prevMerchant := ""
    
    SendStartStatusAlert()

    GuiControl, +c0x2ECC71, txtStatus
    SetTimer, CheckBiomeTask, 1000
    SetTimer, UpdateGuiTimer, 1000
    
    if (AntiAfkEnabled) {
        SetTimer, AntiAfkTask, 2000
    }
    if (AutoFishEnabled) {
        SetTimer, AutoFishTask, 30
    }
    if (MerchantEnabled) {
        if WinExist("ahk_exe RobloxPlayerBeta.exe") {
            WinActivate, ahk_exe RobloxPlayerBeta.exe
            Sleep, 300
            Send, {F11}
            Sleep, 500
            Send, /
            Sleep, 300
            MouseMove, 250, 180, 2
        }
        SetTimer, MerchantTask, 1000
    }
return

StopMacro:
StopManage:
    GuiControlGet, hBtn, Hwnd, BtnStop
    AnimateButton(hBtn)
    Gui, Submit, NoHide
    
    if (!IsRunning) {
        return
    }

    SetTimer, CheckBiomeTask, Off
    SetTimer, UpdateGuiTimer, Off
    SetTimer, AntiAfkTask, Off
    SetTimer, AutoFishTask, Off
    SetTimer, MerchantTask, Off
    IsRunning := false

    if (WebhookURL != "" && InStr(WebhookURL, "discord.com/api/webhooks/") > 0) {
        SendStopStatusAlert("User Stopped")
    }

    MacroStartTime := 0
    GuiControl, +c0xE74C3C, txtStatus
    GuiControl,, txtStatus, Status: Stopped.
return

TestWebhook:
    GuiControlGet, hBtn, Hwnd, BtnTest
    AnimateButton(hBtn)
    Gui, Submit, NoHide
    WebhookURL    := txtWebhook
    PSLink        := txtPSLink

    if (WebhookURL = "" || InStr(WebhookURL, "discord.com/api/webhooks/") == 0) {
        MsgBox, 48, MLG21 Macro Warning, Please enter a valid Discord Webhook URL first!
        return
    }

    SendTestAlert("Webhook Successfully Tested", 65535)
return

; ==============================================================================
; GUI TIMER & DURATION FORMATTER
; ==============================================================================
UpdateGuiTimer:
    if (!IsRunning || !MacroStartTime)
        return

    elapsedSec := Floor((A_TickCount - MacroStartTime) / 1000)
    days := Floor(elapsedSec / 86400)
    hours := Floor(Mod(elapsedSec, 86400) / 3600)
    minutes := Floor(Mod(elapsedSec, 3600) / 60)
    seconds := Mod(elapsedSec, 60)

    timeStr := ""
    if (days > 0)
        timeStr := days . "d " . hours . "h " . minutes . "m " . seconds . "s"
    else if (hours > 0)
        timeStr := hours . "h " . minutes . "m " . seconds . "s"
    else if (minutes > 0)
        timeStr := minutes . "m " . seconds . "s"
    else
        timeStr := seconds . "s"

    GuiControl,, txtStatus, Status: Running [%timeStr%]
return

GetFormattedCurrentTime() {
    FormatTime, outTime,, yyyy-MM-dd HH:mm:ss
    return outTime
}

GetISOTimeStamp() {
    return SubStr(A_NowUTC,1,4) . "-" . SubStr(A_NowUTC,5,2) . "-" . SubStr(A_NowUTC,7,2) . "T" . SubStr(A_NowUTC,9,2) . ":" . SubStr(A_NowUTC,11,2) . ":" . SubStr(A_NowUTC,13,2) . ".000Z"
}

GetElapsedTimeFormatted() {
    if (!MacroStartTime)
        return "0s"
    
    elapsedSec := Floor((A_TickCount - MacroStartTime) / 1000)
    days := Floor(elapsedSec / 86400)
    hours := Floor(Mod(elapsedSec, 86400) / 3600)
    minutes := Floor(Mod(elapsedSec, 3600) / 60)
    seconds := Mod(elapsedSec, 60)

    timeStr := ""
    if (days > 0)
        timeStr := days . "d " . hours . "h " . minutes . "m " . seconds . "s"
    else if (hours > 0)
        timeStr := hours . "h " . minutes . "m " . seconds . "s"
    else if (minutes > 0)
        timeStr := minutes . "m " . seconds . "s"
    else
        timeStr := seconds . "s"
    
    return timeStr
}

; ==============================================================================
; WEBHOOK SENDER FUNCTIONS
; ==============================================================================
SendTestAlert(titleText, embedColor) {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("POST", WebhookURL, false)
    req.setRequestHeader("Content-Type", "application/json")
    currentTime := GetFormattedCurrentTime()

    payload =
    (
    {
      "embeds": [
        {
          "author": {
            "name": "mlg21macro v1.2 by tungvietmlg"
          },
          "title": "%titleText%",
          "color": %embedColor%,
          "description": "Private Server Link:\n%PSLink%",
          "fields": [
            {"name": "glitchhunter367: https://discord.gg/pzZxAdkYdE", "value": "%currentTime%", "inline": false}
          ]
        }
      ]
    }
    )
    try {
        req.send(payload)
    } catch e {
    }
}

SendStartStatusAlert() {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("POST", WebhookURL, false)
    req.setRequestHeader("Content-Type", "application/json")
    currentTime := GetFormattedCurrentTime()

    payload =
    (
    {
      "content": "MLG21 BIOME MACRO STARTED!(v1.2)",
      "embeds": [
        {
          "author": {
            "name": "mlg21macro v1.2 by tungvietmlg"
          },
          "title": "Macro Status: Active",
          "color": 65280,
          "fields": [
            {"name": "glitchhunter367: https://discord.gg/pzZxAdkYdE", "value": "%currentTime%", "inline": false}
          ]
        }
      ]
    }
    )
    try {
        req.send(payload)
    } catch e {
    }
}

SendStopStatusAlert(reason := "Stopped") {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("POST", WebhookURL, false)
    req.setRequestHeader("Content-Type", "application/json")
    currentTime := GetFormattedCurrentTime()
    totalTimeRan := GetElapsedTimeFormatted()

    payload =
    (
    {
      "content": "MLG21 BIOME MACRO STOPPED!",
      "embeds": [
        {
          "author": {
            "name": "mlg21macro v1.2 by tungvietmlg"
          },
          "title": "Macro Status: Inactive",
          "color": 16711680,
          "fields": [
            {"name": "Total Uptime", "value": "%totalTimeRan%", "inline": false},
            {"name": "Reason", "value": "%reason%", "inline": false},
            {"name": "glitchhunter367: https://discord.gg/pzZxAdkYdE", "value": "%currentTime%", "inline": false}
          ]
        }
      ]
    }
    )
    try {
        req.send(payload)
    } catch e {
    }
}

ProcessExist(Name) {
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
        if (process.Name = Name)
            return true
    return false
}

; ==============================================================================
; ANTI-AFK TASK (Auto click left mouse every 2s)
; ==============================================================================
AntiAfkTask:
    if (!IsRunning || !AntiAfkEnabled) {
        SetTimer, AntiAfkTask, Off
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe"))
        return

    if (IsRunning && AntiAfkEnabled) {
        Click, Left
    }
return

; ==============================================================================
; AUTO FISHING MINI-GAME TASK
; ==============================================================================
AutoFishTask:
    if (!IsRunning || !AutoFishEnabled) {
        SetTimer, AutoFishTask, Off
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe"))
        return

    PixelSearch, xCloseX, xCloseY, 450, 380, 830, 520, 0xFF0000, 20, Fast
    if (ErrorLevel = 0 && IsRunning) {        
        MouseClick, Left, xCloseX, xCloseY        
        Sleep, 500
        return
    }

    PixelSearch, fishBtnX, fishBtnY, 450, 480, 830, 620, 0x1E824C, 15, Fast
    if (ErrorLevel = 0 && IsRunning) {        
        MouseClick, Left, fishBtnX, fishBtnY        
        Sleep, 800
        return
    }

    PixelSearch, mgX, mgY, 350, 600, 930, 700, 0xFFFFFF, 25, Fast
    if (ErrorLevel = 0 && IsRunning) {        
        MouseClick, Left        
        Sleep, 20
    }
return

; ==============================================================================
; MERCHANT NOTIFICATION TASK (Dual Log Reader + Screen Capture & Discord Multipart Sender)
; ==============================================================================
MerchantTask:
    if (!IsRunning || !MerchantEnabled) {
        SetTimer, MerchantTask, Off
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe"))
        return

    logDir := LocalAppData "\Roblox\logs"
    newestTime := 0
    newestFile := ""

    Loop, Files, %logDir%\*.log, F
    {
        if (A_LoopFileTimeModified > newestTime) {
            newestTime := A_LoopFileTimeModified
            newestFile := A_LoopFileFullPath
        }
    }

    if !newestFile
        return

    file := FileOpen(newestFile, "r")
    if !IsObject(file)
        return

    size := file.Length
    chunkSize := 20480
    if (size > chunkSize)
        file.Seek(-chunkSize, 2)
    contentFile := file.Read()
    file.Close()

    lines := StrSplit(contentFile, "`n")
    merchantName := ""

    Loop % lines.MaxIndex()
    {
        line := lines[lines.MaxIndex() - A_Index + 1]
        if InStr(line, "[Merchant]:") {
            if InStr(line, "Mari") {
                merchantName := "Mari"
                break
            } else if InStr(line, "Rin") {
                merchantName := "Rin"
                break
            } else if InStr(line, "Jester") {
                merchantName := "Jester"
                break
            }
        }
    }

    if (merchantName && merchantName != "" && merchantName != prevMerchant && IsRunning) {
        prevMerchant := merchantName
        currentTimeStr := GetFormattedCurrentTime()
        isoTime := GetISOTimeStamp()

        ; Kích hoạt cửa sổ game Roblox
        WinActivate, ahk_exe RobloxPlayerBeta.exe
        Sleep, 300

        ; Chụp màn hình và lưu thành file ảnh
        imgPath := A_ScriptDir . "\merchant_screenshot.png"
        if FileExist(imgPath)
            FileDelete, %imgPath%

        ; Dùng PowerShell chụp màn hình cửa sổ Roblox và lưu ra file png
        psScript =
        (
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        \$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        \$bitmap = New-Object System.Drawing.Bitmap \$screen.Width, \$screen.Height
        \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
        \$graphics.CopyFromScreen(\$screen.Location, [System.Drawing.Point]::Empty, \$screen.Size)
        \$bitmap.Save('%imgPath%', [System.Drawing.Imaging.ImageFormat]::Png)
        \$graphics.Dispose()
        \$bitmap.Dispose()
        )
        fileObj := FileOpen(A_ScriptDir . "\capt.ps1", "w", "UTF-8")
        fileObj.Write(psScript)
        fileObj.Close()

        RunWait, PowerShell -ExecutionPolicy Bypass -File "%A_ScriptDir%\capt.ps1",, Hide
        Sleep, 400
        FileDelete, %A_ScriptDir%\capt.ps1

        ; Gửi Webhook kèm file ảnh qua PowerShell (Cơ chế Multipart FormData chuẩn Discord)
        jsonPayload := "{""content"":""A Merchant has arrived!"",""embeds"":[{""author"":{""name"":""mlg21macro v1.2 by tungvietmlg""},""title"":""Merchant Arrived: " . merchantName . """,""description"":""> ### [Merchant]: " . merchantName . " has arrived on the island!\n> ### [Join Server](" . PSLink . ")"",""color"":16753920,""image"":{""url"":""attachment://merchant_screenshot.png""},""fields"":[{""name"":""glitchhunter367: https://discord.gg/pzZxAdkYdE"",""value"":""" . currentTimeStr . """,""inline"":false}],""timestamp"":""" . isoTime . """}]}"

        psWebhookScript =
        (
        \$WebhookURL = "%WebhookURL%"
        \$ImagePath = "%imgPath%"
        \$PayloadJson = '%jsonPayload%'

        try {
            \$form = @{
                payload_json = \$PayloadJson
                file = Get-Item \$ImagePath
            }
            Invoke-RestMethod -Uri \$WebhookURL -Method Post -Form \$form
        } catch {
        }
        )

        fileObj2 := FileOpen(A_ScriptDir . "\sendweb.ps1", "w", "UTF-8")
        fileObj2.Write(psWebhookScript)
        fileObj2.Close()

        RunWait, PowerShell -ExecutionPolicy Bypass -File "%A_ScriptDir%\sendweb.ps1",, Hide
        Sleep, 500
        FileDelete, %A_ScriptDir%\sendweb.ps1
    }
return

; ==============================================================================
; LOG FILE READER TASK (Biome & Aura Checker)
; ==============================================================================
CheckBiomeTask:
    if (!IsRunning) {
        SetTimer, CheckBiomeTask, Off
        return
    }

    if (!ProcessExist("RobloxPlayerBeta.exe")) {
        return
    }
    
    logDir := LocalAppData "\Roblox\logs"
    newestTime := 0
    newestFile := ""

    Loop, Files, %logDir%\*.log, F
    {
        if (A_LoopFileTimeModified > newestTime) {
            newestTime := A_LoopFileTimeModified
            newestFile := A_LoopFileFullPath
        }
    }

    if !newestFile
        return

    file := FileOpen(newestFile, "r")
    if !IsObject(file)
        return

    size := file.Length
    chunkSize := 10240
    if (size > chunkSize)
        file.Seek(-chunkSize, 2)
    contentFile := file.Read()
    file.Close()

    lines := StrSplit(contentFile, "`n")
    regexLine := """state"":""((?:\\.|[^""])*)"".*?""largeImage"":\{""hoverText"":""((?:\\.|[^""])*)"""
    
    state := ""
    biome := ""
    
    Loop % lines.MaxIndex()
    {
        line := lines[lines.MaxIndex() - A_Index + 1]
        if InStr(line, "[BloxstrapRPC]")
        {
            if RegExMatch(line, regexLine, m) {
                state := m1
                biome := m2
                break
            }
        }
    }

    ; -- BIOME CHECKING --
    if (biome && biome != "" && biome != prevBiome && IsRunning)
    {
        biomeKey := "Biome" StrReplace(biome, " ", "")
        IniRead, isBiomeEnabled, %iniFilePath%, "Biomes", %biomeKey%, 1

        if (isBiomeEnabled = 1 || biome = "GLITCHED" || biome = "DREAMSPACE" || biome = "CYBERSPACE") {
            prevBiome := biome
            biome_url := StrReplace(biome, " ", "_")
            thumbnail_url := "https://purestellenium.github.io/biome_thumb/" biome_url ".png"

            color := biomeColors.HasKey(biome) ? biomeColors[biome] : 16777215
            currentTimeStr := GetFormattedCurrentTime()
            isoTime := GetISOTimeStamp()

            if (biome = "GLITCHED" || biome = "DREAMSPACE" || biome = "CYBERSPACE") {
                contentMsg := "@everyone"
            } else {
                contentMsg := "(tungvietmlg) For Any Bug!"
            }

            json =
            (
            {
              "embeds": [
                {
                  "author": {
                    "name": "mlg21macro v1.2 by tungvietmlg"
                  },
                  "description": "> ### Biome Started: %biome%\n> ### [Join Server](%PSLink%)",
                  "color": %color%,
                  "thumbnail": {"url": "%thumbnail_url%"},
                  "fields": [
                    {"name": "glitchhunter367: https://discord.gg/pzZxAdkYdE", "value": "%currentTimeStr%", "inline": false}
                  ],
                  "timestamp": "%isoTime%"
                }
              ],
              "content": "%contentMsg%"
            }
            )

            http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            http.Open("POST", WebhookURL, false)
            http.SetRequestHeader("Content-Type", "application/json")
            http.Send(json)
        }
    }

    ; -- AURA CHECKING --
    if (state && state != "In Main Menu" && state != "Equipped _None_" && state != "" && state != prevState && IsRunning)
    {
        if (prevState != "None") {
            needle := Chr(92) Chr(34)
            pos1 := InStr(state, needle)
            auraName := (pos1 ? (pos2 := InStr(state, needle, false, pos1 + StrLen(needle))) && pos2>pos1 ? SubStr(state, pos1 + StrLen(needle), pos2 - (pos1 + StrLen(needle))) : state : state)
            currentTimeStr := GetFormattedCurrentTime()
            isoTime := GetISOTimeStamp()

            json =
            (
            {
              "embeds": [
                {
                  "author": {
                    "name": "mlg21macro v1.2 by tungvietmlg"
                  },
                  "description": "> ### Aura Equipped: %auraName%\n> ### [Join Server](%PSLink%)",
                  "color": 16777215,
                  "fields": [
                    {"name": "glitchhunter367: https://discord.gg/pzZxAdkYdE", "value": "%currentTimeStr%", "inline": false}
                  ],
                  "timestamp": "%isoTime%"
                }
              ],
              "content": ""
            }
            )

            http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            http.Open("POST", WebhookURL, false)
            http.SetRequestHeader("Content-Type", "application/json")
            http.Send(json)
        }
        prevState := state
    }
return