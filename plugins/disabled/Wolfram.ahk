#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Wolfram <Question>
	Desc: http://wolframalpha.com/
*/

Chat(Channel, Wolfram(Plugin.Param, Settings.Wolfram.AppID))
ExitApp

Wolfram(Query, AppID)
{
	static Wolfram := "http://api.wolframalpha.com/v2/query"
	
	Params := "?input=" UriEncode(Query) "&appid=" UriEncode(AppID)
	
	WA := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WA.Open("GET", Wolfram . Params, False)
	WA.Send()
	
	Data := WA.ResponseText
	
	xml := ComObjCreate("MSXML2.DOMDocument.6.0")
	xml.loadXML(data)
	
	nodes := xml.selectNodes("//plaintext")
	
	while, plaintext := nodes.item[A_Index-1]
	{
		Print(Plaintext.text)
		if (StrLen(plaintext.text) < 100)
		{
			title := plaintext.selectSingleNode("../../@title")
			out .= plaintext.text " - " title.text "`n"
		}
	}
	MsgBox, % Out
	return out
}

FileRead,xml,2014-09-26_09-48-27.xml
dom:=ComObjCreate("MSXML2.DOMDocument")
dom.loadxml(xml)
return