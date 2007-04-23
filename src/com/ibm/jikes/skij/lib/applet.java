package com.ibm.jikes.skij.lib;
class applet extends SchemeLibrary {
  static {
    evalStringSafe("(define *last-applet* #f)");
    evalStringSafe("(define (run-applet class-or-name base-url width height parameters) (install-null-security-manager) (map (lambda (param) (set-car! param (to-string (car param)))) parameters) (let ((applet (new class-or-name)) (stub (new 'com.ibm.jikes.skij.misc.SkijAppletStub parameters (new 'java.net.URL base-url) (new 'java.net.URL base-url))) (window (make-window (string-append \"Applet \" (string class-or-name)) width height))) (set! *last-applet* applet) (invoke applet 'setStub stub) (invoke applet 'init) (invoke applet 'start) (invoke window 'add applet) (invoke window 'show) applet))");
    evalStringSafe("(define (install-null-security-manager) (if (%%null? (invoke-static 'java.lang.System 'getSecurityManager)) (let ((manager (new 'com.ibm.jikes.skij.misc.SkijSecurityManager (lambda (type . args) (cond ((equal? type \"checkExit\") #f) (#t #t)))))) (invoke-static 'java.lang.System 'setSecurityManager manager) manager)))");
  }
}