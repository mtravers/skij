(define-command eval (form)
  (wsdoc "Eval"
	 (env (form (action eval-this))
	      (env (textarea (name form) (cols 40) (rows 6))
		   )
	      (tag input (type submit) (value Submit)))))

(define-command eval-this (form)
  (define result (catch (eval (read-from-string form))))
  (wsdoc "Eval Results"
	 (html-output '"Your result is: ")
	 (output-value result)))


;;; flattened form
  

;(define-command eval (form) (wsdoc "Eval" (env (form (action eval-this)) (env (textarea (name form) (cols 40) (rows 6))	) (tag input (type submit) (value Submit)))))

;(define-command eval-this (form) (define result (catch (eval (read-from-string form)))) (wsdoc "Eval Results" (html-output '"Your result is: ") (output-value result)))


;;; more commands

(define-command log ()
  (wsdoc "Log"
	 (env pre
	      (env (font (size -1))
	      (with-input-file
	       log-file
	       (lambda (in) 
		 (let ((oport (dynamic out))) ; *html-port*
		   (copy-until-eof in oport))))))))