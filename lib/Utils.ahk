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

SetTimer(Func, Period, Params*)
{
	static Times := []
	WasCritical := A_IsCritical
	Critical ; Prevent race conditions
	
	; --- Erase duplicate timer (if any) ---
	; (I could use a second object to speed this up)
	for Time, Timers in Times
	{
		for Index, Timer in Timers
		{
			if (Func == Timer.Func)
			{
				Timers.Remove(Index)
				if !Timers.MaxIndex()
					Times.Remove(Time, "") ; Don't adjust other keys
				break, 2
			}
		}
	}
	
	; --- Add to list of times ---
	if (Period)
	{
		NewTime := A_TickCount + Abs(Period)
		if !IsObject(Times[NewTime])
			Times[NewTime] := []
		Times[Newtime].Insert({Period: Period, Func: Func, Params: Params})
	}
	
	; --- Set a new timer if necessary ---
	if (NewTime == Times.MinIndex())
		SetTimer, MyTimer, % -(Times.MinIndex() - TickCount)
	
	Critical, %WasCritical%
	return
	
	
	
	MyTimer:
	TickCount := A_TickCount
	Print(TickCount)
	; --- Get timer and delete entry if empty ---
	MinIndex := Times.MinIndex() ; Performance
	Timers := Times[MinIndex]
	Timer := Timers.Remove(1) ; First defined first serve. I might want to reverse it while setting for less overhead when calling
	if (!Timers.MaxIndex())
		Times.Remove(MinIndex)
	
	; --- Set another timer if period is positive ---
	if (Timer.Period > 0)
	{
		NewTime := TickCount + Timer.Period
		if !IsObject(Times[NewTime])
			Times[NewTime] := []
		Times[NewTime].Insert(Timer)
	}
	
	; --- Set next timer ---
	if (Times.MinIndex()-TickCount < 0)
		throw Exception("I'm not sure what happened here")
	SetTimer, MyTimer, % -(Times.MinIndex() - TickCount)
	
	; --- Call function ---
	Timer.Func.(Timer.Params*)
	return
}