#Include %A_LineFile%\..\..\Plugin.ahk

Options := StrSplit(Plugin.Param, " ")
Random, Rand, 1, Options.MaxIndex()
Chat(Channel, Options[Rand])
ExitApp