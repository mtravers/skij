package com.ibm.jikes.skij.lib;
class interrupt extends SchemeLibrary {
  static {
    evalStringSafe("(define *old-listener-thread* #f)");
    evalStringSafe("(define (make-interrupter) (define thread (current-thread)) (define window #f) (define panel (new 'java.awt.Panel)) (define button (make-button 'Interrupt (lambda (evt) (newline) (print \"Creating new Listener, old thread is in *old-listener-thread*\") (set! *old-listener-thread* thread) (invoke thread 'stop) (run-in-thread (lambda () (make-interrupter) (catch (invoke (new 'com.ibm.jikes.skij.SchemeListener) 'repl)))) (invoke window 'dispose)))) (define checkbox (new 'java.awt.Checkbox \"Trace\")) (invoke checkbox 'addItemListener (new 'com.ibm.jikes.skij.misc.GenericCallback (lambda (evt) (trace (= (invoke evt 'getStateChange) (peek-static 'java.awt.event.ItemEvent 'SELECTED)))))) (invoke panel 'add button) (invoke panel 'add checkbox) (set! window (make-window-for-panel \"Skij Control\" panel)))");
    evalStringSafe("(make-interrupter)");
  }
}