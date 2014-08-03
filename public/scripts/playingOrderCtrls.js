//- This script controls the player controls boxs its a bit funky at the momment
//- This applies to the about advanced menu if you click outside it
$(document).mouseup(function (e)
{
	var container = $("#buttonBox");
	var div = document.getElementById('buttonBox');
	var header = document.getElementById('buttonBoxHead');
	var playerBox = document.getElementById('playerBox');
	var player = document.getElementById('player');
	var	hovercard = document.getElementById('hovercard');

	if(!container.is(':visible') && e.target == header){
		console.log('open')
		div.style.display = 'block';
		header.innerHTML = 'Playing Order Controls ▲';
		header.style.marginTop = '160px';
		return;
	}
	else if(e.target === header && container.is(':visible')){
		console.log('close')
		div.style.display = 'none';
		header.style.marginTop = '100px';
		header.innerHTML = 'Playing Order Controls ▼';
		return;
	}
	else if(!container.is(e.target) && container.has(e.target).length === 0 && container.is(':visible'))
	{
		console.log('close click anywhere')
		div.style.display = 'none';
		header.style.marginTop = '100px';
		header.innerHTML = 'Playing Order Controls ▼';
		return;
	}
});
