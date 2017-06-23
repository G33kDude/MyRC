#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: aesthetic [SomeText]
	Desc: aesthetic -> Ａ Ｅ Ｓ Ｔ Ｈ Ｅ Ｔ Ｉ Ｃ
*/

if Plugin.Param {
	nor := StrSplit("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!#%&/\()=?@£${[]}^*")
	aes := StrSplit("ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ１２３４５６７８９０！＃％＆／＼（）＝？＠£＄｛［］｝＾＊")

	for index, letter in nor, ref:=[]
		ref[Asc(letter)] := aes[index]

	for index, letter in StrSplit(Plugin.Param)
		Out .= ref[Asc(letter)] ? ref[Asc(letter)] : letter

} else
	Out := "ＡＥＳＴＨＥＴＩＣ"

Chat(Channel, Out)
ExitApp
