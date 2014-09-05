module chartzone.settings;

/**
  * Module that holds run-time settings for chartzone
  * (e.g default Database, port etc);
  */

import vibe.vibe;
public class ChartzoneSettings{

    string hostname = "localhost";
    ushort port = 8080;
    string dbName = "chartzone";
    string[string] dbCollections;

    this(){
        hostname = "localhost";
        port = 8080;
        dbName = "chartzone";
        dbCollections = 
            [ "charts" 				: "charts", 
              "youtube" 			: "youtube", 
              "youtubeCredentials" 	: "youtubeCredentials",
			  "messages" 			: "messages"
            ];

    }

    public void parseSettings(Json j){

		if(auto d = "hostname" in j) { 
			logDebug("Read hostname as %s", d.get!string);
			hostname = d.get!string; 
		}
		if(auto d = "port" in j) {
			logDebug("Read port as %s", d.get!long);
			port = cast(ushort)d.get!long; 
		}
		if(auto d = "dbName" in j) {
			logDebug("Read dbName as %s", d.get!string);
			dbName = d.get!string;
		}
        if(auto arr = "dbCollections" in j){
			//logDebug("Read dbCollections as %s", arr);
            foreach(obj; *arr){
                if(obj["name"].get!string in dbCollections){
					logDebug("Updating dbCollections: %s=%s", obj["name"].get!string, obj["value"].get!string);
                    dbCollections[obj["name"].get!string] = obj["value"].get!string;
				} else {
					logDebug("Discarding: %s=%s", obj["name"].get!string, obj["value"].get!string);
				}
            }
        }
		logInfo("Parsed settings: %s", serializeToJson(this));
    }
}

ChartzoneSettings parseSettingsFile(string file){
	logInfo("parseSettingsFile - Parsing settings file: %s", file);
    ChartzoneSettings settings = new ChartzoneSettings();
    if(existsFile(file)){
        //read file as json
        auto data = stripUTF8Bom(cast(string)openFile(file).readAll());
        auto json = parseJson(data);
        settings.parseSettings(json);
    }
    return settings;
}
