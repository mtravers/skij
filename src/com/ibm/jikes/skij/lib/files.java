package com.ibm.jikes.skij.lib;
class files extends SchemeLibrary {
  static {
    evalStringSafe("(define (open-input-file filename) (define file-obj (new 'java.io.File filename)) (define reader (new 'java.io.BufferedReader (new 'java.io.InputStreamReader (new 'java.io.FileInputStream file-obj)))) (new 'com.ibm.jikes.skij.InputPort reader))");
    evalStringSafe("(define (open-output-file filename) (define file-obj (new 'java.io.File filename)) (define stream (new 'java.io.FileOutputStream file-obj)) (new 'com.ibm.jikes.skij.OutputPort stream))");
    evalStringSafe("(define (call-with-input-file filename func) (define port #f) (dynamic-wind (lambda () (set! port (open-input-file filename))) (lambda () (func port)) (lambda () (close-input-port port))))");
    evalStringSafe("(define (call-with-output-file filename func) (define port #f) (dynamic-wind (lambda () (set! port (open-output-file filename))) (lambda () (func port)) (lambda () (close-output-port port))))");
    evalStringSafe("(define (directory dir) (define fileobj (new 'java.io.File dir)) (define filarray (invoke fileobj 'list)) (vector->list filarray))");
    evalStringSafe("(define (with-open-for-append file proc) (let ((stream #f) (port #f)) (dynamic-wind (lambda () (set! stream (new 'java.io.FileOutputStream (invoke file 'getPath) #t)) (set! port (new 'com.ibm.jikes.skij.OutputPort stream))) (lambda () (proc port)) (lambda () (invoke stream 'close)))))");
    evalStringSafe("(define (for-all-files proc dir) (define (process fileobj) (if (invoke fileobj 'isDirectory) (for-vector (lambda (name) (process (new 'java.io.File fileobj name))) (invoke fileobj 'list)) (proc fileobj))) (process (new 'java.io.File dir)))");
  }
}