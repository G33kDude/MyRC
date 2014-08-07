#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

b := Chr(2), c := Chr(3), n := Chr(15), u := Chr(31)
Out =
( JOIN
%c%2(>^_^)>%A_Space%
%c%3<(^_^<)%A_Space%
%c%4^(^_^)^%A_Space%
%c%5v(^_^)v%A_Space%
%c%6<(^_^<)%A_Space%
%c%7(>^_^)>%A_Space%
%c%8^(^_^)>%A_Space%
%c%9<(^_^)^%A_Space%
%n%%b%:D
)

Random, Rand, 0, 10
if !Rand
	Out .= " " c "3SUPER " c "4HAPPY " c "11FUN"

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Out)
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk