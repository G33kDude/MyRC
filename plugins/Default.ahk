#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

Settings := Ini_Read("Settings.ini")
if (Settings.Bitly)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

Channel := Params[1]
Msg := Params[2]
FileRead, Json, Docs.json
Docs := Json_ToObj(Json)

if (Docs.HasKey(Msg))
{
	TCP := new SocketTCP()
	TCP.Connect("localhost", 26656)
	TCP.SendText(Channel "," Msg " - " Shorten("http://ahkscript.org/" Docs[Msg]))
}
else
	Plugin("plugins\Search.ahk", Channel, "site:ahkscript.org OR site:autohotkey.com " Msg)
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk