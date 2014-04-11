class IRC
{
	__New()
	{
		this.Channels := []
		this.Mode := []
		this.Prefix := {"Letters":{}, "Symbols":{}}
		this.TCP := new SocketTCP()
		this._HandleRecvProxy("",this)
		this.TCP.onRecv := this._HandleRecvProxy
	}
	
	Connect(Server, Port, Nick, User="", Name="", Pass="")
	{
		this.Nick := Nick
		this.User := User ? User : Nick
		this.Name := Name ? Name : Nick
		
		this.TCP.Connect(Server, Port)
		
		if Pass
			this.SendText("PASS " Pass)
		this.SendText("NICK " this.Nick)
		this.SendText("USER " this.User " 0 * :" this.Name)
	}
	
	; Calls _HandleRecv in the right context.
	; Without this, it would think 'this' was the other class
	_HandleRecvProxy(Skt, Parent="")
	{
		static _Parent
		if (parent)
			return _Parent := Parent
		return _Parent._HandleRecv(Skt)
	}
	
	_HandleRecv(Skt)
	{
		static Data
		
		Data .= Skt.RecvText()
		
		; Data := (DatArray:=StrSplit(Data,"`r`n")).Remove(DatArray.MaxIndex())
		DatArray := StrSplit(Data, "`r`n")
		Data := DatArray.Remove(DatArray.MaxIndex())
		
		for Key, Value in DatArray
		{
			if (!Value)
				continue
			
			; :Nick!User@Host Command Parameter Parameter Parameter :Message
			if (!RegExMatch(Value, "^(?:\:([^\!\@ ]*)(?:(?:\!([^\@]*))?\@([^ ]*))? )?([^ ]+)(?: ([^ ]+(?: [^ ]+)*?))??(?: \:(.*?))?\s*$", Match))
			{
				this.Log("Malformed message recieved:" Value)
				continue
			}
			
			this.Log(Value)
			
			Nick := Match1, User := Match2, Host := Match3
			Cmd := Match4, Params := StrSplit(Match5, " "), Msg := Match6
			
			; If no return value, go on to regular handler
			if (!this["_on" Cmd](Nick,User,Host,Cmd,Params,Msg,Data))
				this["on"  Cmd](Nick,User,Host,Cmd,Params,Msg,Data)
		}
		
		return
	}
	
	_onNICK(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Nick == this.Nick)
			this.Nick := Msg
		
		for Channel, NickList in this.Channels
			NickList[Msg] := NickList[Nick], NickList.Remove(Nick)
	}
	
	_onPING(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.SendText("PONG :" Msg)
	}
	
	_onJOIN(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		Channel := Params[1] ? Params[1] : Msg
		if (Nick == this.Nick)
			this.Channels.Insert(Channel, [])
		else
			this.Channels[Channel].Insert(Nick, {"MODE":[]})
	}
	
	_onPART(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Nick == this.Nick)
			this.Channels.Remove(Params[1])
		else
			this.Channels[Params[1]].Remove(Nick)
	}
	
	_onKICK(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Params[2] == this.Nick)
			this.Channels.Remove(Params[1])
		else
			this.Channels[Params[1]].Remove(Nick)
	}
	
	_onQUIT(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		for Channel,NickList in % this.Channels
			NickList.Remove(Nick)
	}
	
	_onPRIVMSG(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (RegExMatch(Msg, "^\x01([^ ]+)(?: (.+))?\x01$", Match))
		{
			this.onCTCP(Nick,User,Host,Match1,Params,Match2,Data)
			return true ; true, we should stop from calling user function
		}
	}
	
	_on376(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.SendText("WHO " this.Nick " %uh")
	}
	
	;:ChanServ!ChanServ@services. MODE #maestrith +o GeekDude
	_onMODE(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		; MsgBox, ALERT!
		this.log("MODE DETECTED")
		if (Params[1] == this.Nick)
			return (False, this.log("USER MODE"))
		this.log("CHANNEL MODE")
		plus := true, i := 2, MODE := Params[2]
		Loop, Parse, MODE
		{
			this.log(A_LoopField)
			if (A_Loopfield == "+")
				plus := True
			else if (A_LoopField == "-")
				plus := False
			else
			{
				this.log("Plus: " Plus)
				i++
				this.log("i: " i)
				if (Plus)
					this.Channels[Params[1], Params[i], "MODE"].Insert(A_LoopField, true)
				else
					this.Channels[Params[1], Params[i], "MODE"].Remove(A_LoopField)
			}
		}
	}
	
	_on354(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Params[1] == this.Nick)
		{
			this.User := Params[2]
			this.Host := Params[3]
		}
	}
	
	_on353(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		Channel := this.Channels[Params[3]]
		
		for i, Nick in StrSplit(Msg, " ")
		{
			MODE := []
			; Only loop 5 times, just in case we hang somehow
			Loop, 5
			{
				; If we can convert the leading symbol into mode letter
				if (this.Prefix.Symbols.HasKey(Prefix := SubStr(Nick, 1, 1)))
				{
					; Add the mode letter to the mode table,
					;  and remove the symbol from the nick
					MODE.Insert(this.Prefix.Symbols[Prefix], true)
					Nick := SubStr(Nick, 2)
				}
				else
					break
			}
			Channel.Insert(Nick, {"MODE":MODE})
		}
	}
	
	_on005(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		for i,Param in Params
		{
			if (KeyVal := StrSplit(Param, "="))
				this.MODE.Insert(KeyVal[1], KeyVal[2])
			else
				this.MODE.Insert(KeyVal[1], "")
		}
		
		if (RegExMatch(this.MODE.PREFIX, "^\((.+)\)(.+)$", Match))
		{
			Loop, % StrLen(Match1)
			{
				this.Prefix.Letters.Insert(SubStr(Match1, A_Index, 1), SubStr(Match2, A_Index, 1))
				this.Prefix.Symbols.Insert(SubStr(Match2, A_Index, 1), SubStr(Match1, A_Index, 1))
			}
		}
	}
	
	GetMODE(Channel, MODE)
	{
		if (!this.isIn(Channel))
			return False
		
		Out := []
		for Nick, Meta in this.Channels[Channel]
		{
			Insert := true
			Needs := true
			Loop, Parse, MODE
			{
				if (A_LoopField == "+")
					Needs := true
				else if (A_LoopField == "-")
					Needs := false
				
				if A_LoopField is not alpha
					continue
				
				if (Needs && !Meta["MODE"].HasKey(A_LoopField)) ; If it should have, but doesn't
				{
					Insert := false
					break
				}
				else if (!Needs && Meta["MODE"].HasKey(A_LoopField)) ; If it shouldn't have, but does
				{
					Insert := false
					break
				}
			}
			if (Insert)
				Out.Insert(Nick, Meta)
		}
		return Out
	}
	
	SendText(msg, encoding="UTF-8")
	{
		msg .= "`r`n"
		this.Log(msg)
		VarSetCapacity(buffer, length := (StrPut(msg, encoding)*(((encoding="utf-16")||(encoding="cp1200")) ? 2 : 1)))
		StrPut(msg, &buffer, encoding)
		return this.TCP.send(&buffer, length-1)
	}
	
	IsIn(Channel)
	{
		return this.Channels.HasKey(Channel)
	}
	
	SendCTCP(Nick, Command, Text)
	{
		return this.SendPRIVMSG(Nick, Chr(1) . Command " " Text . Chr(1))
	}
	
	SendCTCPReply(Nick, Command, Text)
	{
		return this.SendNOTICE(Nick, Chr(1) . Command " " Text . Chr(1))
	}
	
	SendACTION(Channel, Text)
	{
		return this.SendCTCP(Channel, "ACTION", Text)
	}
	
	SendPRIVMSG(Channel, Text)
	{
		Header := "PRIVMSG " Channel " :"
		Max := 510 - StrLen(Header)
		Loop, Parse, Text, `n, `r
		{
			if !Text := A_LoopField
				Continue
			Loop
			{
				this.SendText(Header . SubStr(Text, 1, Max))
				Text := SubStr(Text, Max+1)
			} Until !Text
		}
	}
	
	SendJOIN(Channel)
	{
		return this.SendText("JOIN " Channel)
	}
	
	SendPART(Channel,Message="")
	{
		return this.SendText("PART " Channel (Message ? " :" Message : ""))
	}
	
	SendNICK(NewNick)
	{
		return this.SendText("NICK " NewNick)
	}
	
	SendQUIT(Message="")
	{
		return this.SendText("QUIT" (Message ? " :" Message : ""))
	}
	
	SendNOTICE(User, Text)
	{
		return this.SendText("NOTICE " User " :" Text)
	}
}