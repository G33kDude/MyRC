#Include %A_LineFile%\..\..\Plugin.ahk

ahk := ComObjCreate("AutoHotkey.Script.ANSISANDBOX")
ahk.ahktextdll()
ahk.addFile("SandboxLibrary.ahk")

Script := Plugin.Params.Remove(1)
StringReplace, Script, Script, `;, `n, All
if !InStr(Script, "return")
	Script := "return," Script
Script = x(p1="",p2="",p3="",p4="",p5="",p6=""){`n%Script%`n}
ahk.addScript(Script)

if Plugin.Params.MaxIndex()
	Out := ahk.ahkFunction("x", Plugin.Params*)
else
	Out := ahk.ahkFunction("x")
	
if (Out == "")
	Chat(Channel, " ")
else
{
	for each, Line in StrSplit(Out, "`n", "`r")
	{
		Chat(Channel, Line == "" ? " " : Line)
		Sleep, 200
	}
}
ExitApp
