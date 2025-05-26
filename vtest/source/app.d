
//import vibe.vibe;
// https://github.com/vibe-d/vibe.d/blob/master/source/vibe/vibe.d

import vibe.core.core;
import vibe.http.router;
import vibe.http.server;
import vibe.http.fileserver;
import vibe.http.websockets;
import vibe.core.log;


import std.stdio;
import std.string;
//import std.array;


import memcached4d;

import std.conv : to;

import mustache;
alias MustacheEngine!(string) Mustache;



/* test unproper arguments order */
/* do not */
alias test_key1 = int;
alias test_key2 = int;

string test_args_types_mismash(test_key1 x, test_key2 y){
  return ( to!string(x) ~ " + " ~ to!string(y) ~ "  = " ~ to!string( x + y ) );
}


/* do like */
struct test_key3 { int v; }
struct test_key4 { int v; }

string test_args_types_mismash2(test_key3 x, test_key4 y){
  return ( to!string(x.v) ~ " + " ~ to!string(y.v) ~ "  = " ~ to!string( x.v + y.v ) );
}




void main(){
  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::1", "127.0.0.1"];
  
  //auto fsettings = new HTTPFileServerSettings;
  //fsettings.serverPathPrefix = "/static";
  
  auto router = new URLRouter;
  //router.get("/", &index);
  ////router.get("static/*", serverStaticFiles("public/", fsettings) );
  
  //router.get("/", staticTemplate!"index.html");
  router.get("/", serveStaticFile("public/index.html") );
  router.get("/ws", handleWebSockets(&ws_handle) );
  router.get("/test", &test);
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

/*
void index(HTTPServerRequest req, HTTPServerResponse res){
  res.writeBody("Hello, World!");
}
*/

/*
void hello(HTTPServerRequest req, HTTPServerResponse res){
  res.writeBody("Hello, World!");
}
*/


void test(HTTPServerRequest req, HTTPServerResponse res){
  auto cache = memcachedConnect("127.0.0.1:11211");
  
  
  
  /* test unproper arguments order */
  /* do not */
  test_key1 x = 5;
  test_key2 y = 2;
  //string r1 = test_args_types_mismash(x, y); // proper arguments order
  string r1 = test_args_types_mismash(y, x); // unproper - this compiles but we got logic error bug in runtime.. :( use struct for compiler check this..
  writeln("r1 = ", r1);
  
  /* do like */
  test_key3 x2 = test_key3(5);
  test_key4 y2 = test_key4(2);
  string r2 = test_args_types_mismash2(x2, y2); // proper arguments order
  //string r2 = test_args_types_mismash2(y2, x2); // unproper - this not compiles
  writeln("r2 = ", r2);
  
  
  
  writeln("get test1 = ", cache.get!string("test1"));
  
  string v1 = "value1 = 🔥🦀";
  
  if(cache.store("test1", v1) == RETURN_STATE.SUCCESS ){
    writeln("stored successfully");
    writeln("get stored: ", cache.get!string("test1") );
  }else{
    writeln("not stored");
  }
  
  string result = cache.get!string("test1");
  writeln("get test1 = ", result);
  
  writeln(cache.del("test1"));
  
  
  
  Mustache mustache2;
  auto context2 = new Mustache.Context;
  mustache2.path = "priv/folder2";
  mustache2.ext = "dtl";
  
  context2["param2"] = "blah blah blah ";
  
  Mustache mustache;
  auto context = new Mustache.Context;
  mustache.path = "priv";
  mustache.ext = "dtl";
  
  //context.useSection("boolean");
  //assert(mustache.renderString(" {{#boolean}}YES{{/boolean}}\n {{#boolean}}GOOD{{/boolean}}\n", context) == " YES\n GOOD\n");
  
  //{{#repo}}<b>{{name}}</b>{{/repo}}
  //{{^repo}}No repos :({{/repo}}
  //  to
  //No repos :(
  
  context["lang"] = "en";
  context["number1"] = 42;
  context.useSection("maybe1");
  
  context["part1"] = mustache2.render("part1", context2);
  context["result1"] = "Hello, World!\n" ~ result;
  
  res.headers["Content-Type"] = "text/html; charset=utf-8";
  
  //res.writeBody("Hello, World!\n" ~ result);
  res.writeBody( mustache.render("main", context) );
}


