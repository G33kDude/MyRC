#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Chal <UserName>
	Desc: Grabs stats from ChalamiuS's site - http://www.chalamius.se/ircstats
*/

Chan := Channel = "#ahk" ? "ahk" : "ahkscript"
Url := "http://www.chalamius.se/ircstats/" Chan ".html"

if !(Nick := Plugin.Params[1])
{
	Chat(Channel, "Read more at " Url)
	ExitApp
}

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.Open("GET", Url, False)
http.Send()

html := ComObjCreate("htmlfile")
html.Write(http.responseText())
html.Close()

Map := []
elements := html.getElementsByTagName("tr")
Loop, 25
{
	element := elements.item(A_Index+12)
	children := element.children
	Map[element.children[1].innerText] := {Place: children.item(0).innerText
	, Lines: children.item(2).innerText
	, Words: children.item(4).innerText
	, WPL: children.item(5).innerText}
}

i := 26
Loop, 6
{
	element := elements.item(A_Index+12+25)
	children := element.children
	Loop, 5
		if RegExMatch(children.item(A_Index-1).innerText, "(\S+) \((\d+)\)", Match)
			Map[Match1] := {Place: i++, Lines: Match2}
}

if (Stats := Map[Nick])
{
	x := "Place: " Stats.Place
	. " - Lines: " Stats.Lines
	if Stats.Words
		x .= " - Words: " Stats.Words " - WPL: " Stats.WPL
	Chat(Channel, x " - " Nick)
}
else
	Chat(Channel, "That person is not in the top 55 - " Nick)
ExitApp
