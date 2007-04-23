package com.ibm.jikes.skij.lib;
class let extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (let clauses . body) (if (symbol? clauses) (named-let clauses (car body) (cdr body)) `((lambda ,(map car clauses) ,@body) ,@(map cadr clauses))))");
    evalStringSafe("(define (named-let name clauses body) `(letrec ((,name (lambda ,(map car clauses) ,@body))) (,name ,@(map cadr clauses))))");
    evalStringSafe("(defmacro (letrec clauses . body) `((lambda ,(map car clauses) ,@(map (lambda (clause) `(set! ,(car clause) ,(cadr clause))) clauses) ,@body) ,@(map (lambda (c) #f) clauses)))");
    evalStringSafe("(defmacro (let* clauses . body) `((lambda () ,@(map (lambda (clause) (cons 'define clause)) clauses) ,@body)))");
    evalStringSafe("(defmacro (do clauses end . body) `(let %%loop ,(map (lambda (clause) (list (car clause) (cadr clause))) clauses) (if ,(car end) (begin ,@(cdr end)) (begin ,@body (%%loop ,@(map (lambda (clause) (if (null? (cddr clause)) (car clause) (caddr clause))) clauses))))))");
    evalStringSafe("(defmacro (fluid-let clauses . body) `(let ((%saved-values #f)) (dynamic-wind (lambda () (set! %saved-values (list ,@(map car clauses))) ,@(map (lambda (clause) (cons 'set! clause)) clauses)) (lambda () ,@body) (lambda () ,@(map (lambda (clause) `(set! ,(car clause) (pop %saved-values))) clauses)))))");
  }
}