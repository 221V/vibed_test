
alias uint8  = ubyte;

//import vibe.vibe;
// https://github.com/vibe-d/vibe.d/blob/master/source/vibe/vibe.d

import vibe.core.core;
import vibe.http.router;
import vibe.http.server;
import vibe.http.fileserver;
import vibe.http.websockets;
import vibe.core.log;

import ws_bert_login : ws_bert_handle, login_test; // login - logged - logout -- via ws with bert ++ memcached + postgresql for sessions


import std.string;
import std.array;
import std.algorithm;


import std.datetime : SysTime, Clock; // , dur;
//import core.sync.mutex : Mutex;
import std.concurrency : spawn;
import vibe.core.concurrency;
import vibe.core.core : Task, sleep;
import core.time : Duration, dur;


struct UserState{
  string client_id;
  SysTime last_online_at;
  
  this(string client_id, SysTime last_online_at) pure nothrow @safe{
    this.client_id = client_id;
    this.last_online_at = last_online_at;
  }
}

alias UserStateMap = UserState[string];

class UserStateManager{
  private UserStateMap states;
  private Object lockObj;
  
  this(){
    lockObj = new Object();
  }
  
  bool contains(string client_id){
    synchronized(lockObj){
      return (client_id in states) !is null;
    }
  }
  
  void addOrUpdate(string client_id){
    synchronized(lockObj){
      auto now = Clock.currTime();
      states.remove(client_id);
      states[client_id] = UserState(client_id, now);
    }
  }
  
  void cleanup(){
    synchronized(lockObj){
      auto now = Clock.currTime();
      auto toRemove = states.byKey
        .filter!(k => (now - states[k].last_online_at).total!"seconds" > 30)
        .array;
      
      foreach(client_id; toRemove){
        states.remove(client_id);
      }
    }
  }
  
  size_t length() const{
    synchronized(lockObj){
      return states.length;
    }
  }
}

__gshared UserStateManager userStateManager;



import memcached4d;

import std.conv : to;

import tr;

import mustache;
alias MustacheEngine!(string) Mustache;


import vibe.db.postgresql;
import vibe.data.bson;
//import vibe.data.json;
// https://github.com/vibe-d/vibe.d/blob/master/source/vibe/vibe.d

PostgresClient[] clients;

import settings_toml; // get settings from settings.toml, settings keys, settings validation etc




/* test unproper arguments order */
/* do not */
/*
alias test_key1 = int;
alias test_key2 = int;

string test_args_types_mismash(test_key1 x, test_key2 y){
  return ( to!string(x) ~ " + " ~ to!string(y) ~ "  = " ~ to!string( x + y ) );
}
*/


/* do not */
/*
import std.typecons : Typedef;

alias test_key5 = Typedef!int;
alias test_key6 = Typedef!int;

string test_args_types_mismash(test_key5 x, test_key6 y){
  return ( to!string(x) ~ " + " ~ to!string(y) ~ "  = " ~ to!string( x + y ) );
}
*/


/* do like */

import std.typecons : Typedef;

alias test_key5 = Typedef!(int, int.init, "key5");
alias test_key6 = Typedef!(int, int.init, "key6");

string test_args_types_mismash(test_key5 x, test_key6 y){
  return ( to!string(x) ~ " + " ~ to!string(y) ~ "  = " ~ to!string( x + y ) );
}


/* or -  do like */
struct test_key3 { int v; }
struct test_key4 { int v; }

string test_args_types_mismash2(test_key3 x, test_key4 y){
  return ( to!string(x.v) ~ " + " ~ to!string(y.v) ~ "  = " ~ to!string( x.v + y.v ) );
}



void startCleanupTask(){
  while(true){
    writeln("startCleanupTask();");
    userStateManager.cleanup();
    //sleep(dur!"hours"(1)); // every 1 hour = 3600 sec
    sleep(dur!"seconds"(30)); // every 30 sec
  }
}



void main(){
  read_settings_toml(); // read settings, settings validation
  
  uint conn_num = cast(uint) toml_s[s_toml_db][s_toml_db_conn_num].integer();
  uint8 i = cast(uint8) conn_num;
  // https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING
  // https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS
  //client = new PostgresClient("host=localhost port=5432 dbname=mydb user=username password=pass connect_timeout=5", 100);
  while(i > 0){
    //writeln("i = ", i);
    clients ~= new PostgresClient( "host=" ~ toml_s[s_toml_db][s_toml_db_host].str() ~
      " port=" ~ toml_s[s_toml_db][s_toml_db_port].str() ~
      " dbname=" ~ toml_s[s_toml_db][s_toml_db_name].str() ~
      " user=" ~ toml_s[s_toml_db][s_toml_db_user].str() ~
      " password=" ~ toml_s[s_toml_db][s_toml_db_pass].str() ~
      " connect_timeout=" ~ toml_s[s_toml_db][s_toml_db_conn_timeout].str(),
      conn_num,
      (scope Connection conn){
        conn.prepareEx("get_city_by_id", "SELECT id, name, population FROM test WHERE id = $1");
      } );
    
    i--;
  }
  
  
  
  userStateManager = new UserStateManager();
  userStateManager.addOrUpdate("123");
  
  
  
  auto settings = new HTTPServerSettings;
  //settings.port = 8080;
  //settings.bindAddresses = ["::1", "127.0.0.1"];
  settings.port = cast(ushort)toml_s[s_toml_http][s_toml_http_port].integer();
  settings.bindAddresses = [ toml_s[s_toml_http][s_toml_http_host].str().idup ];
  
  
  //auto fsettings = new HTTPFileServerSettings;
  //fsettings.serverPathPrefix = "/static";
  
  auto router = new URLRouter;
  //router.get("/", &index);
  ////router.get("static/*", serverStaticFiles("public/", fsettings) );
  
  //router.get("/", staticTemplate!"index.html");
  router.get("/", serveStaticFile("public/index.html") ); // static html + ws echo example
  router.get("/ws", handleWebSockets(&ws_handle) ); // static html + ws echo example
  router.get("/test", &test); // Mustache template + memcached + postgresql pool example
  router.get("/ws_login_test", handleWebSockets(&ws_bert_handle) ); // ws handler begins from "ws_" and next same http page path // login - logged - logout -- via ws with bert
  router.get("/login_test", &login_test); // login - logged - logout -- via ws with bert
  router.get("*", serveStaticFiles("public/"));
  
  //auto listener = listenHTTP(settings, &hello);
  auto listener = listenHTTP(settings, router);
  scope (exit){
    listener.stopListening();
  }
  
  
  
  //writeln("userStateManager.states is null? ", userStateManager.states is null);
  //sleep(dur!"seconds"(1));
  spawn(&startCleanupTask); // clean inactive user state
  
  
  
  logInfo("Please open http://127.0.0.1:8080/ in your browser.");
  runApplication();
}


void ws_handle(scope WebSocket sock){
  // simple echo server + :)
  
  //writeln("sock = ", sock); // vibe.http.websockets.WebSocket
  //writeln("sock.request = ", sock.request); // GET /ws?client_id=YaHoAnZo3JPYOwX7yn35 HTTP/1.1
  //writeln("sock.request.requestPath = ", sock.request.requestPath); // /ws
  //writeln("sock.request.queryString = ", sock.request.queryString); // client_id=YaHoAnZo3JPYOwX7yn35
  //writeln("sock.request.query = ", sock.request.query); // ["client_id": "YaHoAnZo3JPYOwX7yn35"]
  
  string client_id = "";
  if("client_id" in sock.request.query){
    client_id = sock.request.query["client_id"];
    //writeln("found client_id = ", client_id);
  }else{
    //writeln("client_id not found");
    throw new StringException("client_id not found");
  }
  
  bool is_new_client = true;
  if(userStateManager.contains(client_id)){
    is_new_client = false;
    writeln("Reconnection from existing client: ", client_id);
  }else{
    writeln("New client connected: ", client_id);
  }
  userStateManager.addOrUpdate(client_id);
  
  /*
  try{
    while(sock.connected){
      auto msg = sock.receiveText();
      sock.send(msg ~ " :)");
    }
  }catch(Exception ex){
    writeln("disconnected client_id = ", client_id);
    writeln("Error: ", ex.msg); // Error: Connection closed while reading message.
  }
  */
  while(sock.waitForData()){
    auto msg = sock.receiveText();
    sock.send(msg ~ " :)");
  }
  writeln("after disconnect"); // now shows
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


/*
void test_pg_conn_driver(){ // https://github.com/denizzzka/vibe.d.db.postgresql/blob/master/example/example.d#L13
  client.pickConnection( (scope conn){
    immutable result = conn.exec(
      "SELECT 123 as first_num, 567 as second_num, 'abc'::text as third_text " ~
      "UNION ALL " ~
      "SELECT 890, 233, 'fgh'::text as third_text",
      ValueFormat.BINARY
    );
    
    assert(result[0]["second_num"].as!PGinteger == 567);
    assert(result[1]["third_text"].as!PGtext == "fgh");
    
    foreach (val; rangify(result[0])){
      writeln("Found entry: ", val.as!Bson.toJson);
    }
  } );
}
*/


string get_all_cities(){
  return "SELECT id, name, population FROM test ORDER BY id";
}

void test_pg_conn_driver_queries(){
  /*
  client.pickConnection( (scope conn){
    QueryParams params; // https://github.com/denizzzka/dpq2/blob/master/src/dpq2/args.d#L15
    params.preparedStatementName = "get_city_by_id";
    params.argsVariadic(3); // https://github.com/denizzzka/dpq2/blob/master/example/example.d#L42  // https://github.com/denizzzka/dpq2/blob/master/src/dpq2/query.d#L336 // https://github.com/denizzzka/vibe.d.db.postgresql/blob/master/source/vibe/db/postgresql/package.d#L423
    conn.prepareEx(params.preparedStatementName, "SELECT id, name, population FROM test WHERE id = $1"); // get_city_by_id
    auto result1 = conn.execPrepared(params);
    
    writeln("id: ", result1[0]["id"].as!PGinteger);
    writeln("name: ", result1[0]["name"].as!PGtext);
    writeln("population: ", result1[0]["population"].as!PGinteger);
    
    //conn.prepareEx("q1", "UPDATE test SET name = $1, population = $2 WHERE id = $3"); // update_city_by_id
    //immutable result1 = conn.execPrepared("", ValueFormat.BINARY);
    
    destroy(conn);
  } );
  */
  
  //auto conn = clients[0].lockConnection(); // todo think is this correct to take index 0 here
  clients[0].pickConnection( (scope conn){ // todo think is this correct to take index 0 here
    QueryParams params; // https://github.com/denizzzka/dpq2/blob/master/src/dpq2/args.d#L15
    params.preparedStatementName = "get_city_by_id";
    params.argsVariadic(3); // https://github.com/denizzzka/dpq2/blob/master/example/example.d#L42  // https://github.com/denizzzka/dpq2/blob/master/src/dpq2/query.d#L336 // https://github.com/denizzzka/vibe.d.db.postgresql/blob/master/source/vibe/db/postgresql/package.d#L423
    //conn.prepareEx(params.preparedStatementName, "SELECT id, name, population FROM test WHERE id = $1"); // get_city_by_id
    auto result1 = conn.execPrepared(params);
    
    writeln("id: ", result1[0]["id"].as!PGinteger);
    writeln("name: ", result1[0]["name"].as!PGtext);
    writeln("population: ", result1[0]["population"].as!PGinteger);
    
    //conn.prepareEx("q1", "UPDATE test SET name = $1, population = $2 WHERE id = $3"); // update_city_by_id
    //immutable result1 = conn.execPrepared("", ValueFormat.BINARY);
    
    destroy(conn);
  } );
}


/*

"SELECT id, name, population FROM test ORDER BY id"
"UPDATE test SET name = $1, population = $2 WHERE id = $3", [City_Name, City_Pop, City_Id]
"INSERT INTO test (name, population) VALUES ($1, $2)", [City_Name, City_Pop]
"INSERT INTO test (name, population) VALUES ($1, $2) RETURNING id", [City_Name, City_Pop]
"DELETE FROM test WHERE id = $1", [City_Id]

*/


void test(HTTPServerRequest req, HTTPServerResponse res){
  auto cache = memcachedConnect("127.0.0.1:11211");
  
  
  
  /* test unproper arguments order */
  /* do not */
  /*
  test_key1 x = 5;
  test_key2 y = 2;
  //string r1 = test_args_types_mismash(x, y); // proper arguments order
  string r1 = test_args_types_mismash(y, x); // unproper - this compiles but we got logic error bug in runtime.. :( use struct for compiler check this..
  writeln("r1 = ", r1);
  */
  
  /* do not */
  /*
  test_key5 x = 5;
  test_key6 y = 2;
  //string r3 = test_args_types_mismash(x, y); // proper arguments order
  string r3 = test_args_types_mismash(y, x); // unproper - this compiles but we got logic error bug in runtime.. :( use struct for compiler check this..
  writeln("r3 = ", r3);
  */
  
  /* do like */
  
  test_key5 x = 5;
  test_key6 y = 2;
  string r3 = test_args_types_mismash(x, y); // proper arguments order
  //string r3 = test_args_types_mismash(y, x); // unproper - this not compiles
  writeln("r3 = ", r3);
  
  /* or - do like */
  test_key3 x2 = test_key3(5);
  test_key4 y2 = test_key4(2);
  string r2 = test_args_types_mismash2(x2, y2); // proper arguments order
  //string r2 = test_args_types_mismash2(y2, x2); // unproper - this not compiles
  writeln("r2 = ", r2);
  
  
  
  Language Lang = Language.uk;
  writeln("tr 1 = ", Tr(Lang, TKey.hello));
  writeln("tr 2 = ", Tr(Lang, TKey.welcome, ["username"], 0) );
  writeln("tr 3 = ", Tr(Lang, TKey.apples, [], 1) );
  writeln("tr 3 = ", Tr(Lang, TKey.apples, [], 2) ) ;
  writeln("tr 3 = ", Tr(Lang, TKey.apples, [], 5) );
  writeln("tr 4 = ", Tr(Lang, TKey.apples_n_oranges, ["6", "7"], 0) );
  
  
  
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
  
  
  //test_pg_conn_driver();
  test_pg_conn_driver_queries();
  
  
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

