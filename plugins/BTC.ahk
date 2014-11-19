#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: BTC [Currency Name]
	Desc: Shows the latest bitcoin exchange rates for a given currency, from bitcoincharts. Defaults to USD
*/

Currency := Plugin.Param

if Currency not in usd,rur,eur,cnh,gbp
	Currency := "usd"

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.open("GET", "https://btc-e.com/api/3/ticker/btc_" Currency, false)
http.Send()

Rate := Json_ToObj(http.responseText)["btc_" currency].last

Chat(Channel, "One Bitcoin is currently worth " Rate " " Currency)
ExitApp