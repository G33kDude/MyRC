#Include Socket.ahk
#Include IRCClass.ahk
#Include Json.ahk

SettingsFile := A_ScriptDir "\Settings.ini"

if !(Settings := Ini_Read(SettingsFile))
{
	Settings =
	( LTrim
	Greetings = Hey|Hi|Hello
	EightBall = Yes,No,Maybe
	ShowHex = 0
	
	[Server]
	Addr = chat.freenode.net
	Port = 6667
	Nick = MyRC_Bot
	User =
	Pass =
	Channels = #ahkscript
	)
	
	File := FileOpen(SettingsFile, "w")
	File.Write(Settings), File.Close()
	
	Settings := Ini_Read(SettingsFile)
}

if (Settings.Bitly)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

Gui, Margin, 5, 5
Gui, Font, s9, Lucida Console
Gui, +HWNDhWnd +Resize
Gui, Add, Edit, w1000 h300 ReadOnly vLog HWNDhLog
Gui, Add, Edit, xm y310 w1000 h299 ReadOnly vChat HWNDhChat
Gui, Add, ListView, ym x1010 w130 h610 vListView -hdr, Hide
LV_ModifyCol(1, 130)
Gui, Add, DropDownList, xm w145 h20 vChannel r20 gDropDown, %IRC_Nick%||
Gui, Add, Edit, w935 h20 x155 yp vMessage
Gui, Add, Button, yp-1 xp940 w45 h22 vSend gSend Default, SEND
Gui, Show

Server := Settings.Server
IRC := new Bot(Settings.Greetings, StrSplit(Settings.EightBall, ",", " `t"), Settings.ShowHex)
IRC.Connect(Server.Addr, Server.Port, Server.Nick, Server.User, Server.Nick, Server.Pass)
IRC.SendJOIN(StrSplit(Server.Channels, ",", " `t")*)
return

GuiSize:
EditH := Floor((A_GuiHeight-40) / 2)
EditW := A_GuiWidth - (15 + 150)
ChatY := 10 + EditH
ListViewX := A_GuiWidth - 155
ListViewH := A_GuiHeight - 35

BarY := A_GuiHeight - 25
TextW := A_GuiWidth - (20 + 145 + 45) ; Margin + DDL + Send
SendX := A_GuiWidth - 50
SendY := BarY - 1

GuiControl, Move, Log, x5 y5 w%EditW% h%EditH%
GuiControl, Move, Chat, x5 y%ChatY% w%EditW% h%EditH%
GuiControl, Move, ListView, x%ListViewX% y5 w150 h%ListViewH%
GuiControl, Move, Channel, x5 y%BarY% w145 h20
Guicontrol, Move, Message, x155 y%BarY% w%TextW% h20
Guicontrol, Move, Send, x%SendX% y%SendY% w45 h22
return

DropDown:
IRC.UpdateListView()
return

Send:
GuiControlGet, Message
GuiControl,, Message ; Clear input box

GuiControlGet, Channel

if RegexMatch(Message, "^/([^ ]+)(?: (.+))?$", Match)
{
	if (Match1 = "join")
		IRC._SendRAW("JOIN " Match2)
	else if (Match1 = "me")
	{
		IRC.SendACTION(Channel, Match2)
		AppendChat(Channel " * " IRC.Nick " " Match2)
	}
	else if (Match1 = "part")
		IRC.SendPART(Channel, Match2)
	else if (Match1 = "reload")
		Reload
	else if (Match1 = "say")
		IRC.SendPRIVMSG(Channel, Match2)
	else if (Match1 = "raw")
		IRC._SendRaw(Match2)
	else if (Match1 = "nick")
		IRC.SendNICK(Match2)
	else if (Match1 = "quit")
		IRC.SendQUIT(Match2)
	else
		IRC.Log("ERROR: Unkown command " Match1)
	return
}

; Send chat and handle it
Messages := IRC.SendPRIVMSG(Channel, Message)
for each, Message in Messages
	IRC.onPRIVMSG(IRC.Nick, IRC.User, IRC.Host, "PRIVMSG", [Channel], Message
, ":" IRC.Nick "!" IRC.User "@" IRC.Host " PRIVMSG " Channel " :" Message)
return

GuiClose:
ExitSub:
ExitApp
return

class Bot extends IRC
{
	__New(Greetings, EightBall, ShowHex=false)
	{
		this.Greetings := Greetings
		this.EightBall := EightBall
		return base.__New(ShowHex)
	}
	
	onMODE(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.UpdateListView()
	}
	
	onJOIN(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Nick == this.Nick)
			this.UpdateDropDown(Params[1])
		AppendChat(Params[1] " " Nick " has joined")
		this.UpdateListView()
	}
	
	; RPL_ENDOFNAMES
	on366(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.UpdateListView()
	}
	
	onPART(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Nick == this.Nick)
			this.UpdateDropDown()
		AppendChat(Params[1] " " Nick " has parted" (Msg ? " (" Msg ")" : ""))
		this.UpdateListView()
	}
	
	onNICK(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		; Can't use nick, was already handled by class
		if (User == this.User)
			this.UpdateDropDown()
		AppendChat(Nick " changed its nick to " Msg)
		this.UpdateListView()
	}
	
	onKICK(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Params[2] == this.Nick)
			this.UpdateDropDown()
		AppendChat(Params[1] " " Params[2] " was kicked by " Nick " (" Msg ")")
		this.UpdateListView()
	}
	
	onQUIT(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		AppendChat(Nick " has quit (" Msg ")")
		this.UpdateListView()
	}
	
	UpdateDropDown(Default="")
	{
		DropDL := "|" this.Nick "|"
		if (!Default)
			GuiControlGet, Default,, Channel
		for Channel in this.Channels
			DropDL .= Channel "|" (Channel==Default ? "|" : "")
		if (!this.Channels.hasKey(Default))
			DropDL .= "|"
		GuiControl,, Channel, % DropDL
	}
	
	UpdateListView()
	{
		GuiControlGet, Channel
		if !IRC.IsIn(Channel)
			return
		
		LV_Delete()
		for Nick,Meta in this.GetMODE(Channel, "o")
			LV_Add("", this.Prefix.Letters["o"] . Nick)
		for Nick,Meta in this.GetMODE(Channel, "v -o") ; voiced not opped
			LV_Add("", this.Prefix.Letters["v"] . Nick)
		for Nick,Meta in this.GetMODE(Channel, "-ov") ; not opped or voiced
			LV_Add("", Nick)
	}
	
	onINVITE(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (User ~= "^\~?G33kDude$")
			this.SendJOIN(Msg)
	}
	
	onCTCP(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Cmd = "ACTION")
			AppendChat(Params[1] " * " Nick " " Msg)
		else
			this.SendCTCPReply(Nick, Cmd, "Zark off!")
	}
	
	onPRIVMSG(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		AppendChat(Params[1] " <" Nick "> " Msg)
		
		GreetEx := "i)^((?:" this.Greetings
		. "),?)\s.*" RegExEscape(this.Nick)
		. "(?P<Punct>[!?.]*).*$"
		
		; Greetings (\pP means any punctuation)
		if (RegExMatch(Msg, GreetEx, Match))
		{
			this.SendPRIVMSG(Params[1], Match1 " " Nick . MatchPunct)
			this.Log(Match0)
		}
		
		; If it is being sent to us, but not by us
		if (Params[1] == this.Nick && Nick != this.Nick)
			this.SendPRIVMSG(Nick, "Hello to you, good sir")
		
		if Msg contains % this.Nick
		{
			SoundBeep
			TrayTip, % this.Nick, % "<" Nick "> " Msg
		}
		
		; If it is a command
		if (RegexMatch(Msg, "^``([^ ]+)(?: (.+))?$", Match))
		{
			if (Match1 = "Help")
				this.Chat(Params[1], "Help, Forum, Docs, g, More, BTC, 8, NewPost, NewNique")
			else if (Match1 = "NewPost")
				this.Chat(Params[1], NewPosts(Match2))
			else if (Match1 = "NewNique")
				this.Chat(Params[1], NewNique(Match2))
			else if (Match1 = "Shorten")
				this.Chat(Params[1], Shorten(Match2))
			Else if Match1 in Forum,Ahk,Script,Docs,g
				this.Chat(Params[1], Search(Match1, Match2))
			else if (Match1 = "More")
				this.Chat(Params[1], Search(Match1, Match2, True))
			else if (Match1 = "BTC" && (BTC := GetBTC()[Match2, "24h"]))
			{
				StringUpper, Match2, Match2
				this.Chat(Params[1], "1BTC == " BTC . Match2)
			}
			else if (Match1 = "8")
			{
				Random, Rand, 1, % this.EightBall.MaxIndex()
				this.Chat(Params[1], this.EightBall[Rand])
			}
		}
	}
	
	Chat(Channel, Message)
	{
		Messages := this.SendPRIVMSG(Channel, Message)
		for each, Message in Messages
			AppendChat(Channel " <" this.Nick "> " Message)
		return Messages
	}
	
	Log(Message)
	{
		AppendLog(Message)
	}
}

RegExEscape(String)
{
	return "\Q" RegExReplace(String, "\\E", "\E\\E\Q") "\E"
}

AppendLog(Message)
{
	global hLog
	Message := RegExReplace(Message, "\R", "") "`r`n"
	AppendControl(Message, hLog)
}

AppendChat(Message)
{
	global hChat
	
	FormatTime, Stamp,, [hh:mm]
	Message := Stamp " " RegExReplace(Message, "\R", "") "`r`n"
	
	AppendControl(Message, hChat)
}

; SendMessages courtesy of TheGood http://www.autohotkey.com/board/topic/52441-append-text-to-an-edit-control/?p=328342
AppendControl(Text, hWnd)
{
	SizeOf := VarSetCapacity(SIF, 28, 0) ; 7 ints/uints
	NumPut(SizeOf, SIF, 0, "UInt") ; Size of struct
	NumPut(1|2|4|16, SIF, 4, "UInt") ; SIF_ALL
	DllCall("GetScrollInfo", "Ptr", hWnd, "Int", 0x1, "Ptr", &SIF)
	Max := NumGet(SIF, 3*4, "Int")
	Pag := NumGet(SIF, 4*4, "Int")
	Pos := NumGet(SIF, 5*4, "Int")
	
	; WM_VSCROLL doesn't like -redraw mode much
	;GuiControl, -Redraw, %hWnd%
	
	SendMessage, 0x000E, 0, 0,, ahk_id %hWnd% ;WM_GETTEXTLENGTH
	SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hWnd% ;EM_SETSEL
	SendMessage, 0x00C2, False, &Text,, ahk_id %hWnd% ;EM_REPLACESEL
	
	if (Pos - (Max - Pag) - 1)
		SendMessage, 0x0115, 0x4 + 0x10000*Pos, 0,, ahk_id %hWnd% ;WM_VSCROLL
	
	;GuiControl, +Redraw, %hWnd%
}

; Fetch latest bitcoin info from bitcoincharts api
GetBTC()
{
	static API := "http://api.bitcoincharts.com/v1/weighted_prices.json"
	
	; Read the last bitcoin data from file.
	; If there is data, load it
	; If not, use a dummy to indicate we should fetch new data
	FileRead, File, LastBTC.txt
	if File
		File := Json_ToObj(File)
	else
		File := [0,"Error"]
	
	LastTime := File[1], Elapsed := A_Now
	EnvSub, Elapsed, LastTime, Hours
	
	; If more than 1 hour has elapsed, or there is no saved last time
	if (Elapsed || !LastTime)
	{
		ToolTip, Fetching new prices
		
		; Fetch the prices
		BTC := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		BTC.Open("GET", API)
		BTC.Send()
		BTC := BTC.ResponseText
		
		; Decode the prices
		Rates := Json_ToObj(BTC)
		
		; Save the prices to file
		FileDelete, LastBTC.txt
		FileAppend, [%A_Now%`, %BTC%], LastBTC.txt
		
		ToolTip
	}
	else ; Read rates from file
		Rates := File[2]
	
	return Rates
}

Search(CSE, Text, More=false)
{ ; Perform a search. Available searches: Forum, Ahk, Script, Docs, g
	static Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"
	, json, index := 1
	
	if More
		Index++
	Else
	{
		if (CSE = "Forum")
			URI := "&cx=017058124035087163209%3A1s6iw9x3kna"
		else if (CSE = "Ahk")
			URI := "&cx=017058124035087163209%3Amvadmlmwt3m"
		else if (CSE = "Script")
			URI := "&cx=017058124035087163209%3Ag-1wna_xozc"
		else if (CSE = "Docs")
			URI := "&cx=017058124035087163209%3Az23pf7b3a3q"
		else if (CSE = "g")
			URI := ""
		else
			return "Error, not an available search engine"
		URI .= "&q=" UriEncode(Text)
		
		Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Google.Open("GET", Base . URI), Google.Send()
		json := Json_ToObj(Google.ResponseText)
		Index := 1
	}
	
	Desc := json.responseData.results[Index].titleNoFormatting
	Url := json.responseData.results[Index].url
	
	if !(Url && Desc)
		return "No results found"
	
	return htmlDecode(Desc) " - " Shorten(UriDecode(Url))
}

; Modified by GeekDude from http://goo.gl/0a0iJq
UriEncode(Uri)
{
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	While Code := NumGet(Var, A_Index - 1, "UChar")
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
	|| Code >= 0x61 && Code <= 0x7A) ; a-z
	Res .= Chr(Code)
	Else
		Res .= "%" . SubStr(Code + 0x100, -1)
	SetFormat, IntegerFast, %f%
	Return, Res
}

UriDecode(Uri)
{
	Pos := 1
	While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos)
	{
		VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code,2)
		Loop, Parse, Code, `%
			NumPut("0x" A_LoopField, Var, A_Index-1, "UChar")
		StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, "UTF-8"), All
	}
	Return, Uri
}

HtmlDecode(Text)
{
	static html := ComObjCreate("htmlfile")
	html.open(), html.write(Text)
	return html.body.innerText
}

GetPosts(Max = 4)
{
	static Posts := [0], UA := "Mozilla/5.0 (X11; Linux"
	. " x86_64; rv:12.0) Gecko/20100101 Firefox/21.0"
	, Feed := "http://ahkscript.org/boards/feed.php"
	
	if (A_TickCount - Posts[1] > 1 * 60 * 1000 || Max < 0) ; 1 minute
	{
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.Open("GET", Feed, True) ; Async
		http.setRequestHeader("User-Agent", UA)
		http.Send()
		
		; Wait for data or timeout
		TickCount := A_TickCount
		While A_TickCount - TickCount < 10 * 1000 ; 10 seconds
			Try ; If it errors, the data has not been recieved yet
				Rss := http.responseText, TickCount := 0
		if !Rss
			return "Error: Server timeout"
		
		; Load XML
		xml:=ComObjCreate("MSXML2.DOMDocument")
		xml.loadXML(Rss)
		if !entries := xml.selectnodes("/feed/entry")
			return "Error: Malformed XML"
		
		; Read entries
		Posts := [A_TickCount]
		While entry := entries.item[A_Index-1]
		{
			Title := HtmlDecode(entry.selectSingleNode("title").text)
			Author := entry.selectSingleNode("author/name").text
			Url := Shorten(entry.selectSingleNode("link/@href").text)
			Posts.Insert({"Author":Author, "Title":Title, "Url":Url})
		}
	}
	
	Out := Posts.Clone()
	Out.Remove(Abs(Max)+2, 17) ; The key after the last one we want, and +1 because of timestamp
	
	return Out
}

NewPosts(Max=4)
{
	Max := Floor(Max)
	if (Max < -7 || Max > 7 || !Max)
		Max := 4
	
	Posts := GetPosts(Max)
	if !IsObject(Posts)
		return Posts
	
	if (Cached := (A_TickCount-Posts.Remove(1)) // 1000)
		Out := "Information is " Cached " seconds old (use negative to force refresh)`n"
	
	for each, Post in Posts
		Out .= Post.Author " - " Post.Title " - " Post.Url "`n"
	
	return Out
}

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

Shorten(LongUrl, SetKey="")
{
	static Shortened := {"http://www.autohotkey.net/": "http://ahk.me/sqTsfk"
	, "http://www.autohotkey.com/": "http://ahk.me/sDikbQ"
	, "http://www.autohotkey.com/forum/": "http://ahk.me/rJiLHk"
	, "http://www.autohotkey.com/docs/Tutorial.htm": "http://ahk.me/uKJ4oh"
	, "http://github.com/polyethene/robokins": "http://git.io/robo"
	, "http://ahkscript.org/": "http://ahk4.me/QMmuVo"}
	, http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	, Base := "http://api.bitly.com/v3/shorten"
	, login, apiKey
	
	if SetKey
	{
		apiKey := SetKey
		login := LongUrl
		return
	}
	
	if (Shortened.HasKey(LongUrl))
		return Shortened[LongUrl]
	
	if !(login && apiKey)
		return LongUrl
	
	Url := Base
	. "?login=" login
	. "&apiKey=" apiKey
	. "&longUrl=" UriEncode(Trim(LongUrl, " `r`n`t"))
	. "&format=txt"
	
	http.Open("GET", Url), http.Send()
	ShortUrl := Trim(http.responseText, " `r`n`t")
	Shortened.Insert(LongUrl, ShortUrl)
	
	return ShortUrl
}

Ini_Read(FileName)
{
	FileRead, File, %FileName%
	return File ? Ini_Reads(File) : ""
}

Ini_Reads(FileName)
{
	static RegEx := "^\s*(?:`;.*|(.*?)(?:\s+`;.*)?)\s*$"
	Section := Out := []
	Loop, Parse, FileName, `n, `r
	{
		if !(RegExMatch(A_LoopField, RegEx, Match) && Line := Match1)
			Continue
		if RegExMatch(Line, "\[(.+)\]", Match)
			Out.Insert(Match1, Section := [])
		else if RegExMatch(Line, "^(.+?)\s*=\s*(.+)$", Match)
			Section.Insert(Match1, Match2)
	}
	return Out
}