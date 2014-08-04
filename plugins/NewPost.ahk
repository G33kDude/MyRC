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
if (MaxEntries < 1 || MaxEntries > 8 || !MaxEntries) ; Strings are greater than integers
	MaxEntries := 4

Feed := "http://ahkscript.org/boards/feed.php"
UA := "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0"

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.Open("GET", Feed, False)
http.setRequestHeader("User-Agent", UA)
http.Send()

; Trim out some fluff that breaks wine compatiblity
Rss := RegExReplace(http.responseText, "s)<feed[^>]*>(.*)</feed>.*$", "<feed>$1</feed>")

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

/*
	NewNique(Max=4)
	{
		Max := Floor(Max)
		if (Max < -7 || Max > 7 || !Max)
			Max := 4
		
		Posts := GetPosts(Max > 0 ? 16 : -16)
		if !IsObject(Posts)
			return Posts
		
		if (Cached := (A_TickCount-Posts.Remove(1)) // 1000)
			Out := "Information is " Cached " seconds old (use negative to force refresh)`n"
		
		Max := Abs(Max), i := 0
		for each, Post in Posts
		{
			if InStr(Post.Title, " • Re: ")
				continue
			if (++i >= Max)
				Break
			Out .= Post.Author " - " Post.Title " - " Post.Url "`n"
		}
		
		return Out ? Out : "No new posts"
	}
*/
