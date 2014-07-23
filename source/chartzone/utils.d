module chartzone.utils;

public string replaceMap(string str, string[string] keys){
    import std.array;
    foreach(key, val; keys){
        str = str.replace(key, val);
    }
    return str;
}

unittest{
	assert("Replace map test".replaceMap([
		"Replace" : "Substitution",
		"map" : "directions",
		"test" : "trial"]) == "Substitution directions trial");
}