#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

Settings := Ini_Read("Settings.ini")
if (Settings.Bitly)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Search(Params[2]))
ExitApp
return

Search(Text)
{ ; Perform a search. Available searches: Forum, Ahk, Script, Docs, g
	static Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"
	, json, Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	
	if (Text ~= "i)^More")
	{
		if !FileExist("temp\Search.json")
			return "No results found"
		
		File := FileOpen("temp\Search.json", "r")
		json := Json_ToObj(File.Read())
		File.Close()
		
		json[1] += 1
		
		Desc := json[2].responseData.results[json[1]].titleNoFormatting
		Url := json[2].responseData.results[json[1]].url
		
		File := FileOpen("temp\Search.json", "w")
		File.Write(Json_FromObj(json))
		File.Close()
	}
	Else
	{
		Google.Open("GET", Base "&q=" UriEncode(Text), False)
		Google.Send()
		Response := Google.ResponseText
		
		json := Json_ToObj(Response)
		Desc := json.responseData.results[1].titleNoFormatting
		Url := json.responseData.results[1].url
		
		File := FileOpen("temp\Search.json", "w")
		File.Write("[" 1 "," Response "]")
		File.Close()
	}
	
	if !(Url && Desc)
		return "No results found"
	
	return htmlDecode(Desc) " - " Shorten(UriDecode(Url))
}

#Include %A_LineFile%\..\..\IRCBot.ahk