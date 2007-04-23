(define (kentest host port)
  (define socket (new 'java.net.Socket host port))
  (define out (new 'com.ibm.jikes.skij.OutputPort (invoke socket 'getOutputStream)))
  (for-each (lambda (line)
	      (display line out)
	      (newline out))
	    lines)
  (define in (new 'com.ibm.jikes.skij.InputPort (invoke socket 'getInputStream)))
  (do ((line (read-line in) (read-line in)))
        ((eof-object? line))
      (display line)
      (newline)))

(define lines 
  '("POST /simpleupload.php HTTP/1.0"
    "Pragma: no-cache"
    "Cache-control: no-cache"
    "Content-type: multipart/form-data; boundary=------------------------------4844136176792136526464136435952"
    "Content-length: 243"
    ""
    "--------------------------------4844136176792136526464136435952"
    "Content-Disposition: form-data; name=\"userfile\"; filename=\"fourletter.txt\""
    "Content-Type: text/plain"
    ""
    "fuck"
    "--------------------------------4844136176792136526464136435952--"
    ))

;;; another approach
;; from https://lists.xcf.berkeley.edu/lists/advanced-java/2003-April/019453.html
;; this is swell but does a get -- how do I do the post?
(define (urltest url)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDefaultUseCaches #f)
  (invoke conn 'setRequestProperty "Content-type" "application/x-www-form-urlencoded")
  (define outstream (new 'java.io.DataOutputStream (invoke conn 'getOutputStream)))
;  (define outwriter (new 'java.io.OutputStreamWriter outstream))
  (define out (lambda (string) (invoke outstream 'writeBytes
				       (invoke-static 'java.net.URLEncoder 'encode (write-to-string string)))))
  (out "filename=foo&userfile=")
  (out (write-to-string m))
  (invoke outstream 'write 13)
  (invoke outstream 'write 10)
  (invoke outstream 'flush)
  (invoke outstream 'close)
  ;;
  (define instream (new 'java.io.DataInputStream (invoke conn 'getInputStream)))
  (do ((byte 0)) 
      ((= byte -1));(> (invoke instream 'available) 0)
    (set! byte (invoke instream 'read))
    (write-char (int->char byte)))
  )

(urltest "http://www.hyperphor.com/patblocks/sampleupload.php")
(urltest "http://localhost/simpleupload.php")

;;; scrap
(invoke conn 'setDefaultUseCaches #f)
(invoke conn 'setDoInput #t)
(define postWriter (new 'java.io.PrintWriter (invoke conn 'getOutputStream)))
(invoke postWriter 'print (string-append "

;;; and yet another, from http://www.javaworld.com/javaworld/javatips/jw-javatip34.html

(define (happytest url)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDoInput #t)
  (invoke conn 'setDefaultUseCaches #f)
  

;;; and again
(define (posttest url)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDefaultUseCaches #f)
  (invoke conn 'setRequestMethod "POST")
  (invoke conn 'setRequestProperty "Content-Type" "application/x-www-form-urlencoded")
  ;; content length?
  (invoke conn 'setRequestProperty "Content-Length" "25")
  (define outstream (new 'java.io.DataOutputStream (invoke conn 'getOutputStream)))
;  (define outwriter (new 'java.io.OutputStreamWriter outstream))
  (define out (lambda (string) (invoke outstream 'writeBytes
				       (invoke-static 'java.net.URLEncoder 'encode (write-to-string string)))))
  (out "foo=blither&userfile=")
  (out (write-to-string m))
  (invoke outstream 'write 13)
  (invoke outstream 'write 10)
  (invoke outstream 'flush)
  (invoke outstream 'close)
  ;;
  (define instream (new 'java.io.DataInputStream (invoke conn 'getInputStream)))
  (do ((byte 0)) 
      ((= byte -1));(> (invoke instream 'available) 0)
    (set! byte (invoke instream 'read))
    (write-char (int->char byte)))
  )


(define (posttest2 url string)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDefaultUseCaches #f)
  (invoke conn 'setRequestMethod "POST")
  (invoke conn 'setRequestProperty "Content-Type" "application/x-www-form-urlencoded")
  (define encoded (invoke-static 'java.net.URLEncoder 'encode string))
  (invoke conn 'setRequestProperty "Content-Length" (display-to-string (string-length encoded)))
;  (define outstream (invoke conn 'getOutputStream))
  (define outstream (new 'java.io.DataOutputStream (invoke conn 'getOutputStream)))

  (invoke outstream 'write (invoke encoded 'getBytes))
  (invoke outstream 'flush)
  (invoke outstream 'close)
  ;;
  (display `(response ,(invoke conn 'getResponseCode)))

  (define instream (new 'java.io.DataInputStream (invoke conn 'getInputStream)))
  (do ((byte 0)) 
      ((= byte -1));(> (invoke instream 'available) 0)
    (set! byte (invoke instream 'read))
    (write-char (int->char byte)))
  )

;(posttest2a "http://localhost/debug.php" "foo=blither&something=somethingelse")
; doesn't work, damn it
(define (posttest2a url string)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDefaultUseCaches #f)
  (invoke conn 'setRequestMethod "POST")
  (invoke conn 'setRequestProperty "Content-Type" "application/x-www-form-urlencoded")
  (define encoded (invoke-static 'java.net.URLEncoder 'encode string))
  (invoke conn 'setRequestProperty "Content-Length" (display-to-string (string-length encoded)))
;  (define outstream (invoke conn 'getOutputStream))
  (define outstream (new 'java.io.PrintStream (invoke conn 'getOutputStream)))

  (invoke outstream 'println encoded)
  (invoke outstream 'flush)
  (invoke outstream 'close)
  ;;
  (display `(response ,(invoke conn 'getResponseCode)))

  (define instream (new 'java.io.DataInputStream (invoke conn 'getInputStream)))
  (do ((byte 0)) 
      ((= byte -1));(> (invoke instream 'available) 0)
    (set! byte (invoke instream 'read))
    (write-char (int->char byte)))
  )


;;; Yay, this works!
;(posttest2a "http://localhost/debug.php" '(("foo" "blither") ("something" "somethingelse")))
(define (posttest2a url params)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDefaultUseCaches #f)
  (invoke conn 'setRequestMethod "POST")
  (invoke conn 'setRequestProperty "Content-Type" "application/x-www-form-urlencoded")
;  (define encoded (invoke-static 'java.net.URLEncoder 'encode string))
  (define encoded 
    (with-string-output-port 
     (lambda (out)
       (for-each (lambda (item)
		   (display (car item) out)
		   (display "=" out)
		   (display (invoke-static 'java.net.URLEncoder 'encode (cadr item)) out)
		   (display "&" out))
		 params))))
     
  (invoke conn 'setRequestProperty "Content-Length" (display-to-string (string-length encoded)))
;  (define outstream (invoke conn 'getOutputStream))
  (define outstream (new 'java.io.PrintStream (invoke conn 'getOutputStream)))

  (invoke outstream 'println encoded)
  (invoke outstream 'flush)
  (invoke outstream 'close)
  ;;
  (display `(response ,(invoke conn 'getResponseCode)))

  (define instream (new 'java.io.DataInputStream (invoke conn 'getInputStream)))
  (do ((byte 0)) 
      ((= byte -1));(> (invoke instream 'available) 0)
    (set! byte (invoke instream 'read))
    (write-char (int->char byte)))
  )

(define (post-url url params)
  (define url (new 'java.net.URL url))
  (define conn (invoke url 'openConnection))
  (invoke conn 'setDoOutput #t)
  (invoke conn 'setDefaultUseCaches #f)
  (invoke conn 'setRequestMethod "POST")
  (invoke conn 'setRequestProperty "Content-Type" "application/x-www-form-urlencoded")
  (define encoded 
    (with-string-output-port 
     (lambda (out)
       (for-each (lambda (item)
		   (display (car item) out)
		   (display "=" out)
		   (display (invoke-static 'java.net.URLEncoder 'encode (cadr item)) out)
		   (display "&" out))
		 params))))
     
  (invoke conn 'setRequestProperty "Content-Length" (display-to-string (string-length encoded)))
  (define outstream (new 'java.io.PrintStream (invoke conn 'getOutputStream)))
  (invoke outstream 'println encoded)
  (invoke outstream 'flush)
  (invoke outstream 'close)
  '(define instream (new 'java.io.DataInputStream (invoke conn 'getInputStream)))

  ;; reads the reply
  '(do ((byte 0)) 
      ((= byte -1))
    (set! byte (invoke instream 'read))
    (write-char (int->char byte)))
  )
