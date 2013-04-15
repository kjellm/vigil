var SocketKlass = "MozWebSocket" in window ? MozWebSocket : WebSocket;
var ws = new SocketKlass('ws://' + window.location.host + '/messages');
ws.onmessage = function(msg){
  console.log(msg.data);
  var data = msg.data.split('.');
  var project = data[0];
  var task = data[1];
  var status = data[2];
  if (task === "build" && status === "started") {
    $("#" + project + " li").removeClass();
  }
  else {
    var klass = "failed";
    if (status === "started") {
      klass = "running";
    }
    else if (status === "done") {
      klass = "ok";
    }
     
    $("#" + project + "-" + task).removeClass();
    $("#" + project + "-" + task).addClass(klass);
  }
  $('#info').text(msg.data);
}
