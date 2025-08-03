
// mutex example

// http://127.0.0.1:8080/   +   'ws://' + window.location.host + '/ws_mutex';


import std.stdio : writeln;

import std.string;
import std.array;
import std.algorithm;

import vibe.core.core;
import vibe.http.router;
import vibe.http.server;
import vibe.http.fileserver;
import vibe.http.websockets;
import vibe.core.log;

import core.sync.mutex : Mutex;
import std.datetime : SysTime, Clock;
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



void startCleanupTask(){
  while(true){
    writeln("startCleanupTask();");
    userStateManager.cleanup();
    //writeln("88 userStateManager.states is null? ", userStateManager.states is null);
    //sleep(dur!"hours"(1)); // every 1 hour = 3600 sec
    sleep(dur!"seconds"(30)); // every 30 sec
  }
}


void init_mutex(){
  userStateManager = new UserStateManager();
  //userStateManager.addOrUpdate("123");
  
  //writeln("99 userStateManager.states is null? ", userStateManager.states is null);
  //sleep(dur!"seconds"(1));
  
  spawn(&startCleanupTask); // clean inactive user state
}


void ws_mutex_handle(scope WebSocket sock){
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
  
  
  while(sock.waitForData()){
    auto msg = sock.receiveText();
    sock.send(msg ~ " :)");
  }
  writeln("after disconnect");
}

/*

./vtest
Listening for requests on http://127.0.0.1:8080/
//99 userStateManager.states is null? true
Please open http://127.0.0.1:8080/ in your browser.
startCleanupTask();
//88 userStateManager.states is null? true
startCleanupTask();
//88 userStateManager.states is null? true
New client connected: zkytkcKzeGaDfvfDs6y5
after disconnect
Reconnection from existing client: zkytkcKzeGaDfvfDs6y5
after disconnect
startCleanupTask();
//88 userStateManager.states is null? false
New client connected: zkytkcKzeGaDfvfDs6y5
after disconnect
startCleanupTask();
//88 userStateManager.states is null? false

*/
