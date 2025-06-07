
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

import tr;

import mustache;
alias MustacheEngine!(string) Mustache;


import vibe.db.postgresql;
import vibe.data.bson;
//import vibe.data.json;
// https://github.com/vibe-d/vibe.d/blob/master/source/vibe/vibe.d

PostgresClient client;


import std.file : read;
import toml;

TOMLDocument toml_s;


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




void main(){
  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::1", "127.0.0.1"];
  
  
  toml_s = parseTOML(cast(string)read("settings.toml"));
  if( are_valid_config_values(toml_s) ){}else{ return; }
  // https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING
  // https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS
  //client = new PostgresClient("host=localhost port=5432 dbname=mydb user=username password=pass connect_timeout=5", 100);
  client = new PostgresClient( "host=" ~ toml_s[s_toml_db][s_toml_db_host].str() ~
    " port=" ~ toml_s[s_toml_db][s_toml_db_port].str() ~
    " dbname=" ~ toml_s[s_toml_db][s_toml_db_name].str() ~
    " user=" ~ toml_s[s_toml_db][s_toml_db_user].str() ~
    " password=" ~ toml_s[s_toml_db][s_toml_db_pass].str() ~
    " connect_timeout=" ~ toml_s[s_toml_db][s_toml_db_conn_timeout].str(),
    cast(uint) toml_s[s_toml_db][s_toml_db_conn_num].integer() );
  
  
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


string s_toml_db              = "database";
string s_toml_db_host         = "host";
string s_toml_db_port         = "port";
string s_toml_db_name         = "dbname";
string s_toml_db_user         = "user";
string s_toml_db_pass         = "pass";
string s_toml_db_conn_timeout = "connect_timeout";
string s_toml_db_conn_num     = "connections_number";

bool are_valid_config_values(ref TOMLDocument toml_s){
  string invalid_settings = "invalid settings: ";
  string grumpy = " :(";
  string invalid_group = " group ";
  string invalid_key = " key" ~ grumpy;
  
  bool invalid_toml_group(string group){
    writeln(invalid_settings ~ group ~ invalid_group ~ grumpy); return false;
  }
  
  bool invalid_toml_value(string group, string key){
    writeln(invalid_settings ~ group ~ invalid_group ~ key ~ invalid_key ~ grumpy); return false;
  }
  
  if((s_toml_db in toml_s) != null){
      auto toml_db = toml_s[s_toml_db];
      
      if((s_toml_db_host in toml_db) != null){
        if(toml_db[s_toml_db_host].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_db, s_toml_db_host); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_host); }
      
      if((s_toml_db_port in toml_db) != null){
        if(toml_db[s_toml_db_port].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_db, s_toml_db_port); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_port); }
      
      if((s_toml_db_name in toml_db) != null){
        if(toml_db[s_toml_db_name].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_db, s_toml_db_name); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_name); }
      
      if((s_toml_db_user in toml_db) != null){
        if(toml_db[s_toml_db_user].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_db, s_toml_db_user); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_user); }
      
      if((s_toml_db_pass in toml_db) != null){
        if(toml_db[s_toml_db_pass].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_db, s_toml_db_pass); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_pass); }
      
      if((s_toml_db_conn_timeout in toml_db) != null){
        if(toml_db[s_toml_db_conn_timeout].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_db, s_toml_db_conn_timeout); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_conn_timeout); }
      
      if((s_toml_db_conn_num in toml_db) != null){
        if(toml_db[s_toml_db_conn_num].type == TOMLType.INTEGER){}else{ return invalid_toml_value(s_toml_db, s_toml_db_conn_num); }
      }else{ return invalid_toml_value(s_toml_db, s_toml_db_conn_num); }
      
  }else{ return invalid_toml_group(s_toml_db); }
  return true;
}

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
  
  auto conn = client.lockConnection();
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

