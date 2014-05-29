/**
	Module that contains functions to go to websites and collect chart information
*/

module chartzone.datafetchers;

import vibe.vibe;
import chartzone.db : ChartEntry,GenreEntry,SongEntry;

import std.regex;
import std.stdio;
import std.range;

import kxml.xml;
/**
	Goes to the BBC radio1 chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.

	TODO: Should probably refactor to use dom.d also
*/
public ChartEntry getBBCTop40(){
	// read from BBC
	string bbcTop40;

	requestHTTP("http://www.bbc.co.uk/radio1/chart/singles",
			(scope req){},
			(scope res){
				bbcTop40 = res.bodyReader.readAllUTF8();
			}
		);
	auto artistsRegex = ctRegex!(`<div class="cht-entry-artist">(?P<artist>.*)</div>`, "gm");
	auto songInfoRegex = ctRegex!(`<div class="cht-entry-title">(?P<title>.*)</div>`, "gm");
	auto artistMatch = match(bbcTop40, artistsRegex);
	auto songInfoMatch = match(bbcTop40, songInfoRegex);

	SongEntry[] songs;
	uint i=1;
	foreach(c; zip(artistMatch, songInfoMatch)){
		songs ~= SongEntry(
			c[1]["title"],
			c[0]["artist"],
			"youtubeid_unknown",
			i++,
			["BBC Top 40", "pop"]
			);
	}
	return ChartEntry(
			"BBC Top 40",
			songs
		);
}

/**
	Goes to the BBC radio1 dance chart and gets top 40.
	Parses it into the ChartEntry struct and returns that.

	TODO: Should probably refactor to use dom.d also
*/
public ChartEntry getBBCTop40Dance(){
	// read from BBC
	string bbcTop40;

	requestHTTP("http://www.bbc.co.uk/radio1/chart/dancesingles",
			(scope req){},
			(scope res){
				bbcTop40 = res.bodyReader.readAllUTF8();
			}
		);
	auto artistsRegex = ctRegex!(`<div class="cht-entry-artist">(?P<artist>.*)</div>`, "gm");
	auto songInfoRegex = ctRegex!(`<div class="cht-entry-title">(?P<title>.*)</div>`, "gm");
	auto artistMatch = match(bbcTop40, artistsRegex);
	auto songInfoMatch = match(bbcTop40, songInfoRegex);

	SongEntry[] songs;
	uint i=1;
	foreach(c; zip(artistMatch, songInfoMatch)){
		songs ~= SongEntry(
			c[1]["title"],
			c[0]["artist"],
			"youtubeid_unknown",
			i++,
			["BBC Top 40", "Dance"]
			);
	}
	return ChartEntry(
			"BBC Top 40",
			songs
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
public ChartEntry getBillboardTop100(){
	import arsd.dom;

	string[] urls;
	urls ~= "http://www.billboard.com/charts/hot-100";
	foreach(i; 1..10){ // create the URLs we're going to use
		urls ~= format("%s?page=%s", urls[0], i);
	}

	SongEntry[] songs;

	foreach(url; urls){
		string billboardStr = requestHTTP(url, (scope req){} )
			.bodyReader.readAllUTF8();

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
				.getElementsByTagName(`a`)[1] // the second <a is the artist
				.getAttribute("title")
				.strip();

			string songTitle = songEntry
				.getElementsByTagName(`h1`)[0] // the first one is the song title
				.innerHTML()
				.chomp(); 

			// writefln("%s: %s, %s", position, artist, songTitle);
			// append a new song object to songs[]
			songs ~= SongEntry(
					songTitle,
					artist,
					"youtubeid_unknown",
					position.to!uint,
					["Billboard Top 100", "pop"]
				);
		}
	}
	//writefln("%s: %s, %s", position, artist, songTitle);
	return ChartEntry("Billboard Top 100", songs);
}