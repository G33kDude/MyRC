#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Pastebin
	Desc: Links to the integrated pastebin.
*/

Url := (Channel = "#ahk" ? "http://ahk.us.to/" : "http://ahk.uk.to/")
Chat(Channel, "Please use the unofficial AutoHotkey pastebin to share code: " Url)
ExitApp