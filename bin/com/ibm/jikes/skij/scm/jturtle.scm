(define w (make-window 'turtles 200 200))
(define g (invoke w 'getGraphics))
(define jt (new 'com.ibm.jikes.jhacks.logo.Turtle g))
(invoke jt 'penDown)