#Include %A_LineFile%\..\..\Plugin.ahk
/*
	Usage: Zalgo <Text>
	Desc: H̷̡e͢ w̨͡h̢͟ơ͝ ̸͡w̢a̡͠i͝͡͏ts̵͝ ̨͘͢b̵͝e͘hi͠͏͏nd ̢t͟͟h͢è ͡w̛͏͝a͢͠l̷͡l
*/

Chat(Channel, Zalgo(Plugin.Param))
ExitApp

Zalgo(Text)
{
	Static Zalgo := []
	if !Zalgo.MaxIndex()
		for each, n in [0,6,43,44,67,12,13,18,19,31,32,33,58,71,72,73,74,75,77,35,34,76]
			Zalgo.Insert(Chr(n+789))
	
	for each, Char in StrSplit(Text)
	{
		Loop, % Rand(0, 3)
			Out .= Zalgo[Rand(1, Zalgo.MaxIndex())]
		Out .= Char
	}
	
	return Out
}