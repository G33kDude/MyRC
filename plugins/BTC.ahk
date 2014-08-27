#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: BTC [Currency Name]
	Desc: Shows the latest bitcoin exchange rates for a given currency, from bitcoincharts. Defaults to USD
*/

Currency := Plugin.Param
Rates := GetBTC()
if !Rates.HasKey(Currency)
	Currency := "USD"

Chat(Channel, "One Bitcoin is currently worth " Rates[Currency, "24h"] " " Currency)
ExitApp

; Fetch latest bitcoin info from bitcoincharts api
GetBTC()
{
	static API := "http://api.bitcoincharts.com/v1/weighted_prices.json"
	
	if !InStr(FileExist("temp"), "D")
		FileCreateDir, temp
	
	; Read the last bitcoin data from file.
	; If there is data, load it
	; If not, use a dummy to indicate we should fetch new data
	FileRead, File, temp\LastBTC.txt
	if File
		File := Json_ToObj(File)
	else
		File := [0,"Error"]
	
	LastTime := File[1], Elapsed := A_Now
	EnvSub, Elapsed, LastTime, Hours
	
	; If more than 1 hour has elapsed, or there is no saved last time
	if (Elapsed || !LastTime)
	{
		ToolTip, Fetching new prices
		
		; Fetch the prices
		BTC := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		BTC.Open("GET", API, False)
		BTC.Send()
		BTC := BTC.ResponseText
		
		; Decode the prices
		Rates := Json_ToObj(BTC)
		
		; Save the prices to file
		FileDelete, temp\LastBTC.txt
		FileAppend, [%A_Now%`, %BTC%], temp\LastBTC.txt
		
		ToolTip
	}
	else ; Read rates from file
		Rates := File[2]
	
	return Rates
}