;;; lame version of circular list printing

(define original-write write)

(define (write thing . rest)
  (define port (if (null? rest) 
		   (current-output-port)
		   (car rest)))
  (let ((*written* (dynamic *written*)))
    (if (or (pair? thing) (vector? thing))
	(if (memq thing *written*)
	    (original-write '<<recursion>> port)
	    (begin
	      (push thing *written*)
	      (original-write thing port)))
	(original-write thing port))))