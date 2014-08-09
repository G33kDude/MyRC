#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

b := Chr(2), c := Chr(3), n := Chr(15), u := Chr(31)

Moves := ["(>^_^)>"
, "<(^_^<)"
, "^(^_^)^"
, "v(^_^)v"
, "<(^_^<)"
, "(>^_^)>"
, "^(^_^)>"
, "<(^_^)^"]

Loop, % Moves.MaxIndex()
{
	Out .= c . Rand(2, 13)
	Out .= Moves.Remove(Rand(1, Moves.MaxIndex())) " "
}
if !Rand(0, 9) ; 1 in 10
{
	Out .= c . Rand(2, 13) "SUPER "
	Out .= c . Rand(2, 13) "HAPPY "
	Out .= c . Rand(2, 13) "FUN "
}
Out .= n . b ":D"

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Out)
ExitApp
return

Rand(Min, Max)
{
	Random, Rand, Min, Max
	return Rand
}

#Include %A_LineFile%\..\..\IRCBot.ahk