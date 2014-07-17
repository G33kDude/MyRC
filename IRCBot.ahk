#Include Socket.ahk
#Include IRCClass.ahk
#Include Json.ahk
#Include ini.ahk
#Include Commands.ahk

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

myTcp := new SocketTCP()
myTcp.bind("addr_any", 26656)
myTcp.listen()
myTcp.onAccept := Func("OnTCPAccept")
return

OnTCPAccept()
{
	global myTcp
	newTcp := myTcp.accept()
	Text := newTcp.recvText()
	Comma := InStr(Text, ",")
	Channel := Trim(SubStr(Text, 1, Comma-1))
	Message := Trim(SubStr(Text, Comma+1))
	IRC.Chat(Channel, Message)
	newTcp.__Delete()
}

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
	IRC._onRecv(":" IRC.Nick "!" IRC.User "@" IRC.Host " PRIVMSG " Channel " :" Message)
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
		FileRead, Json, Docs.json
		this.Docs := Json_ToObj(Json)
		this.DocsList := []
		For Name, Location in this.Docs
			this.DocsList[A_Index] := Name
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
		for Nick in this.GetMODE(Channel, "o")
			LV_Add("", this.Prefix.Letters["o"] . Nick)
		for Nick in this.GetMODE(Channel, "v -o") ; voiced not opped
			LV_Add("", this.Prefix.Letters["v"] . Nick)
		for Nick in this.GetMODE(Channel, "-ov") ; not opped or voiced
			LV_Add("", Nick)
	}
	
	onINVITE(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (User == this.User)
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
		
		; Greetings
		if (RegExMatch(Msg, GreetEx, Match))
		{
			this.Chat(Params[1], Match1 " " Nick . MatchPunct)
			return
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
				this.Chat(Params[1], ShowHelp(Match2))
			else if (Match1 = "NewPost")
				this.Chat(Params[1], NewPosts(Match2))
			else if (Match1 = "NewNique")
				this.Chat(Params[1], NewNique(Match2))
			else if (Match1 = "Shorten")
				this.Chat(Params[1], Shorten(Match2))
			else if Match1 in Forum,Ahk,Script,g
				this.Chat(Params[1], Search(Match1, Match2))
			else if (Match1 = "More")
				this.Chat(Params[1], Search(Match1, Match2, True))
			else if (Match1 = "Docs")
			{
				if (Doc := MatchItemFromList(this.DocsList, Match2))
					this.Chat(Params[1], Doc.Text " - " Shorten("http://ahkscript.org/" this.Docs[Doc.Text]) " - Fitness: " Doc.Fitness)
				else
					this.Chat(Params[1], "No results found")
			}
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
			else if (Match1 = "p")
			{
				Url := Params[1] = "#ahk" ? "http://ahk.us.to/" : "http://a.hk.am/"
				this.Chat(Params[1], "Please use the unofficial AutoHotkey pastebin to share code: " Url)
			}
			else
				this.Chat(Params[1], Search("forum", Trim(Match1 " " Match2))) ; Forum search
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