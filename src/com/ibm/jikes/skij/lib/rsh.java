package com.ibm.jikes.skij.lib;
class rsh extends SchemeLibrary {
  static {
    evalStringSafe("(define (rsh cmd host user password out) (define conn (open-tcp-conn host 512)) (define stream (conn 'out)) (define (net-out string) (invoke stream 'write string) (write-char #,(integer->char 0) stream)) (net-out \"\") (net-out user) (net-out password) (net-out cmd) (read-char (conn 'in)) (copy-until-eof (conn 'in) out))");
  }
}