

import tr : TKey, Translation;

alias t = Translation;


Translation[] translations = [
  t(["Hello"], 0),
  t(["Welcome, %s!"], 1),
  //t(["%d apple", "%d apples", "%d apples"], 1),
  t(["%s apple", "%s apples", "%s apples"], 1),
  t(["%s apples and %s oranges"], 2)
];

