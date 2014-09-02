module chartzone.utils;
	import std.datetime;
	import vibe.vibe;
    import std.string;
    import std.regex;

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


public string getYoutubePlaylistTitle(string title){

	title = format("%s, Day: %s, Week: %s, Year: %s",
                         title,
                         SysTime(Clock.currStdTime()).dayOfWeek,
                         SysTime(Clock.currStdTime()).isoWeek,
                         SysTime(Clock.currStdTime()).year);

	return title;
}

public string removeExtraSpaces(string str){
    return str.replace(regex(r"\s{2,}"), " ");
}
