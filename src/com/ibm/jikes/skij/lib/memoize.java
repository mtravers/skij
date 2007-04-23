package com.ibm.jikes.skij.lib;
class memoize extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (define-memoized form . body) (let ((fname (car form)) (arg (cadr form)) (process (cddr form))) `(begin (define ,fname #f) (let ((ht (make-hashtable))) (set! ,fname (lambda (key) (if (eq? key ':hashtable) ht (hashtable-lookup ht ,(if (null? process) 'key `(,(car process) key)) (lambda (,arg) ,@body)))))))))");
  }
}