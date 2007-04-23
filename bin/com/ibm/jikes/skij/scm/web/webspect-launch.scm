(define webspect-url 
  (new 'java.net.URL "http://fury.watson.ibm.com:2341/webspect/home.html"))

(define (webspect-server-up?)
  (let ((stream
	 (catch (invoke webspect-url 'openStream))))
    (if (instanceof stream 'java.lang.Exception)
	(begin (display `(Error trying to access ,webspect-url ,stream))
	       #f)
	(begin
	  (invoke stream 'close)
	  (display `(WebSpect looks OK ,webspect-url))))))

(require 'dialogs)

;;; assumes there is a "webspect" script defined on server
(define (start-webspect-server)
  (let* ((host (invoke webspect-url 'getHost))
	 (user "mt")
	 (password
	  (string-from-user (to-string `(password for ,user at ,host)) 'password #t)))
    (rsh "webspect" host user password (current-output-port))))
