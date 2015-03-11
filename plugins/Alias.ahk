#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Alias [Alias]
	Desc: Lists alias information
*/

if Settings.Aliases.HasKey(Plugin.Param)
	Out := Plugin.Param " = " Settings.Aliases[Plugin.Param]
else
{
	for Alias in Settings.Aliases
		Out .= ", " Alias
	Out := SubStr(Out, 3)
}
Chat(Channel, Out)
ExitApp