; pp is still screwy and very slow
;  fixed formatting, still leaves something to be desired
;  still too slow
; <i> in titles
; define-memoized things don't come out well.


(define (hppp thing)
  (generic-write thing
		 #f
		 80
		 (lambda (string)
		   (define proc #f)
		   (if (let* ((sym (string->symbol string))
			      (proc (catch (invoke (global-environment) 'getBinding sym))))
			 (and (procedure? proc)
			      (not (instanceof proc 'com.ibm.jikes.skij.PrimProcedure)))) ;let's suppress primitives
		       (with-link (string-append 'skijproc?proc= (%encode string))
				  (html-output string))
		       (html-output string))
		   #t)))
			     
		 
(define-command skijproc (proc obj)
  (define procedure 
    (if obj
	(code-object obj)
	(invoke (global-environment) 'getBinding (intern proc))))
  (unless proc
	  (set! proc (string procedure)))
  (wsdoc (lambda () 
	   (html-output "Definition of ")
	   (env i
		(html-output proc)))
	 (cond ((instanceof procedure 'com.ibm.jikes.skij.CompoundProcedure)
		(lenv PRE
		     (env TT
			  (hppp (proc-form procedure)))))
	       ((instanceof procedure 'com.ibm.jikes.skij.PrimProcedure)
		(html-output "Sorry, this is a primitive procedure and I can't display it."))
	       ((eq? procedure #f)
		(html-output "That procedure isn't defined."))
	       (#t
		(html-output "I'm confused.")))))

(define-command pageproc (pagename)
  (set! pagename (intern pagename))
  (define command-proc (hashtable-get *command-table* pagename #f))
  (wsdoc (lambda ()
	   (html-output "Page generation code for the ")
	   (env i
		(html-output pagename))
	   (html-output " command."))
	 (if command-proc
	     (env pre
		  (env tt 
		       (hppp (command-form command-proc pagename))))
	     (html-output "Unknown page"))))
	 

;;; turn a command procedure back into a form. Knows too much about DEFINE-COMMAND
(define (command-form command-proc command-name)
  (define nbody (proc-body command-proc))
  (let loopx ((params '())
	      (rbody (cdr nbody)))	;discard first item
    (if (and (pair? (car rbody))
	     (eq? (caar rbody) 'pull-parameter))
	(loopx (cons (caddr (car rbody)) params)
	       (cdr rbody))
	`(define-command ,command-name ,params ,@rbody))))

(define (output-doc-end)
  (tag hr)
  (env i
       (env (a (href /webspect/home.html))
	    (html-output "WebSpect Home")))
  (tag br)
  (ignore-errors			;*command* may not be bound
   (env small
	(let ((command (dynamic *command*)))
	  (html-output "View the ")
	  (with-link "http://w3.watson.ibm.com/~mt/skij"
		     (html-output 'Skij))
	  (html-output " code that ")
	  (with-link (string-append "pageproc?pagename=" (dynamic *command*))
		     (html-output "generated this page"))
	  (html-output ".")))))
