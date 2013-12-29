var socket = io.connect('http://localhost:3000');

socket.on('greet', function(data){
  console.log(data);
});

socket.on('newMedia-video', function(data){
  console.log(data);
  $(data).each(function(index, media){
    $('#videos').prepend('<video><source src="'+media.videos.low_resolution.url+'"></video>');
    //   $('source').attr('src', media.videos.standard_resolution.url).load(function(){
    //     var numChildren = $('#wrapper').children().length;
    //     var index = Math.floor(Math.random() * numChildren);
    //     var $container = $($('#wrapper').children()[index]);
    // });
  });
});
