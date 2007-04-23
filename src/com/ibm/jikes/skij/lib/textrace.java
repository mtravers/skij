package com.ibm.jikes.skij.lib;
class textrace extends SchemeLibrary {
  static {
    evalStringSafe("(define *trace-level* 0)");
    evalStringSafe("(define (traceprint msg) (newline) (let loop ((i (dynamic *trace-level*))) (unless (zero? i) (display \"  \") (loop (- i 1)))) (write msg))");
    evalStringSafe("(defmacro (with-traceprint msg . body) `(begin (traceprint ,msg) (let ((*trace-level* (+ (dynamic *trace-level*) 1))) ,@body)))");
    evalStringSafe("(define (proc-name proc) (%or-null (peek proc 'name) proc))");
    evalStringSafe("(define (trace-encapsulate procedure) (lambda args (traceprint `(Entering ,(proc-name procedure) with args ,@args)) (define result #f) (let ((*trace-level* (+ (dynamic *trace-level*) 1))) (set! result (apply procedure args))) (traceprint `(Exit ,(proc-name procedure) with ,result)) result))");
    evalStringSafe("(defmacro (ttrace procname) `(set! ,procname (trace-encapsulate ,procname)))");
  }
}