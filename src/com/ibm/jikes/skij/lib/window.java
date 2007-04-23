package com.ibm.jikes.skij.lib;
class window extends SchemeLibrary {
  static {
    evalStringSafe("(define (make-window name width height) (define w (new 'java.awt.Frame name)) (primp-window w width height #f) w)");
    evalStringSafe("(define (make-window-for-panel title panel) (define w (new 'java.awt.Frame title)) (invoke w 'add panel) (invoke w 'pack) (invoke w 'show) (add-window-close-handler w (lambda () #f)) w)");
    evalStringSafe("(define (primp-window w width height proc) (invoke w 'setSize width height) (invoke w 'setVisible #t) (add-window-close-handler w (or proc (lambda () #f))))");
    evalStringSafe("(define window-closing-event-id (peek-static 'java.awt.event.WindowEvent 'WINDOW_CLOSING))");
    evalStringSafe("(define (add-window-close-handler window proc) (invoke window 'addWindowListener (new 'com.ibm.jikes.skij.misc.GenericCallback (lambda (evt) (if (= (invoke evt 'getID) window-closing-event-id) (begin (invoke window 'dispose) (proc)))))))");
    evalStringSafe("(define (make-button name action) (define b (new 'java.awt.Button (to-string name))) (define listener (new 'com.ibm.jikes.skij.misc.GenericCallback action)) (invoke b 'addActionListener listener) b)");
  }
}