module chartzone.main;

import std.stdio;
import std.conv;
import std.file;
import std.datetime;
import core.thread;

import vibe.vibe;
import docopt;

import chartzone.datafetchers;
import chartzone.db;
import chartzone.youtube;
import chartzone.soundcloud;
import chartzone.settings;
import chartzone.chartzone;


/*
 * Global data
 * */
public ChartzoneDB db;
ChartzoneSettings chartzoneSettings;
auto doc = "chartzone

    Usage:
        chartzone [--settings SETTINGSFILE] [--port PORT] server
        chartzone [--settings SETTINGSFILE] [--createYoutubePlaylist] update CHART ...
        chartzone -h | --help
        chartzone --version

    Options:
        --server
        --update CHART              The chart to get. Can be one of (CHARTSTRING).
        -w --createYoutubePlaylist  Whether to create the youtube playlist or not [default: false]
        -n --dontSearchYoutube      Whether to search youtube for the songid at creation time or not [default: false]
        -s --settings SETTINGSFILE  [default: server.json]
        -p --port PORT              The port to run the server under [default: 8080]
        -h --help                   Show this screen.
        -v --version                Show version.
";


shared static this(){
	// get timestamp from std.datetime
    if(!"logs/".exists){
        mkdir("logs");
    }
	string time = to!string(Clock.currTime().toISOString());
	auto logger = cast(shared)new HTMLLogger("logs/chartzone_"~time~".html");
	//logger.lock().format = FileLogger.Format.threadtime;
	registerLogger(logger);
}

/**
  * Custom main function
  */
public void main(string[] args){

	// Parse command line options
    auto cli = docopt.docopt(doc, args[1..$], true, "0.01alpha");
	// parse runtime settings
	if(!cli["--settings"].toString.exists){
		logFatal("Settings file not found at: %s", cli["--settings"].toString);
		return;
	}
	chartzoneSettings = parseSettingsFile(cli["--settings"].toString);

	// pass runtime settings to other modules
	setupDBModule(chartzoneSettings);
	setupYoutubeModule(chartzoneSettings);


	logInfo("Command line args passed: %s", cli);

    if(cli["update"].toString.to!bool){

        // go ahead and call the updater lib
        db = new ChartzoneDB(
				chartzoneSettings.dbName);

		string[] chartsToUpdate = cli["CHART"].asList;
		logInfo("Received update command, Updating charts: %s", chartsToUpdate);

		if(chartsToUpdate.length==1 && chartsToUpdate[0].toUpper == "ALL")
			chartsToUpdate = chartGetters.keys;
		string[] errorCharts;
		ChartEntry[] successCharts;

		foreach(chartName; chartsToUpdate){
			if(chartName !in chartGetters){
				logDebug("Chart %s not available. Skipping", chartName);
				errorCharts ~= chartName;
			}
			else{
				logDebug("Updating: %s", chartName);
				ChartEntry newEntry = chartGetters[chartName]();
				successCharts ~= newEntry;
			}
		}

		// Update the youtube ID's for each song, later add whatever functions are needed to get other video services
		foreach(ref chart; successCharts){
			logInfo("Searching for chart: %s", chart.name);
			foreach(ref song; chart.songs){

				//YOUTUBE STUFF    //.items[0].id.videoId.to!string
				Json youtubeObj = searchFor(song);
				//If youtube returns results
				if(youtubeObj.items.length>0){
					logInfo("YoutubeID : %s_%s - First ID: %s", song.songname, song.artist, youtubeObj.items[0].id.videoId.to!string);
					song.setYoutubeIds(youtubeObj);
					song.setYoutubeImages(youtubeObj);
				}
				//else put unknow url/id in db
				else{
					logInfo("Youtube Response contained no results");
					song.setYoutubeIdsEmpty;
					song.setYoutubeImagesEmpty;
				}

				//SOUNDCLOUD STUFF
				Json[] soundcloudObj = searchSoundcloud(song);
				//If soundcloud returns results
				if(soundcloudObj.length>0){
					logInfo("Soundcloud Artist_Title : %s_%s - URL:  %s - Artwork: %s", song.songname, song.artist, soundcloudObj[0].uri.to!string, soundcloudObj[0].artwork_url.to!string);
					song.setSoundcloudUrls(soundcloudObj);
					song.setSoundcloudImages(soundcloudObj);
				}
				//If no results just stick in an unknown-url
				else{
					logInfo("Soundcloud Response contained no results");
					song.setSoundcloudUrlsEmpty;
					song.setSoundcloudImagesEmpty;
				}
			}
		}

		// Create the playlist if required
		if(cli["--createYoutubePlaylist"].toString.to!bool){
			foreach(ref chart; successCharts){
				chart.playListId = createPlaylist(chart);
			}
		}

		// If we have any success charts, print out a status and add to the DB
		if(successCharts.length>0){
			logInfo("Committing charts to DB:\n\t%s", successCharts.map!(a=> a.name).join("\n\t"));
			foreach(chart; successCharts){
				db.add(chart);
			}
		}

		// print any errors we may have
		if(errorCharts.length>0){
			stderr.writefln("Error updating charts: ");
			logInfo("Error updating charts: %s", errorCharts);
			foreach(chart; errorCharts) {
				writefln("\t%s", chart);
			}
			writefln("Ensure charts are in range: \n\t%s", chartGetters.keys);
		}

        return;
    }
    else if(cli["server"].toString.to!bool){
        //read settings file
        ChartzoneSettings chartzoneSettings =
            parseSettingsFile(cli["--settings"].toString);
        logInfo("Starting server...");

        auto settings = new HTTPServerSettings;
        settings.useCompressionIfPossible = true;
		settings.port = chartzoneSettings.port;
        //settings.port = cli["--port"].toString().to!ushort;
        settings.bindAddresses = ["::1", "127.0.0.1"];

        auto router = new URLRouter;
		router.get("/", &chartlist);
        router.get("/about", &about);
        router.get("/contact", &contact);
		router.post("/process-contact-form", &processContactForm);
        router.get("*", serveStaticFiles("public/"));

        db = new ChartzoneDB(
                chartzoneSettings.dbName
            );

        listenHTTP(settings, router);
		logInfo("Server ready...");
        // Run the Vibe event loop
        lowerPrivileges();
        runEventLoop();
    }
}

void chartlist(HTTPServerRequest req, HTTPServerResponse res)
{
	logInfo("Chartlist request from: %s", req.clientAddress);
	//writefln("%s", req.query);
	string chartname;
	// check if query has chartname query
	if("chartname" in req.query)
		chartname = req.query["chartname"];
	if(chartname.length > 0 ){
		try{
			res.renderCompat!("music.dt", ChartEntry, "chart")( db.getLatestChart(chartname) );
		} catch (DBSearchException dbE){
			res.renderCompat!("error.dt", string, "msg")("Error finding chart with name: "~req.query["chartname"]);
		}
    }
	else{
		try{
			res.renderCompat!("chartlist.dt", ChartEntry[], "charts")(db.getLatestCharts());
		} catch (DBSearchException dbE){
			res.renderCompat!("error.dt", string, "msg")("Error finding charts in DB. Contact admins for assistance...");
		}
    }
}

void about(HTTPServerRequest req, HTTPServerResponse res)
{
    res.renderCompat!("about.dt")();
}


void contact(HTTPServerRequest req, HTTPServerResponse res)
{
    res.renderCompat!("contact.dt")();
}

void processContactForm(HTTPServerRequest req, HTTPServerResponse res){
	logDebug("Recieved contact form: \n\tName -> %s\n\tEmail ->%s\n\tMessage ->%s",
	         req.form["name"], req.form["email"], req.form["message"]);

	MessageEntry msg = MessageEntry(req.form["name"], req.form["email"], req.form["message"]);
	db.add(msg);
	res.writeBody("Success!");
}
