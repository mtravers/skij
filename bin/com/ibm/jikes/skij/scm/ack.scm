(define (increment x) (+ x 1))


(define (add x y)
  (if (= y 0) x
      (increment (add x (- y 1)))))

(define (mult x y)
  (if (= y 1) x
      (add x (mult x (- y 1)))))

(define (expt x y)
  (if (= y 1) x
      (mult x (expt x (- y 1)))))

; sigh, this gets a stack overflow real fast...I *think* this is right.
(define (ack l x y)
  (if (= l 0) 
      (+ x y)
      (if (= y 1)
	  x
	  (ack (- l 1)
	       x
	       (ack l x (- y 1))))))


;;; this is closer to the original
(define (ack m n)
  (if (= m 0) (+ n 1)
      (if (= n 0)
	  (ack (- m 1) 1)
	  (ack (- m 1)
	       (ack m (- n 1))))))

