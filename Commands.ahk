Search(CSE, Text, More=false)
{ ; Perform a search. Available searches: Forum, Ahk, Script, Docs, g
	static Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"
	, json, index := 1, Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	
	if More
		Index++
	Else
	{
		if (CSE = "Forum")
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
		
		Google.Open("GET", Base . URI, False), Google.Send()
		json := Json_ToObj(Google.ResponseText)
		Index := 1
	}
	
	Desc := json.responseData.results[Index].titleNoFormatting
	Url := json.responseData.results[Index].url
	
	if !(Url && Desc)
		return "No results found"
	
	return htmlDecode(Desc) " - " Shorten(UriDecode(Url))
}

; Modified by GeekDude from http://goo.gl/0a0iJq
UriEncode(Uri)
{
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	While Code := NumGet(Var, A_Index - 1, "UChar")
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
	|| Code >= 0x61 && Code <= 0x7A) ; a-z
	Res .= Chr(Code)
	Else
		Res .= "%" . SubStr(Code + 0x100, -1)
	SetFormat, IntegerFast, %f%
	Return, Res
}

UriDecode(Uri)
{
	Pos := 1
	While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos)
	{
		VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code,2)
		Loop, Parse, Code, `%
			NumPut("0x" A_LoopField, Var, A_Index-1, "UChar")
		StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, "UTF-8"), All
	}
	Return, Uri
}

HtmlDecode(Text)
{
	html := ComObjCreate("htmlfile")
	html.write(Text)
	return html.body.innerText
}

Shorten(LongUrl, SetKey="")
{
	static Shortened := {"http://www.autohotkey.net/": "http://ahk.me/sqTsfk"
	, "http://www.autohotkey.com/": "http://ahk.me/sDikbQ"
	, "http://www.autohotkey.com/forum/": "http://ahk.me/rJiLHk"
	, "http://www.autohotkey.com/docs/Tutorial.htm": "http://ahk.me/uKJ4oh"
	, "http://github.com/polyethene/robokins": "http://git.io/robo"
	, "http://ahkscript.org/": "http://ahk4.me/QMmuVo"}
	, http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	, Base := "http://api.bitly.com/v3/shorten"
	, login, apiKey
	
	if SetKey
	{
		apiKey := SetKey
		login := LongUrl
		return
	}
	
	if (Shortened.HasKey(LongUrl))
		return Shortened[LongUrl]
	
	if !(login && apiKey)
		return LongUrl
	
	Url := Base
	. "?login=" login
	. "&apiKey=" apiKey
	. "&longUrl=" UriEncode(Trim(LongUrl, " `r`n`t"))
	. "&format=txt"
	
	http.Open("GET", Url, False), http.Send()
	ShortUrl := Trim(http.responseText, " `r`n`t")
	Shortened.Insert(LongUrl, ShortUrl)
	
	return ShortUrl
}

ShowHelp(Command)
{
	static Commands := Ini_Read("Help.ini")
	if !Commands.HasKey(Command)
		Command := "Help"
	
	return "Usage: " Commands[Command].Usage "`n" Commands[Command].Desc
}
