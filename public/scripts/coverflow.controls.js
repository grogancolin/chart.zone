/****************************
*	Coverflow Controls.js
*	Controls dem coverflows
*****************************/

var size = $('.cover').size();

$(function() {
	$('.coverflow').coverflow({
		"duration":"fast"
	});

	$('.firstPos').click(function() {
		$('.coverflow').coverflow('index', 0);
		$('.coverflow').coverflow('index', 1);
		$('.coverflow').coverflow('index', 0);
		changeToSongOrPlaylist(1);
	});

	$('.middlePos').click(function() {
		var middle = Math.floor(($('.cover').length) / 2) - 1;
		$('.coverflow').coverflow('index',middle);
		$('.coverflow').coverflow('index',middle+1);
		$('.coverflow').coverflow('index',middle);
		changeToSongOrPlaylist(middle);
	});

	$('.lastPos').click(function() {
		$('.coverflow').coverflow('index', -1);
		$('.coverflow').coverflow('index', -2);
		$('.coverflow').coverflow('index', -1);
		changeToSongOrPlaylist(-1);
	});
});

function goToIndex(){
	var index = document.getElementById('goToBoxText').value;
	if(index.contains("<") || index.toLowerCase().contains("script")){
		console.log("Ah Ah Ah, you didn't say the magic word");
		console.log("https://www.youtube.com/watch?v=RfiQYRn7fBg&feature=kp")
		return;
	}
	if(index == "" || isNaN(index) || index.indexOf("") > 0)
		return;
	if(index == 1){
		$('.coverflow').coverflow('index', 0);
		$('.coverflow').coverflow('index', 1);
		$('.coverflow').coverflow('index', 0);
		var curIndex = $('.coverflow').coverflow('index');
		changeToSongOrPlaylist(curIndex);
	}
	if(index > 1 && index <= size){
		$('.coverflow').coverflow('index', index-1);
		$('.coverflow').coverflow('index', index-2);
		$('.coverflow').coverflow('index', index-1);
		console.log(index)
		var curIndex = $('.coverflow').coverflow('index');
		changeToSongOrPlaylist(curIndex);
	}
}

