(define w (make-window 'foo 300 300))
(invoke w 'setLayout (new 'java.awt.FlowLayout))

(define (fribble)
  (loop
   (define word (read))
   (define word (new 'java.awt.Label word))
   (if (eq? word 'theend) (break #t))
   (invoke w 'add word)
   (invoke w 'show)))

(define (read-line in-port)
  (