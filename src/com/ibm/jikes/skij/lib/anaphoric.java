package com.ibm.jikes.skij.lib;
class anaphoric extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (aif pred then . else) `(let ((it ,pred)) (if it ,then ,@else)))");
    evalStringSafe("(defmacro (aand . args) (cond ((null? args) #t) ((null? (cdr args)) (car args)) (#t `(aif ,(car args) (aand ,@(cdr args)) #f))))");
    evalStringSafe("(defmacro (awhen pred . body) `(aif ,pred (begin ,@body)))");
    evalStringSafe("(defmacro (acond . clauses) (if (null? clauses) #f (if (null? (cdar clauses)) `(or ,(caar clauses) (acond ,@(cdr clauses))) `(aif ,(caar clauses) (begin ,@(cdar clauses)) (acond ,@(cdr clauses))))))");
    evalStringSafe("(defmacro (key args key default) `(define ,key (aif (memq ',key ,args) (cadr it) ,default)))");
    evalStringSafe("(defmacro (repeat n . body) `(let loop ((i ,n)) (unless (= i 0) ,@body (loop (- i 1)))))");
  }
}