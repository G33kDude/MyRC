StrSplit(String, Delim="", Omit=""){
	StringSplit, String, String, %Delim%, %Omit%
	Out := []
	Loop, %String0%
		Out.Insert(String%A_Index%)
	return Out
}

Array(p*)
{
	p["base"] := CustomBase
	return p
}

class CustomBase
{
	Push(p*)
	{
		this.Insert(p*)
	}
	
	Length()
	{
		mi := this.MaxIndex()
		return mi ? mi : 0
	}
	
	Pop()
	{
		return this.Remove()
	}
	
	RemoveAt(p*)
	{
		this.Remove(p*)
	}
	
	Delete(p)
	{
		return this.Remove(p, "")
	}
}