

import memcached4d;


import std.stdio : writeln;

import vibe.core.core;
import vibe.http.router;
import vibe.http.server;
import vibe.http.fileserver;
import vibe.http.websockets;
import vibe.core.log;


import mustache;
alias MustacheEngine!(string) Mustache;



void memcached_test(HTTPServerRequest req, HTTPServerResponse res){
  auto cache = memcachedConnect("127.0.0.1:11211");
  
  
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
  
  //{{escaped_html_tags}}
  //{{{not_escaped_html_tags}}}
  
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

