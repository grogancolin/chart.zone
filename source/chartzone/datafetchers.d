/**
	Module that contains functions to go to websites and collect chart information
*/

module chartzone.datafetchers;

import vibe.vibe;
import arsd.dom;

import chartzone.db : ChartEntry,GenreEntry,SongEntry;
import chartzone.youtube;
import chartzone.utils;

import std.regex;
import std.stdio;
import std.range;
import std.uri;
import std.algorithm;
import std.utf;

/**
  * This enum will be something like:
  * enum Chart : ChartMapper{
  *     ChartName = ChartMapper("ChartName", &getChart_ChartName),
  *     ...
  * }
  * makeEnum() scans the chartzone.datafetchers module for any functions beginning with
  * "getChart_", and adds that funciton to the enum for retrieval later.
  */
//mixin(makeEnum());
public ChartEntry function()[string] chartGetters;

public string[] chartTypes;

string mapFuncNamesToAA(string funcId){
        auto funNames = [__traits(allMembers, chartzone.datafetchers)]
            .filter!(a => a.startsWith(funcId))
            .map!(a => "\"" ~ a[funcId.length..$] ~ "\":&" ~ a[0..$])
            .joiner(",");
        string toRet;
        foreach(f; funNames){
            toRet ~= f;
        }
        return toRet;
}


shared static this(){
    mixin("chartGetters = [" ~ mapFuncNamesToAA("getChart_") ~ "];");
    chartTypes = chartGetters.keys;
}
/+
/**
* Calls the ChartMappers function pointer, and returns the ChartEntry
*/
public ChartEntry callChart(Chart type){
    return type();
}

    /**
    * Calls the ChartMappers function pointer, but only if the string passed exists.
    */
public ChartEntry callChart(string type){
    //decide what type of chart (if any) is represented by type
    mixin(makeSwitch!("type"));
}+/

/**
* Makes an enum string that contains all the functions in module mod with names
* starting with getChart
*/
private string makeEnum(){
    auto getChartFunctions = [__traits(allMembers, chartzone.datafetchers)].
        filter!(a => (a.startsWith("getChart_")));
    string toRet = "public enum Chart: ChartMapper {\n";
    foreach(item; getChartFunctions){
        toRet ~= "$NAME$ = ChartMapper(\"$NAME$\", &$FUNC_NAME$),\n".
            replaceMap(["$NAME$" : item[9..$], "$FUNC_NAME$" : item]);
    }
    toRet = toRet[0..$-2] ~ "\n}";
    return toRet;
}

private string makeSwitch(alias var)(){
    auto chartTypes = [__traits(allMembers, Chart)];
    string toRet = "switch("~var~"){\n";
    foreach(type; chartTypes){
    toRet ~= "\tcase \"$TYPE_STRING$\": return __traits(getMember, Chart, \"$TYPE_STRING$\")();\n"
        .replaceMap( [
					"$TYPE_STRING$" : type,
					"$TYPE_FUNC$" : type
				]);
	}
	toRet ~= "\tdefault: throw new ChartFetcherException(\"ERROR in searching for chart type: \"~ $VAR$);\n"
		.replaceMap( [ "$VAR$" : var] );
	toRet ~= "}";
	return toRet;
}

private struct ChartMapper{
    string name;
    ChartEntry function() fp;

    this(string name, ChartEntry function() fp){
        this.name = name;
        this.fp = fp;
    }

    string toString()
    {
        return this.name;
    }

    ChartEntry opCall(){
        return this.fp();
    }
}
/**
	Exception for Chartzone data fetchers.
*/
public class ChartFetcherException : Exception{
	this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
		super(message, file, line, next);
	}
}

/+ All Chart Getter functions from here on.
    NOTE: All ChartGetter functions should have the identity:
        ChartEntry getChart_XYZ();
    where XYZ is the name of the chart.
+/


/**
	Goes to the BBC radio1 chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.
*/
public ChartEntry getChart_BBCTop40(){
	logInfo("In datafetchers.d getBBCTOP40");
	// read from BBC
	string bbcTop40 = getDataFromURL("http://www.bbc.co.uk/radio1/chart/singles");

	Document htmlObj = new Document();
	htmlObj.parse(bbcTop40);
	auto artistListing = htmlObj.getElementsBySelector(`div[class="cht-entry-artist"]`);
	auto trackListing = htmlObj.getElementsBySelector(`div[class="cht-entry-title"]`);

	// ensure we have equal numbers
	if(artistListing.length == 0 || trackListing.length == 0){
		throw new ChartFetcherException("Received no 'div[class=\"cht-entry-artist\"]' tags from http://www.bbc.co.uk/radio1/chart/singles");
	}
	if(artistListing.length != trackListing.length){
		throw new ChartFetcherException("Error parsing information from http://www.bbc.co.uk/radio1/chart/singles");
	}

	//Create Playlist and get playlist Id
	string playListId = createPlaylist("BBC Top 40".getChartTitleDate());

	SongEntry[] songs;
	string nameToSearch;
	string videoId;
	auto artist_track = zip(artistListing, trackListing);
	uint i=1;
	foreach(ele; artist_track){
		nameToSearch = format("%s %s", ele[1].innerHTML.decode(), ele[0].innerHTML.decode());
		nameToSearch = nameToSearch.htmlEntitiesDecode;
		videoId = searchFor(nameToSearch);
		//Add song to playlist
		addVideoToPlaylist(playListId, videoId);
		songs ~= SongEntry(
			ele[1].innerHTML.htmlEntitiesDecode,
			ele[0].innerHTML.htmlEntitiesDecode,
			videoId,
			i++,
			["BBCTop40", "pop"]
			);
	}

	return ChartEntry(
			"BBCTop40", "uk", playListId,  songs
		);

}

/**
	Goes to the BBC radio1 dance chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.
*/
public ChartEntry getChart_BBCTop40Dance(){
	// read from BBC
	string bbcTop40 = getDataFromURL("http://www.bbc.co.uk/radio1/chart/dancesingles");



	Document htmlObj = new Document();
	htmlObj.parse(bbcTop40);
	auto artistListing = htmlObj.getElementsBySelector(`div[class="cht-entry-artist"]`);
	auto trackListing = htmlObj.getElementsBySelector(`div[class="cht-entry-title"]`);

	// ensure we have equal numbers
	if(artistListing.length == 0 || trackListing.length == 0){
		throw new ChartFetcherException("Received no 'div[class=\"cht-entry-artist\"]' tags from http://www.bbc.co.uk/radio1/chart/dancesingles");
	}
	if(artistListing.length != trackListing.length){
		throw new ChartFetcherException("Error parsing information from http://www.bbc.co.uk/radio1/chart/dancesingles");
	}


	//Create Playlist and get playlist Id
	string playListId = createPlaylist("BBC Top 40 Dance".getChartTitleDate());

	SongEntry[] songs;
	string nameToSearch;
	string videoId;

	auto artist_track = zip(artistListing, trackListing);
	uint i=1;
	foreach(ele; artist_track){
		nameToSearch = format("%s %s", ele[1].innerHTML.decode(), ele[0].innerHTML.decode());
		nameToSearch = nameToSearch.htmlEntitiesDecode;
		videoId = searchFor(nameToSearch);
		//Add song to playlist
		addVideoToPlaylist(playListId, videoId);
		songs ~= SongEntry(
			ele[1].innerHTML.htmlEntitiesDecode,
			ele[0].innerHTML.htmlEntitiesDecode,
			videoId,
			i++,
			["BBCTop40Dance", "Dance"]
			);
	}
	return ChartEntry(
		"BBCTop40Dance", "uk", playListId,  songs
		);
}


/**
	Gets the top 100 off billboard hot 100, and parses it to generate a ChartEntry object.

	Sample string that it parses
	/+
	<div class="listing chart_listing">
		<article class="song_review no_category chart_albumTrack_detail no_divider" id="node-1">
			<a id="rank_1"></a>
			<header>
				<span class="chart_position position-up position-greatest-gains">1</span>
				<h1>Fancy        </h1>
				<p class="chart_info">
					<a title="Iggy Azalea Featuring Charli XCX" href="/artist/5694588/iggy-azalea">Iggy Azalea Featuring Charli XCX</a>        <br />
		</p> . . . etc etc
     +/
*/
public ChartEntry getChart_BillboardTop100(){
	import arsd.dom;

	string[] urls;
	urls ~= "http://www.billboard.com/charts/hot-100";
	foreach(i; 1..10){ // create the URLs we're going to use
		urls ~= format("%s?page=%s", urls[0], i);
	}

	//Create Playlist and get playlist Id
	string playListId = createPlaylist("Billboard Top 100".getChartTitleDate());

	SongEntry[] songs;
	string nameToSearch;
	string videoId;

	foreach(url; urls){
		string billboardStr = getDataFromURL(url);

		Document htmlObj = new Document();
		htmlObj.parse(billboardStr);
		auto chartListing = htmlObj.getElementsBySelector(`div[class="listing chart_listing"]`);
		assert(chartListing.length==1,
			"Error parsing response from Billboard 100. Error: couldnt find <div class=\"listing chart_listing\">");

		foreach(songEntry; chartListing[0].getElementsByTagName(`article`)){
			string position = songEntry
				.getElementsByTagName(`a`)[0] // the first <a is the position
				.getAttribute("id")
				.strip()	//remove any pre and post whitespace
				.replace("rank_", "");

			string artist = songEntry
				.getElementsByTagName(`a`)[1] // the second <a> is the artist
				.getAttribute("title")
				.strip();

			string songTitle = songEntry
				.getElementsByTagName(`h1`)[0] // the first h1 is the song title
				.innerHTML()
				.chomp();

			nameToSearch = format("%s %s", songTitle, artist);
			nameToSearch = nameToSearch.htmlEntitiesDecode;
			videoId = searchFor(nameToSearch);
			//Add song to playlist
			addVideoToPlaylist(playListId, videoId);

			// writefln("%s: %s, %s", position, artist, songTitle);
			// append a new song object to songs[]
			songs ~= SongEntry(
					songTitle.htmlEntitiesDecode,
					artist.htmlEntitiesDecode,
					videoId,
					position.to!uint,
				["BillboardTop100", "pop"]
				);
		}
	}

	return ChartEntry("BillboardTop100", "usa", playListId,  songs);

}

/**
	Gets the iTunes Top 100 and puts it into a chart entry object
*/

public ChartEntry getChart_ItunesTop100(){
	import arsd.dom;
    string iTunesTop100 = getDataFromURL("http://www.apple.com/itunes/charts/songs/");

    //Replace all img tags as some are badly formed on Apple site
    auto imgRegex = ctRegex!(r"(<img[^>]+\>)","igm");
    iTunesTop100 = replaceAll(iTunesTop100, imgRegex, "");

    Document htmlObj = new Document();
	htmlObj.parse(iTunesTop100);
	auto chartListing = htmlObj.getElementsByTagName(`ul`);
	assert(chartListing.length >= 1,
			"Error parsing response from iTunes Top 100. Error: couldnt find at least one ul tag");

    //Create Playlist and get playlist Id
	string playListId = createPlaylist("iTunes Top 100".getChartTitleDate());

	SongEntry[] songs;
	string nameToSearch;
	string videoId;
    uint i = 0;
    //second ul is the list
    foreach(songEntry; chartListing[3].getElementsByTagName(`li`)){
    	string songTitle = "", artist = "";
    	songTitle = songEntry.getElementsByTagName(`h3`)[0].getElementsByTagName(`a`)[0].innerText();
    	artist = songEntry.getElementsByTagName(`h4`)[0].getElementsByTagName(`a`)[0].innerText();

    	if(songTitle != "" && artist != ""){
        	nameToSearch = format("%s %s", songTitle, artist);
			nameToSearch = nameToSearch.htmlEntitiesDecode;
			videoId = searchFor(nameToSearch);
			//Add song to playlist
			addVideoToPlaylist(playListId, videoId);
            songs ~= SongEntry(
					songTitle.htmlEntitiesDecode,
					artist.htmlEntitiesDecode,
					videoId,
					i++,
				["ItunesTop100", "pop"]
				);
         }
    }

	return ChartEntry("ItunesTop100", "global", playListId,  songs);

}

public string getDataFromURL(string url){
	return requestHTTP(url,
			(scope req){}
		).bodyReader.readAllUTF8();
}


