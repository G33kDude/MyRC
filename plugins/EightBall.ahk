#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: EightBall <Question>
	Desc: Answers questions about users, bugs, documentation, and more!
*/

Eightball := StrSplit(Settings.EightBall, ",")
Chat(Channel, EightBall[Rand(1, EightBall.MaxIndex())])
ExitApp