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
				this.Log("Malformed message recieved")
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
		if (User == this.User)
			this.Nick := Msg
	}
	
	_onPING(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		this.SendText("PONG :" Msg)
	}
	
	_onJOIN(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		; if you're joining a channel you're not in
		if (User == this.User && !this.IsIn(Params[1]))
			this.Channels.Insert(Params[1])
	}
	
	_onPART(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (User == this.User)
			Loop, % (this.Channels.MaxIndex(),i:=0)
				if (this.Channels[++i] == Params[1])
					this.Channels.Remove(i--)
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
		For k,v in this.Channels
			if (v == Channel)
				return v
		return false
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
		ToolTip, % NewNick 
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

