#Include %A_ScriptDir%\..\..\lib\Jxon.ahk

/*
	Generates Docs.json
	First use an archive software such as 7zip to extract Index.hhk from AutoHotkey.chm
	Then run this script and select Index.hhk, and the file to export to (Docs.json)
*/

FileSelectFile, IndexFile, 3,, Select the extracted Index.hhk file.
if ErrorLevel
	ExitApp
FileSelectFile, DocsFile, S, %A_ScriptDir%\Docs.json, Select the JSON file to export to.
if ErrorLevel
	ExitApp

html := ComObjCreate("htmlfile")
html.write(FileOpen(IndexFile, "r").Read())

Docs := []
entries := html.body.children[0].children
Loop, % entries.length
{
	children := entries.item(A_Index-1).children[0].children
	Params := []
	loop, % children.length
	{
		child := children.item(A_Index-1)
		Params[child.getAttribute("name")] := child.getAttribute("value")
	}
	Docs[params.Name] := params.Local
}

FileOpen(DocsFile, "w").Write(Jxon_Dump(Docs, "`t"))

MsgBox, Exported
ExitApp
return
