#Include lib_json.ahk
#Include Socket.ahk
#Include IRCClass.ahk
FileRead, Greetings, Greetings.txt
FileRead, Passwords, %A_Desktop%\IRC.txt

IRC_Nick := "GeekBot"

Gui, Margin, 5, 5
Gui, Font, s9, Lucida Console
Gui, +HWNDhWnd +Resize
Gui, Add, Edit, w1000 h300 ReadOnly vLog HWNDhLog
Gui, Add, Edit, xm y310 w1000 h299 ReadOnly vChat HWNDhChat
Gui, Add, ListView, ym x1010 w130 h610 vListView -hdr, Hide
Gui, Add, DropDownList, xm w145 h20 vChannel r20 gDropDown, %IRC_Nick%||
Gui, Add, Edit, w935 h20 x155 yp vText
Gui, Add, Button, yp-1 xp940 w45 h22 vSend gSend Default, SEND
Gui, Show

IRC := new Bot()
IRC.Connect("irc.freenode.net", 6667, IRC_Nick, IRC_Nick, IRC_Nick, Passwords)
return

GuiSize:
EditH := Floor((A_GuiHeight-40) / 2)
EditW := A_GuiWidth - (15 + 130)
ChatY := 10 + EditH
ListViewX := A_GuiWidth - 135
ListViewH := A_GuiHeight - 35

BarY := A_GuiHeight - 25
TextW := A_GuiWidth - (20 + 145 + 45) ; Margin + DDL + Send
SendX := A_GuiWidth - 50
SendY := BarY - 1

GuiControl, Move, Log, x5 y5 w%EditW% h%EditH%
GuiControl, Move, Chat, x5 y%ChatY% w%EditW% h%EditH%
GuiControl, Move, ListView, x%ListViewX% y5 w130 h%ListViewH%
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
	{
		IRC.SendQUIT(Match2)
		SetTimer, ExitSub, -3000
	}
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
		this.SendJOIN("#maestrith")
		this.SendJOIN("#Sjc_Bot")
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
		; Hypothetically, @+ could exist
		for i,v in ["@,@+","+",""]
			for Nick,Meta in IRC.GetMeta(Channel, v)
				LV_Add("", Meta[1] . Nick)
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
		
		if (RegExMatch(Msg, "i)^("Greetings ").*" this.Nick, Match))
			this.SendPRIVMSG(Params[1], Match1 " " Nick)
		
		; If it is being sent to us, but not by us
		if (Params[1] == this.Nick && Nick != this.Nick)
			this.SendPRIVMSG(Nick, "Hello to you, good sir")
		
		if Msg contains % this.Nick
		{
			SoundBeep
			TrayTip, % this.Nick, % "<" Nick "> " Msg
		}
		
		; if it is a command
		if (RegexMatch(Msg, "^(?:``|\/)([^ ]+)(?: (.+))?$", Match))
		{
			if Match1 in Ahk,Script,Both,Docs,g
			{
				Search := Search(Match1, Match2)
				this.SendPRIVMSG(Params[1], Search)
				AppendChat(Params[1] " <" this.Nick "> " Search)
			}
			else if (Match1 = "BTC" && (BTC := GetBTC()[Match2, "24h"]))
			{
				StringUpper, Match2, Match2
				this.SendPRIVMSG(Params[1], "1BTC == " BTC . Match2)
				AppendChat(Params[1] " <" this.Nick "> 1BTC == " BTC . Match2)
			}
			else if (Match1 = "8")
			{
				Random, Rand, 0, 1
				this.SendPRIVMSG(Params[1], Rand ? "Yes" : "No")
				AppendChat(Params[1] " <" this.Nick "> " (Rand ? "Yes" : "No"))
			}
		}
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
		File := Json_From(File)
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
		BTC := BTC.ResponseText()
		
		; Decode the prices
		Rates := Json_From(BTC)
		
		; Save the prices to file
		FileDelete, LastBTC.txt
		FileAppend, % Json_To([A_Now, Rates]), LastBTC.txt
		
		ToolTip
	}
	else ; Read rates from file
		Rates := File[2]
	
	return Rates
}

Search(CSE, Text)
{
	static Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"
	
	if (CSE = "Both")
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
	Google.Open("GET", Base . URI)
	Google.Send()
	Response := Google.ResponseText()
	
	JSON := Json_From(Response)
	
	Url := UriDecode(JSON["responseData", "results", 1, "titleNoFormatting"])
	Desc := UriDecode(JSON["responseData", "results", 1, "url"])
	
	if !(Url && Desc)
		return
	
	return Desc " - " Url
}

; modified from jackieku's code (http://www.autohotkey.com/forum/post-310959.html#310959)
UriEncode(Uri, Enc = "UTF-8")
{
	StrPutVar(Uri, Var, Enc)
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	Loop
	{
		Code := NumGet(Var, A_Index - 1, "UChar")
		If (!Code)
			Break
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	}
	SetFormat, IntegerFast, %f%
	Return, Res
}

UriDecode(Uri, Enc = "UTF-8")
{
	Pos := 1
	Loop
	{
		Pos := RegExMatch(Uri, "i)(?:%[\da-f]{2})+", Code, Pos++)
		If (Pos = 0)
			Break
		VarSetCapacity(Var, StrLen(Code) // 3, 0)
		StringTrimLeft, Code, Code, 1
		Loop, Parse, Code, `%
			NumPut("0x" . A_LoopField, Var, A_Index - 1, "UChar")
		StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, Enc), All
	}
	Return, Uri
}

StrPutVar(Str, ByRef Var, Enc = "")
{
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}