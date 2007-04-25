;;; draw grids of colored boxes
;;; requires color.scm

(define box-size 8)
(define box-border 1)



(define (draw-grid xs ys proc)
  (let* ((w (make-window "grid" (* xs box-size) (* ys box-size)))
	 (p (new 'com.ibm.jikes.skij.misc.Panel
		 (lambda (g)
		   (invoke g 'setColor black)
		   (invoke g 'fillRect 0 0 (* xs box-size) (* ys box-size))
		   (dotimes (x xs)
			    (dotimes (y ys)
				     (draw-box g x y (proc x y))))))))
    (invoke w 'add p)))

(define (draw-random-grid xs ys)
  (draw-grid xs ys (lambda (x y) (random-color))))

(define (draw-box g x y color)
  (invoke g 'setColor color)
  (invoke g 'fillRect (* x box-size) (* y box-size) (- box-size box-border) (- box-size box-border)))

;;; here's a nice one
;(draw-grid 30 30 (lambda (x y) (make-color (* x 8) (* y 8) 200)))

'(draw-grid 40 40 (lambda (x y)
		   (make-color-safe (* 10 (abs (- x 20)))
				    100
				    (* 10 (distance 20 20 x y)))))

(define (square x) (* x x))
(define (distance x1 y1 x2 y2)
  (sqrt (+ (square (- x1 x2)) (square (- y1 y2)))))


;;; utils that should be somewhere else

(defmacro (dotimes var-until . body)
  `(for-times (lambda (,(car var-until)) ,@body)
	      ,(cadr var-until)))

(define (for-times proc n)
  (letrec ((pproc (lambda (nn)
		    (unless (= nn n)
			    (proc nn)
			    (pproc (+ nn 1))))))
    (pproc 0)))
		    

