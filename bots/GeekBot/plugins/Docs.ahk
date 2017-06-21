#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Docs <Page name>
	Desc: Finds a page in the documentation.
	
	Update: Changed matching function to Fuzzy() - https://autohotkey.com/boards/viewtopic.php?f=6&t=28677
*/

if !StrLen(Plugin.Param)
{
	Chat(Channel, "No results found")
	ExitApp
}

FileRead, Json, Docs.json
Docs := Jxon_Load(Json)
DocsList := []

For Name, Location in Docs
	DocsList[A_Index] := Name

Match := Fuzzy(Plugin.Param, DocsList)

if StrLen(Match.1) && StrLen(Docs[Match.1])
	Out := Match.1 " - " Shorten("http://ahkscript.org/" Docs[Match.1])
else
	Out := "No results found"

Chat(Channel, Out)
ExitApp

Fuzzy(input, arr) {
	arren:=[]
	input := StrReplace(input, " ", "")
	if !StrLen(input) ; input is empty, just return the array
		return arr
	for id, item in arr {
		taken:=[], needle:="i)", limit:=false
		name:=StrReplace(item, " ", "")
		Loop, Parse, input
			taken[A_LoopField] := (StrLen(taken[A_LoopField])?taken[A_LoopField]+1:1)
		for char, hits in taken {
			StrReplace(name, char, char, found)
			if (found<hits) {
				limit:=true
				break
			} needle .= "(?=.*\Q" char "\E)"
		} if RegExMatch(name, needle) && !limit
			arren.Insert(item)
	} for index, item in arren, i:=0 ; contains
		if InStr(item, input)
			arren.RemoveAt(index), arren.InsertAt(++i, item)
	for index, item in arren, outline := [] { ; get outlines based on spaces
		for num, word in StrSplit(item, " ") {
			outline[index] .= SubStr(word, 1, 1)
			continue
		}
	} for index, item in arren, i:=0 ; outline
		if InStr(RegExReplace(item, "[^A-Z0-9]"), input) || InStr(temp:=outline[index], input)
			arren.RemoveAt(index), arren.InsertAt(++i, item), outline.RemoveAt(index), outline.InsertAt(i, item)
	for index, item in arren, i:=0 ; word start (contains)
		if (SubStr(item, InStr(item, input) - 1, 1) = " ") && InStr(item, input)
			arren.RemoveAt(index), arren.InsertAt(++i, item)
	for index, item in arren, i:=0 ; word start
		if (InStr(item, input) = 1)
			arren.RemoveAt(index), arren.InsertAt(++i, item)
	for index, item in arren, i:=0 ; outline is equal to input
		if (outline[index] = input)
			arren.RemoveAt(index), arren.InsertAt(++i, item)
	for index, item in arren, i:=0 ; worst start and ONLY word
		if (InStr(item, input) = 1) && !InStr(item, " ")
			arren.RemoveAt(index), arren.InsertAt(++i, item)
	return arren
}
