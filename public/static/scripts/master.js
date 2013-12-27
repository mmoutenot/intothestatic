var socket = io.connect('http://localhost:3000');

socket.on('greet', function(data){
  console.log(data);
});

socket.on('newMedia', function(data){
  console.log(data);
  // var data = $.parseJSON(update);
  // $(document).trigger(data);
});

var Media = {
    onNewMedia: function(ev) {
        console.log("New media:" + ev.media);
        // $(ev.media).each(function(index, media){
        //     $('source').attr('src', media.videos.standard_resolution.url).load(function(){
        //       var numChildren = $('#wrapper').children().length;
        //       var index = Math.floor(Math.random() * numChildren);
        //       var $container = $($('#wrapper').children()[index]);
        //   });
        // });
    },
    positionAll: function(){
        var columns = 5;
        var width = parseInt($('.container').css('width'));
      $('.container').each(function(index, item){
        $(item).css('top', 10+parseInt(index / columns) * width +'px')
          .css('left', 10+(index % columns) * width +'px');
      });
    }
};

$(document).bind("newMedia", Media.onNewMedia)
