#Include %A_LineFile%\..\..\Plugin.ahk

ahk := ComObjCreate("AutoHotkey.Script.ANSISANDBOX")
ahk.ahktextdll()
Script := Plugin.Param
StringReplace, Script, Script, `;, `n, All
ahk.addScript("x(p1="",p2="",p3="",p4="",p5="",p6=""){`n" Script "`n}")
Out := ahk.ahkFunction("x")
for each, Line in StrSplit(Out, "`n", "`r")
{
	Chat(Channel, Line)
	Sleep, 1000
}
ExitApp