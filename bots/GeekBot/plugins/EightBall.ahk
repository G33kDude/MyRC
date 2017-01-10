#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: EightBall <Question>
	Desc: Answers questions about users, bugs, documentation, and more!
*/

Eightball := StrSplit(Settings.EightBall, ",")
Sum := 0
for each, Char in StrSplit(PRIVMSG.Nick . Plugin.Param)
	Sum += Asc(Char)
Sum := Mod(Sum, EightBall.MaxIndex()) + 1
Chat(Channel, EightBall[Sum])
;Chat(Channel, EightBall[Rand(1, EightBall.MaxIndex())])
ExitApp