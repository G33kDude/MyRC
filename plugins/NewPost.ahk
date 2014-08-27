#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: NewPost [MaxEntries]
	Desc: Gets the last couple entries from the AHKScript forum. MaxEntries to return defaults to 4, and is limited to 8.
*/

MaxEntries := Plugin.Param
if (MaxEntries < 1 || MaxEntries > 8 || !MaxEntries) ; Strings are greater than integers
	MaxEntries := 4

Feed := "http://ahkscript.org/boards/feed.php"
UA := "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0"

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.open("GET", Feed, False)
http.setRequestHeader("User-Agent", UA)
http.send()

; Trim out some fluff that breaks wine compatiblity
Rss := RegExReplace(http.responseText, "s)<feed[^>]*>(.*)</feed>.*$", "<feed>$1</feed>")

xml := ComObjCreate("MSXML2.DOMDocument")
xml.loadXML(Rss)
if !entries := xml.selectNodes("/feed/entry")
	ExitApp ; Malformed xml

While (A_Index <= MaxEntries && entry := entries.item[A_Index-1])
{
	Title := HtmlDecode(entry.selectSingleNode("title").text)
	Author := entry.selectSingleNode("author/name").text
	Url := Shorten(entry.selectSingleNode("link/@href").text)
	
	Out .= Author " - " Title " - " Url "`n"
}

Chat(Channel, Out)
ExitApp