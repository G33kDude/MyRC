#Persistent
#NoTrayIcon
#SingleInstance, off
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] ",The latest installer can be found at http://ahkscript.org/download/ahk-install.exe")
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk