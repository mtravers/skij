package com.ibm.jikes.skij.lib;
class encapsulate extends SchemeLibrary {
  static {
    evalStringSafe("(define (encapsulate proc-name before after) (save-procedure proc-name) (define original (eval proc-name)) (define encapsulated (lambda args (before args) (define result (apply original args)) (after result) result)) (eval `(set! ,proc-name ',encapsulated)))");
    evalStringSafe("(define *saved-procs* (make-hashtable))");
    evalStringSafe("(define (save-procedure name) (hashtable-put *saved-procs* name (eval name)))");
    evalStringSafe("(define (restore-procedure name) (eval `(set! ,name (hashtable-get *saved-procs* ',name))))");
    evalStringSafe("(define (restore-all-procedures) (map-hashtable (lambda (name proc) (restore-procedure name)) *saved-procs*))");
  }
}