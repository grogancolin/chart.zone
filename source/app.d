import std.stdio;
import std.conv;
import core.thread;

import vibe.vibe;
import docopt;

import chartzone.datafetchers;
import chartzone.db;
import chartzone.youtube;
ChartzoneDB db;

/**
  * Custom main function
  */
public void main(string[] args){
   
    scope(exit){
            writefln("Shutting down.");
    }
    auto cli = docopt.docopt(doc, args[1..$], true, "0.01alpha");
    writefln("%s", cli);

    if(cli["update"].toString.to!bool){
        // go ahead and call the updater lib
        db = new ChartzoneDB(
                cli["--db"].toString, 
                cli["--collection"].toString);

        if(cli["CHART"].toString !in chartGetters){
            stderr.writefln("Error retrieving chart: %s. Ensure chart is in range: %s", 
                    cli["CHART"], chartGetters.keys);
            return;
        }

        db.add(chartGetters[cli["CHART"].toString]());
        return;
    }
    else if(cli["server"].toString.to!bool){
        //read settings file
        writefln("Starting server...");
        
        auto settings = new HTTPServerSettings;
        settings.port = 8080;
        //settings.port = cli["--port"].toString().to!ushort;
        settings.bindAddresses = ["::1", "127.0.0.1"];

        auto router = new URLRouter;
        router.get("/test", &hello);
        router.get("/chartlist", &chartlist);

        db = new ChartzoneDB("chartzone", "charts");

        listenHTTP(settings, router);

        // Run the Vibe event loop
        lowerPrivileges();
        runEventLoop();
    }
}
auto doc = "chartzone

    Usage:
        chartzone server [--settings SETTINGSFILE] [--port PORT]
        chartzone update CHART [--db DB] [--collection COLL]
        chartzone -h | --help
        chartzone --version

    Options:
        --server 
        --update CHART              The chart to get. Can be one of (CHARTSTRING).
        -s --settings SETTINGSFILE  [default: server.json]
        -p --port PORT              The port to run the server under [default: 8080]
        -d --db DB                  The mongo DB to update [default: chartzone]
        -t --collection COLL        The mongo Collection to update [default: charts]
        -h --help                   Show this screen.
        -v --version                Show version.
";

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

void hello(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody("Hello, World!");
}

void chartlist(HTTPServerRequest req, HTTPServerResponse res)
{
	//writefln("%s", req.query);
	string chartname;
	// check if query has chartname query
	if("chartname" in req.query)
		chartname = req.query["chartname"];
	if(chartname.length > 0 ){
		//res.renderCompat!("chartlist.dt", ChartEntry[], "charts")([db.getLatestChart(chartname)]);
		res.renderCompat!("chartlist.dt", ChartEntry[], "charts")([]);
    }
	else{
		//res.renderCompat!("chartlist.dt", ChartEntry[], "charts")(db.getLatestCharts());
		res.renderCompat!("chartlist.dt", ChartEntry[], "charts")();
    }
}
