(require 'files)

(define msg-file 
  (new 'java.io.File
       (invoke-static 'java.lang.System 'getProperty "user.dir")
       "webspect-messages.txt"))
  
(define-command message-board ()
  (wsdoc "Message Board"
	 (output-message-board)))

(define (output-message-board)
  (html-output "The latest message is at the ")
  (env (a (href "#bottom"))
       (html-output "bottom"))
  (html-output " of this page.")
  (env pre
       (catch				;file may not exist
       (html-output
	(bypassing-security
	(with-string-output-port
	 (lambda (out)
	   (with-input-file 
	    msg-file
	    (lambda (in)
	      (copy-until-eof in out)))))))))
  (tag a (name bottom))
  (tag hr)
  (env big
       (html-output "Please add your own comment."))
  (env (form (action added-message))
       (html-output "Your name is: ")
       (tag input (name name) (type input))
       (ltag br)
       (env (textarea (name msg) (cols 40) (rows 6))
	    (html-output "Replace this text with your message"))
       (tag br)
       (tag input (type submit) (value Submit))))

(define (add-msg name msg)
  (bypassing-security
   (with-open-for-append 
    msg-file
    (lambda (port)
      (let ((*html-output* (lambda (string) (display string port))))
	(tag hr)
	(env big
	     (env b (html-output name))
	     (env small
		  (html-output " (")
		  (html-output (string (dynamic *host*)))
		  (html-output ")"))
	     (html-output " at ")
	     (html-output (now-string))
	     (env pre
		  (print msg port))))))))

(define-command added-message (msg name)
  (add-msg name msg)
  (wsdoc "Message has been added"
	 (output-message-board)))