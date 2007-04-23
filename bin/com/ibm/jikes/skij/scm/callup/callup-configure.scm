(define *location* 'US)			;location DB to use

(define *os* (intern (invoke-static 'java.lang.System 'getProperty "os.name")))
(define *remote-os* *os*)		;may be overridden during configuration

;;; these are for use in remote modes
(define *remote-host* "w3.watson.ibm.com")

; remote-shell mode
(define *user* "mt")
(define *password* #f)

;;; remote-server mode
(define *remote-socket* 2345)

; must end with space
(define *callup-command*'"/usr/agora/bin/call2 ")

(define (configure-callup)
  (cond ((probe-for-local)
	 (configure-for-local))
	((probe-for-server)
	 (configure-for-server))
	((probe-for-remote-shell)
	 (configure-for-remote-shell))
	(#t
	 (error '"Can't find a path to callup"))))

(define (probe-for-server)
  (not (instanceof
	(catch (simple-client *remote-host* *remote-socket* '"blow, joe"))
	'java.lang.Exception)))

(define (configure-for-server)
  (print `(using callup through remote server at ,*remote-host*))
  (set! *remote-os* 'AIX)
  (set! callup-string
	(lambda (string)
	  (simple-client *remote-host* *remote-socket* string))))

(define (probe-for-local)
  (eq? *os* 'AIX))

(define (configure-for-local)
  (print `(using callup locally))
  (set! callup-string
	(lambda (string)
	  (with-string-output-port
	   (lambda (out)
	     (shell-exec (callup-command string) out))))))

(define (probe-for-remote-shell)
  (or *password*
      (begin 
	(print '"Set *user* and *password* for a valid Agora account, and try again.")
	#f)))

(define (configure-for-remote-shell)
  (print `(using callup through remote shell at ,*remote-host*))
  (set! callup-string
	(lambda (string)
	  (with-string-output-port
	   (lambda (out)
	     (rsh (callup-command string)
		  *remote-host*
		  *user*
		  *password*
		  out))))))

		