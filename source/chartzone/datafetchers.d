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
	debug{ 
		writeln("Pos: Artist, Title");
		uint i=0;
		foreach(c; zip(artistMatch, songInfoMatch)){
			writefln("%s: %s, %s", i++, c[0]["artist"], c[1]["title"]);
		}
	}
	SongEntry[] songs;
	i=1;
	foreach(c; zip(artistMatch, songInfoMatch)){
		songs ~= SongEntry(
			c[1]["title"],
			c[0]["artist"],
			"youtubeid_unknown",
			i++,
			[]
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
	debug{ 
		writeln("Pos: Artist, Title");
		uint i=0;
		foreach(c; zip(artistMatch, songInfoMatch)){
			writefln("%s: %s, %s", i++, c[0]["artist"], c[1]["title"]);
		}
	}
	SongEntry[] songs;
	i=1;
	foreach(c; zip(artistMatch, songInfoMatch)){
		songs ~= SongEntry(
			c[1]["title"],
			c[0]["artist"],
			"youtubeid_unknown",
			i++,
			[]
			);
	}
	return ChartEntry(
			"BBC Top 40",
			songs
		);
}

public ChartEntry getBillboardTop100(){
	//urls http://www.billboard.com/charts/hot-100
	//http://www.billboard.com/charts/hot-100?page=1
	string[] urls;
	urls ~= "http://www.billboard.com/charts/hot-100";
	foreach(i; 1..9){
		urls ~= format("%s?page=%s", urls[0], i);
	}

	SongEntry[] songs;
	//foreach(url; urls){
		requestHTTP(urls[0],
			(scope req){},
			(scope res){
				string billboardStr = res.bodyReader.readAllUTF8();
				writefln("%s", billboardStr);
				// parse it as xml
				//auto html = readDocument(billboardStr);
				// get all the song titles and artists
				//auto songPositions = html.parseXPath(`//div[@class="listing_chart_listing]/article/a"`);
				//auto songtitles = html.parseXPath(`//div[@class="listing_chart_listing]/article/header/h1"`);
				//auto artists = html.parseXPath(`//div[@class="listing_chart_listing]/article/header/p/a"`);
				//writefln("Song postions: ", songPositions[0]);
			}
		);
	//}
	return ChartEntry("", "", songs);
}