#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%\..\..

#Include %A_ScriptDir%\..\..\lib
#Include IRCClass.ahk
#Include Socket.ahk
#Include Utils.ahk

PostFeed := "http://www.reddit.com/r/dailyprogrammer.rss"
CommentFeed := "http://www.reddit.com/r/dailyprogrammer/comments.rss"
UserAgent := "DailyProgBot by /u/G33kDude (http://github.com/G33kDude/MyRC)"

ChallengeRE := "i)^\[([\d-]+)\] Challenge #(\d+) \[(.).*?\] (.+)$"

PostUrlRE := ["i)^.+comments/(.+?)/.+$", "http://redd.it/$1"]
CommentTitleRE := ["i)^(\S+).+?#(\d+).+?\[(.).*?\]", "$1 on #$2$3:"]
CommentUrlRE := ["^.+/(.+?)/.+?/(.+)$", "https://reddit.com/comments/$1/-/$2?context=3"]

PostFormat := Chr(3) "04{} - {}"
CommentFormat := Chr(3) "03{} - {}"
ChallengeFormat := "#{}{} {}"

Server := Ini_Read(A_ScriptDir "\Settings.ini").Server

MyBot := new IRCBot()
MyBot.Connect(Server.Addr, Server.Port, Server.Nick, Server.User,, Server.Pass)
MyBot.SendJOIN(Server.Chan)

PreviousPosts := [], PreviousComments := []
GetItems(HttpRequest(PostFeed), PreviousPosts)
GetItems(HttpRequest(CommentFeed), PreviousComments)

SetTimer, Poll, % 1 * 60 * 1000
return

Poll:
Out := ""
Tmp := HttpRequest(PostFeed)
Tmp := GetItems(Tmp, PreviousPosts)
for each, Post in Tmp
{
	Url := RegExReplace(Post.Url, PostUrlRE*)
	Out .= Format(PostFormat, Post.title, Url) "`n"
	if RegExMatch(Post.Title, ChallengeRE, Match)
		MyBot.ChangeTopicChallenge(Challenge, Format(ChallengeFormat, Match2, Match3, Url))
}

for each, Comment in GetItems(HttpRequest(CommentFeed), PreviousComments)
{
	Title := RegExReplace(Comment.Title, CommentTitleRE*)
	Url := RegExReplace(Comment.Url, CommentUrlRE*)
	Out .= Format(CommentFormat, Title, Url) "`n"
}

if Out
	MyBot.SendPRIVMSG(Server.Chan, Out)
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
		
		if this.Channels[Params[2], this.Nick, "MODE", "o"]
			this.SendPRIVMSG("ChanServ", "deop " Params[2] " " this.Nick)
	}
	
	OnMODE(Nick, User, Host, Cmd, Params, Msg, Data)
	{
		if this.Channels[Params[1], this.Nick, "MODE", "o"]
			this._SendTCP("TOPIC " Params[1] "`r`n")
	}
	
	OnPRIVMSG(Nick, User, Host, Cmd, Params, Msg, Data)
	{
		global PostFeed, PostUrlRE, ChallengeRE, ChallengeFormat
		Channel := Params[1]
		Msg := Trim(Msg)
		if (Msg = "!source")
			this.SendPRIVMSG(Channel, "https://github.com/G33kDude/MyRC/blob/dev/bots/DailyProgBot.ahk")
		else if (Msg = "!topic")
		{
			for each, Post in GetItems(HttpRequest(PostFeed), [])
			{
				if RegExMatch(Post.Title, ChallengeRE, Match)
				{
					Url := RegExReplace(Post.Url, PostUrlRE*)
					Challenge := Format(ChallengeFormat, Match2, Match3, Url)
					this.ChangeTopicChallenge(Channel, Challenge)
					Break
				}
			}
		}
	}
	
	ChangeTopicChallenge(Channel, NewChallenge)
	{
		; Send off for a topic so we can modify it
		this.NewChallenge := NewChallenge
		this.SendPRIVMSG("ChanServ", "op " Channel " " this.Nick)
	}
	
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

GetItems(Rss, ByRef Previous)
{
	; Trim WINE breaking fluff
	Rss := RegExReplace(Rss, "s).*?<feed[^>]*>(.*)</feed>.*?", "<feed>$1</feed>")
	
	xml := ComObjCreate("MSXML2.DOMDocument")
	xml.loadXML(Rss)
	if !entries := xml.selectNodes("/rss/channel/item")
		throw Exception("Malformed XML") ; Malformed xml
	
	NewPrevious := []
	Out := []
	While entry := entries.item[A_Index-1]
	{
		Url := entry.selectSingleNode("link").text
		NewPrevious[Url] := True
		if Previous.HasKey(Url)
			Continue
		Title := HtmlDecode(entry.selectSingleNode("title").text)
		Desc := HtmlDecode(entry.selectSingleNode("description").text)
		Out.Insert({"Url": Url, "Title": Title, "Desc": Desc})
	}
	
	Previous := NewPrevious
	
	return Out
}

HttpRequest(Url)
{
	global UserAgent
	try
	{
		Http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Http.Open("GET", Url, False)
		Http.SetRequestHeader("User-Agent", UserAgent)
		Http.Send()
		return Http.responseText
	}
	return
}