package com.ibm.jikes.skij.lib;
class runtime extends SchemeLibrary {
  static {
    evalStringSafe("(define *runtime* (invoke-static 'java.lang.Runtime 'getRuntime))");
    evalStringSafe("(define (shell command) (shell-exec command (current-output-port)))");
    evalStringSafe("(define (shell-to-string command) (with-string-output-port (lambda (out) (shell-exec command out))))");
    evalStringSafe("(define (shell-exec command out) (define p (invoke *runtime* 'exec command)) (define s (invoke-static 'com.ibm.jikes.skij.misc.Kludge 'processInputStream p)) (define ss (new 'com.ibm.jikes.skij.InputPort s)) (define e (invoke-static 'com.ibm.jikes.skij.misc.Kludge 'processErrorStream p)) (define es (new 'com.ibm.jikes.skij.InputPort e)) (copy-until-eof ss out) (define errstring (with-string-output-port (lambda (error) (copy-until-eof es error)))) (if (> (string-length errstring) 0) (error errstring)))");
    evalStringSafe("(define (gc) (invoke *runtime* 'gc))");
    evalStringSafe("(define (room) (invoke *runtime* 'freeMemory))");
  }
}