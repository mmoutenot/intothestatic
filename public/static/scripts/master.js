var crt = new CRT();
var socket = io.connect(location.host);

function enqueueVideo(v){
  video_data = {
    'id' : v.id,
    'preview' : v.images.low_resolution.url,
    'sources' : {
      'hi' : v.videos.standard_resolution.url,
      'lo' : v.videos.low_resolution.url
    },
    'details' : {
      'username' : v.user.username,
      'profile_picture' : v.user.profile_picture,
      'post' : v.caption,
      'location' : v.location
    }
  }
  crt.enqueue(video_data);
}

function processNewMedia(data){
  console.log("New videos received");
  $(data).each(function(index, media){
    enqueueVideo(media);
  });
}

function createSocketListener(tagName){
  console.log('Subscribing to the ' + tagName + ' channel');
  socket.on('newMedia-'+tagName, processNewMedia);
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

function playNextVideo(){
  crt.playNext();
}

function enqueueVideosForTag(tagName){
    $.ajax({
      type: 'GET',
      url: '/tag/' + tagName
    }).done(function(data) {
      data['videos'].forEach(function(v){
        enqueueVideo(v);
      });
    });
}

$().ready(function() {
  // setTimeout(introduction(), 2500);
  $('input').attr('value', tag);

  $('a#next').click(playNextVideo);

  if (tag){
    enqueueVideosForTag(tag);
  }

  $('input').bind("enterKey",function(e){
    var newTag = $(this)[0].value;

    socket.removeListener('newMedia-'+tag, processNewMedia);
    console.log('unbinding from ' + tag + ' channel');

    crt.clearQueue();

    tag = newTag;
    createSocketListener(tag);

    console.log('tag submitted: ' + newTag);

    // get backlog of videos to start playing
    enqueueVideosForTag(tag);
  });

  $('input').keyup(function(e){
    if(e.keyCode == 13) {
      $(this).trigger("enterKey");
    }
  });

  $('#video_box').append(crt.$el_video);
  $('#details_wrap').append(crt.$el_details);
});

