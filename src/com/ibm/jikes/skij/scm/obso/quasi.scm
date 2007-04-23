(require 'control)

;;; with splicing, does a hell of a lot of excess list-building
(define (eval-quasi exp)
  (car (eval-quasi1 exp #e0)))

; returns value with extra list wrapping (so unquote-splice can work)
(define (eval-quasi1 exp level)
  (if (pair? exp)
      (if (null? exp) '(())
	  (cond ((eq? 'unquote (car exp))
		 (list (eval-unquote exp level)))
		((eq? 'unquote-splice (car exp))
		 (eval-unquote exp level))
		((eq? 'quasiquote (car exp))
		 (list (list 'quasiquote (eval-quasi1 (cadr exp) (i+ level #e1)))))
		(#t (list (apply append (map (lambda (subexp) (eval-quasi1 subexp level))
					     exp))))))
      (list exp)))
 

(define (eval-unquote form level)
  (if (i= level #e0)
      (eval (cadr form))
      (list (car form) (eval-quasi (cadr form) (i- level #e1)))))