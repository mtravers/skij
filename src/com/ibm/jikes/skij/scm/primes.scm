(define (isprime x primes)
  (cond ((null? primes) #t)
	((= 0 (remainder x (car primes)))
	 #f)
	;; this clause is not necessary but saves a good deal of time
	((> (* (car primes) (car primes)) x)
	 #t)
	(#t
	 (isprime x (cdr primes)))))

(define (gen-primes x primes)
  (if (isprime x primes)
      (begin
	(print x)
	(gen-primes (+ x 2) (nconc primes (list x))))
      (gen-primes (+ x 2) primes)))

; (gen-primes 3 '())

(define (divides? a b)
  (zero? (modulo b a)))

(define (factors x)
  (if (divides? 2 x)
      (cons 2 (factors (/ x 2)))
      (factors1 x 3)))

(define (factors1 x n)
  (cond ((divides? n x)
	 (cons n (factors1 (/ x n) n)))
	((= 1 x) '())
	(#t (factors1 x (+ n 2)))))

