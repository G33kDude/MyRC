#Include Socket.ahk
#Include IRCClass.ahk
#Include Json.ahk

FileRead, Greetings, Greetings.txt
FileRead, Passwords, %A_Desktop%\IRC.txt

IRC_Nick := "GeekBot"

Gui, Margin, 5, 5
Gui, Font, s9, Lucida Console
Gui, +HWNDhWnd +Resize
Gui, Add, Edit, w1000 h300 ReadOnly vLog HWNDhLog
Gui, Add, Edit, xm y310 w1000 h299 ReadOnly vChat HWNDhChat
Gui, Add, ListView, ym x1010 w130 h610 vListView -hdr, Hide
LV_ModifyCol(1, 130)
Gui, Add, DropDownList, xm w145 h20 vChannel r20 gDropDown, %IRC_Nick%||
Gui, Add, Edit, w935 h20 x155 yp vText
Gui, Add, Button, yp-1 xp940 w45 h22 vSend gSend Default, SEND
Gui, Show

IRC := new Bot()
IRC.Connect("irc.freenode.net", 6667, IRC_Nick, IRC_Nick, IRC_Nick, Passwords)
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
Guicontrol, Move, Text, x155 y%BarY% w%TextW% h20
Guicontrol, Move, Send, x%SendX% y%SendY% w45 h22
return

DropDown:
IRC.UpdateListView()
return

Send:
GuiControlGet, Text
GuiControl,, Text

GuiControlGet, Channel

if RegexMatch(Text, "^/([^ ]+)(?: (.+))?$", Match)
{
	if (Match1 = "join")
		IRC.SendText("JOIN " Match2)
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
		IRC.SendText(Match2)
	else if (Match1 = "nick")
		IRC.SendNICK(Match2)
	else if (Match1 = "greetings")
		FileRead, Greetings, Greetings.txt
	else if (Match1 = "quit")
		IRC.SendQUIT(Match2)
	else
		IRC.Log("ERROR: Unkown command " Match1)
	return
}

IRC.SendPRIVMSG(Channel, Text)
IRC.onPRIVMSG(IRC.Nick,IRC.User,"","PRIVMSG",[Channel],Text,":" IRC.Nick "!" IRC.User "@" IRC.Host " PRIVMSG " Channel " :" Text)
return

GuiClose:
ExitSub:
ExitApp
return

class Bot extends IRC
{
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
	
	on366(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.UpdateListView()
	}
	
	; RPL_ENDOFMOTD
	on376(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.SendJOIN("#ahkscript")
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
		global Greetings
		
		AppendChat(Params[1] " <" Nick "> " Msg)
		
		if (RegExMatch(Msg, "i)^(("Greetings "),?).*" this.Nick, Match))
			this.SendPRIVMSG(Params[1], Match1 " " Nick)
		
		; If it is being sent to us, but not by us
		if (Params[1] == this.Nick && Nick != this.Nick)
			this.SendPRIVMSG(Nick, "Hello to you, good sir")
		
		if Msg contains % this.Nick
		{
			SoundBeep
			TrayTip, % this.Nick, % "<" Nick "> " Msg
		}
		
		; If it is a command
		if (RegexMatch(Msg, "^(?:``|\/)([^ ]+)(?: (.+))?$", Match))
		{
			if (Match1 = "Help")
				this.Chat(Params[1], "Help, Forum, Docs, g, More, BTC, 8")
			if Match1 in Forum,Ahk,Script,Docs,g
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
				Random, Rand, 0, 1
				this.Chat(Params[1], Rand ? "Yes" : "No")
			}
		}
	}
	
	Chat(Channel, Message)
	{
		this.SendPRIVMSG(Channel, Message)
		AppendChat(Channel " <" this.Nick "> " Message)
	}
	
	Log(Text)
	{
		AppendLog(Text)
	}
}

Rand(Min, Max)
{
	Random, Rand, Min, Max
	return Rand
}

AppendLog(Text)
{
	global hLog
	Text := RegExReplace(Text, "\R", "") "`r`n"
	
	SendMessage, 0x000E, 0, 0,, ahk_id %hLog% ;WM_GETTEXTLENGTH
	SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hLog% ;EM_SETSEL
	SendMessage, 0x00C2, False, &Text,, ahk_id %hLog% ;EM_REPLACESEL
	
	SendMessage, 0x0115, 7, 0,, ahk_id %hLog% ;WM_VSCROLL
}

; SendMessages courtesy of TheGood http://www.autohotkey.com/board/topic/52441-append-text-to-an-edit-control/?p=328342
AppendChat(Text)
{
	global hChat
	
	FormatTime, Stamp,, [hh:mm]
	
	Text := Stamp " " RegExReplace(Text, "\R", "") "`r`n"
	
	SendMessage, 0x000E, 0, 0,, ahk_id %hChat% ;WM_GETTEXTLENGTH
	SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hChat% ;EM_SETSEL
	SendMessage, 0x00C2, False, &Text,, ahk_id %hChat% ;EM_REPLACESEL
	
	SendMessage, 0x0115, 7, 0,, ahk_id %hChat% ;WM_VSCROLL
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
{ ; Preform a search. Available searches: Forum, Ahk, Script, Docs, g
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
	
	http:=ComObjCreate("htmlfile"),http.write(Desc)
	return http.body.innertext " - " UriDecode(Url)
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