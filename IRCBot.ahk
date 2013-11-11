#persistent
#Include Socket.ahk
#Include IRCClass.ahk
FileRead, Greetings, Greetings.txt

IRC_Nick := "GeekD00d"

Gui, Margin, 5, 5
Gui, Font, s9, Lucida Console
Gui, Add, Edit, w1000 h300 ReadOnly vLog HWNDhLog
Gui, Add, Edit, w1000 h300 ReadOnly vChat HWNDhChat
Gui, Add, DropDownList, w145 h20 vChannel r20, |%IRC_Nick%||
Gui, Add, Edit, w800 h20 xp+150 vText
Gui, Add, Button, yp-1 xp+805 w45 h22 gSend Default, SEND
Gui, Show
;return

IRC := new Bot()
IRC.Connect("irc.freenode.net", 6667, IRC_Nick)
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
		IRC.SendACTION(Channel, Match2)
	else if (Match1 = "quit")
	{
		IRC.SendQUIT(Match2)
		SetTimer, ExitSub, -3000
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
	else if (Match1 = "hi")
		FileRead, Greetings, Greetings.txt
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
		if (User == this.User)
			this.UpdateDropDown()
	}
	
	; RPL_ENDOFMOTD
	on376(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.SendJOIN("#Sjc_Bot")
	}
	
	onPART(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (User == this.User)
			this.UpdateDropDown()
	}
	
	onNICK(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (User == this.User)
			this.UpdateDropDown()
	}
	
	UpdateDropDown()
	{
		DropDL := "|" this.Nick
		for k,v in this.Channels
			DropDL .= "|" v
		GuiControl,, Channel, % DropDL "||"
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
			if Match1 in Ahk,Script,Both,Docs
				this.SendPRIVMSG(Params[1], Search(Match1, Match2))
		}
	}
	
	Log(Text)
	{
		global hLog
		Text := RegExReplace(Text, "\R", "") "`r`n"
		
		SendMessage, 0x000E, 0, 0,, ahk_id %hLog% ;WM_GETTEXTLENGTH
		SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hLog% ;EM_SETSEL
		SendMessage, 0x00C2, False, &Text,, ahk_id %hLog% ;EM_REPLACESEL
		
		SendMessage, 0x0115, 7, 0,, ahk_id %hLog% ;WM_VSCROLL
	}
}

AppendChat(Text)
{
	global hChat
	
	Text := RegExReplace(Text, "\R", "") "`r`n"
	
	SendMessage, 0x000E, 0, 0,, ahk_id %hChat% ;WM_GETTEXTLENGTH
	SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hChat% ;EM_SETSEL
	SendMessage, 0x00C2, False, &Text,, ahk_id %hChat% ;EM_REPLACESEL
	
	SendMessage, 0x0115, 7, 0,, ahk_id %hChat% ;WM_VSCROLL
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
	else
		return "Error, not an available search engine"
	URI .= "&q=" UriEncode(Text)
	
	Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	Google.Open("GET", Base . URI)
	Google.Send()
	
	JSON := Google.ResponseText()
	
	if !(RegexMatch(JSON, """url"":""(.*?)"",""", Url))
		return
	if !(RegexMatch(JSON, """titleNoFormatting"":""(.*?)"",""", Desc))
		return
	return Url1 " - " Desc1
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
