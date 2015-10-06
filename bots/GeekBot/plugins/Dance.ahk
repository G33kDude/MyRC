#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Dance
	Desc: Everybody dance now!
*/

Bold := Chr(2)
Color := Chr(3)
Normal := Chr(15)
Underline := Chr(31)

Moves := ["(>^_^)>", "<(^_^<)"
, "^(^_^)^", "v(^_^)v"
, "<(^_^<)", "(>^_^)>"
, "^(^_^)>", "<(^_^)^"]

Loop, % Moves.MaxIndex()
{
	Out .= Color . Rand(2, 13)
	Move := Rand(1, Moves.MaxIndex())
	Out .= Moves.Remove(Move) " "
}

if !Rand(0, 9) ; 1 in 10
{
	Out .= Color . Rand(2, 13) "SUPER "
	Out .= Color . Rand(2, 13) "HAPPY "
	Out .= Color . Rand(2, 13) "FUN "
}
Out .= Normal . Bold ":D"

Chat(Channel, Out)
ExitApp