package com.ibm.jikes.skij.lib;
class numeric extends SchemeLibrary {
  static {
    evalStringSafe("(define (number? x) (instanceof x 'java.lang.Number))");
    evalStringSafe("(define complex? number?)");
    evalStringSafe("(define real? number?)");
    evalStringSafe("(define rational? number?)");
    evalStringSafe("(define (integer? x) (instanceof x 'java.lang.Integer))");
    evalStringSafe("(define real? number?)");
    evalStringSafe("(define exact? integer?)");
    evalStringSafe("(define (inexact? x) (instanceof x 'java.lang.Double))");
    evalStringSafe("(define (exact->inexact x) (double x))");
    evalStringSafe("(define (inexact->exact x) (if (= (round x) x) (invoke-static 'java.lang.Math 'round x) (error `(,x cant be made exact))))");
    evalStringSafe("(define (zero? x) (= 0 x))");
    evalStringSafe("(define (negative? x) (< x 0))");
    evalStringSafe("(define (positive? x) (> x 0))");
    evalStringSafe("(define (number->string n . radix) (if (null? radix) (to-string n) (if (instanceof n 'java.lang.Integer) (invoke-static 'java.lang.Integer 'toString n (car radix)) (error \"can\\'t use radix for non-integers in number->string\"))))");
    evalStringSafe("(define (string->number string . radix) (define try-int (catch (invoke-static 'java.lang.Integer 'valueOf string (if (null? radix) 10 (car radix))))) (if (instanceof try-int 'java.lang.Integer) try-int (if (null? radix) (let ((try-double (catch (invoke-static 'java.lang.Double 'valueOf string)))) (if (instanceof try-double 'java.lang.Number) try-double #f)) (error \"Can\\'t parse floats in non-decimal radices\"))))");
    evalStringSafe("(define (modulo x y) (define rem (remainder x y)) (if (or (and (< rem 0) (> y 0)) (and (< y 0) (> rem 0))) (+ rem y) rem))");
    evalStringSafe("(define (even? x) (= 0 (modulo x 2)))");
    evalStringSafe("(define (odd? x) (= 1 (modulo x 2)))");
    evalStringSafe("(define (abs x) (if (> x 0) x (* -1 x)))");
    evalStringSafe("(define (long x) (invoke x 'longValue))");
    evalStringSafe("(define (byte x) (invoke x 'byteValue))");
    evalStringSafe("(define (short x) (invoke x 'shortValue))");
    evalStringSafe("(define (float x) (invoke x 'floatValue))");
    evalStringSafe("(define (double x) (invoke x 'doubleValue))");
    evalStringSafe("(defmacro (def-math name) `(define (,name x) (invoke-static 'java.lang.Math ',name x)))");
    evalStringSafe("(def-math sqrt)");
    evalStringSafe("(def-math exp)");
    evalStringSafe("(def-math log)");
    evalStringSafe("(def-math floor)");
    evalStringSafe("(def-math atan)");
    evalStringSafe("(def-math acos)");
    evalStringSafe("(def-math atan)");
    evalStringSafe("(def-math ceil)");
    evalStringSafe("(define ceiling ceil)");
    evalStringSafe("(define (expt a b) (if (zero? a) (if (zero? b) 1 0) (exp (* b (log a)))))");
    evalStringSafe("(define (quotient a b) (/ (integer a) (integer b)))");
    evalStringSafe("(define (modulo a b) (let ((rem (remainder a b))) (if (eq? (negative? b) (negative? rem)) rem (+ rem b))))");
    evalStringSafe("(begin (define (gcd2 a b) (if (zero? b) a (gcd b (remainder a b)))) (define (lcm2 a b) (/ (* a b) (gcd a b))) (define (make-nary 2func identity) (letrec ((nfunc (lambda args (cond ((null? args) identity) ((null? (cdr args)) (abs (car args))) ((null? (cddr args)) (2func (car args) (cadr args))) (#t (2func (car args) (apply nfunc (cdr args)))))))) nfunc)))");
    evalStringSafe("(define gcd (make-nary gcd2 0))");
    evalStringSafe("(define lcm (make-nary lcm2 1))");
  }
}