#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: NewPost [MaxEntries]
	Desc: Desc: Gets the last couple entries from the AHKScript forum. MaxEntries to return defaults to 4, and is limited to 8.
*/

MaxEntries := Plugin.Param
Feed := "http://ahkscript.org/boards/feed.php"
UserAgent := "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0"

; Trim out some fluff that breaks wine compatiblity, as well as remove the irrelevant error messages at the end of the feed
; I can use such an "unsafe" regex because user inputted < and > are escaped as &lt; and &gt;
Rss := RegExReplace(GetRss(Feed, UserAgent), "s)<feed[^>]*>(.*)</feed>.*$", "<feed>$1</feed>")

xml := ComObjCreate("MSXML2.DOMDocument")
xml.loadXML(Rss)
if !entries := xml.selectNodes("/feed/entry")
	ExitApp ; Malformed xml

if !InStr(FileExist("temp"), "D")
	FileCreateDir, temp

Previous := []
for each, Url in StrSplit(FileOpen("temp\prevrss.txt", "r").Read(), "`n", "`r")
	Previous[Url] := True

if PRIVMSG ; Is chat command
{
	if (MaxEntries < 1 || MaxEntries > 8 || !MaxEntries) ; Strings are greater than integers
		MaxEntries := 4
	Loop, % MaxEntries
	{
		if !(entry := entries.item[A_Index-1])
			Break ; Shouldn't ever happen
		Title := HtmlDecode(entry.selectSingleNode("title").text)
		Author := entry.selectSingleNode("author/name").text
		Url := Shorten(entry.selectSingleNode("link/@href").text)
		Out .= Author " - " Title " - " Url "`n"
	}
}
else ; Was run automatically
{
	While (entry := entries.item[A_Index-1])
	{
		if !Previous[Url := entry.selectSingleNode("link/@href").text]
		{
			Title := HtmlDecode(entry.selectSingleNode("title").text)
			Author := entry.selectSingleNode("author/name").text
			Url := Shorten(Url)
			Out := Author " - " Title " - " Url "`n" Out
		}
	}
}

While entry := entries.item[A_Index-1]
	Previous[entry.selectSingleNode("link/@href").text] := True

Write := ""
for Url in Previous
	Write .= "`r`n" Url
FileOpen("temp\prevrss.txt", "w").Write(SubStr(Write, 3))

if Out
	Chat(Channel, Out)
else if PRIVMSG
	Chat(Channel, "No posts")
ExitApp

GetRss(Feed, UserAgent="")
{
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.open("GET", Feed, False)
	if UserAgent
		http.setRequestHeader("User-Agent", UserAgent)
	http.send()
	return http.responseText
}