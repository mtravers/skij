(define (set-security-manager proc)
  (define mgr (new 'mt.skij.misc.SkijSecurityManager proc))
  (invoke '(class java.lang.System) 'setSecurityManager mgr)
  mgr)

(define (set-security-warn)
  (print 'ignoreMe)
  (set-security-manager
   (lambda (op . args)
     (print `(security check: ,op ,@args))
     #t)))

(define *security-default* #t)		;#t to allow access by default
(define *security-handlers* (make-hashtable))
(defmacro (define-security-handler form . body)
  `(hashtable-put *security-handlers*
		  ',(car form)
		  (lambda ,(cdr form)
		    ,@body)))

;;; force these to autoload BEFORE manager is set up.

(define (setup-security-manager)
  (print `(foo ,23))
  (aif 'blah 'foo 'bar)
  (set-security-manager
   (lambda (op . args)
     (print `(security check: ,op ,@args))
     (aif (hashtable-get *security-handlers* op #f)
	  (apply it args)
	  *security-default*))))



   




