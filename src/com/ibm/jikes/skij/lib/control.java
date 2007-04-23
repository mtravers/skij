package com.ibm.jikes.skij.lib;
class control extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (cond . clauses) (if (null? clauses) #f (let ((clause (car clauses))) (if (eq? (car clause) 'else) `(begin ,@(cdr clause)) (if (eq? (cadr clause) '=>) `(let ((%temp% ,(car clause))) (if %temp% (,(caddr clause) %temp%) (cond ,@(cdr clauses)))) `(if ,(caar clauses) (begin ,@(cdar clauses)) (cond ,@(cdr clauses))))))))");
    evalStringSafe("(defmacro (case item . clauses) (let ((sym '%%gensym%%)) `(let ((,sym ,item)) ,(cons 'cond (map (lambda (clause) (cons (if (eq? (car clause) 'else) #t `(memv ,sym ',(car clause))) (cdr clause))) clauses)))))");
    evalStringSafe("(define (eqv? a b) (or (eq? a b) (and (instanceof a 'java.lang.Number) (instanceof b 'java.lang.Number) (= a b)) (and (instanceof a 'java.lang.Character) (instanceof b 'java.lang.Character) (invoke a 'equals b))))");
    evalStringSafe("(define (not x) (if x #f #t))");
    evalStringSafe("(defmacro (when pred . body) `(if ,pred (begin ,@body)))");
    evalStringSafe("(defmacro (unless pred . body) `(if (not ,pred) (begin ,@body)))");
  }
}