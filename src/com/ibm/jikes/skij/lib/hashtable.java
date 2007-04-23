package com.ibm.jikes.skij.lib;
class hashtable extends SchemeLibrary {
  static {
    evalStringSafe("(define (make-hashtable) (new 'java.util.Hashtable))");
    evalStringSafe("(define (identity thing) thing)");
    evalStringSafe("(define (hashtable-get ht name default) (%or-null (invoke ht 'get name) default))");
    evalStringSafe("(define (hashtable-put ht name value) (invoke ht 'put name value))");
    evalStringSafe("(define (hashtable-remove ht name) (invoke ht 'remove name))");
    evalStringSafe("(define (hashtable-lookup ht name generator) (synchronized name (%or-null (invoke ht 'get name) (begin (define new (generator name)) (invoke ht 'put name new) new))))");
    evalStringSafe("(define (clear-hashtable ht) (invoke ht 'clear))");
    evalStringSafe("(define (map-hashtable func ht) (map-enumeration (lambda (key) (func key (hashtable-get ht key #f))) (invoke ht 'keys)))");
    evalStringSafe("(define (for-hashtable func ht) (for-enumeration (lambda (key) (func key (hashtable-get ht key #f))) (invoke ht 'keys)))");
    evalStringSafe("(define (hashtable-contents ht) (map-hashtable (lambda (key value) (cons key value)) ht))");
  }
}