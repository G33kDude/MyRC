#Include %A_LineFile%\..\..\Plugin.ahk

Url := (Channel = "#ahk" ? "http://ahk.us.to/" : "http://ahk.uk.to/")
Chat(Channel, "Please use the unofficial AutoHotkey pastebin to share code: " Url)
ExitApp