#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: xkcd <Search>
	Desc: Searches xkcd for a comic and returns the alt text plus a link
*/

UserAgent := "GeekBot by GeekDude (Contact me on GitHub: https://github.com/G33kDude/MyRC)"
Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"

Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
Google.Open("GET", Base "&q=" UriEncode("site:xkcd.com -site:*.xkcd.com " Plugin.Param), false)
Google.SetRequestHeader("User-Agent", UserAgent)
Google.Send()

if !(Result := Jxon_Load(Google.ResponseText).responseData.results[1])
{
	Chat(Channel, "No results found")
	ExitApp
}

Url := UriDecode(Result.Url)

if !(Url ~= "^https?://xkcd.com/\d+/$")
{
	Chat(Channel, "Invalid url found: " Url)
	ExitApp
}

xkcd := ComObjCreate("WinHttp.WinHttpRequest.5.1")
xkcd.Open("GET", Url "info.0.json", false)
xkcd.SetRequestHeader("User-Agent", UserAgent)
xkcd.Send()

AltText := Jxon_Load(xkcd.responseText).alt
if AltText
	Chat(Channel, AltText " - " Url)
else
	Chat(Channel, "Something went wrong. - " Url)
ExitApp