

import tr_en;
import tr_uk;

import std.array : empty;
import std.conv : to;
import std.format;

enum TKey{
  hello,
  welcome,
  apples,
  apples_n_oranges,
}

struct Translation{
  string[] text;
  int arg_count;
}

enum Language{
  en,
  uk
}


string plural(int count, string[] txt){
  int n1 = count % 100; // get rem
  if(n1 > 4 && n1 < 20){
    return txt[2];
  }else{
    switch(count % 10){ // get rem
      case 0: return txt[2];
        case 1: return txt[0];
        case 2, 3, 4: return txt[1];
        default: return txt[2];
    }
  }
}

// plural(1, ["яблуко", "яблука", "яблук"]) => "яблуко"
// plural(2, ["яблуко", "яблука", "яблук"]) => "яблука"
// plural(5, ["яблуко", "яблука", "яблук"]) => "яблук"


string format_args(string txt, string[] args){
  switch (args.length){
    case 0: return txt;
    case 1: return format(txt, args[0]);
    case 2: return format(txt, args[0], args[1]);
    case 3: return format(txt, args[0], args[1], args[2]);
    case 4: return format(txt, args[0], args[1], args[2], args[3]);
    default: return txt;
  }
}


string Tr(Language lang, TKey text_key, string[] args = [], int plural_num = 0){
  Translation translation;
  switch(lang){
    case Language.uk:
      translation = tr_uk.translations[text_key];
      break;
    //case Language.en:
    //  translation = tr_en.translations[text_key];
    //  break;
    default :
      translation = tr_en.translations[text_key];
  }
  
  if( (plural_num > 0) && (args.length < translation.arg_count) ){
    args = [ to!string(plural_num) ] ~ args;
  }
  
  if(args.length != translation.arg_count){
    return translation.text[0];
  }
  
  if( (translation.text.length > 1) && (plural_num > 0) ){
    auto text = plural(plural_num, translation.text);
    return format_args(text, args);
  }else{
    return (args.empty) ? translation.text[0] : format_args(translation.text[0], args);
  }
}

