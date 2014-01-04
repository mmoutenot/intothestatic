var videoQueue = [];
var socket = io.connect('http://localhost:3000');

socket.on('greet', function(data){
  console.log(data);
});

socket.on('newMedia-video', function(data){
  console.log(data);
  $(data).each(function(index, media){
    videoQueue.push(media);
  });
});
