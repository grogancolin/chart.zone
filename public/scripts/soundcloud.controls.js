/******************************************************************************************************
*
*	Sound Cloud Widget API javascript code
*	Dependancy is the soundcloud.embed.min.js
*	For instructions on this code visit https://developers.soundcloud.com/docs/api/html5-widget
*
********************************************************************************************************/

//Current Order
var curOrder;


/*****************************************************************
*	On Ready bind to events
******************************************************************/
$(document).ready(function() {
	//Inital bind on ready
	var widget = SC.Widget(document.getElementById('player'));
		widget.bind(SC.Widget.Events.READY, function() {
			console.log("Soundcloud widget playing");
			widget.setVolume(0.5);
	});

	widget.bind(SC.Widget.Events.PLAY_PROGRESS, function() {
		var vol = $('#slider').slider("option", "value");
		widget.setVolume(vol/100);
	});


	//Sets the current playing order to "next" on ready
	playOrder('next');


	//When a song finishes
	widget.bind(SC.Widget.Events.FINISH, function(){
		var curIndex = $('.coverflow').coverflow("index");
		//If order going up and at the end go to start
		if(curOrder === "next" && curIndex === size-1){
			$('.coverflow').coverflow('index', 0);
			$('.coverflow').coverflow('index', 1);
			$('.coverflow').coverflow('index', 0);
			changeSongOnFinish(0);
		}
		//If curOrder going up and anywhere go to next
		else if(curOrder === "next"){
			$('.coverflow').coverflow('index', curIndex+1);
			$('.coverflow').coverflow('index', curIndex);
			$('.coverflow').coverflow('index', curIndex+1);
			changeSongOnFinish(curIndex+1);
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
			changeSongOnFinish(randomIndex);
		}
		//If curOrder going down and at the start
		else if(curOrder === "prev" && curIndex === 0){
			$('.coverflow').coverflow('index', -1);
			$('.coverflow').coverflow('index', -2);
			$('.coverflow').coverflow('index', -1);
			changeSongOnFinish(-1);
		}
		//If curOrder going down and anywhere
		else if(curOrder === "prev"){
			$('.coverflow').coverflow('index', curIndex-1);
			$('.coverflow').coverflow('index', curIndex);
			$('.coverflow').coverflow('index', curIndex-1);
			changeSongOnFinish(curIndex-1);
		}
	})
});

/*************************************************************************
*	Changes to the song in the elem your are going to change to's onclick
**************************************************************************/
function changeSongOnFinish(curIndex, size){
	var elemOnClickArgs = $('.cover:eq(' + curIndex  + ')').attr('onclick');
	var trackUrl;
	var str = elemOnClickArgs.split("changeSong(")[1].split("'");
	trackUrl = str[1];
	changeSong(trackUrl)
}

/**********************************************
*	Changes the song
*	This is in the .cover elem as onClick func
***********************************************/
function changeSong(trackUrl){
	var widget = SC.Widget(document.getElementById('player'));
	widget.load(trackUrl, {
		auto_play : true,
		visual : true,
		show_comments : false,
		hide_related : true
	})
}


/**************************************
* Playing order configuration
***************************************/
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

	//Internal function to set css
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
}


/************************************************************
*	Changes to song or playlist when using coverflow controls
************************************************************/
function changeSongWithControls(curIndex){
	var onClickArgs = $('.cover:eq(' + curIndex  + ')').attr('onclick');
	var trackUrl;
	var str = onClickArgs.split("changeSong(")[1].split("'");
	trackUrl = str[1];
	changeSong(trackUrl);
}
