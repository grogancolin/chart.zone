import std.stdio;

import vibe.d;

import chartzone.datafetchers;
import chartzone.db;

ChartzoneDB db;

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;
	router.get("/test", &hello);
	router.get("/chartlist", &chartlist);

	db = new ChartzoneDB("chartzone", "charts");
	db.add(getBillboardTop100());
	db.add(getBBCTop40());
	db.add(getBBCTop40Dance());
	db.add(getItunesTop100());

	listenHTTP(settings, router);
}

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
	if(chartname.length > 0 )
		res.renderCompat!("chartlist.dt", ChartEntry[], "charts")([db.getLatestChart(chartname)]);
	else
		res.renderCompat!("chartlist.dt", ChartEntry[], "charts")(db.getLatestCharts());
}
