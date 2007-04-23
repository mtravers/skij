package com.ibm.jikes.skij.lib;
class tcp extends SchemeLibrary {
  static {
    evalStringSafe("(define (open-tcp-conn host port) (define sock (new 'java.net.Socket host port)) (define in (new 'com.ibm.jikes.skij.InputPort (invoke sock 'getInputStream))) (define out (new 'com.ibm.jikes.skij.OutputPort (invoke sock 'getOutputStream))) (lambda args (define op (car args)) (case op ((in) in) ((out) out) (#t (error \"foo\")))))");
    evalStringSafe("(define (set-proxy-host host) (invoke (invoke-static 'java.lang.System 'getProperties) 'put \"socksProxyHost\" host))");
  }
}