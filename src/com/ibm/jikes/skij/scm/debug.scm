
(defmacro (begin-traced . forms)
  `(begin ,@(map (lambda (form)
		   `(begin
		      (print `(eval ,',form))
		      (print ,form)))
		 forms)))


