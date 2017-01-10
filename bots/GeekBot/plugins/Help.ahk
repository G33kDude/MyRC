#Include %A_LineFile%\..\..\Plugin.ahk
/*
	RuntimeError: maximum recursion depth exceeded
*/

IncludeRE := RegExEscape("#Include %A_LineFile%\..\..\Plugin.ahk")
PlugRE := "is)^" IncludeRE "\R\s*(?:\/\*\s*(?P<Desc>.*?)\s*\*\/)"

; Remove invalid plugin name characters
PlugName := RegExReplace(Plugin.Param, "[^A-Za-z0-9]")

if (PlugName && FileExist("plugins\" PlugName ".ahk"))
{
	; Has plugin formatting
	FileRead, PlugFile, plugins\%PlugName%.ahk
	if RegexMatch(PlugFile, PlugRE, Match)
	{
		Desc := RegExReplace(MatchDesc, "`am)^\s+", "") ; Trim leading whitespace
		Chat(Channel, Desc)
		ExitApp
	}
}

Loop, plugins\*.*
{
	; Not a valid plugin name
	if !RegExMatch(A_LoopFileName, "^(?P<Name>[A-Za-z0-9]+)\.ahk$", Match)
		Continue
	
	; Has plugin formatting
	FileRead, PlugFile, %A_LoopFileFullPath%
	If RegExMatch(PlugFile, PlugRE)
		Plugins .= ", " MatchName
}
Plugins := SubStr(Plugins, 3)
Chat(Channel, "Usage: Help [Command]`nAvailable commands: " Plugins)
ExitApp