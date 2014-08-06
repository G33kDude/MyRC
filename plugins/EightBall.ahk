#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

Eightball := StrSplit(Ini_Read("Settings.ini").EightBall, ",")

Random, Rand, 1, % EightBall.MaxIndex()

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," EightBall[Rand])
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk