;;; A successful porting of littleboxes.scm to jscheme.  Very few changes necessary


;;; see lib/graph.scm

(import "java.awt.*")

(define (random arg)
  (if arg
      (random-range arg)
    (invoke-static 'java.lang.Math 'random)))

(define (random-range n)
  (* n (random #f)))

(define (make-window name width height)
  (define w (new 'java.awt.Frame name))
  (primp-window w width height #f)
  w)

(define (primp-window w width height proc)
  (invoke w 'setSize width height)
  (invoke w 'setVisible #t))

(define (random-color)
  (random-bright-color 100))

(define (integer x)
  (inexact->exact x))

;;; utils that should be somewhere else

(define-macro (dotimes var-until . body)
  `(for-times (lambda (,(car var-until)) ,@body)
	      ,(cadr var-until)))

(define (for-times proc n)
  (letrec ((pproc (lambda (nn)
		    (if (not (= nn n))
			(begin
			  (proc nn)
			  (pproc (+ nn 1)))))))
    (pproc 0)))


(define (random-bright-color min-component)
  (define (random-bright-component)
    (+ min-component (integer (random-range (- 256 min-component)))))
  (Color. (random-bright-component) (random-bright-component) (random-bright-component)  ))

(define (make-color r g b) (new 'java.awt.Color r g b))
(define black (make-color 0 0 0))

(define (make-color-safe r g b) (new 'java.awt.Color (modulo (integer r) 256) (modulo (integer g) 256) (modulo (integer b) 256)))



;;; draw grids of colored boxes

(define box-size 8)
(define box-border 1)

(define (draw-grid xs ys proc)
  (let* ((w (make-window "grid" (* xs box-size) (* ys box-size)))
	 (p (new 'jlib.SchemeCanvas 200 200))) ;+++ on size
    (poke p "paintHandler"
	  (lambda (g)
	    (invoke g 'setColor black)
	    (invoke g 'fillRect 0 0 (* xs box-size) (* ys box-size))
	    (dotimes (x xs)
		     (dotimes (y ys)
			      (draw-box g x y (proc x y))))))
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



		    


