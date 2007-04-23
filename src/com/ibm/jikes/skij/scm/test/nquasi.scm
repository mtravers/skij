(define (expand-quasi form env)
  (if (pair? exp)
      (if (null? exp) (list '())
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
		      (list (apply nconc (map (lambda (subexp) (eval-quasi1 subexp env level))
					      exp)))))))
      (list exp))