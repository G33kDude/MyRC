StrSplit(String, Delim="", Omit="")
{
	StringSplit, String, String, %Delim%, %Omit%
	Out := []
	Loop, %String0%
		Out.Insert(String%A_Index%)
	return Out
}

StrReplace(Haystack, SearchText, ReplaceText="")
{
	StringReplace, OutputVar, Haystack, %SearchText%, %ReplaceText%, All
	return OutputVar
}

Object(p*)
{
	Out := []
	Loop, % p.MaxIndex()/2
		Out[p[A_Index*2-1]] := p[A_Index*2]
	return Out
}

Array(p*)
{
	p["base"] := CustomBase
	return p
}

class CustomBase
{
	InsertAt(Pos, Values*)
	{
		if Pos is not integer
			throw Exception("Parameter #1 invalid.", "", Pos)
		this.Insert(Pos, Values*)
	}
	
	RemoveAt(Pos, Length=1)
	{
		if Pos is not integer
			throw Exception("Parameter #1 invalid.", "", Pos)
		if Length is not integer
			return 0
		return this.Remove(Pos, Pos+Length-1)
	}
	
	Push(Values*)
	{
		return this.Insert(this.Length()+1, Values*)
	}
	
	Pop()
	{
		return this.Remove()
	}
	
	Delete(Key) ; TODO: Implement two-parameter mode
	{
		return this.Remove(Key, "")
	}
	
	Length()
	{
		MaxIndex := this.MaxIndex()
		return MaxIndex ? MaxIndex : 0
	}
}

; Assumes decimal integer format
Format(Input, Inputs*)
{
	RegEx := "O){"
	. "(?<Index>\d*)"
	. "(?:\:"
	.  "(?<Flags>[\-+0 #]*)"
	.  "(?<Width>\d*)"
	.  "(?<Precision>\.\d+)?"
	.  "(?<ULT>[ULT])?"
	.  "(?<Type>[diuxXofeEgGaApsc])?"
	. ")?}"
	
	Pos := 1, Out := "", i := 0
	while Pos := RegExMatch(Input, RegEx, Match, Pos+StrLen(Out))
	{
		Out := Match.Value()
		i := Match.Index ? Match.Index : i+1
		if !Inputs.HasKey(i)
			continue
		
		Out := Inputs[i]
		
		if (Match.Type == "x" || Match.Type == "X")
		{
			SetFormat, IntegerFast, H
			Out := SubStr(Out+0, 3)
			SetFormat, IntegerFast, D
			if (Match.Type == "x")
				StringLower, Out, Out
		}
		else if (Match.Type == "i")
			Out := Out + 0
		
		if (Match.ULT == "U")
			StringUpper, Out, Out
		else if (Match.ULT == "L")
			StringLower, Out, Out
		else if (Match.ULT == "T")
			StringUpper, Out, Out, T
		
		if (Match.Width)
		{
			if InStr(Match.Flags, "-")
				Loop, % Match.Width - StrLen(Out)
					Out := Out . " "
			else
			{
				Pad := InStr(Match.Flags, "0") ? "0" : " "
				Loop, % Match.Width - StrLen(Out)
					Out := Pad . Out
			}
		}
		
		Input := SubStr(Input, 1, Match.Pos-1)
		. Out . SubStr(Input, Match.Pos+Match.Len)
	}
	return Input
}
