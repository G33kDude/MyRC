#Include %A_LineFile%\..\..\lib
#Include Socket.ahk
#Include Utils.ahk
#Include IRCClass.ahk
; ComObjError(0)

SetWorkingDir, %A_LineFile%\..\..
MsgBox, % A_WorkingDir

Previous := []
for each, Url in StrSplit(FileOpen("temp\prevredditrss.txt", "r").Read(), "`n", "`r")
	Previous[Url] := True

PostFeed := "http://www.reddit.com/r/dailyprogrammer.rss"
CommentFeed := "http://www.reddit.com/r/dailyprogrammer/comments.rss"

Posts := DoRss(HttpRequest(PostFeed))
Comments := DoRss(HttpRequest(CommentFeed))

MyBot := new IRCBot()
MyBot.Connect("chat.freenode.net", 6667, "GeekDudesBot")
MyBot.SendJOIN("#reddit-dailyprogrammer")
OnExit, ExitSub
return

ExitSub:
ExitApp
return

class IRCBot extends IRC
{
	onJOIN(p*)
	{
		this.onPING(p*)
	}
	
	onPING(p*)
	{
		global Previous, PostFeed, CommentFeed
		
		cTitleRE := ["i)^(\S+).*#(\d+).*\[(Easy|Intermediate|Hard)\]", "$1 on #$2 [$3]:"]
		cUrlRE := ["^.*/([^/]+)/[^/]+/([^/]+)$", "http://reddit.com/comments/$1/-/$2?context=3"]
		
		Posts := DoRss(HttpRequest(PostFeed))
		Comments := DoRss(HttpRequest(CommentFeed))
		
		for each, Post in Posts
			Out .= Chr(3) "4" Post.Title " - " Post.Url "`r`n"
		
		for each, Comment in Comments
			Out .= Chr(3) "3" RegExReplace(Comment.Title, cTitleRE*) " - " RegExReplace(Comment.Url, cUrlRE*) "`r`n"
		
		if Out
			this.SendPRIVMSG("#reddit-dailyprogrammer", Out)
	}
	
	Log(Data)
	{
		Print(Data)
	}
}

Print(Text)
{
	static _ := DllCall("AllocConsole")
	StdOut := FileOpen("CONOUT$", "w")
	StdOut.Write(Text "`n")
}

DoRss(Rss)
{
	global Previous
	
	Rss := RegExReplace(Rss, "s)<feed[^>]*>(.*)</feed>.*$", "<feed>$1</feed>")
	
	xml := ComObjCreate("MSXML2.DOMDocument")
	xml.loadXML(Rss)
	if !entries := xml.selectNodes("/rss/channel/item")
		throw Exception("Malformed XML") ; Malformed xml
	
	Out := []
	While entry := entries.item[A_Index-1]
	{
		Url := entry.selectSingleNode("link").text
		if !Previous[Url]
		{
			Title := HtmlDecode(entry.selectSingleNode("title").text)
			Out.Insert({"Url": Url, "Title": Title})
		}
		
		Previous[Url] := True
	}
	
	Write := ""
	for Url in Previous
		Write .= "`r`n" Url
	FileOpen("temp\prevredditrss.txt", "w").Write(SubStr(Write, 3))
	
	return Out
}

HttpRequest(Url, UserAgent="")
{
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.open("GET", Url, False)
	if UserAgent
		http.setRequestHeader("User-Agent", UserAgent)
	http.send()
	return http.responseText
}