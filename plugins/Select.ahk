#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Select [item] [item] [item]...
	Desc: Randomly selects an item from a given list
*/

Options := StrSplit(Plugin.Param, " ")
Random, Rand, 1, Options.MaxIndex()
Chat(Channel, "Your selected item: " Options[Rand])
ExitApp