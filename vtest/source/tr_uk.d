

import tr : TKey, Translation;

alias t = Translation;


Translation[] translations = [
  t(["Привіт"], 0),
  t(["Ласкаво просимо, %s!"], 1),
  //t(["%d яблуко", "%d яблука", "%d яблук"], 1),
  t(["%s яблуко", "%s яблука", "%s яблук"], 1),
  t(["%s яблук і %s апельсинів"], 2)
];

