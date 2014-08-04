#Persistent
#NoTrayIcon
#SingleInstance, Ignore
SetWorkingDir, %A_ScriptDir%\..

Params := []
Loop, %0%
	Params[A_Index] := %A_Index%

FileRead, Json, Docs.json
Docs := Json_ToObj(Json)
DocsList := []
For Name, Location in Docs
	DocsList[A_Index] := Name

Settings := Ini_Read("Settings.ini")
if (Settings.Bitly)
	Shorten(Settings.Bitly.login, Settings.Bitly.apiKey)

if (Doc := MatchItemFromList(DocsList, Params[2]))
	Out := Doc.Text " - " Shorten("http://ahkscript.org/" Docs[Doc.Text])
else
	Out := "No results found"

TCP := new SocketTCP()
TCP.Connect("localhost", 26656)
TCP.SendText(Params[1] "," Out)
ExitApp
return

; Modified from http://www.autohotkey.com/board/topic/35990-string-matching-using-trigrams/
MatchItemFromList(sList, sItem)
{
	iLength := StrLen(sItem)
	iTrigrams := iLength-2
	iCount := sList.MaxIndex()
	
	loop, %iCount%
		if (sList[A_Index] = sItem)
			return {"Fitness":100, "Index":A_Index, "Text": sList[A_Index]}
	if (iLength < 3)
		return False
	else ; Get Trigram count
	{
		sItem_ := []
		Loop, % iTrigrams
		{
			; Check if the trigram we're about to extract is unique
			i := InStr(sItem, SubStr(sItem, A_Index, 3), False, 1)
			if (i && i < A_Index)
			{
				sItem_[i] += 1 ; Not unique, add count to original
				sItem_[A_Index] := 0 ; discard current index
			}
			else
				sItem_[A_Index] := InStrCount(sItem, SubStr(sItem, A_Index, 3))
		}
	}
	
	sList_Diff := []
	;COMPARE TRIGRAMS
	Loop, % iCount
	{
		i := A_Index
		if (StrLen(sList[i]) < 3)
			sList_Diff[i] := -1
		else
		{
			sList_Diff[i] := 0
			Loop, %iTrigrams% ; Get trigram count
			{
				If (sItem_[A_Index])
					sList_Diff[i] += Abs(InStrCount(sList[i], SubStr(sItem, A_Index, 3)) - sItem_[A_Index])
			}
		}
	}
	
	iBestI := 0
	iBestD := 0x999999
	Loop, %iCount%
	{
		if (sList_Diff[A_Index] != -1 && sList_Diff[A_Index] < iBestD)
		{
			iBestD := sList_Diff[A_Index]
			iBestI := A_Index
		}
	}
	
	;Round((iTrigrams - iBestD) * 100 / iTrigrams)
	Return {"Fitness": iBestD, "Index":iBestI, "Text": sList[iBestI]}
}

;Returns the number of times a trigrams occurs in a string
InStrCount(ByRef Haystack, Trigram) {
	j := 0, i := 1
	Loop {
		i := InStr(Haystack, Trigram, False, i)
		If Not i
			Return j
		j += 1, i += 3
	}
}

#Include %A_LineFile%\..\..\IRCBot.ahk