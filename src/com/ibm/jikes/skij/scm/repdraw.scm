(require 'window)
(require 'thread)

(define (repdraw w x0 y0 x1 y1 x0f y0f x1f y1f)
  (draw-line w x0 y0 x1 y1)
  (repdraw w 
	   (x0f x0) (y0f y0) (x1f x1) (y1f y1)
	   x0f y0f x1f y1f))

(define (incr d) (lambda (x) (+ x d)))
(define (identity x) x)

(define w (make-window 'RepDraw 400 400))
'(run-in-thread 
 (lambda ()
   (repdraw w 0 30 0 400 (incr 3) (incr 1) (incr 2) (incr -3))))

'(run-in-thread 
 (lambda ()
   (repdraw w 0 400 300 400 (incr 2) (incr -1) (incr -2) (incr -3))))
		  
 

(define (itrdraw w n x0 y0 x1 y1 x0f y0f x1f y1f)
  (loop
   (draw-line w x0 y0 x1 y1)
   (set! n (+ n -1))
   (if (= n 0) (break #f))
   (set! x0 (x0f x0))
   (set! y0 (y0f y0))
   (set! x1 (x1f x1))
   (set! y1 (y1f y1))))




