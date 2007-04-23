;;; see if we can improve on quasi

(require 'lists)
;(require 'io)				;temp, for debugging statements
;(require 'trace)

;;; Correct, I think, but VERY slow.

(defmacro (or-as-is exp form)
  `(begin
     (define result ,exp)
     (if (eq? result 'fribble)
	 ,exp
	 result)))

(define (eval-quasi exp env)
;  (print (string-append '"eval-quasi on " (invoke exp 'toString)))
  (or-as-is exp (eval-quasi1 exp env 0)))

; returns value with extra list wrapping (so unquote-splice can work)
; unfortunately COND depends on quasi so we can't use it here.

; returns 'fribble if passed-in exp can be used without modification
(define (eval-quasi1 exp env level)
;  (define node (tracein tracer (string-append '"eval-quasi on " (invoke exp 'toString) '" at level " (invoke level 'toString))))
;  (define result
  (if (list? exp)
      (if (null? exp) '()
	  (if (eq? 'quasiquote (car exp))
	      ;; nested quasiquote
	      (list (list 'quasiquote (car (eval-quasi1 (cadr exp) env (+ level 1)))))
	      (if (eq? 'unquote (car exp))
		  (if (= level 0)
		      (list (eval (cadr exp) env)) ;expanded unquote
		      (list (list 'unquote (car (eval-quasi1 (cadr exp) env (- level 1)))))) ;deferred unquote
		  (if (eq? 'unquote-splice (car exp))
		      (if (= level 0)
			  (eval (cadr exp) env)	;expanded unquote-splice
			  (list (list 'unquote-splice (car (eval-quasi1 (cadr exp) env (- level 1)))))) ; deferred unquote-splice
		      ;; everything else
		      (
		      (list (apply nconc (map (lambda (subexp) (eval-quasi1 subexp env level))
					      exp)))))))
	  exp)
;  (traceout node result)
;  result
  )





