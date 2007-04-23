;;; read an embedded url, produce an output that is the original input plus
;;; superscripts and endnotes for each link, for printing.
;;; started Fri Mar 12 09:50:00 1999

;;; potential problems:
; this parser sucks in its treatment of text and whitespace
; frames need to be dealt with
; GRRR... it occurs to me that I have a much more developed HTML parser/manipulator
; written in CL...so there.
; id


(define (start-endnote-service port)
  (start-http-service 
   port
   (lambda (out command url headers *socket*)
     (define *client-site* (invoke *socket* 'getInetAddress))
     (let ((*html-output* (lambda (thing) (display thing out)))
	   (*html-port* out))
       (define result
;	 (catch
	  (process-url url))
;       (if (instanceof result 'java.lang.Throwable)
;	   (output-error result #f))
       (close-output-port out))))
  )

(start-endnote-service 1111)


(define (process-url xurl)
  (let* ((url (new 'java.net.URL
		   (substring xurl 1 (string-length xurl)))) ;get rid of leading /
	 (instream (invoke url 'openStream))
	 (url-seen #f)
	 (text-seen #f)
	 (collected-links '()))
    (define (collect)
      (push (list url-seen text-seen) collected-links)
      (set! url-seen #f)
      (set! text-seen #f))
    (html-parse instream
		(lambda (tag)
		  (define tag-type (invoke tag 'getTagType))
		  (if (and url-seen 
			   (= 1 tag-type)
			   (invoke tag 'isEndTag))
		      (collect))
		  (cond ((= 1 tag-type)	;it's an A tag
			 (awhen (invoke tag 'getParam "href")
				(if url-seen (collect))
				(set! url-seen it)))
			; +++ should do something more intelligent for frames
			((= 38 tag-type)	;FRAME tag
			 (awhen (invoke tag 'getParam "src")
				(if url-seen (collect))
				(set! url-seen it))))
		  (lambda (text)
		    (when url-seen
			  (push text text-seen)))))
    (close instream)))
  
  

(require-resource 'scm/web/html-parser.scm)

