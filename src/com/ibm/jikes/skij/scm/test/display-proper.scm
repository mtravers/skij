(defun (proper-string obj)
  (cond ((boolean? obj)
	 (if obj '"#t" '"#f"))
;...	
	(#t
	 (string obj))))