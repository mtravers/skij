package com.ibm.jikes.skij.lib;
class lists extends SchemeLibrary {
  static {
    evalStringSafe("(define (caar x) (car (car x)))");
    evalStringSafe("(define (cdar x) (cdr (car x)))");
    evalStringSafe("(define (cddr x) (cdr (cdr x)))");
    evalStringSafe("(define (caaar x) (car (car (car x))))");
    evalStringSafe("(define (caadr x) (car (car (cdr x))))");
    evalStringSafe("(define (cadar x) (car (cdr (car x))))");
    evalStringSafe("(define (caddr x) (car (cdr (cdr x))))");
    evalStringSafe("(define (cdaar x) (cdr (car (car x))))");
    evalStringSafe("(define (cdadr x) (cdr (car (cdr x))))");
    evalStringSafe("(define (cddar x) (cdr (cdr (car x))))");
    evalStringSafe("(define (cdddr x) (cdr (cdr (cdr x))))");
    evalStringSafe("(define (cadddr x) (car (cdr (cdr (cdr x)))))");
    evalStringSafe("(define (list? l) (if (null? l) #t (if (pair? l) (list? (cdr l)) #f)))");
    evalStringSafe("(define (length l) (if (null? l) 0 (+ 1 (length (cdr l)))))");
    evalStringSafe("(define (memq thing lst) (if (eq? lst '()) #f (if (eq? thing (car lst)) lst (memq thing (cdr lst)))))");
    evalStringSafe("(define (memv thing list) (if (null? list) #f (if (eqv? thing (car list)) list (memv thing (cdr list)))))");
    evalStringSafe("(define (assq obj alist) (%ass obj alist eq?))");
    evalStringSafe("(define (assv obj alist) (%ass obj alist eqv?))");
    evalStringSafe("(define (assoc obj alist) (%ass obj alist equal?))");
    evalStringSafe("(define (%ass obj alist compare) (if (null? alist) #f (if (compare obj (caar alist)) (car alist) (%ass obj (cdr alist) compare))))");
    evalStringSafe("(define (reverse lst) (define (reverse1 lst rev) (if (null? lst) rev (reverse1 (cdr lst) (cons (car lst) rev)))) (reverse1 lst '()))");
    evalStringSafe("(define (sort lst comp) (if (null? lst) lst (if (null? (cdr lst)) lst (begin (define pivot (car lst)) (define less '()) (define more '()) (for-each (lambda (elt) (if (comp pivot elt) (set! more (cons elt more)) (set! less (cons elt less)))) (cdr lst)) (append (sort less comp) (cons pivot (sort more comp)))))))");
    evalStringSafe("(define append (lambda lists (if (null? lists) '() (if (null? (cdr lists)) (car lists) (append1 (car lists) (apply append (cdr lists)))))))");
    evalStringSafe("(define (append1 l1 l2) (if (null? l1) l2 (cons (car l1) (append1 (cdr l1) l2))))");
    evalStringSafe("(define (list-tail lst k) (if (= k 0) lst (list-tail (cdr lst) (- k 1))))");
    evalStringSafe("(define (list-ref lst k) (car (list-tail lst k)))");
    evalStringSafe("(define (position elt lst test) (define rest lst) (define i 0) (loop (if (null? rest) (break #f)) (if (test (car rest) elt) (break i)) (set! rest (cdr rest)) (set! i (+ i 1))))");
    evalStringSafe("(define (last-cdr lst) (if (null? (cdr lst)) lst (last-cdr (cdr lst))))");
    evalStringSafe("(define (filter-out pred list) (if (null? list) list (if (pred (car list)) (filter-out pred (cdr list)) (cons (car list) (filter-out pred (cdr list))))))");
    evalStringSafe("(define (filter pred list) (if (null? list) list (if (pred (car list)) (cons (car list) (filter pred (cdr list))) (filter pred (cdr list)))))");
    evalStringSafe("(define (butlast list) (if (= (length list) 1) '() (cons (car list) (butlast (cdr list)))))");
    evalStringSafe("(define (last list) (if (= (length list) 1) (car list) (last (cdr list))))");
    evalStringSafe("(define (delete object list) (cond ((null? list) list) ((eq? (car list) object) (delete object (cdr list))) (#t (cons (car list) (delete object (cdr list))))))");
    evalStringSafe("(define (ndelete object list) (if (eq? object (car list)) (ndelete object (cdr list)) (let loopx ((rest list)) (cond ((null? rest) #f) ((and (pair? (cdr rest)) (eq? (car (cdr rest)) object)) (set-cdr! rest (cdr (cdr rest))) (loopx (cdr rest))) (#t (loopx (cdr rest)))) list)))");
    evalStringSafe("(define (remove-duplicates list) (cond ((null? list) '()) ((memq (car list) (cdr list)) (remove-duplicates (cdr list))) (#t (cons (car list) (remove-duplicates (cdr list))))))");
    evalStringSafe("(begin (define (nconc1 l1 l2) (set-cdr! (last-cdr l1) l2) l1))");
    evalStringSafe("(define nconc (lambda args (if (null? args) '() (if (null? (car args)) (apply nconc (cdr args)) (if (null? (cdr args)) (car args) (nconc1 (car args) (apply nconc (cdr args))))))))");
  }
}