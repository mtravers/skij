(let loop ((x 1))
  (print x)
  (if (< x 10) (loop (+ x 1))))

(let loop ((x 1))
  (print x)
  (cond ((< x 10) (loop (+ x 1)))))

; has error
(let loop ((x 1))
  (print x)
  (cond ((> x 10))
	(#t (loop (+ x 1)))))

; has error
(let loop ((x 1))
  (print x)
  (or (> x 10)
      (cond (#t (loop (+ x 1))))))

; has error
(let loop ((x 1))
  (print x)
  (or (> x 10)
      (if #t (begin (loop (+ x 1))) (cond))))

; has error
(let ((x 10))
  (or #f
      (print x)))

; has error
(let ((x 10))
  (or #f
      x))

(cond ((equal? 10 10))
      ((equal? 10 20)
       (print 'foo))
      ((equal? 20 20))
      (#t (print 'hey)))