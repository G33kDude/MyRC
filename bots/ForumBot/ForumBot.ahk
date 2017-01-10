#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%\..\..

#Include %A_ScriptDir%\..\..\lib
#Include IRCClass.ahk
#Include Socket.ahk
#Include Utils.ahk

UserAgent := "Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0"

Settings := Ini_Read(A_ScriptDir "\Settings.ini")
Server := Settings.Server

if (Settings.Bitly.login)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

MyBot := new IRCBot()
MyBot.Connect(Server.Addr, Server.Port, Server.Nick, Server.User,, Server.Pass)
MyBot.SendJOIN(Server.Chan)

GetNewPosts(Settings.Feed.Url, UserAgent, Settings.Feed.Blacklist)
SetTimer, Poll, % 1 * 60 * 1000
return

Poll:
Out := ""
for each, Post in GetNewPosts(Settings.Feed.Url, UserAgent, Settings.Feed.Blacklist)
	Out := Chr(3) "03" Post.Author " - " Post.Title " - " Shorten(Post.Url) "`n" Out
if Out
	MyBot.SendPRIVMSG(Server.Chan, Out)
return

class IRCBot extends IRC
{
	Log(Data)
	{
		Print(Data)
	}
}

Print(Params*)
{
	static _ := DllCall("AllocConsole")
	StdOut := FileOpen("*", "w")
	for each, Param in Params
		StdOut.Write(Param "`n")
}

GetRss(Feed, UserAgent="")
{
	try
	{
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.open("GET", Feed, False)
		if UserAgent
			http.setRequestHeader("User-Agent", UserAgent)
		http.send()
		return http.responseText
	}
	Catch
		return
}

GetNewPosts(Feed, UserAgent, Blacklist="")
{
	static Previous := []
	
	; Trim out some fluff that breaks wine compatiblity, as well as remove the irrelevant error messages at the end of the feed
	; I can use such an "unsafe" regex because user inputted < and > are escaped as &lt; and &gt;
	Rss := RegExReplace(GetRss(Feed, UserAgent), "s)<feed[^>]*>(.*)</feed>.*$", "<feed>$1</feed>")
	
	; Escape special characters before loading into the xml parser
	Loop, 31
		if A_Index not in 10,31 ; Skip newlines
			StringReplace, Rss, Rss, % Chr(A_Index), &#%A_Index%;, All
	
	xml := ComObjCreate("MSXML2.DOMDocument")
	xml.loadXML(Rss)
	if !entries := xml.selectNodes("/feed/entry")
		return ; Malformed xml
	
	NewPosts := []
	While (entry := entries.item[A_Index-1])
	{
		Url := entry.selectSingleNode("link/@href").text
		if !Previous[Url]
		{
			Title := HtmlDecode(entry.selectSingleNode("title").text)
			if Title contains %Blacklist%
				continue
			
			Author := entry.selectSingleNode("author/name").text
			
			Print([Author, Title, Url])
			NewPosts.Insert({Author: Author, Title: Title, Url: Url})
		}
	}
	
	for each, Post in NewPosts
		Previous[Post.Url] := True
	
	return NewPosts
}