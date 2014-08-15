#Include %A_LineFile%\..\..\Plugin.ahk

Eightball := StrSplit(Settings.EightBall, ",")
Chat(Channel, EightBall[Rand(1, EightBall.MaxIndex())])
ExitApp