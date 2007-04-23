;;; Experiments in pure lambda calculus
;;; see G. Revesz, Lambda-Calculus, Combinators, and Functional Programming

;;; church numerals

(define zero
  (lambda (f)
    (lambda (x) x)))

(define one
  (lambda (f)
    (lambda (x)
      (f x))))

(define two
  (lambda (f)
    (lambda (x)
      (f (f x)))))

(define (integerize church-numeral)
  ((church-numeral
    (lambda (x)
      (+ x 1)))
   0))

(define successor
  (lambda (n)
    (lambda (f)
      (lambda (x)
	(f ((n f) x))))))

'(integerize (successor two))

(define three (successor two))

(define add
  (lambda (n)
    (lambda (m)
      (lambda (f)
	(lambda (x)
	  ((n f) ((m f) x)))))))

'(integerize ((add two) two))

(define multiply
  (lambda (n)
    (lambda (m)
      (lambda (f)
	(lambda (x)
	  ((n (m f)) x))))))

(integerize ((multiply three) two))

(define expn
  (lambda (n)
    (lambda (m)
      (lambda (f)
	(lambda (x)
	  (((n m) f) x))))))

;;; booleans

(define true
  (lambda (x)
    (lambda (y)
      x)))

(define false
  (lambda (x)
    (lambda (y)
      y)))

(define zerop
  (lambda (n)
    ((n (true false)) true)))

(define notp
  (lambda (b)
    ((b false) true)))

(define (booleanize church-boole)
  ((church-boole #t) #f))

;;; predecessor -- Church himself had trouble with this! (according to Revesz p41)

;;; (((pair 'x) 'y) true) ==> x
;;; (((pair 'x) 'y) false) ==> y
(define pair
  (lambda (a)
    (lambda (b)
      (lambda (z)
	((z a) b)))))

; [n, n-1] ==> [n+1, n]
(define next-pair
  (lambda (pair)
    (lambda (z)
      ((z (successor (pair true)))
       (pair true)))))

(define (listify pair)
  (list (integerize (pair true)) (integerize (pair false))))

(define base-pair ((pair zero) zero))

(define predecessor
  (lambda (n)
    (((n next-pair) base-pair) false)))