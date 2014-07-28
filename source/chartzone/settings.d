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
            [ "charts" : "charts", 
              "youtube" : "youtube", 
              "youtubeCredentials" : "youtubeCredentials" 
            ];

    }

    public void parseSettings(Json j){

        if(auto d = "hostname" in j) hostname = d.get!string;
        if(auto d = "port" in j) port = cast(ushort)d.get!long;
        if(auto d = "dbName" in j) dbName = d.get!string;
        if(auto arr = "dbCollections" in j){
            foreach(obj; *arr){
                if(obj["name"].get!string in dbCollections)
                    dbCollections[obj["name"].get!string] = obj["value"].get!string;
            }
        }
    }
}

ChartzoneSettings parseSettingsFile(string file){
    ChartzoneSettings settings = new ChartzoneSettings();
    if(existsFile(file)){
        //read file as json
        auto data = stripUTF8Bom(cast(string)openFile(file).readAll());
        auto json = parseJson(data);
        settings.parseSettings(json);
        debug(chartzoneSettings){
            writefln("DEBUG : Chartzone settings: \n%s", serializeToJson(settings));
        }
    }
    return settings;
}
