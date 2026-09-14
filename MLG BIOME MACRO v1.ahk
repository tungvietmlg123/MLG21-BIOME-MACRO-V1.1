; <=======================================================================>
; SAVE INSTRUCTIONS: Open Notepad -> Paste code -> Click File > Save As 
; Select Encoding as "UTF-8 with BOM" and save your .ahk file!
; <=======================================================================>

#Requires AutoHotkey v1.1
#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Pixel, Screen

global IniFile        := A_ScriptDir . "\config.ini"
global iniFilePath    := A_ScriptDir . "\..\settings.ini"
global WebhookURL     := ""
global PSLink         := ""
global IsRunning      := false
global MacroStartTime := 0

global prevBiome := "None"
global prevState := "None"
global biomeColors := { "NORMAL":16777215, "SAND STORM":16040572, "HELL":6033945, "STARFALL":6784224, "CORRUPTION":9454335, "NULL":0, "GLITCHED":6684517, "WINDY":9566207, "SNOWY":12908022, "RAINY":4425215, "DREAMSPACE":16743935, "PUMPKIN MOON":13983497, "GRAVEYARD":16777215, "BLOOD RAIN":16711680, "CYBERSPACE":2904999, "EGGLAND":65535, "SINGULARITY":14716000, "INCINERATOR":16736031, "BLAZING SUN":16760650}

EnvGet, LocalAppData, LOCALAPPDATA

OnExit("ExitHandler")

IniRead, SavedWebhook, %IniFile%, Settings, WebhookURL, %A_Space%
IniRead, SavedPSLink, %IniFile%, Settings, PSLink, %A_Space%

if (SavedWebhook = "ERROR" || InStr(SavedWebhook, "http") = 0)
    SavedWebhook := ""
if (SavedPSLink = "ERROR" || InStr(SavedPSLink, "http") = 0)
    SavedPSLink := ""

; ==============================================================================
; USER INTERFACE (DARK MODE)
; ==============================================================================
Gui, Color, 0x0D0E12, 0x16181D
Gui, +Resize -MaximizeBox

Gui, Font, s15 Bold, Segoe UI
Gui, Add, Text, x20 y15 w410 h35 +Center c0x00FFC8, MLG21 BIOME MACRO V1.0

Gui, Font, s9 Bold, Segoe UI
Gui, Add, GroupBox, x20 y60 w410 h170 c0x3A3D4D, CONNECTION SETTINGS

Gui, Font, s9 Normal, Segoe UI
Gui, Add, Text, x35 y90 c0x9DA0A8, Webhook URL:
Gui, Add, Edit, x35 y107 w380 h26 vtxtWebhook c0xFFFFFF Background0x22242C, %SavedWebhook%

Gui, Add, Text, x35 y138 c0x9DA0A8, Private Server Link:
Gui, Add, Edit, x35 y155 w380 h26 vtxtPSLink c0xFFFFFF Background0x22242C, %SavedPSLink%

Gui, Font, s9 Bold, Segoe UI
Gui, Add, GroupBox, x20 y245 w410 h55 c0x3A3D4D, STATUS
Gui, Font, s9 Italic Bold, Segoe UI
Gui, Add, Text, x30 y268 w390 h22 vtxtStatus +Center c0xF1C40F, Status: Waiting to start...

Gui, Font, s9 Bold, Segoe UI
Gui, Add, Button, x20 y315 w130 h38 gTestWebhook c0xFFFFFF, Test Webhook
Gui, Add, Button, x160 y315 w130 h38 gStartMacro +Default c0x2ECC71, Start Macro
Gui, Add, Button, x300 y315 w130 h38 gStopMacro c0xE74C3C, Stop Macro

Gui, Show, w450 h375, MLG21 Biome Macro V1.0

SetTimer, CheckBiomeTask, Off
SetTimer, UpdateGuiTimer, Off
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
; CONTROL BUTTONS
; ==============================================================================
StartMacro:
    Gui, Submit, NoHide

    if (IsRunning) {
        MsgBox, 48, Notice, Macro is already running!
        return
    }

    WebhookURL    := txtWebhook
    PSLink        := txtPSLink

    if (WebhookURL = "" || InStr(WebhookURL, "discord.com/api/webhooks/") == 0) {
        MsgBox, 48, Warning, Please enter a valid Discord Webhook URL!
        return
    }

    IniWrite, %WebhookURL%, %IniFile%, Settings, WebhookURL
    IniWrite, %PSLink%, %IniFile%, Settings, PSLink

    IsRunning := true
    MacroStartTime := A_TickCount
    prevBiome := "None"
    prevState := "None"
    
    SendStartStatusAlert()

    GuiControl, +c0x2ECC71, txtStatus
    SetTimer, CheckBiomeTask, 1000
    SetTimer, UpdateGuiTimer, 1000
    MsgBox, 64, Success, Macro started successfully!
return

StopMacro:
    Gui, Submit, NoHide
    
    if (!IsRunning) {
        MsgBox, 64, Notice, Macro is not running!
        return
    }

    SetTimer, CheckBiomeTask, Off
    SetTimer, UpdateGuiTimer, Off
    IsRunning := false
    MacroStartTime := 0

    if (WebhookURL != "" && InStr(WebhookURL, "discord.com/api/webhooks/") > 0) {
        SendStopStatusAlert("User Stopped")
    }

    GuiControl, +c0xE74C3C, txtStatus
    GuiControl,, txtStatus, Status: Stopped.
    MsgBox, 48, Notice, Macro has been stopped!
return

TestWebhook:
    Gui, Submit, NoHide
    WebhookURL    := txtWebhook
    PSLink        := txtPSLink

    if (WebhookURL = "" || InStr(WebhookURL, "discord.com/api/webhooks/") == 0) {
        MsgBox, 48, Error, Please input Webhook URL before testing!
        return
    }

    SendTestAlert("Webhook Successfully Tested", 65535)
    MsgBox, 64, Success, Test notification sent to Webhook!
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
            "name": "tungvietmlg"
          },
          "title": "%titleText%",
          "color": %embedColor%,
          "description": "Private Server Link:\n%PSLink%",
          "fields": [
            {"name": "glisch hant: https://discord.gg/pzZxAdkYdE", "value": "%currentTime%", "inline": false}
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
      "content": "MLG21 BIOME MACRO STARTED!",
      "embeds": [
        {
          "author": {
            "name": "tungvietmlg"
          },
          "title": "Macro Status: Active",
          "color": 65280,
          "fields": [
            {"name": "glisch hant: https://discord.gg/pzZxAdkYdE", "value": "%currentTime%", "inline": false}
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

    payload =
    (
    {
      "content": "MLG21 BIOME MACRO STOPPED!",
      "embeds": [
        {
          "author": {
            "name": "tungvietmlg"
          },
          "title": "Macro Status: Inactive",
          "color": 16711680,
          "fields": [
            {"name": "glisch hant: https://discord.gg/pzZxAdkYdE", "value": "%currentTime%", "inline": false},
            {"name": "Reason", "value": "%reason%", "inline": false}
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
; LOG FILE READER TASK
; ==============================================================================
CheckBiomeTask:
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
    if (biome && biome != "" && biome != prevBiome)
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
                contentMsg := ""
            }

            json =
            (
            {
              "embeds": [
                {
                  "author": {
                    "name": "tungvietmlg"
                  },
                  "description": "> ### Biome Started: %biome%\n> ### [MLG21BIOMEMACRO - Join Server](%PSLink%)",
                  "color": %color%,
                  "thumbnail": {"url": "%thumbnail_url%"},
                  "fields": [
                    {"name": "glisch hant: https://discord.gg/pzZxAdkYdE", "value": "%currentTimeStr%", "inline": false}
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
    if (state && state != "In Main Menu" && state != "Equipped _None_" && state != "" && state != prevState)
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
                    "name": "tungvietmlg"
                  },
                  "description": "> ### Aura Equipped: %auraName%\n> ### [MLG21BIOMEMACRO - Join Server](%PSLink%)",
                  "color": 16777215,
                  "fields": [
                    {"name": "glisch hant: https://discord.gg/pzZxAdkYdE", "value": "%currentTimeStr%", "inline": false}
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