class IRC
{
	__New()
	{
		this.Channels := []
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
			if (!RegExMatch(Value, "^(?:\:([^\!\@ ]*)(?:(?:\!([^\@]*))?\@([^ ]*))? )?([^ ]+)(?: ([^ ]+(?: [^ ]+)*?))??(?: \:(.*))?$", Match))
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
		if (Nick == this.Nick)
			this.Channels.Insert(Params[1], [])
		else
			this.Channels[Params[1]].Insert(Nick, [""])
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
		if (!Index := Channel.MaxIndex())
			Index := 0
		
		for i, Nick in StrSplit(Msg, " ")
		{
			Prefix := SubStr(Nick, 1, 1)
			if Prefix in @,+
				Nick := SubStr(Nick, 2)
			else
				Prefix := ""
			
			Channel.Insert(Nick, [Prefix])
		}
	}
	
	GetMeta(Channel, prefix)
	{
		if !this.isIn(Channel)
			return False
		
		Out := []
		for Nick, Meta in this.Channels[Channel]
			if (Meta[1] == Prefix)
				Out.Insert(Nick)
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
		return this.SendText("PRIVMSG " Channel " :" Text)
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

