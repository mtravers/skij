package com.ibm.jikes.skij.lib;
class thread extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (synchronized thing . body) `(%synchronized ,thing (lambda () ,@body)))");
    evalStringSafe("(define (run-in-thread thunk) (define thread (new 'java.lang.Thread thunk)) (invoke thread 'start) thread)");
    evalStringSafe("(defmacro (in-own-thread . body) `(run-in-thread (lambda () ,@body)))");
    evalStringSafe("(define (current-thread) (invoke-static 'java.lang.Thread 'currentThread))");
    evalStringSafe("(define (all-threads group) (define count (invoke group 'activeCount)) (define array (%make-vector count (class-named 'java.lang.Thread))) (invoke group 'enumerate array) (vector->list array))");
    evalStringSafe("(define (user-threads) (all-threads (invoke (current-thread) 'getThreadGroup)))");
    evalStringSafe("(define (sleep n) (invoke-static 'java.lang.Thread 'sleep n))");
    evalStringSafe("(define (thread-inspector) (define bigpanel (new 'com.sun.java.swing.JPanel)) (invoke bigpanel 'setLayout (new 'java.awt.GridLayout 0 1)) (for-each (lambda (thread) (define smallpanel (new 'com.sun.java.swing.JPanel)) (invoke smallpanel 'add (new 'com.sun.java.swing.JTextArea (invoke thread 'getName))) (invoke smallpanel 'add (make-button 'Suspend (lambda (evt) (invoke thread 'suspend)))) (invoke smallpanel 'add (make-button 'Resume (lambda (evt) (invoke thread 'resume)))) (invoke smallpanel 'add (make-button 'Interrupt (lambda (evt) (invoke thread 'interrupt)))) (invoke bigpanel 'add smallpanel)) (user-threads)) (make-window 'Threads bigpanel))");
  }
}