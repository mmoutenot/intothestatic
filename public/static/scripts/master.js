var videoQueue = [];
var socket = io.connect('http://localhost:3000');

socket.on('greet', function(data){
  console.log(data);
});

var urlSplit = window.location.pathname.split('/');

function processNewMedia(data){
    var playOnAdd = false;
    var videoPlaying = $('video')[0].paused;
    if(videoQueue.length == 0 &&
      ($('video').attr('src') == 'undefined' || $('video').attr('src') == '' || !videoPlaying)){
      playOnAdd = true;
    }

    $(data).each(function(index, media){
      videoQueue.push(media);
      if(playOnAdd) playNextVideo();
    });
}

function createSocketListener(tagName){
  console.log('Subscribing to the ' + tagName + ' channel');
  socket.on('newMedia-'+tagName, processNewMedia);
}

function playNextVideo(){
  var nextVideo = videoQueue.shift();
  var url = nextVideo.videos.standard_resolution.url;
  console.log("Playing " + url);
  $video = $('video')[0];
  $video.setAttribute('src', url);
  $video.play();
}

function introduction() {
  var $input = $('input')[0];
  deleteLastLetter($input);
}

var defaultChannel = tag;
function deleteLastLetter($input) {
  var tag = $input.value;
  var delay = 1000 * Math.random();
  $input.focus();
  if (tag.length > 0){
    setTimeout(function(){
      $input.value = tag.slice(0, tag.length-1);
      deleteLastLetter($input);
    }, delay + 200);
  } else {
    setDefaultChannel($input);
  }
}

function setDefaultChannel($input) {
  var tag = $input.value;
  var delay = 800 * Math.random();
  $input.focus();
  if (tag.length != defaultChannel.length){
    setTimeout(function(){
      $input.value+=defaultChannel[tag.length];
      setDefaultChannel($input);
    }, delay + 100);
  } else {
    $('input').trigger("enterKey");
  }
}

$().ready(function() {
  $('#wrap').tubular({videoId: 'bf7NbRFyg3Y', repeat: true});
  setTimeout(introduction(), 2500);

  $('input').bind("enterKey",function(e){
    var newTag = $(this)[0].value;

    socket.removeListener('newMedia-'+tag, processNewMedia);
    console.log('unbinding from ' + tag + ' channel');

    tag = newTag;
    createSocketListener(tag);

    console.log('tag submitted: ' + newTag);

    $.ajax({
      type: 'GET',
      url: '/tag/' + newTag
    }).done(function(data) {
      console.log(data);
      videoQueue = data['videos'];
      playNextVideo();
    });
  });

  $('input').keyup(function(e){
    if(e.keyCode == 13)
    {
      $(this).trigger("enterKey");
    }
  });

});

