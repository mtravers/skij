(define *sock* '())

; doesn't work, gets IllegalAccess on read, presumably because
; in is a java.net.SocketInputStream, which is not a public 
; class
(define (tcp-test)
  (define sock (new 'java.net.Socket '"gumby.watson.ibm.com" #e21))
  (define in (invoke sock 'getInputStream))
  (set! *sock* sock)
  (invoke in 'read))			;gets an IllegalAccessException, why?


; however, this loses too, it can't get a constructor for the filter,
; despite the fac that java.net.SocketInputStream DOES inherit from
; java.io.InputStream, and there is one for that....
(define (tcp-test1)
  (define sock (new 'java.net.Socket '"gumby.watson.ibm.com" #e21))
  (set! *sock* sock)
  (define in (invoke sock 'getInputStream))
  (define inb (new 'java.io.FilterInputStream in))
  (invoke inb 'read))

;;; ok, i defined read-char as a primitive. This works. Sigh.
(define (tcp-test2)
  (define sock (new 'java.net.Socket '"gumby.watson.ibm.com" #e21))
  (define in (invoke sock 'getInputStream))
  (set! *sock* sock)
  (read-char in))


(define (open-tcp-conn host port)
  (define sock (new 'java.net.Socket '"gumby.watson.ibm.com" #e21))
  (define in (invoke sock 'getInputStream))
  (define out (invoke sock 'getOutputStream))
  (lambda args
    (define op (car args))
    (if (eq? op 'in)
	in
	(if (eq? op 'out)
	    out
	    (error)))))
