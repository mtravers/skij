(load-resource 'scm/web/html-parser.scm)

; a link is a list: (webnode link-text)
(defstruct webnode
  url
  links-in
  links-out
  distance)

(define start-node #f)

(define (set-start url)
  (set! start-node (intern-url url))
  (set-webnode-distance! start-node 0))

; given url object or string, return a webnode
(define-memoized (intern-url url)
  (if (string? url)
      (set! url (new 'java.net.URL url)))
  (make-webnode url #f #f #f))

;;; screen out mailto:, etc.
(define (useful-url? url)
  (not (or (equal? 'mailto (invoke url 'getProtocol))
	   )))

(define (explore-out node)
  (define new-frontier (+ 1 (webnode-distance node)))
  (set-webnode-links-out! 
   node
   (map (lambda (ref)
	  (define newbie (intern-url (car ref)))
	  (set-webnode-distance! newbie new-frontier)
	  (list newbie (cadr ref)))
	(begin
	  (define u (webnode-url node))
	  (print `(reading ,u))
	  (html-links u)))))

; needs work
(define (explore-in webnode)
  (define new-frontier (- (webnode-distance webnode) 1))
  (set-webnode-links-in! 
   webnode
   (map (lambda (ref)
	  (define newbie (intern-url ref))
	  (set-webnode-distance! newbie new-frontier)
	  newbie)
	(url-back-references (webnode-url webnode))))
  (webnode-links-in webnode))

(define (url-back-references url)
  (define iu (new 'java.net.URL 
		  (string-append '"http://www.altavista.digital.com/cgi-bin/query?pg=q&what=web&kl=XX&q="
				 (invoke-static 'java.net.URLEncoder
					 'encode
					 (string-append '"link:" url)))))
  (print iu)
  (av-links iu))


;;; given alta vista page url, return the links
(define (av-links u)
  (define raw-refs (html-links u))
  (define (string-tail? string tail)
    (define len (string-length tail))
    (invoke string 'regionMatches #t (- (string-length string) len) tail 0 len))
  (filter (lambda (entry)
	    (define hostname (invoke (car entry) 'getHost))
	    (not (or (string-tail? hostname 'altavista.digital.com)
		     (string-tail? hostname 'www.digital.com)
		     (string-tail? hostname 'doubleclick.net)
		     (string-tail? hostname 'www.amazon.com))))	;might rule out some legit links, oh well
	  raw-refs))
	    

