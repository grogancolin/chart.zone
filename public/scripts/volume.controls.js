/*****************************************************************************
*
*		Volume Toggle controls, volume is 3 things the buttons the soundcloud volume
*		and the slider value when you change 1 all NEED to change or else it looks
*		poorly and what the user sees does not represent the truth
*
******************************************************************************/

$(function() {
    $("#slider").slider({
    	min: 0,
    	max: 100,
    	value: 50,
    	animate: true,
    	range: "min",
    	slide: function(event, ui) {
    		setVolume(ui.value / 100);
    	}
    });
});

//Create Global var
//Soundcloud api widget access
var widget = SC.Widget(document.getElementById('player'));

function setVolume(vol){
	widget.setVolume(vol);
	//Change the low volume picture
	if(vol != 0){
		$('#volumeLow').css({"background" : "url('../images/audio_volume_low.png') no-repeat",
 							 "background-position" :"center",
    						 "margin-right" : "10px",
    						 "height" : "100%"
 	 });
	}
	else{
		$('#volumeLow').css({"background" : "url('../images/audio_volume_muted.png') no-repeat",
 							 "background-position" :"center",
    						 "margin-right" : "10px",
    						 "height" : "100%"
 	 });
	}
}

function mute(){
	//Set Soundcloud to 0
	widget.setVolume(0);
	//Set slider to 0
	$("#slider").slider('value',0);
	//Change to mute picture
 	$('#volumeLow').css({"background" : "url('../images/audio_volume_muted.png') no-repeat",
 						 "background-position" :"center",
    					 "margin-right" : "10px",
    					 "height" : "100%"
 	 });
}

function maxVol(){
	//Set soundclound sound to 100
	widget.setVolume(100);
	//Set slider to 0
	$("#slider").slider('value',100);
	//Set the image back to the low one not muted
	$('#volumeLow').css({"background" : "url('../images/audio_volume_low.png') no-repeat",
 						 "background-position" :"center",
    					 "margin-right" : "10px",
    					 "height" : "100%"
 	 });
}

