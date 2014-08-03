/*************************************************************************
* Script Not included
* if we decide to use it need to include the 3 script files in layout.dt
*	script(src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js")
*	script(src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js")
*	script(type="text/javascript", src="scripts/changeBackgrounds.js")
**************************************************************************/

$(document).ready(function(){
	var totalBG = 11;
	var num = Math.ceil(Math.random() * totalBG);
	$('body').css('background-image', "url(" + "http://localhost:8080/images/background"+ num +".png" + ")");
});
