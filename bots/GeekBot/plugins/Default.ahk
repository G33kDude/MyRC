#Include %A_LineFile%\..\..\Plugin.ahk

for Alias, Repl in Settings.Aliases
{
	if (Plugin.Name = Alias)
	{
		if !RegExMatch(Repl, "^(\S+)(?:\s+(.+?))?\s*$", Match)
			ExitApp
		Match1 := RegExReplace(Match1, "i)[^a-z0-9]")
		if FileExist("plugins\" Match1 ".ahk")
		{
			if Match2
			{
				Plugin.Params.Insert(1, Match2)
				Plugin.Param := Match2 " " Plugin.Param
			}
			
			Param := Jxon_Dump({"PRIVMSG": PRIVMSG
			, "Channel": Channel
			, "Plugin": Plugin})
			
			Run(A_AhkPath, "plugins\" Match1 ".ahk", Param)
			ExitApp
		}
		else if (Match1 = "Say")
		{
			Chat(Channel, Match2 " " Plugin.Param)
			ExitApp
		}
	}
}

FileRead, Docs, Docs.json
Docs := Jxon_Load(Docs)

if Docs.HasKey(Plugin.Match)
{
	Key := GetKey(Docs, Plugin.Match)
	Chat(Channel, Key " - " Shorten("http://ahkscript.org/" Docs[Key]))
}
else
{
	Plugin.Name := "Search", Plugin.Param := "site:autohotkey.com/boards/ " Plugin.Match
	Run(A_AhkPath, "plugins\Search.ahk", Jxon_Dump({"PRIVMSG":PRIVMSG,"Channel":Channel,"Plugin":Plugin}))
}
ExitApp

GetKey(Array, Key)
{
	for RealKey in Array
		if (RealKey = Key)
			return RealKey
}
