package com.ibm.jikes.skij.lib;
class quasi extends SchemeLibrary {
  static {
    evalStringSafe("(define (eval-quasi exp env) (car (eval-quasi1 exp env 0)))");
    evalStringSafe("(begin (define (eval-quasi1 exp env level) (if (pair? exp) (if (null? exp) (list '()) (if (eq? 'quasiquote (car exp)) (list (list 'quasiquote (car (eval-quasi1 (cadr exp) env (+ level 1))))) (if (eq? 'unquote (car exp)) (if (= level 0) (list (eval (cadr exp) env)) (list (list 'unquote (car (eval-quasi1 (cadr exp) env (- level 1)))))) (if (eq? 'unquote-splicing (car exp)) (if (= level 0) (copy-list (eval (cadr exp) env)) (list (list 'unquote-splicing (car (eval-quasi1 (cadr exp) env (- level 1)))))) (list (nconc (eval-quasi1 (car exp) env level) (car (eval-quasi1 (cdr exp) env level)))))))) (if (vector? exp) (list (list->vector (car (eval-quasi1 (vector->list exp) env level)))) (list exp)))) (define (copy-list lis) (if (pair? lis) (cons (car lis) (copy-list (cdr lis))) lis)))");
  }
}