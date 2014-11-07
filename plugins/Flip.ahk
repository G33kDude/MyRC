#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Flip [SomeText]
	Desc: (╯°□°）╯︵ ʇxǝ┴ǝɯoS
*/

if Plugin.Param
{
	Upsidown := StrSplit("∀qƆpƎℲפHIſʞ˥WNOԀQɹS┴∩ΛMX⅄Zɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎz˙'¡¿")
	Normal   := StrSplit("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?")
	
	Map := []
	for Index, Char in Normal
		Map[Asc(Char)] := Upsidown[Index]
	
	for Index, Char in Upsidown
		Map[Asc(Char)] := Normal[Index]
	
	for each, Char in StrSplit(Plugin.Param)
		Out := (Map[Asc(Char)] ? Map[Asc(Char)] : Char) . Out
	
	Out := "(╯°□°）╯︵ " Out
}
else
	Out := "(╯°□°）╯︵ ┻━┻"

Chat(Channel, Out)
ExitApp