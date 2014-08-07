function changeList(type){
	console.log("HEHEHEHEE")
	if(type === "music"){
		$('#moviesList').hide();
		$('#musicList').show();
	}
	else if(type === "movies"){
		$('#musicList').hide();
		$('#moviesList').show();
	}
}
