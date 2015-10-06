#Include %A_LineFile%\..\..\Plugin.ahk

Script := StrReplace(Plugin.Params.Remove(1), ";", "`n")
if !InStr(Script, "return")
	Script := "return," Script
Script = x(p1="",p2="",p3="",p4="",p5="",p6=""){`n%Script%`n}

ahk := ComObjCreate("AutoHotkey.Script.ANSISANDBOX")
ahk.ahktextdll()
ahk.addFile("SandboxLibrary.ahk")
ahk.addScript(Script)

Out := ahk.ahkFunction("x", Plugin.Params*)
if (Out ~= "\R" || StrLen(Out) > 100)
	Ahkbin(Out, "GeekBot", "Sandbox", Channel)
else
	Chat(Channel, PRIVMSG.Nick ": " Out)
ExitApp

Ahkbin(Content, Name="", Desc="", Channel="")
{
	static URL := "http://p.ahkscript.org/"
	Form := "code=" UriEncode(Content)
	if Name
		Form .= "&name=" UriEncode(Name)
	if Desc
		Form .= "&desc=" UriEncode(Desc)
	if Channel
		Form .= "&announce=on&channel=" UriEncode(Channel)
	
	Pbin := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	Pbin.Open("POST", URL, False)
	Pbin.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	Pbin.Send(Form)
	; return Pbin.Option(1) ; Doesn't work in WINE
}