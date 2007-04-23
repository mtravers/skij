package com.ibm.jikes.skij.lib;
class random extends SchemeLibrary {
  static {
    evalStringSafe("(define (random arg) (if arg (integer (random-range arg)) (invoke-static 'java.lang.Math 'random)))");
    evalStringSafe("(define (random-range n) (* n (random #f)))");
    evalStringSafe("(define (arand center range) (- (+ center (* 2 (* range (random #f)))) range))");
  }
}