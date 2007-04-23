package com.ibm.jikes.skij.lib;
class io extends SchemeLibrary {
  static {
    evalStringSafe("(define eol-character (integer->char 10))");
    evalStringSafe("(define cr-character (integer->char 13))");
    evalStringSafe("(define newline (lambda args (if (null? args) (write-char eol-character) (write-char eol-character (car args)))))");
    evalStringSafe("(define print (lambda args (require-write) (apply write args) (apply newline (cdr args)) (car args)))");
    evalStringSafe("(define (close-input-port inport) (invoke (peek inport 'reader) 'close))");
    evalStringSafe("(define (close-output-port outport) (invoke (peek outport 'writer) 'close))");
    evalStringSafe("(define (eof-object? obj) (instanceof obj 'com.ibm.jikes.skij.EOFObject))");
    evalStringSafe("(define (copy-until-eof instream outstream) (define char (read-char instream)) (if (not (eof-object? char)) (begin (write-char char outstream) (copy-until-eof instream outstream))))");
    evalStringSafe("(define (read-line in) (if (class-supports-readLine? (invoke (peek in 'reader) 'getClass)) (invoke (peek in 'reader) 'readLine) (with-string-output-port (lambda (outport) (let loop ((char (read-char in))) (cond ((equal? char eol-character)) ((equal? char cr-character) (define lf? (read-char in)) (if (equal? lf? eol-character) #f (error `(Non-linefeed ,lf? seen after CR)))) ((equal? char -1)) (#t (write-char char outport) (loop (read-char in)))))))))");
    evalStringSafe("(define (input-port? thing) (instanceof thing 'com.ibm.jikes.skij.InputPort))");
    evalStringSafe("(define (output-port? thing) (instanceof thing 'com.ibm.jikes.skij.OutputPort))");
    evalStringSafe("(define-memoized (class-supports-readLine? class) (instanceof (catch (invoke class 'getMethod \"readLine\" (%make-vector 0 (class-named 'java.lang.Class)))) 'java.lang.reflect.Method))");
  }
}