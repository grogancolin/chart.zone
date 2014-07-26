Build with
$ dub build

Run with 
$ ./binaries/chartzone.bin


Web services currently available

	<hostname>/chartlist
	<hostname>/chartlist?chartname={BBC Top 40,BBC Top 40 Dance,Billboard Top 100}

	Service currently returns a simple web page containing a list of only the latest chartlist for each chart type supported.

Chart types available are:
	BBCTop40
	BBCTop40Dance
	BillboardTop100
	ItunesTop100

