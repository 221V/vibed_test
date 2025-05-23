
import vibe.vibe;
import vibe.http.websockets;

void main(){
  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::1", "127.0.0.1"];
  
  auto router = new URLRouter;
  router.get("/", &index);
  
  //auto listener = listenHTTP(settings, &hello);
  auto listener = listenHTTP(settings, router);
  scope (exit){
    listener.stopListening();
  }
  
  logInfo("Please open http://127.0.0.1:8080/ in your browser.");
  runApplication();
}

void index(HTTPServerRequest req, HTTPServerResponse res){
  res.writeBody("Hello, World!");
}

/*
void hello(HTTPServerRequest req, HTTPServerResponse res){
  res.writeBody("Hello, World!");
}
*/

