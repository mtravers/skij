package com.ibm.jikes.skij.lib;
class delay extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (delay exp) `(make-promise (lambda () ,exp)))");
    evalStringSafe("(define (make-promise proc) (let ((forced? #f) (value #f)) (lambda () (if forced? value (begin (set! value (proc)) (set! forced? #t) value)))))");
    evalStringSafe("(define (force promise) (promise))");
  }
}