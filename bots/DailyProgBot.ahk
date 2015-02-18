#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%\..

#Include %A_ScriptDir%\..\lib
#Include IRCClass.ahk
#Include Socket.ahk
#Include Utils.ahk

PostFeed := "http://www.reddit.com/r/dailyprogrammer.rss"
CommentFeed := "http://www.reddit.com/r/dailyprogrammer/comments.rss"
UserAgent := "DailyProgBot by /u/G33kDude (http://github.com/G33kDude/MyRC)"
Channel := "#reddit-dailyprogrammer"

ChallengeRE := "i)^\[([\d-]+)\] Challenge #(\d+) \[(.).*?\] (.+)$"

PostUrlRE := ["i)^.+comments/(.+?)/.+$", "http://redd.it/$1"]
CommentTitleRE := ["i)^(\S+).+?#(\d+).+?\[(.).*?\]", "$1 on #$2$3:"]
CommentUrlRE := ["^.+/(.+?)/.+?/(.+)$", "https://reddit.com/comments/$1/-/$2?context=3"]

PostFormat := Chr(3) "4{} - {}"
CommentFormat := Chr(3) "3{} - {}"

Settings := Ini_Read("Settings.ini")
MyBot := new IRCBot() ; Create a new instance of your bot
MyBot.Connect("chat.freenode.net", 6667, "DailyProgBot",,, Settings.Server.Pass)
MyBot.SendJOIN(Channel) ; Join a channel
PreviousPosts := [], PreviousComments := []
GetItems(HttpRequest(PostFeed), PreviousPosts)
GetItems(HttpRequest(CommentFeed), PreviousComments)
SetTimer, Poll, % 1 * 60 * 1000
return

Poll:
Out := ""
for each, Post in GetItems(HttpRequest(PostFeed), PreviousPosts)
{
	Url := RegExReplace(Post.Url, PostUrlRE*)
	Out .= Format(PostFormat, Post.title, Url) "`n"
	if RegExMatch(Post.Title, ChallengeRE, Match)
	{
		; Send off for a topic so we can modify it
		MyBot.NewChallenge := "#" Match2 . Match3 " " Url
		MyBot._SendTCP("TOPIC " Channel "`r`n")
	}
}

for each, Comment in GetItems(HttpRequest(CommentFeed), PreviousComments)
{
	Title := RegExReplace(Comment.Title, CommentTitleRE*)
	Url := RegExReplace(Comment.Url, CommentUrlRE*)
	Out .= Format(CommentFormat, Title, Url) "`n"
}

if Out
	MyBot.SendPRIVMSG(Channel, Out)
return

class IRCBot extends IRC
{
	; RPL_TOPIC
	On332(Nick, User, Host, Cmd, Params, Msg, Data)
	{
		if this.NewChallenge
		{
			; Topic received, modify it
			NewTopic := RegExReplace(Msg, "\|\s*#\d+.*?\|", "| " this.NewChallenge " |")
			if (NewTopic != Msg)
				this._SendTCP("TOPIC " Params[2] " :" NewTopic "`r`n")
		}
	}
	
	OnPRIVMSG(Nick, User, Host, Cmd, Params, Msg, Data)
	{
		if (Trim(Msg) = "!source")
			this.SendPRIVMSG(Params[1], "https://github.com/G33kDude/MyRC/blob/Devlopment/bots/DailyProgBot.ahk")
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

GetItems(Rss, Previous)
{
	; Trim WINE breaking fluff
	Rss := RegExReplace(Rss, "s).*?<feed[^>]*>(.*)</feed>.*?", "<feed>$1</feed>")
	
	xml := ComObjCreate("MSXML2.DOMDocument")
	xml.loadXML(Rss)
	if !entries := xml.selectNodes("/rss/channel/item")
		throw Exception("Malformed XML") ; Malformed xml
	
	Out := []
	While entry := entries.item[A_Index-1]
	{
		Url := entry.selectSingleNode("link").text
		if Previous.HasKey(Url)
			Continue
		Title := HtmlDecode(entry.selectSingleNode("title").text)
		Desc := HtmlDecode(entry.selectSingleNode("description").text)
		Out.Insert({"Url": Url, "Title": Title, "Desc": Desc})
		Previous[Url] := True
	}
	return Out
}

HttpRequest(Url, UserAgent="")
{
	try
	{
		Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Http.Open("GET", Url, False)
		if UserAgent
			Http.SetRequestHeader("User-Agent", UserAgent)
		Http.Send()
		return Http.responseText
	}
	return
}