#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: py <Code>
	Desc: Executes sandboxed python code
*/

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.Open("POST", "http://localhost:1234/test.py", false)
http.SetRequestHeader("User-Agent", UserAgent)
http.Send(Plugin.Params.Remove(1))

Chat(Channel, PRIVMSG.Nick ": " http.ResponseText)
ExitApp
