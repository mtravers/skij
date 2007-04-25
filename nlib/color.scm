
;;; see lib/graph.scm

(define (random-color)
  (random-bright-color 100))

(define (random-bright-color min-component)
  (define (random-bright-component)
    (+ min-component (integer (random-range (- 256 min-component)))))
  (new 'java.awt.Color (random-bright-component) (random-bright-component) (random-bright-component)  ))

(define (make-color r g b) (new 'java.awt.Color r g b))
(define black (make-color 0 0 0))

(define (make-color-safe r g b) (new 'java.awt.Color (modulo (integer r) 256) (modulo (integer g) 256) (modulo (integer b) 256)))



