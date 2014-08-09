#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Zalgo(Params[2]))
ExitApp
return

Rand(Min, Max)
{
	Random, Rand, Min, Max
	return Rand
}

Zalgo(Text)
{
	Static Zalgo := []
	if !Zalgo.MaxIndex()
		for each, n in [0,6,43,44,67,12,13,18,19,31,32,33,58,71,72,73,74,75,77,35,34,76]
			Zalgo.Insert(Chr(n+789))
	
	for each, Char in StrSplit(Text)
	{
		Loop, % Rand(0, 3)
			Out .= Zalgo[Rand(1, Zalgo.MaxIndex())]
		Out .= Char
	}
	
	return Out
}

#Include %A_LineFile%\..\..\IRCBot.ahk