package com.ibm.jikes.skij.lib;
class chars extends SchemeLibrary {
  static {
    evalStringSafe("(define character? char?)");
    evalStringSafe("(define char=? equal?)");
    evalStringSafe("(define (char->integer char) (invoke char 'hashCode))");
    evalStringSafe("(define char->int char->integer)");
    evalStringSafe("(define int->char integer->char)");
    evalStringSafe("(define (char-upcase char) (invoke-static 'java.lang.Character 'toUpperCase char))");
    evalStringSafe("(define (char-downcase char) (invoke-static 'java.lang.Character 'toLowerCase char))");
    evalStringSafe("(define (char-lower-case? char) (invoke-static 'java.lang.Character 'isLowerCase char))");
    evalStringSafe("(define (char-upper-case? char) (invoke-static 'java.lang.Character 'isUpperCase char))");
    evalStringSafe("(define (char-alphabetic? char) (invoke-static 'java.lang.Character 'isLetter char))");
    evalStringSafe("(define (char-numeric? char) (invoke-static 'java.lang.Character 'isDigit char))");
    evalStringSafe("(define (char-whitespace? char) (invoke-static 'java.lang.Character 'isWhitespace char))");
    evalStringSafe("(define (char=? c1 c2) (equal? c1 c2))");
    evalStringSafe("(define (char-lower-case ch) (invoke-static 'java.lang.Character 'toLowerCase ch))");
    evalStringSafe("'(defmacro (def-char-compare comp) `(begin (define (,(symbol-conc 'char comp '?) s1 s2) (,comp (invoke s1 'compareTo s2) 0)) (define (,(symbol-conc 'char-ci comp '?) s1 s2) (,comp (invoke (char-lower-case s1) 'compareTo (char-lower-case s2))))))");
    evalStringSafe("(defmacro (def-char-compare comp) `(begin (define (,(symbol-conc 'char comp '?) s1 s2) (,comp (char->integer s1) (char->integer s2))) (define (,(symbol-conc 'char-ci comp '?) s1 s2) (,comp (char->integer (char-lower-case s1)) (char->integer (char-lower-case s2))))))");
    evalStringSafe("(def-char-compare <)");
    evalStringSafe("(def-char-compare >)");
    evalStringSafe("(def-char-compare >=)");
    evalStringSafe("(def-char-compare <=)");
    evalStringSafe("(define (char-ci=? s1 s2) (invoke (char-lower-case s1) 'equals (char-lower-case s2)))");
  }
}