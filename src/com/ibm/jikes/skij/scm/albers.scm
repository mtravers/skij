(print '"Please set screen to 16-bit color or higher!")

(define (paint-rect g red green blue top left width height)
  (define color (new 'java.awt.Color (integer red) (integer green) (integer blue)))
  (synchronized g
   (invoke g 'setColor color)
   (invoke g 'fillRect (integer top) (integer left) (integer width) (integer height))))

; interesting "notched-tower" bug if you swap width and height on recurse
(define (rep-rect graphics r g b top left width height
		  dr dg db dtop dleft dwidth dheight)
  (define (rep-rect1 r g b top left width height)
    (paint-rect graphics r g b top left width height)
    (rep-rect1 (+ r dr) (+ g dg) (+ b db)
	       (+ top dtop) (+ left dleft) (+ width dwidth) (+ height dheight)))
  (rep-rect1 r g b top left width height))

; (rep-rect g 100 100 100 100 100 100 100 5 -10 15 5 5 10 10)
  
(require 'random)

(define (random-albers g size)
  (rep-rect g (random-range 256)(random-range 256)(random-range 256)
	    (random-range size) (random-range size) (random-range size) (random-range size) 
	    (arand 0 5) (arand 0 5) (arand 0 5) 
	    (arand 0 10) (arand 0 10) (* -1 (random-range 10)) (* -1 (random-range 10))))

(require 'thread)

(define (multi-albers n g size)
  (run-in-thread (lambda () (random-albers g size)))
  (if (> n 0)
      (multi-albers ("-" n 1) g size)))
  

(define (albers)
  (define w (make-window "Albers" 500 500))
  (define g (invoke w 'getGraphics))
  (in-own-thread 
   (let loop () 
     (catch				;+++ won't die when window closes
      (random-albers g 500))
     (loop))))
