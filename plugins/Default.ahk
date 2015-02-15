﻿#Include %A_LineFile%\..\..\Plugin.ahk

for Alias, Repl in Settings.Aliases
{
	if (Plugin.Name = Alias)
	{
		if !RegExMatch(Repl " " Plugin.Param, "^(\S+)(?:\s+(.+?))?\s*$", Match)
			ExitApp
		Match1 := RegExReplace(Match1, "i)[^a-z0-9]")
		if FileExist("plugins\" Match1 ".ahk")
		{
			Param := Json_FromObj({"PRIVMSG": PRIVMSG, "Channel": Channel
			, "Plugin": {"Name": Plugin.Name, "Param": Match2}})
			
			Run(A_AhkPath, "plugins\" Match1 ".ahk", Param)
			ExitApp
		}
		else if (Match1 = "Say")
		{
			Chat(Channel, Match2)
			ExitApp
		}
	}
}

FileRead, Docs, Docs.json
Docs := Json_ToObj(Docs)

if Docs.HasKey(Plugin.Match)
{
	Key := GetKey(Docs, Plugin.Match)
	Chat(Channel, Key " - " Shorten("http://ahkscript.org/" Docs[Key]))
}
else
{
	Plugin.Name := "Search", Plugin.Param := "site:ahkscript.org/ OR site:autohotkey.com/board/ " Plugin.Match
	Run(A_AhkPath, "plugins\Search.ahk", Json_FromObj({"PRIVMSG":PRIVMSG,"Channel":Channel,"Plugin":Plugin}))
}
ExitApp

GetKey(Array, Key)
{
	for RealKey in Array
		if (RealKey = Key)
			return RealKey
}