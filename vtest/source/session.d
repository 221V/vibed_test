
// session with multisession --
//   we have same user_id - but few cookies (devices or people on same account etc)

// sessions store:
//   postgresql = cookie -- user_id
//   memcached  = cookie -- user_id ; user_id + key_part -- some_cached_values // todo think maybe store only - user_id + key_part -- used_id_cookies_list_csv_str


import std.stdio : writeln;
import std.array;
import std.string;
private{
  import std.digest.sha;
  import std.random : uniform;
  import std.base64 : Base64;
  import std.datetime : SysTime, Clock, dur;
  import std.algorithm;
  import std.typecons : Tuple, Nullable;
}

ubyte[][string] userSessions;

//userSessions["user123"] = 42;
//if("user123" in userSessions){
//  int value = userSessions["user123"];
//}
//userSessions.remove("user123");
//userSessions.remove("user123", null);



ubyte idLength = 15; // we got 20 chars here // session ID length in Base64 like YouTube videos id
ubyte validityDays = 255; // max value for ubyte too enaught // session validity in days

string generateCookie(){ // Cookie as SessionId
  ubyte[16] randomBytes;
  foreach(ref b; randomBytes){
    b = cast(ubyte)uniform(0, 256);
  }
  
  auto hash = sha256Of(randomBytes);
  ubyte[15] idBytes = hash[0..15].dup; // get 15 bytes - (120 bits) for 15-symbols Base64 // but got up to 20 symbols
  
  // Base64 - URL-safe coding
  auto base64 = Base64.encode(idBytes)
    .tr("+/", "-_")  // replace +/ to -_
    .stripRight("="); // rm padding
  
  return base64.idup; // convert char[] into string
}



