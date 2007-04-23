; todo
; - filter out GIFs and other non-html files 
; need timeouts and error handling for net stuff
;

(define tt-text (peek-static 'adc.parser.HtmlStreamTokenizer 'TT_TEXT))
(define tt-tag (peek-static 'adc.parser.HtmlStreamTokenizer 'TT_TAG))
(define tt-eof (peek-static 'adc.parser.HtmlStreamTokenizer 'TT_EOF))

(define (html-parse stream process-tag process-text)
  (define tokenizer (new 'adc.parser.HtmlStreamTokenizer stream))
  (define ttype #f)
  (define tag (new 'adc.parser.HtmlTag))
  (define result '())
  (call-with-current-continuation 
   (lambda (break)
     (let loop ((ttype (invoke tokenizer 'nextToken)))
       (cond ((= ttype tt-text)
	      (process-text (invoke tokenizer 'getStringValue))) ;warning: returned string is ephemeral, intern if saving
	     ((= ttype tt-tag)
	      (invoke tokenizer 
		      'parseTag 
		      (invoke tokenizer 'getStringValue)
		      tag)
	      (process-tag tag))		;same with tag, it;s reused
	     ((= ttype tt-eof)
	      (break #t))
	     )
       (loop (invoke tokenizer 'nextToken))))))


(define (html-references stream)
  (define result '())
  (html-parse stream
	      (lambda (tag)
		(if (= 1 (invoke tag 'getTagType))	;it's an A tag
		    (aif (invoke tag 'getParam "href")
			 (push it result))))
	      (lambda (x) '()))
  (reverse result))


;;; get link text as well...clumsily since parser breaks up words
(define (html-links url)
  (define stream (invoke url 'openStream))
  (define result '())
  (define url-seen #f)
  (define text-seen #f)
  (define (trim-off-anchor url-string)
    (aif (string-search url-string (char->int #\#) 0)
	 (substring url-string 0 it)
	 url-string))
  (define (collect)
    (ignore-errors-and-warn		;URL may be bad
     (set! url-seen (trim-off-anchor url-seen))	;+++ might want to be optional
     (define url-obj (new 'java.net.URL url url-seen))
     (when (and (member (invoke url-obj 'getProtocol)
			'("http" "ftp"))
		(not (equal? url-obj url)) ;ignore idempotent links
		(not (assoc url-obj result))) ;ignore duplicates
	   (print `(link to ,url-obj " *** " ,text-seen))
	   (push (list url-obj  text-seen) result))
     (set! url-seen #f)
     (set! text-seen #f)))
  (html-parse stream
	      (lambda (tag)
;		(print `(tag ,tag of type ,(invoke tag 'getTagType)))
		(define tag-type (invoke tag 'getTagType))
		(if (and url-seen 
			 (= 1 tag-type)
			 (invoke tag 'isEndTag))
		    (collect))
		
		(cond ((= 1 tag-type)	;it's an A tag
		       (awhen (invoke tag 'getParam "href")
			      (if url-seen (collect))
			      (set! url-seen it)))
		      ((= 38 tag-type)	;FRAME tag
		       (awhen (invoke tag 'getParam "src")
			      (if url-seen (collect))
			      (set! url-seen it)))))
	      (lambda (x) 
		(if url-seen
		    (set! text-seen
			  (if text-seen
			      (string-append text-seen '" " (string x))
			      (string x))))))
  (if url-seen (collect))
  (reverse result))
