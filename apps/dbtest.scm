;;; Trying to figure out why I can't make dbpanel work right

(define (dbtest)
  (define w (make-window "dbtest" 300 300))
  (define x 100)
  (define y 100)
  (define color (random-color))
  (define panel (new 'com.ibm.jikes.skij.misc.DBPanel 
		     (lambda (graphics)
		       (invoke graphics 'setColor (invoke w 'getBackground))
		       (invoke graphics 'fillRect 0 0 (invoke w 'getWidth) (invoke w 'getHeight))
		       (invoke graphics 'setColor color)
		       (invoke graphics 'fillRect x y 20 20))))
  (invoke w 'add panel)
  (define animator 
    (lambda () 
      (set! x (+ x (random 11) -5))
      (set! y (+ y (random 11) -5))
      (invoke panel 'repaint)))
  animator)
		       
