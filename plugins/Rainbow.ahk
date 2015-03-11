#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Rainbow <Text>
	Desc: Makes things more 04c07o08l09o11r12f02u06l
*/

Colors := ["13", "04", "07", "08", "09", "11", "12", "02", "06"]
for each, Char in StrSplit(Plugin.Param)
	out .= Chr(3) Colors[Mod(A_Index, 9)+1] Char

Chat(Channel, Out)
ExitApp