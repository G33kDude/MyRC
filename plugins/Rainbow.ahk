#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: BTC [Currency Name]
	Desc: Shows the latest bitcoin exchange rates for a given currency, from bitcoincharts. Defaults to USD
*/

Colors := ["13", "04", "07", "08", "09", "11", "12", "02", "06"]
for each, Char in StrSplit(Plugin.Param)
	out .= Chr(3) Colors[Mod(A_Index, 9)+1] Char

Chat(Channel, Out)
ExitApp