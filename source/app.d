module chartzone.main;

import std.stdio;
import std.conv;
import core.thread;

import vibe.vibe;
import docopt;

import chartzone.datafetchers;
import chartzone.db;
import chartzone.youtube;
import chartzone.settings;
import chartzone.chartzone;


/*
 * Global data
 * */
public ChartzoneDB db;
public static string settingsFile = "server.json";

auto doc = "chartzone

    Usage:
        chartzone [--settings SETTINGSFILE] [--port PORT] server 
        chartzone [--db DB] [--collection COLL] [--createYoutubePlaylist] update CHART ...
        chartzone -h | --help
        chartzone --version

    Options:
        --server
        --update CHART              The chart to get. Can be one of (CHARTSTRING).
        -w --createYoutubePlaylist  Whether to create the youtube playlist or not [default: false]
        -n --dontSearchYoutube      Whether to search youtube for the songid at creation time or not [default: false]
        -s --settings SETTINGSFILE  [default: server.json]
        -p --port PORT              The port to run the server under [default: 8080]
        -d --db DB                  The mongo DB to update [default: chartzone]
        -t --collection COLL        The mongo Collection to update [default: charts]
        -h --help                   Show this screen.
        -v --version                Show version.
";


shared static this(){
	// get timestamp from std.datetime
	import std.datetime;
	string time = to!string(Clock.currTime().toISOString());
	auto logger = cast(shared)new HTMLLogger("chartzone_"~time~".html");
	//logger.lock().format = FileLogger.Format.threadtime;
	registerLogger(logger);
}
/**
  * Custom main function
  */
public void main(string[] args){

    /*
     * Print message on exit.
     * Some things to add here maybe, is a list of updates that happened to the system over the course of its life.
     * May help in debugging
     */
    scope(exit){
            writefln("Shutting down.");
    }

    auto cli = docopt.docopt(doc, args[1..$], true, "0.01alpha");
	settingsFile = cli["--settings"].toString;
	setupYoutubeModule(cli["--settings"].toString);
	logInfo("Command line args passed: %s", cli);

    if(cli["update"].toString.to!bool){
		logInfo("Received update command, Updating charts: %s", cli["CHART"].asList);
        // go ahead and call the updater lib
        db = new ChartzoneDB(
                cli["--db"].toString,
                cli["--collection"].toString);

		string[] errorCharts;
		ChartEntry[] successCharts;
		foreach(chartName; cli["CHART"].asList){
			if(chartName !in chartGetters){
				logDebug("Chart %s no available. Skipping", chartName);
				errorCharts ~= chartName;
			}
			else{
				logDebug("Updating: %s", chartName);
				ChartEntry newEntry = chartGetters[chartName]();
				db.add(newEntry);
				successCharts ~= newEntry;
			}
		}

		if(successCharts.length>0){
			logInfo("Successfully updated charts: %s", successCharts.map!(a=> a.name));
			writefln("Successfully updated charts: ");
			foreach(chart; successCharts){
				writefln("\t%s", chart.name);
			}
		}

		if(cli["--createYoutubePlaylist"].toString.to!bool){
			foreach(chart; successCharts){
				chart.playListId = createPlaylist(chart);
				db.update(chart.name, chart.date, chart);
			}
		}

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
                chartzoneSettings.dbName,
                chartzoneSettings.dbCollections["charts"]
            );


        listenHTTP(settings, router);
		logInfo("Server ready...");
		writefln("Server ready...");
        // Run the Vibe event loop
        lowerPrivileges();
        runEventLoop();
    }
}

/*shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;
	router.get("/test", &hello);
	router.get("/chartlist", &chartlist);

	db = new ChartzoneDB("chartzone", "charts");

	listenHTTP(settings, router);
}*/

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
	writefln("Recieved contact form: \n\tName -> %s\n\tEmail ->%s\n\tMessage ->%s", 
	         req.form["name"], req.form["email"], req.form["message"]);

	MessageEntry msg = MessageEntry(req.form["name"], req.form["email"], req.form["message"]);
	db.addMessage(msg);
	res.writeBody("Success");
}
