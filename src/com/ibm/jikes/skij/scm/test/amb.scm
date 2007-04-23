; we' like to be able to say 
;    (* (amb 1 2 3) (amb 1 5 7))
; but that requires full call/cc. So instead:
;
;(let-amb x (1 2 3)
;   (let-amb y (1 5 7)
;      (* x y)))
; this requires all values to be computed in advance, so 

(define *backtrack-points* '())

(define (fail)
  (if (pair? *backtrack-points*)
      ((pop *backtrack-points*) ':failed)
      (error "fail failed: no more choices")))

(define call/cc call-with-current-continuation)

(defmacro (let-amb var values . body)
 `(let loop ((values ,values))
  (if (null? values)
      (fail)
      (let* ((,var (car values))
	     (result
	      (call/cc 
	       (lambda (k)
		 (push k *backtrack-points*)
		 ,@body))))
	(if (eq? result ':failed)
	    (loop (cdr values))
	    result)))))

(let-amb x '(1 2 3)
   (let-amb y '(1 5 7)
      (print (* x y))
      (fail)))
	
     
     

     
  
