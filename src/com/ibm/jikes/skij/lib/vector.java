package com.ibm.jikes.skij.lib;
class vector extends SchemeLibrary {
  static {
    evalStringSafe("(define (vector->list vector) (define l (vector-length vector)) (define (a2l n) (if (= n l) '() (cons (vector-ref vector n) (a2l (+ n 1))))) (a2l 0))");
    evalStringSafe("(define (list->vector list) (invoke-static 'com.ibm.jikes.skij.PrimProcedure 'makeArray list))");
    evalStringSafe("(define (make-vector n . optional) (define newvec (invoke-static 'java.lang.reflect.Array 'newInstance (class-named 'java.lang.Object) n)) (if (not (null? optional)) (let loop ((elt (car optional)) (index 0)) (unless (= index n) (vector-set! newvec index elt) (loop elt (+ index 1))))) newvec)");
    evalStringSafe("(define (vector . args) (list->vector args))");
    evalStringSafe("(define (map-vector func vector) (define len (vector-length vector)) (define (map1 n) (if (= n len) '() (cons (func (vector-ref vector n)) (map1 (+ n 1))))) (map1 0))");
    evalStringSafe("(define (for-vector func vector) (define len (vector-length vector)) (define (map1 n) (if (= n len) (%null) (begin (func (vector-ref vector n)) (map1 (+ n 1))))) (map1 0))");
    evalStringSafe("(define (memq-vector item vector) (define len (vector-length vector)) (define (map1 n) (if (= n len) #f (or (eq? item (vector-ref vector n)) (map1 (+ n 1))))) (map1 0))");
    evalStringSafe("(define (%make-vector n class) (invoke-static 'java.lang.reflect.Array 'newInstance class n))");
    evalStringSafe("(define (%fill-vector vector list) (define index 0) (for-each (lambda (elt) (vector-set! vector index elt) (set! index (+ index 1))) list))");
  }
}