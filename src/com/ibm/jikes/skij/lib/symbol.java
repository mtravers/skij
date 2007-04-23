package com.ibm.jikes.skij.lib;
class symbol extends SchemeLibrary {
  static {
    evalStringSafe("(define (symbol? thing) (instanceof thing 'com.ibm.jikes.skij.Symbol))");
    evalStringSafe("(define (symbol->string sym) (peek sym 'name))");
    evalStringSafe("(define (string->symbol name) (invoke-static 'com.ibm.jikes.skij.Symbol 'intern name))");
    evalStringSafe("(define intern string->symbol)");
    evalStringSafe("(define (symbol-conc . args) (intern (apply string-append (map to-string args))))");
    evalStringSafe("(defmacro (bound? symbol) `(not (%%null? (invoke (current-environment) 'getBindingSafe ,symbol))))");
  }
}