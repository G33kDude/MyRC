#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

Settings := Ini_Read("Settings.ini")
if (Settings.Bitly)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

MaxEntries := Params[2]
if (MaxEntries < 1 || MaxEntries > 8) ; Strings are greater than integers
	MaxEntries := 4

Feed := "http://ahkscript.org/boards/feed.php"
UA := "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0"

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.Open("GET", Feed, False)
http.setRequestHeader("User-Agent", UA)
http.Send()
Rss := RegExReplace(http.responseText, "s)<feed[^>]*>(.*)</feed>.*$", "<feed>$1</feed>")

; Load XML
xml:=ComObjCreate("MSXML2.DOMDocument")
xml.loadXML(Rss)
if !entries := xml.selectnodes("/feed/entry")
	ExitApp ; Malformed xml

While (A_Index <= MaxEntries && entry := entries.item[A_Index-1])
{
	Title := HtmlDecode(entry.selectSingleNode("title").text)
	Author := entry.selectSingleNode("author/name").text
	Url := Shorten(entry.selectSingleNode("link/@href").text)
	
	Out .= Author " - " Title " - " Url "`n"
}

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Out)
ExitApp
return

#Include %A_LineFile%\..\..\IRCBot.ahk