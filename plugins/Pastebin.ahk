#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

Url := (Params[1] = "#ahk" ? "http://ahk.us.to/" : "http://a.hk.am/")
Out := "Please use the unofficial AutoHotkey pastebin to share code: " Url

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Out)
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk