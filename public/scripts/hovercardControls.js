/**********************************************
*	Hovercard controls - As the name suggests
*	This controls the hovercard when hovering
*	on the main coverflow element
***********************************************/

$(document).ready(function(){

	$('.cover').hover(
		function(){
			var index = $('.coverflow').coverflow('index');
			$('#hovercard').css("display", "block");
		},
		function(){
				$('#hovercard').css("display","none");
		});
})

function hovercardData(artist, songTitle, chart, pos){
	$("#artist h3").html(artist);
	$("#songName h3").html(songTitle);
	$("#chartName h3").html(chart);
	$("#position h3").html(pos);
}
