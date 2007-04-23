package com.ibm.jikes.skij.lib;
class test extends SchemeLibrary {
  static {
    evalStringSafe("(this should get an error)");
  }
}