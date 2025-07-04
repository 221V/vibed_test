
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


import secured.symmetric; // https://github.com/221V/SecureD   // https://github.com/221V/js_AES256CBC
import secured.rsa;

import session;


import mustache;
alias MustacheEngine!(string) Mustache;



string byte_arr_to_str(ubyte[] arr){
  string[] str_arr;
  foreach(elem; arr){
    str_arr ~= to!string(elem);
  }
  return "[" ~ str_arr.join(",") ~ "]";
}


ubyte[] str_to_byte_arr(string str_arr){
  str_arr = str_arr.replace("[", "").replace("]", "");
  string[] parts = str_arr.split(",");
  ubyte[] result;
  result.reserve(parts.length);
  foreach(part; parts){
    result ~= to!ubyte(part.strip());
  }
  return result;
}


void ws_bert_handle(scope WebSocket sock){
  //foreach(pair; req.headers.byKeyValue()){
  //  writeln("Header: ", pair.key, " = ", pair.value);
  //}
  // simple echo server + :)
  
  //string client_id = req.attributes.get("client_id", "");
  //writeln("96 client_id = ", client_id);
  
  // https://vibed.org/api/vibe.http.websockets/WebSocket
  // https://vibed.org/api/vibe.http.websockets/WebSocket.request
  // https://vibed.org/api/vibe.http.server/HTTPServerRequest
  //writeln("sock.request = ", sock.request); // GET /ws_login_test HTTP/1.1
  //writeln("sock.request.headers = ", sock.request.headers); // ["Host": "127.0.0.1:8080", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0", "Accept": "*/*", "Accept-Language": "uk-UA,uk;q=0.8,en-US;q=0.5,en;q=0.3", "Accept-Encoding": "gzip, deflate, br, zstd", "Sec-WebSocket-Version": "13", "Origin": "http://127.0.0.1:8080", "Sec-WebSocket-Extensions": "permessage-deflate", "Sec-WebSocket-Key": "NW+zQGtSdkuSRHWuU/VevA==", "DNT": "1", "Sec-GPC": "1", "Connection": "keep-alive, Upgrade", "Sec-Fetch-Dest": "empty", "Sec-Fetch-Mode": "websocket", "Sec-Fetch-Site": "same-origin", "Pragma": "no-cache", "Cache-Control": "no-cache", "Upgrade": "websocket"]
  
  //writeln("sock.request.context = ", sock.request.context); // []
  //writeln("sock.request.params = ", sock.request.params); // []
  //string client_id = req.params.get("client_id", "");
  
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
  // todo delete data in userSessions here
}



void msg_match(BertValue decoded, WebSocket sock){
  writeln("Decoded: ", decoded.toString());
  
  auto rsa_keypair = new RSA(2048); // Only allows for (2048/8)-42 = 214 bytes to be asymmetrically RSA encrypted
  scope(exit) rsa_keypair.destroy();
  
  ubyte[] rsa_private_key = rsa_keypair.getPrivateKey(null);
  ubyte[] rsa_public_key = rsa_keypair.getPublicKey();
  //writeln("rsa_private_key = ", rsa_private_key);
  //writeln("rsa_public_key = ", rsa_public_key);
  
  //ubyte[214] plaintext214 = 2; // 2 being an arbitrary value
  auto plaintext214 = cast(ubyte[])"12345678testтест";
  
  ubyte[] encMessage214 = rsa_keypair.encrypt(plaintext214);
  //writeln("encMessage214.length = ", encMessage214.length); // 256
  //writeln("encMessage214 = ", encMessage214);
  
  ubyte[] decMessage214 = rsa_keypair.decrypt(encMessage214);
  //writeln("decMessage214 = ", decMessage214);
  writeln("decMessage214 = ", cast(string)decMessage214);
  
  
  ubyte[] key;
  ubyte[] iv;
  
  if(decoded.type_ == BertType.Tuple){
    auto decoded1 = decoded.tupleValue;
    if(decoded1.length == 1){
      if(auto num1 = cast(uint8)decoded1[0].intValue){ // we can use js AES for additional password encrypt for login-logout  // ws.send(enc(tuple( number(1) )));
        if(num1 == 1){ // init login -- get key + iv for encrypt password and send to server
          
          /*
          ubyte[] test_pass = cast(ubyte[])"12345678";
          SymmetricKey key = generateSymmetricKey( SymmetricAlgorithm.AES256_CBC );
          EncryptedData enc = encrypt(key, test_pass);
          //auto iv_hex = toHexString!(LetterCase.lower)(enc.iv);
          //auto encrypt = toHexString!(LetterCase.lower)(enc.cipherText);
          auto iv_hex = enc.iv;
          auto encrypt = enc.cipherText;
          writeln("Key: ", key.key);
          //writeln("Key: ", key.toString); // base64 encoded string
          //writeln("IV: ", toHexString!(LetterCase.lower)(enc.iv));
          writeln("IV: ", iv_hex);
          //writeln("Encrypt: ", enc);
          writeln("Encrypt: ", encrypt);
          */
          
          
          SymmetricKeyIV rand_key_iv = generateSymmetricKeyIV(); // default SymmetricAlgorithm.AES256_CBC
          writeln("rand key: ", rand_key_iv.key);
          writeln("rand iv: ", rand_key_iv.iv);
          string client_id = generateCookie();
          userSessions[client_id ~ "_key"] = rand_key_iv.key;
          userSessions[client_id ~ "_iv"] = rand_key_iv.iv;
          
          /*
          //auto test_pass = cast(ubyte[])"12345678";
          auto test_pass = cast(ubyte[])"12345678testтест";
          auto key = cast(ubyte[])[34, 74, 12, 214, 126, 234, 101, 147, 13, 32, 244, 185, 45, 217, 142, 33, 213, 116, 63, 179, 84, 23, 138, 187, 134, 130, 234, 54, 48, 66, 20, 152];
          auto iv = cast(ubyte[])[62, 133, 213, 219, 194, 200, 76, 142, 202, 16, 12, 237, 163, 147, 65, 93];
          
          
          auto encrypted = encrypt(key, iv, test_pass, SymmetricAlgorithm.AES256_CBC);
          writeln("Encrypted: ", encrypted.cipherText); // [223, 86, 210, 55, 192, 240, 144, 50, 159, 4, 238, 182, 171, 185, 80, 48] // [90, 85, 212, 32, 94, 33, 182, 43, 20, 183, 121, 59, 232, 45, 180, 158, 153, 9, 54, 45, 244, 32, 85, 24, 162, 206, 56, 235, 107, 194, 143, 192]
          
          //auto encrypted_data = cast(ubyte[])[223, 86, 210, 55, 192, 240, 144, 50, 159, 4, 238, 182, 171, 185, 80, 48];
          auto encrypted_data = cast(ubyte[])[90, 85, 212, 32, 94, 33, 182, 43, 20, 183, 121, 59, 232, 45, 180, 158, 153, 9, 54, 45, 244, 32, 85, 24, 162, 206, 56, 235, 107, 194, 143, 192];
          
          ubyte[] decrypted = decrypt(key, iv, encrypted_data, SymmetricAlgorithm.AES256_CBC);
          writeln("Decrypted: ", decrypted); // [49, 50, 51, 52, 53, 54, 55, 56] // [49, 50, 51, 52, 53, 54, 55, 56, 116, 101, 115, 116, 209, 130, 208, 181, 209, 129, 209, 130]
          writeln("Decrypted: ", cast(string)decrypted); // "12345678" // "12345678testтест"
          */
          
          
          sock.send("{window.key = new Uint8Array(" ~ byte_arr_to_str(rand_key_iv.key) ~ ");" ~
            "window.iv = new Uint8Array(" ~ byte_arr_to_str(rand_key_iv.iv) ~ ");" ~
            "window.uid = '" ~ client_id ~ "';" ~
            "do_log_in();}");
          
          
          /*
          ubyte[] key = sock.context.get("aes_key", "");
          ubyte[] iv = sock.context.get("aes_iv", "");
          
          if( key.empty || iv.empty ){}else{
            sock.send("{window.key = new Uint8Array(" ~ byte_arr_to_str(key) ~ ");" ~
              "window.iv = new Uint8Array(" ~ byte_arr_to_str(iv) ~ ");" ~
              "do_log_in();}");
          }
          */
          
        } // else do nothing
      } // else do nothing
    
    
    }else if(decoded1.length == 4){ // {2, "uid", "login", "encrypted_pass"}
      if(auto code2 = cast(uint8)decoded1[0].intValue){ // 2
        if(code2 == 2){
          
          if(auto client_id = cast(string)decoded1[1].binaryValue){
            writeln("client_id = ", client_id);
          
            if(auto login_str = cast(string)decoded1[2].binaryValue){
              writeln("login_str = ", login_str);
              
              if(auto maybe_encrypted_pass = cast(string)decoded1[3].binaryValue){
                writeln("maybe_encrypted_pass = ", maybe_encrypted_pass, " ", typeof(maybe_encrypted_pass).stringof); // Decoded: {2, <<116,101,115,116,49>>, <<91,49,50,53,44,50,51,54,44,50,50,48,44,50,53,53,44,49,50,48,44,49,54,57,44,49,56,51,44,49,48,50,44,50,49,49,44,51,53,44,50,52,54,44,50,49,55,44,55,49,44,50,54,44,50,49,50,44,56,56,93>>} // maybe_encoded_pass = [125,236,220,255,120,169,183,102,211,35,246,217,71,26,212,88] string
                //sock.send("{console.log('" ~ str1 ~ " la-la-la" ~ "')}"); // 
                
                try{
                  auto encrypted_pass = str_to_byte_arr(maybe_encrypted_pass);
                  writeln("encoded_pass = ", encrypted_pass);
                  
                  if( (client_id ~ "_key") in userSessions){
                    key = userSessions[client_id ~ "_key"];
                  }
                  if( (client_id ~ "_iv") in userSessions){
                    iv = userSessions[client_id ~ "_iv"];
                  }
                  
                  writeln("key = ", key);
                  writeln("iv = ", iv);
                  
                  ubyte[] pass = decrypt(key, iv, encrypted_pass, SymmetricAlgorithm.AES256_CBC);
                  writeln("Decrypted: ", pass); // byte array
                  writeln("Decrypted: ", cast(string)pass); // string
                  
                  
                }catch(Exception e){} // skip err, do nothing
              
              }
            } // else do nothing
            
          } // else do nothing
        } // else do nothing
      } // else do nothing
    
    
    
    }else if(decoded1.length == 3){
      
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
  //string client_id = generateCookie();
  //writeln("client_id: ", client_id); // client_id: tkoy8ybolXM95fpEqYRY
  //req.context["client_id"] = generateCookie();
  //req.params["client_id"] = generateCookie();
  //writeln("req.context = ", req.context); // req.context = ["client_id": MM2YjBQvSOSAdzLDZPNH]
  //writeln("req.params = ", req.params);   // req.params = ["client_id": "Io-oRQ2DFXqBIShxs5z0"]
  
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

