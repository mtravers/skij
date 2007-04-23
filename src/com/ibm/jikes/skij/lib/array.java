package com.ibm.jikes.skij.lib;
class array extends SchemeLibrary {
  static {
    evalStringSafe("(define (%make-array dimensions class) (invoke-static 'java.lang.reflect.Array 'newInstance class (list->int-vector dimensions)))");
    evalStringSafe("(define (list->int-vector list) (define vec (%make-vector (length list) (peek-static 'java.lang.Integer 'TYPE))) (%fill-vector vec list) vec)");
    evalStringSafe("(define (aref array . idxs) (if (null? idxs) array (apply aref (%vector-ref array (car idxs)) (cdr idxs))))");
    evalStringSafe("(define (aset array val . idxs) (if (null? (cdr idxs)) (vector-set! array (car idxs) val) (apply aset (vector-ref array (car idxs)) val (cdr idxs))))");
  }
}