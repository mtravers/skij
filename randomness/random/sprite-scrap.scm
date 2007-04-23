;;; Random stuff from sprites/patblocks that is not actually needed.

(define (make-random-rect)
  (make 'rect-sprite 
    'x (random 300) 'y (random 300) 
    'xs (+ 20 (random 100)) 'ys (+ 20 (random 100)) 
    'color (random-color)))

(define (make-rect-window)
  (define manager (make-sprite-window "Sprites" 300 300))
  (repeat 10 (add-sprite manager (make-random-rect)))
;  (manager-clock man)
  manager)

