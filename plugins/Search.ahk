#Include %A_LineFile%\..\..\Plugin.ahk

Chat(Channel, Search(Plugin.Param))
ExitApp

Search(Text)
{
	static Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"
	
	if !InStr(FileExist("temp"), "D")
		FileCreateDir, temp
	
	if (Text ~= "i)^More")
	{
		if !FileExist("temp\Search.json")
			return "No results found"
		
		FileRead, Json, temp\Search.json
		FileDelete, temp\Search.json
		
		Results := Json_ToObj(Json).responseData.results
		Results.Remove(1)
		
		for each, Result in Results
			Out .= HtmlDecode(Result.titleNoFormatting) "-" Shorten(UriDecode(Result.url)) "`n"
	}
	else
	{
		Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Google.Open("GET", Base "&q=" UriEncode(Text), False)
		Google.Send()
		Response := Google.ResponseText
		
		File := FileOpen("temp\Search.json", "w")
		File.Write(Response)
		File.Close()
		
		Result := Json_ToObj(Response).responseData.results[1]
		Out := HtmlDecode(Result.titleNoFormatting) " - " Shorten(UriDecode(Result.url))
	}
	
	return Out
}