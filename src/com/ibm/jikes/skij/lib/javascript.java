package com.ibm.jikes.skij.lib;
class javascript extends SchemeLibrary {
  static {
    evalStringSafe("(define *javascript-window* (ignore-errors (invoke-static 'netscape.javascript.JSObject 'getWindow *applet*)))");
    evalStringSafe("(define (jsinvoke jsobject method . args) (invoke jsobject 'call (string method) (list->vector args)))");
  }
}