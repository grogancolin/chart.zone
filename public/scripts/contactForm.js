/*
 * Controls the contact form...
 */


 $(document).ready(function(){
 	$("#contactForm").submit(function(event){
 		event.preventDefault();
 		var url = "/process-contact-form";
 		var posting = $.post(url, 
 		{
 			name : $('#name').val(), 
		    email : $('#email').val(),
		    message : $('#message').val()
 		});
 	
		posting.done(function(data) {
			if(data=="Success!"){
				$("#success").show();
				$("#errors").hide();
			}
			else{
				$("#success").hide();
				$("#errors").show();
			}
		});
 	});
 });
 /*
  * onsubmit callback for the form. Reads relevant info and POSTS to the server
  */
  /*
function handleSubmit(){
  var payload = 
  { 
  	name : $('#name').val(), 
    email : $('#email').val(),
    message : $('#message').val()
  };

  console.log("Payload -> " + JSON.stringify(payload));
  $.post("/process-contact-form", payload).
  	done(function( data ) {
    	console.log("Response from server: " + data);
  });
  
};*/
