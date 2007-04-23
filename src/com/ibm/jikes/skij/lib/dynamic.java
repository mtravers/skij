package com.ibm.jikes.skij.lib;
class dynamic extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (dynamic name) `(%dynamic ',name))");
  }
}