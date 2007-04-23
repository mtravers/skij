package com.ibm.jikes.skij.lib;
class string extends SchemeLibrary {
  static {
    evalStringSafe("(define (string . args) (if (null? (cdr args)) (to-string (car args)) (let ((chars (%make-vector (length args) '#,(peek-static 'java.lang.Character 'TYPE)))) (%fill-vector chars args) (new 'java.lang.String chars))))");
    evalStringSafe("(define (make-string k . rest) (define chars (%make-vector k (peek-static 'java.lang.Character 'TYPE))) (when (not (null? rest)) (define char (car rest)) (let loopx ((i 0)) (when (< i k) (vector-set! chars i char) (loopx (+ i 1))))) (new 'java.lang.String chars))");
    evalStringSafe("(define (string-ref string k) (invoke string 'charAt k))");
    evalStringSafe("(define (string-set! string k char) (error '\"Sorry, string-set! is not supported.\"))");
    evalStringSafe("(define (substring string start end) (invoke string 'substring start end))");
    evalStringSafe("(define (string-trim string) (invoke string 'trim))");
    evalStringSafe("(define (string-search string char from) (define result (if from (invoke string 'indexOf (integer char) from) (invoke string 'indexOf (integer char)))) (if (= result -1) #f result))");
    evalStringSafe("(define (string-replace string char-in char-out) (invoke string 'replace char-in char-out))");
    evalStringSafe("(define (string-replace-string string old new) (let ((index (invoke string 'indexOf old))) (if (negative? index) string (string-append (substring string 0 index) new (substring string (+ index (string-length old)) (string-length string))))))");
    evalStringSafe("(define (with-string-output-port func) (define writer (new 'java.io.StringWriter)) (define out (new 'com.ibm.jikes.skij.OutputPort writer)) (func out) (to-string writer))");
    evalStringSafe("(define (display-to-string thing) (with-string-output-port (lambda (port) (display thing port))))");
    evalStringSafe("(define (write-to-string thing) (with-string-output-port (lambda (port) (write thing port))))");
    evalStringSafe("(define (with-input-from-string string func) (define reader (new 'java.io.StringReader string)) (define in (new 'com.ibm.jikes.skij.InputPort reader)) (func in))");
    evalStringSafe("(define (read-from-string string) (with-input-from-string string (lambda (in) (read in))))");
    evalStringSafe("(define (string-length string) (invoke string 'length))");
    evalStringSafe("(define string=? equal?)");
    evalStringSafe("(defmacro (def-string-compare comp) `(begin (define (,(symbol-conc 'string comp '?) s1 s2) (,comp (invoke s1 'compareTo s2) 0)) (define (,(symbol-conc 'string-ci comp '?) s1 s2) (,comp (invoke (invoke s1 'toLowerCase) 'compareTo (invoke s2 'toLowerCase)) 0))))");
    evalStringSafe("(def-string-compare <)");
    evalStringSafe("(def-string-compare >)");
    evalStringSafe("(def-string-compare >=)");
    evalStringSafe("(def-string-compare <=)");
    evalStringSafe("(define (string-ci=? s1 s2) (invoke s1 'equalsIgnoreCase s2))");
    evalStringSafe("(define (string-ref string i) (invoke string 'charAt i))");
    evalStringSafe("(define (parse-substrings string separator) (let loopx ((results '()) (index0 0) (index1 (invoke string 'indexOf separator))) (if (negative? index1) (reverse (cons (substring string index0 (string-length string)) results)) (loopx (cons (substring string index0 index1) results) (+ index1 1) (invoke string 'indexOf separator (+ index1 1))))))");
    evalStringSafe("(define (string->list string) (define len (string-length string)) (let loop ((i 0)) (if (= i len) '() (cons (string-ref string i) (loop (+ i 1))))))");
    evalStringSafe("(define (list->string list) (apply string list))");
  }
}