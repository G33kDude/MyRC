#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: BTC [Currency Name]
	Desc: Shows the latest bitcoin exchange rates for a given currency, from bitpay. Defaults to USD
*/

Currency := Plugin.Param

http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
http.open("GET", "https://bitpay.com/rates", False)
http.Send()

Rates := []
for Index, Rate in Jxon_Load(http.responseText)["data"]
	Rates[Rate.code] := Rate.rate

if Rates.HasKey(Currency)
	Chat(Channel, "One Bitcoin is currently worth " Rates[Currency] " " Currency)
else
	Chat(Channel, "One Bitcoin is currently worth " Rates["USD"] " " Currency)
ExitApp
