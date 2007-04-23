package com.ibm.jikes.skij.lib;
class proc extends SchemeLibrary {
  static {
    evalStringSafe("(define (procedure? thing) (instanceof thing 'com.ibm.jikes.skij.Procedure))");
    evalStringSafe("(define (procedure-arity-valid? proc k) (let ((arity (procedure-arity proc))) (and (>= k (car arity)) (or (not (cdr arity)) (<= k (cdr arity))))))");
    evalStringSafe("(define (procedure-arity proc) (let loop ((rest (peek proc 'args)) (count 0)) (cond ((null? rest) (cons count count)) ((pair? rest) (loop (cdr rest) (+ count 1))) ((symbol? rest) (cons count #f)) (#t (error \"bad arglist\")))))");
    evalStringSafe("(define (procedure-environment proc) (peek proc 'env))");
    evalStringSafe("(define (args proc) (peek proc 'args))");
  }
}