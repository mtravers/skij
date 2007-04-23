package com.ibm.jikes.skij.lib;
import com.ibm.jikes.skij.Scheme;

class SchemeLibrary {

  static void evalStringSafe(String str) {
    try {
      Scheme.evalString(str);
    }
    catch (Throwable e) {
      System.out.println("Error evaluating " + str + ": " + e.toString());
    }
  }

}
