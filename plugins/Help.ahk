#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

Commands := Ini_Read("Help.ini")
Command := Params[2]
if !Commands.HasKey(Command)
	Command := "Help"

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] ",Usage: " Commands[Command].Usage "`n" Commands[Command].Desc)
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk