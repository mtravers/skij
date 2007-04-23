; error
(define (snark8)
  (display (string-append "foo" "bar")))

;ok
(display (string-append "foo" "bar"))

; ok
(define (snark2 name)
  (display "fuck me harder")
  )

;ok
(define (snark4)
  (string-append "foo" "bar"))

;ok
(define (snark5)
  (display (begin "foo")
	   ))

; error
(define (snark9)
  (begin
    (display (string-append "foo" "bar"))
    34))

; ok
(define (snark10)
  (display (new 'java.lang.String "frutznicator")))

; error
(define (snark11)
  (display (new-string)))

(define (new-string)
  (new 'java.lang.String "frutznicator"))

; so the error happens when the arg to display is a function call?  

; ok
(define (snark12)
  (display (current-environment)))

; error
(define (snark13)
  (display ((lambda () (current-environment)))))

;ok
(define (snark14)
  ((lambda () (current-environment))))

; ok
(define (snark15)
  (+ 3 ((lambda () 6))))

;ok
(define (snark16)
  (list ((lambda () (current-environment)))))

;ok (when port is bound to good output port)
(define (snark17)
  (display ((lambda () (current-environment))) port))

; alright, so problem is in port lookup...argh

(define (foo) *bar)
(let ((*bar* 23)) (foo))

; this gets stackoverflowerror, despite no dynamic lookup...argh

; so does this, so let is just broken...
(let ((*bar* 23)) (+ 3 4))

; so does this
(macroexpand '(let ((*bar* 23)) (+ 3 4)))

; oh, maybe it's autoload, which calls display...


;;;; a different problem
(define (xlast-cdr list)
  (if (null? (cdr list))
      list
      (xlast-cdr (cdr list))))

(xlast-cdr '(a b c))

returns correct value but leaves the top-level value of list as (d) !!!!

Alright, fixed this...


(define (tailtri n)
  (define (helper m res)
    (if (= n m)
	res
	(helper (+ m 1) (+ res m))))
  (helper 0 0))

(tailtri 10000) works in tail evaluator, overflows in regular, alright!
    
speed is comprable, maybe a little slower.

  