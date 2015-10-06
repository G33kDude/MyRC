StrSplit(String, Delim="", Omit=""){
	StringSplit, String, String, %Delim%, %Omit%
	Out := []
	Loop, %String0%
		Out.Insert(String%A_Index%)
	return Out
}