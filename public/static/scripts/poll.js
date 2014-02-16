var minID = -1;

function poll(){
  setTimeout(function(){
    $.ajax({
      type: 'GET',
      url: '/tag/'+tag+'/min_id/' + minID
    }).done(function(data){
      data['videos'].forEach(function(v){
        console.log(v);
        enqueueVideo(v);
      });
      poll(tag);
    });
  }, 5000);
}
