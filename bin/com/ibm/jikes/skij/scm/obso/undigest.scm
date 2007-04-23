(define (undigest-file infile outfile)
  (call-with-output-file 
      outfile
    (lambda (out)
      (set! out (current-output-port))
      (define (line-out line)
	(invoke out 'write line)
	(newline out))
      (call-with-input-file
	  infile
	(lambda (in)
	  (let loop ((line (read-line in)))
	    (if (invoke line 'startsWith "--------------------")
		(begin
		  (line-out line)
		  (set! line (read-line in))
		  (if (= 0 (string-length line))
		      (begin (line-out line)
			     (line-out "From ???@??? Thu Oct 23 22:53:05 1997"))
		      (begin
			(print (string-append "warning: nonblank line after separator: "
					      line))
			(line-out line))))
		(line-out line))
	    (loop (read-line in))))))))

(undigest-file "d:/Eudora/Lists.fol/scheme.mbx"
	       "d:/Eudora/Lists.fol/scheme.undigest")
	    
		      
