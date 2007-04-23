'(An icon-like language. Values are represented by a cons of their current value and
a generator)

(define (%find string in-string from)
  (invoke in-string 'indexOf string from))

; (every e1 e2)

(every (write (find 'er '"Here are later answers.")))

; should write a bunch of values

(sequence 1 20)

(defprim (sequence from to)
  (if (= from to)
      (fail)
      (make-sequence from
		     (sequence (+ from 1) to))))


(define (i:fail) 
  )

(define (i:eval exp scont fcont)
  (cond ((not (list? exp))
	 (cons exp fcont))
	((eq? (car exp) 'every)
	 (i:eval (cadr exp) 
		 (lambda ()
		   
	 
