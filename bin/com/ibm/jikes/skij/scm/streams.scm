;;; delayed streams a la SICP


(defmacro (make-stream first rest)
  `(cons ,first
	 (lambda ()
	   ,rest)))

(define stream-head car)

(define (stream-tail stream)
  ((cdr stream)))
  
(define empty-stream '())
(define empty-stream? null?)

(define (expand stream)
  (if (empty-stream? stream)
      '()
      (cons (stream-head stream)
	    (expand (stream-tail stream)))))

(define (expand-n stream n)
  (if (or (empty-stream? stream)
	  (zero? n))
      '()
      (cons (stream-head stream)
	    (expand-n (stream-tail stream) (- n 1)))))

;;; implementation-independent

(define (enumerate a b)
  (if (= a b) 
      empty-stream
      (make-stream a
		   (enumerate (+ a 1) b))))


(define (filter pred stream)
  (cond ((empty-stream? stream) empty-stream)
	((pred (stream-head stream))
	 (make-stream (stream-head stream)
		      (filter pred (stream-tail stream))))
	(#t (filter pred (stream-tail stream)))))
  
(define (combine-streams func s1 s2)
  (make-stream (func (stream-head s1) (stream-head s2))
	       (combine-streams func (stream-tail s1) (stream-tail s2))))

(define ones (make-stream 1 ones))

(define integers
  (make-stream 1 (combine-streams + ones integers)))

(define fibs
  (make-stream 0
	       (make-stream 1
			    (combine-streams + (stream-tail fibs) fibs))))

;;; caching version
(defmacro (make-stream first rest)
  `(let ((ran? #f)
	 (value #f))
     (cons ,first
	   (lambda ()
	     (if (not ran?)
		 (begin (set! value ,rest) (set! ran? #t) value)
		 value)))))