#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Wikipedia <Search>
	Desc: Searches wikipedia for a page and returns the first sentence plus a link
*/

UserAgent := "GeekBot by GeekDude (Contact me on GitHub: https://github.com/G33kDude/MyRC)"
Base := "https://ajax.googleapis.com/ajax/services/search/web?v=1.0"

Google := ComObjCreate("WinHttp.WinHttpRequest.5.1")
Google.Open("GET", Base "&q=" UriEncode("site:en.wikipedia.org " Plugin.Param), false)
Google.SetRequestHeader("User-Agent", UserAgent)
Google.Send()

if !(Result := Jxon_Load(Google.ResponseText).responseData.results[1])
{
	Chat(Channel, "No results found")
	ExitApp
}

Url := UriDecode(Result.Url)
SplitPath, Url, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive

if !(OutDrive ~= "^https?://en\.wikipedia\.org")
{
	Chat(Channel, "Non wikipedia URL found: " OutDrive)
	ExitApp
}

Base := "http://en.wikipedia.org/w/api.php?action=query&prop=extracts&exintro=&format=xml"

Wiki := ComObjCreate("WinHttp.WinHttpRequest.5.1")
Wiki.Open("GET", Base "&titles=" UriEncode(OutFileName), false)
Wiki.SetRequestHeader("User-Agent", UserAgent)
Wiki.Send()

xml := ComObjCreate("MSXML2.DOMDocument")
xml.loadXML(Wiki.ResponseText)

html := ComObjCreate("htmlfile")
html.write(xml.selectSingleNode("//extract").text)

Page := html.body.innerText

if (Pos := InStr(Page, "."))
	Page := SubStr(Page, 1, Pos)
else
	Page := SubStr(Page, 1, 64)
Chat(Channel, Page " - " Shorten(Url))
ExitApp
