
alias int8  = byte;    //                 -128 —                 127
alias int16 = short;   //               -32768 —               32767
alias int32 = int;     //          -2147483648 —          2147483647
alias int64 = long;    // -9223372036854775808 — 9223372036854775807

alias uint8  = ubyte;  // 0 —                  255
alias uint16 = ushort; // 0 —                65535
alias uint32 = uint;   // 0 —           4294967295
alias uint64 = ulong;  // 0 — 18446744073709551615

alias f32 = float;
alias f64 = double;

// char     '\xFF'          unsigned 8 bit (UTF-8 code unit)
// wchar    '\uFFFF'        unsigned 16 bit (UTF-16 code unit)
// dchar    '\U0000FFFF'    unsigned 32 bit (UTF-32 code unit)



import vibe.core.core;
import vibe.http.router;
import vibe.http.server;
import vibe.http.fileserver;
import vibe.http.websockets;
import vibe.core.log;

import std.stdio;
import std.string;
import std.array;
import std.conv : to;


import bert; // https://github.com/221V/dlang_erl_bert  https://git.4dev.win/game1/dlang_erl_bert


import mustache;
alias MustacheEngine!(string) Mustache;



void ws_bert_handle(scope WebSocket sock){
  // simple echo server + :)
  while(sock.connected){
    //auto msg = sock.receiveText();
    //sock.send(msg ~ " :)");
    auto msg = sock.receiveBinary();
    if(msg == "1"){
      sock.send("0"); // ws PING - PONG
    }else{
      writeln("Received: ", msg);
      
      auto decoder = new BertDecoder( cast(ubyte[])msg.dup );
      auto decoded = decoder.decode();
      msg_match(decoded, sock);
    }
  }
}

void msg_match(BertValue decoded, WebSocket sock){
  writeln("Decoded: ", decoded.toString());
  
  if(decoded.type_ == BertType.Tuple){
    auto decoded1 = decoded.tupleValue;
    if(decoded1.length == 3){
      
      if(auto num1 = cast(uint8)decoded1[0].intValue){
        writeln("num1 = ", num1, " ", typeof(num1).stringof); // ws.send(enc(tuple( number(1), number(42), number(777) ))); // Decoded: {1, 42, 777} // num1 = 1 ubyte
        sock.send("{console.log(" ~ to!string(num1 + 42) ~ ")}"); // got 43 in browser console
        
      } // else do nothing
      
      if(auto str1 = cast(string)decoded1[1].binaryValue){
        writeln("str1 = ", str1, " ", typeof(str1).stringof); // ws.send(enc(tuple( number(1), bin('blabla'), number(777) ))); // Decoded: {1, <<98,108,97,98,108,97>>, 777} // str1 = blabla string
        sock.send("{console.log('" ~ str1 ~ " la-la-la" ~ "')}"); // got 'blabla la-la-la' in browser console
        
      } // else do nothing
      
      // var big_value = bigInt("61196067033413");
      // ws.send(enc(tuple( number(1), bin('9'), bignum( big_value ) ))); // got as long for auto
      if(decoded1[2].type_ == BertType.Int){
        if(auto num3 = decoded1[2].intValue){
          writeln("num3 = ", num3, " ", typeof(num3).stringof); // ws.send(enc(tuple( number(1), bin('9'), number(1) ))); // Decoded: {1, <<57>>, 1} // num3 = 1 long
        } // else do nothing
      } // else do nothing
      
      // var big_value = bigInt("6119606703341361196067033413");
      // ws.send(enc(tuple( number(1), bin('9'), bignum( big_value ) ))); // got as BigInt
      if(decoded1[2].type_ == BertType.BigInt){
        if(auto num3b = decoded1[2].bigintValue){
          writeln("num3b = ", num3b, " ", typeof(num3b).stringof); // Decoded: {1, <<57>>, 6119606703341361196067033413} // num3b = 6119606703341361196067033413 BigInt
        } // else do nothing
      } // else do nothing
      
      if(decoded1[2].type_ == BertType.List){
        auto list1 = decoded1[2].listValue; // ws.send(enc(tuple( number(1), bin('blabla'), list( number(1), number(2), number(3) ) ))); // Decoded: {1, <<98,108,97,98,108,97>>, [1, 2, 3]}
        if(list1.length == 3){
          
          //if(auto num31 = cast(uint32)list1[0].intValue){
          if(auto num31 = list1[0].intValue){
            writeln("num31 = ", num31, " ", typeof(num31).stringof); // ws.send(enc(tuple( number(1), bin('9'), list( number(1), number(2), number(3) ) ))); // Decoded: {1, <<57>>, [1, 2, 3]} // num31 = 1 uint
            sock.send("{console.log(" ~ to!string(num31 + 77) ~ ")}"); // got 78 in browser console
          } // else do nothing
        
        } // else do nothing
      
      } // else do nothing
    
    } // else do nothing
  } // else do nothing
}

void login_test(HTTPServerRequest req, HTTPServerResponse res){
  Mustache mustache;
  auto context = new Mustache.Context;
  mustache.path = "priv";
  mustache.ext = "dtl";
  
  context["lang"] = "en";
  context["number1"] = 42;
  context.useSection("maybe1");
  
  context["part1"] = "<span>777</span>";
  context["result1"] = "Hello, World!\n";
  
  res.headers["Content-Type"] = "text/html; charset=utf-8";
  
  //res.writeBody("Hello, World!\n" ~ result);
  res.writeBody( mustache.render("login_test", context) );
}

