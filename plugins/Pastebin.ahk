#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Pastebin
	Desc: Links to the integrated pastebin.
*/

Url := (Channel = "#ahk" ? "http://ahk.us.to/" : "http://ahk.uk.to/")
Chat(Channel, "Please share your code on the unofficial AutoHotkey pastebin: " Url)
ExitApp