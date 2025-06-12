
public{
  import std.stdio;
  import std.file : read;
  import toml;
}

TOMLDocument toml_s;

// settings keys
string s_toml_http            = "http";
string s_toml_http_host       = "host";
string s_toml_http_port       = "port";

string s_toml_db              = "database";
string s_toml_db_host         = "host";
string s_toml_db_port         = "port";
string s_toml_db_name         = "dbname";
string s_toml_db_user         = "user";
string s_toml_db_pass         = "pass";
string s_toml_db_conn_timeout = "connect_timeout";
string s_toml_db_conn_num     = "connections_number";


void read_settings_toml(){ // read settings, settings validation
  toml_s = parseTOML(cast(string)read("settings.toml"));
  if( are_valid_config_values(toml_s) ){}else{ return; } // settings validation
}


bool are_valid_config_values(ref TOMLDocument toml_s){ // settings validation
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
  
  
  if((s_toml_http in toml_s) != null){
    auto toml_http = toml_s[s_toml_http];
    
    if((s_toml_http_host in toml_http) != null){
      if(toml_http[s_toml_http_host].type == TOMLType.STRING){}else{ return invalid_toml_value(s_toml_http, s_toml_http_host); }
    }else{ return invalid_toml_value(s_toml_http, s_toml_http_host); }
    
    if((s_toml_http_port in toml_http) != null){
      if(toml_http[s_toml_http_port].type == TOMLType.INTEGER){}else{ return invalid_toml_value(s_toml_http, s_toml_http_port); }
    }else{ return invalid_toml_value(s_toml_http, s_toml_http_port); }
    
  }else{ return invalid_toml_group(s_toml_http); }
  
  
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

