#Include %A_ScriptDir%\lib ; Load includes from the lib directory
#Include Socket.ahk ; Include the sockets library
#Include IRCClass.ahk ; Include the IRC library

MyBot := new IRCBot() ; Create a new instance of your bot
MyBot.Connect("chat.freenode.net", 6667, "MyBotsName") ; Connect to an IRC server
MyBot.SendJOIN("#botters-test") ; Join a channel
return

class IRCBot extends IRC ; Create a bot that extends the irc library
{
	onPRIVMSG(Nick,User,Host,Cmd,Params,Msg,Data) ; On PRIVMSG (IRC protocol name for incoming message)
	{
		ToolTip, % "<" Nick "> " Msg ; Tooltip with the message
	}
	
	Log(Data) ; This function gets called for every raw line from the server
	{
		Print(Data) ; Print the raw data
	}
}

Print(Text)
{
	static _ := DllCall("AllocConsole") ; Create a console on script start
	StdOut := FileOpen("CONOUT$", "w") ; Open the output
	StdOut.Write(Text "`n") ; Write text to console output
}