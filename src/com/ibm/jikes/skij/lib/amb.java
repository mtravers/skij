package com.ibm.jikes.skij.lib;
class amb extends SchemeLibrary {
  static {
    evalStringSafe("(define *backtrack-points* '())");
    evalStringSafe("(define (fail . args) (if (pair? *backtrack-points*) ((pop *backtrack-points*) ':failed) (error \"fail failed: no more choices\")))");
    evalStringSafe("(define call/cc call-with-current-continuation)");
    evalStringSafe("(defmacro (let-amb var values . body) `(let loop ((values ,values)) (if (null? values) (fail \"no more choices\") (let* ((,var (car values)) (result (call/cc (lambda (k) (push k *backtrack-points*) ,@body)))) (if (eq? result ':failed) (loop (cdr values)) result)))))");
    evalStringSafe("(define (integers a b) (if (= a b) '() (cons a (integers (+ a 1) b))))");
    evalStringSafe("(define (square? x) (let ((sqt (round (sqrt x)))) (= (* sqt sqt) x)))");
    evalStringSafe("(define (pythagorean n) (let ((ints (integers 1 n))) (let-amb x ints (let-amb y ints (if (square? (+ (* x x) (* y y))) (print `(,x ,y ,(integer (sqrt (+ (* x x) (* y y))))))) (fail)))))");
  }
}