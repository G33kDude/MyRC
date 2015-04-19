; Modified by GeekDude from http://goo.gl/0a0iJq
UriEncode(Uri, RE="[0-9A-Za-z]") {
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	While Code := NumGet(Var, A_Index - 1, "UChar")
		Res .= (Chr:=Chr(Code)) ~= RE ? Chr : Format("%{:02X}", Code)
	Return, Res
}

UriDecode(Uri) {
	Pos := 1
	While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos)
	{
		VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code,2)
		Loop, Parse, Code, `%
			NumPut("0x" A_LoopField, Var, A_Index-1, "UChar")
		Decoded := StrGet(&Var, "UTF-8")
		Uri := SubStr(Uri, 1, Pos-1) . Decoded . SubStr(Uri, Pos+StrLen(Code)+1)
		Pos += StrLen(Decoded)+1
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
	
	try
	{
		http.Open("GET", Url, False), http.Send()
		ShortUrl := Trim(http.responseText, " `r`n`t")
		Shortened.Insert(LongUrl, ShortUrl)
		return ShortUrl
	}
	catch
		return LongUrl
}

Ini_Read(FileName)
{
	FileRead, File, %FileName%
	return File ? Ini_Reads(File) : ""
}

Ini_Reads(FileName)
{
	static RegEx := "^\s*(?:`;.*|(.*?)(?:\s+`;.*)?)\s*$"
	Section := Out := []
	Loop, Parse, FileName, `n, `r
	{
		if !(RegExMatch(A_LoopField, RegEx, Match) && Line := Match1)
			Continue
		if RegExMatch(Line, "^\[(.+)\]$", Match)
			Out[Match1] := (Section := [])
		else if RegExMatch(Line, "^\s*(.+?)\s*=\s*(.*?)\s*$", Match)
			Section[Match1] := Match2
	}
	return Out
}

Rand(Min, Max)
{
	Random, Rand, Min, Max
	return Rand
}

Run(Params*)
{
	for each, Param in Params
	{
		Param := RegExReplace(Param, "(\\*)""", "$1$1\""")
		RunStr .= """" Param """ "
	}
	Run, %RunStr%
}

RegExEscape(String)
{
	return "\Q" RegExReplace(String, "\\E", "\E\\E\Q") "\E"
}
