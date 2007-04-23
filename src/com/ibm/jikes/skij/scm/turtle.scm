(require 'window)

(define (make-turtle w)
  (define window w)
  (define x 200)
  (define y 200)
  (define heading 0)
  (define pendown #t)
  (define (move nx ny)
    (if pendown (draw-line window x y nx ny))
    (set! x nx)
    (set! y ny))
  (lambda (msg arg)			;. notation doesn't work, in parser or apply, in fact you can't have a Cons with a non-list cdr
    (if (eq? msg 'fd)
	(move (+ x (* arg (cos heading)))
	      (+ y (* arg (sin heading)))))
    (if (eq? msg 'rt)
	(set! heading (+ heading arg)))))

(define (repeat thunk n)
  (if (= n 0) '()
    (begin (thunk) (repeat thunk (+ n -1)))))

(define (repeat-forever thunk)
  (thunk)
  (repeat-forever thunk))

;(repeat (lambda () (turt 'fd 50) (turt 'rt 2)) 100)

(define (spi dl dtheta)
  (define l 0)
  (define theta 0)
  (define (loop)
    (turt 'fd l) (turt 'rt theta)
    (set! l (+ l dl))
    (set! theta (+ theta dtheta))
    (loop))
  (loop))
                   

(repeat-forever (lambda () 
		  