#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Update
	Desc: Chats a link to the latest maintained AHK installer
*/

Installer := "http://ahkscript.org/download/ahk-install.exe"
VersionFile := "http://ahkscript.org/download/1.1/version.txt"

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.Open("GET", VersionFile, False)
http.Send()
Version := SubStr(http.ResponseText, 1, 12)

Chat(Channel, "The latest maintained stable AutoHotkey installer v" Version ": " Installer)
ExitApp