/+
 + 
 + Any funcitons used to help build the front end webpage here.
 +/

module chartzone.chartzone;

import std.algorithm;

import chartzone.db;

import vibe.vibe;

/**
 * Creates a table of charts from the list. Each row is comprised of rowLength items, defaulted to 3
 * */
ChartEntry[][] createChartTable(ChartEntry[] list, int rowLength=3){
	logInfo("Creating table from %s", list.map!(a => a.name));
	ChartEntry[][] table;
	while(list.length > 0){
		if(list.length < rowLength){
			table ~= list;
			break;
		}
		else{
			table ~= list[0..rowLength];
			list = list[rowLength..$];
		}
	}
	return table;
}