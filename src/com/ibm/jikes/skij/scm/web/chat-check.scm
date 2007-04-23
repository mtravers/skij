;;; check a web page for changes periodically

;example:
;(monitor-page "http://www.alphaWorks.ibm.com/forum/skij.nsf/discussion_current"  ; the URL
;	      "alphaworks"                ; a unique name
;	      (* 1000 60 60 24))          ; time in milliseconds between checks


(defstruct page url save-file time-file interval)

(define *temp-dir* "c:/temp/")

(define (monitor-page url name time)
  (background-check
   (make-page url
	      (string-append *temp-dir* name "-contents")
	      (string-append *temp-dir* name "-time")
	      time)))


(define (download-url url file)
  (call-with-output-file file
    (lambda (out)
      (copy-until-eof (new 'com.ibm.jikes.skij.InputPort 
			   (invoke (new 'java.net.URL url) 'openStream))
		      out))))

(define (page-to-string page)
  (with-string-output-port
    (lambda (out)
      (copy-until-eof (new 'com.ibm.jikes.skij.InputPort 
			   (invoke (new 'java.net.URL (page-url page)) 'openStream))
		      out))))

(define (file-to-string file)
  (with-string-output-port
   (lambda (out)
     (call-with-input-file file
       (lambda (in)
	 (copy-until-eof in out))))))

(define (string-to-file string file)
  (with-input-from-string
   string
   (lambda (in)
     (call-with-output-file file
       (lambda (out)
	 (copy-until-eof in out))))))

(define (check-page-changed page)
  (define page-string (page-to-string page))
  (define file-string (catch (file-to-string (page-save-file page))))
  (if (equal? page-string file-string)
      (print `(Nothing new for ,(page-url page)))
      (begin
	(print `(***NEW STUFF*** on ,(page-url page)))
	(require-resource 'scm/browser.scm)
	(browse-url (page-url page))
	(delete-file (page-save-file page))
	(string-to-file page-string (page-save-file page)))))
  
(define (time-for-check? page)
  (let ((res
	 (catch
	  (call-with-input-file (time-file page)
	    (lambda (in)
	      (> (- (integer (now)) (read in))
		 (page-interval page)))))))
    (if (boolean? res)
	res
	#t)))

(define (check page)
  (if (time-for-check? page)
      (begin
	(check-page-changed page)
	(delete-file (page-time-file page))
	(call-with-output-file (page-time-file page)
	  (lambda (out)
	    (print (integer (now)) out)))) ;+++ can't read longs, and this seems to preserve order at least
;      (display "\n(relax, i'll check later)")
      ))

(define (delete-file file)
  (invoke (new 'java.io.File file) 'delete))
	
(define (background-check page)
  (in-own-thread
   (check page)
   (sleep (page-interval page))))



; http://www.dejanews.com/dnquery.xp?QRY=skij&DBS=2&defaultOp=AND&maxhits=20&ST=QS&format=terse