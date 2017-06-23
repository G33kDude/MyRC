#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Update
	Desc: Chats a link to the latest maintained AHK installer
*/

VersionFile := "https://api.github.com/repos/Lexikos/AutoHotkey_L/releases/latest"

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.Open("GET", VersionFile, False)
http.Send()
release := Jxon_Load(http.responseText)

Chat(Channel, "The latest maintained stable AutoHotkey installer "
. release.name ": " release.assets[1].browser_download_url)
ExitApp
