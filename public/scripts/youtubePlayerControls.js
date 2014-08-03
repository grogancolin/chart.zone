// 2. This code loads the IFrame Player API code asynchronously.
var tag = document.createElement('script');

tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

// This function creates an <iframe> (and YouTube player)
// after the API code downloads.
var player;
function onYouTubeIframeAPIReady() {

	//This code gets the playlist buttons on click attribute stips it takes the
	//video ID arg then sets up the player with that as the first video
	//TEMP needs refinine ment and there's probably a way of doing it with the api itself

	var onClickArgs = $('.cover:eq(0)').attr('onclick');
	var str = onClickArgs.split("changeVideo(")[1].split("'");
	var videoId = str[1];
	console.log(videoId)
	player = new YT.Player('player',
	{
		height: '400',
		width: '700',
		videoId: videoId,
		events: {
			'onReady': onPlayerReady,
			'onStateChange': onPlayerStateChange
		}
	});
}

//The API will call this function when the video player is ready.
function onPlayerReady(event) {
	event.target.playVideo();
}

//Listens for change of state of player like song ending
var size = $('.cover').size();
function onPlayerStateChange(state){
	var curIndex = $('.coverflow').coverflow("index");
	if(state.data === 0){
		//If order going up and at the end go to start
		if(curOrder === "next" && curIndex === size-1){
			$('.coverflow').coverflow('index', 0);
			$('.coverflow').coverflow('index', 1);
			$('.coverflow').coverflow('index', 0);
			changeToSongOrPlaylist(0);
		}
		//If curOrder going up and anywhere go to next
		else if(curOrder === "next"){
			$('.coverflow').coverflow('index', curIndex+1);
			$('.coverflow').coverflow('index', curIndex);
			$('.coverflow').coverflow('index', curIndex+1);
			changeToSongOrPlaylist(curIndex+1);
		}
		//If curOrder staic don't move
		else if(curOrder === "static"){
			//stay or maybe repeat
		}
		//If curOrder is shuffle go random within 0 to size range
		else if(curOrder === "shuffle"){
			var randomIndex;

			//No repeats
			do{
				randomIndex = Math.ceil(Math.random() * size);
			}while(randomIndex === curIndex && randomIndex != 0)

			$('.coverflow').coverflow('index', randomIndex);
			$('.coverflow').coverflow('index', randomIndex-1);
			$('.coverflow').coverflow('index', randomIndex);
			changeToSongOrPlaylist(randomIndex);
		}
		//If curOrder going down and at the start
		else if(curOrder === "prev" && curIndex === 0){
			$('.coverflow').coverflow('index', -1);
			$('.coverflow').coverflow('index', -2);
			$('.coverflow').coverflow('index', -1);
			changeToSongOrPlaylist(-1);
		}
		//If curOrder going down and anywhere
		else if(curOrder === "prev"){
			$('.coverflow').coverflow('index', curIndex-1);
			$('.coverflow').coverflow('index', curIndex);
			$('.coverflow').coverflow('index', curIndex-1);
			changeToSongOrPlaylist(curIndex-1);
		}
	}
}

function stopVideo() {
	player.stopVideo();
}


//Called by the onclick event and sends the video id
//where it will then be played
function changeVideo(videoId){
	player.loadVideoById(videoId);
}


function changePlaylist(listId){
	player.loadPlaylist({
			list: listId
	});
}



//Playing Order Controls
var curOrder;
function playOrder(order){
	curOrder = order;

	var styleObj = {
		"background": "rgb(243,197,189)",
		"background": "-moz-linear-gradient(top, rgba(243,197,189,1) 0%, rgba(232,108,87,1) 42%, rgba(234,40,3,1) 88%, rgba(255,102,0,1) 100%, rgba(199,34,0,1) 100%)",
		"background": "-webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(243,197,189,1)), color-stop(42%,rgba(232,108,87,1)), color-stop(88%,rgba(234,40,3,1)), color-stop(100%,rgba(255,102,0,1)), color-stop(100%,rgba(199,34,0,1)))",
		"background": "-webkit-linear-gradient(top, rgba(243,197,189,1) 0%,rgba(232,108,87,1) 42%,rgba(234,40,3,1) 88%,rgba(255,102,0,1) 100%,rgba(199,34,0,1) 100%)",
		"background": "-o-linear-gradient(top, rgba(243,197,189,1) 0%,rgba(232,108,87,1) 42%,rgba(234,40,3,1) 88%,rgba(255,102,0,1) 100%,rgba(199,34,0,1) 100%)",
		"background": "-ms-linear-gradient(top, rgba(243,197,189,1) 0%,rgba(232,108,87,1) 42%,rgba(234,40,3,1) 88%,rgba(255,102,0,1) 100%,rgba(199,34,0,1) 100%)",
		"background": "linear-gradient(to bottom, rgba(243,197,189,1) 0%,rgba(232,108,87,1) 42%,rgba(234,40,3,1) 88%,rgba(255,102,0,1) 100%,rgba(199,34,0,1) 100%)",
		"filter": "progid:DXImageTransform.Microsoft.gradient( startColorstr='#f3c5bd', endColorstr='#c72200',GradientType=0 )",
	}

	if(order === 'prev'){
		allNonSelected()
		$('#prev').css(styleObj);
	}
	else if(order === 'static'){
		allNonSelected()
		$('#static').css(styleObj);
	}
	else if(order === 'shuffle'){
		allNonSelected()
		$('#shuffle').css(styleObj);
	}
	else if(order === 'next'){
		allNonSelected()
		$('#next').css(styleObj);
	}
}

function allNonSelected(){

	var styleObj = {
		"background": "rgb(228,245,252)",
		"background": "-moz-linear-gradient(top, rgba(228,245,252,1) 0%, rgba(191,232,249,1) 18%, rgba(159,216,239,1) 33%, rgba(42,176,237,1) 100%)",
		"background": "-webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(228,245,252,1)), color-stop(18%,rgba(191,232,249,1)), color-stop(33%,rgba(159,216,239,1)), color-stop(100%,rgba(42,176,237,1)))",
		"background": "-webkit-linear-gradient(top, rgba(228,245,252,1) 0%,rgba(191,232,249,1) 18%,rgba(159,216,239,1) 33%,rgba(42,176,237,1) 100%)",
		"background": "-o-linear-gradient(top, rgba(228,245,252,1) 0%,rgba(191,232,249,1) 18%,rgba(159,216,239,1) 33%,rgba(42,176,237,1) 100%)",
		"background": "-ms-linear-gradient(top, rgba(228,245,252,1) 0%,rgba(191,232,249,1) 18%,rgba(159,216,239,1) 33%,rgba(42,176,237,1) 100%)",
		"background": "linear-gradient(to bottom, rgba(228,245,252,1) 0%,rgba(191,232,249,1) 18%,rgba(159,216,239,1) 33%,rgba(42,176,237,1) 100%)",
		"filter": "progid:DXImageTransform.Microsoft.gradient( startColorstr='#e4f5fc', endColorstr='#2ab0ed',GradientType=0 )"
 	}
 	$('.button').css(styleObj);
}

function changeToSongOrPlaylist(curIndex, size){
	var onClickArgs = $('.cover:eq(' + curIndex  + ')').attr('onclick');
	var videoId;
	var str = onClickArgs.split("changeVideo(")[1].split("'");
	videoId = str[1];
	changeVideo(videoId)
}


$(document).ready(function () {
	playOrder('next')
});




