package com.ibm.jikes.skij.lib;
class trace extends SchemeLibrary {
  static {
    evalStringSafe("(define tracer #f)");
    evalStringSafe("(define (make-tracer name) (define tree (make-tree-window name #f)) (set! tracer (list tree (set-root tree name))) tracer)");
    evalStringSafe("(make-tracer 'tracer)");
    evalStringSafe("(define (set-current-node tracer nnode) (set-car! (cdr tracer) nnode))");
    evalStringSafe("(define (traceprint tracer msg) (add-child (car tracer) (cadr tracer) (write-to-string msg)))");
    evalStringSafe("(define (tracein tracer msg) (define nnode (traceprint tracer msg)) (set-current-node tracer nnode) nnode)");
    evalStringSafe("(define (traceout node msg) (if node '() (set! node (cadr tracer))) (set-current-node tracer (node-parent node)) (traceprint tracer msg))");
    evalStringSafe("(define (traced-proc procedure name) (define encapsulated (trace-encapsulate procedure)) (lambda args (if (eq? (car args) 'magic-restore-argument) (eval `(set! ,name procedure)) (apply encapsulated args))))");
    evalStringSafe("(define (trace-encapsulate procedure) (lambda args (define node (tracein tracer `(Entering ,procedure with ,args))) (define result (apply procedure args)) (traceout node `(Exit with ,result)) result))");
    evalStringSafe("(define (settrace procname) (set! saved-procs (cons (list procname (eval procname)) saved-procs)) (eval `(set! ,procname (traced-proc (eval procname) procname))))");
    evalStringSafe("(defmacro (ptrace procname) `(set! ,procname (trace-encapsulate ,procname)))");
    evalStringSafe("(define (untrace procname) (restore-original procname))");
    evalStringSafe("(define saved-procs '())");
    evalStringSafe("(define (save-original procname) (set! saved-procs (cons `(,procname ,(eval procname)) saved-procs)))");
    evalStringSafe("(define (restore-original procname) (eval `(set! ,procname (cadr (assq procname saved-procs)))))");
    evalStringSafe("(define (untrace-all) (for-each (lambda (entry) (restore-original (car entry))) saved-procs))");
  }
}