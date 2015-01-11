#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Pastebin
	Desc: Links to the integrated pastebin.
*/

if (Channel = "#ahk")
	Message := "Please share your code on the official AutoHotkey pastebin: http://ahk.us.to/"
else
	Message := "Please share your code on the unofficial AHKScript pastebin: http://ahk.uk.to/"

Chat(Channel, Message)
ExitApp