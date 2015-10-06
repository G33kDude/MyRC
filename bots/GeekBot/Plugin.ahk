#NoEnv
#Persistent
#NoTrayIcon
#SingleInstance, Off
SetWorkingDir, %A_LineFile%\..
SetBatchLines, -1
#Include %A_LineFile%\..\lib
#Include Socket.ahk
#Include Json.ahk
#Include Utils.ahk

Json = %1%
for Var, Value in Json_ToObj(Json)
	%Var% := Value

Settings := Ini_Read("Settings.ini")
if (Settings.Bitly.login)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

Chat(Channel, Text)
{
	IRC.Chat(Channel, Text)
}

class IRC
{
	static _ := IRC := new IRC() ; Automatically initialize base object
	__Call(Name, Params*)
	{
		TCP := new SocketTCP()
		TCP.Connect("localhost", 26656)
		TCP.SendText(Json_FromObj({MethodName: Name, Params: Params}))
		return Json_ToObj(TCP.recvText()).return
	}
}