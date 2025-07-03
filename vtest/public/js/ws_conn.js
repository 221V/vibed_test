
function qi(name){ return document.getElementById(name); }
function qs(name){ return document.querySelector(name); }
function qa(name){ return document.querySelectorAll(name); }

var active      = false,
    token       = "sess",
    protocol    = window.location.protocol == 'https:' ? "wss://" : "ws://",
    //querystring = window.location.pathname + window.location.search,
    //querystring = window.location.pathname,
    querystring = window.location.pathname.substr(1), // rm heading "/"
    host        = window.location.host,
    port        = window.location.hostname == 'localhost' ? window.location.port : (window.transition ? window.transition.port : '');

var heartbeat = null;
var reconnectDelay = 1000;
var maxReconnects = 1000;
var not_reconnect = false;


// WebSocket Transport
var $ws = { heart: true, interval: 5000,
            creator: function(url) { return window.WebSocket ? new window.WebSocket(url) : false; },
            //onheartbeat: function() { this.channel.send('1'); } }; // send 'PING'
            onheartbeat: function() { this.channel.send( utf8_enc('1') ); } }; // send 'PING'

// Reliable Connection
var $conn = { onopen: nop, onmessage: nop, onclose: nop, onconnect: nop,
              send:  function(data)   { if (this.port.channel) this.port.channel.send(data); },
              close: function(manual) { if(this.port.channel){ clearInterval(heartbeat); if(manual === true){ not_reconnect = true } this.port.channel.close(); } } };

function nop(){  }
function bullet(url){ $conn.url = url; return $conn; }
function reconnect(){ setTimeout(connect, reconnectDelay); }
function next(){ $conn.port = $ws; return $conn.port ? connect() : false; }
function connect(){
  $conn.port.channel = $conn.port.creator($conn.url);
  $conn.port.channel.binaryType = "arraybuffer";
  $conn.port.channel.onmessage = function(e){ $conn.onmessage(e); };
  $conn.port.channel.onopen = function(){
    if($conn.port.heart) heartbeat = setInterval(()=>{ $conn.port.onheartbeat(); }, $conn.port.interval);
    $conn.onopen();
    $conn.onconnect(); };
  $conn.port.channel.onclose = function(){ $conn.onclose(); clearInterval(heartbeat); if(not_reconnect){ not_reconnect = false; }else{ reconnect(); } };
  return $conn; }

function ws_start(){
  //ws = new bullet(protocol + host + (port == "" ? "" : ":" + port) + "/ws" + querystring);
  ws = new bullet(protocol + host + (port == "" ? "" : ":" + port) + "/ws_" + querystring);
  ws.onmessage = function(evt){
    //console.log('evt: ', evt);
    if(evt.data === '' || evt.data === '0'){return}
    //for(var i = 0;i < protos.length; i++){ p = protos[i]; if(p.on(evt, p.do).status == "ok") return; }
    //if($bert.on(evt, $bert.do).status == "ok") return;
    try{
      console.log('evt.data: ', evt.data);
      eval(evt.data);
    }catch(e){
      console.error("Eval failed: \n", e);
      console.log('RESPONSE: ', evt.data);
    }
  };
  ws.onopen = function(){
    if(!active){
      active = true;
      console.log('ws Connect!');
      //ws.send('1');
    }
  };
  ws.onclose = function(){
    active = false;
    console.log('ws Disconnect!');
  };
  next();
}


/*
var $io = {};
$io.on = function onio(r, cb){
  if(is(r, 3, 'io')){
    if(typeof cb == 'function') cb(r);
    var evalex = utf8_arr(r.v[1].v);
    try{
      console.log("from n2o.js:46 \n", evalex);
      eval(evalex);
      return { status: "ok" };
    }catch(e){
      console.error("Eval failed: \n", e);
      return { status: '' };
    }
  }else return { status: '' };
};

var $file = {};
$file.on = function onfile(r, cb){
  //console.log('r ', r);
  //console.log('is ', is(r,13,'ftp'));
  if(is(r,13,'ftp')){
    if(typeof cb == 'function') cb(r);
    return { status: "ok" };
  }else return { status: ''};
};

var $bin = {};
$bin.on = function onbin(r, cb){
  if(is(r,2,'bin')){
    if(typeof cb == 'function') cb(r);
    return { status: "ok" };
  }else return { status: '' };
};


var $bert = {};
//$bert.protos = [$io, $bin, $file];
$bert.protos = [$io];
$bert.on = function onbert(evt, cb){
  if(ArrayBuffer.prototype.isPrototypeOf(evt.data) && (evt.data.byteLength > 0)){
    try{
      var erlang = dec(evt.data);
      //console.log(JSON.stringify(erlang));
      if(typeof cb  == 'function') cb(erlang);
      for(var i = 0; i < $bert.protos.length; i++){
        p = $bert.protos[i];
        var ret = p.on(erlang, p.do);
        if(ret != undefined && ret.status == "ok") return ret;
      }
    }catch(e){ console.error(e); }
    return { status: "ok" };
  }else return { status: "error", desc: "data" };
};

//var protos = [ $bert ];
*/

