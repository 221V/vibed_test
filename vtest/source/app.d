
//import vibe.vibe;
// https://github.com/vibe-d/vibe.d/blob/master/source/vibe/vibe.d

import vibe.core.core;
import vibe.http.router;
import vibe.http.server;
import vibe.http.fileserver;
import vibe.http.websockets;
import vibe.core.log;


void main(){
  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::1", "127.0.0.1"];
  
  //auto fsettings = new HTTPFileServerSettings;
  //fsettings.serverPathPrefix = "/static";
  
  auto router = new URLRouter;
  router.get("/", &index);
  ////router.get("static/*", serverStaticFiles("public/", fsettings) );
  
  //router.get("/", staticTemplate!"index.html"); // todo fix
  router.get("/ws", handleWebSockets(&ws_handle) );
  router.get("*", serveStaticFiles("public/"));
  
  //auto listener = listenHTTP(settings, &hello);
  auto listener = listenHTTP(settings, router);
  scope (exit){
    listener.stopListening();
  }
  
  logInfo("Please open http://127.0.0.1:8080/ in your browser.");
  runApplication();
}


void ws_handle(scope WebSocket sock){
  // simple echo server + :)
  while(sock.connected){
    auto msg = sock.receiveText();
    sock.send(msg ~ " :)");
  }
}


void index(HTTPServerRequest req, HTTPServerResponse res){
  res.writeBody("Hello, World!");
}


/*
void hello(HTTPServerRequest req, HTTPServerResponse res){
  res.writeBody("Hello, World!");
}
*/

