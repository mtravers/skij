;;; Dynamic HTML generation

;;; very dynamic!
(require 'dynamic)

(define (html-output string)
  ((dynamic *html-output*) string))

(define (output-start-tag name attributes)
  (define html-output (dynamic *html-output*)) ;save a few dynamic lookups
  (html-output '<)
  (html-output name)
  (for-each (lambda (att)
	      (html-output " ")
	      (html-output (car att))
	      (when (cdr att)
		(html-output '=)
		(if (number? (cadr att))
		    (html-output (cadr att))
		    (begin
		      (html-output "\"")
		      (html-output (cadr att))
		      (html-output "\"")))))
	    attributes)
  (html-output '>))

(define (output-end-tag name)
  (output-start-tag (end-tag name) '()))

;;; saves some string consing
(define-memoized (end-tag start-tag)
  (string-append '/ start-tag))

(define (with-env name attributes body-proc)
  (output-start-tag name attributes)
  (body-proc)
  (output-end-tag name))

(defmacro (tag name . atts)
  `(output-start-tag ',name ',atts))

(defmacro (env tag . body)
  (if (list? tag)
      `(with-env ',(car tag) ',(cdr tag) (lambda () ,@body))
      `(with-env ',tag '() (lambda () ,@body))))

(defmacro (lenv . args)
  `(begin
     (html-output "\n")
     (env ,@args)))

(defmacro (ltag . args)
  `(begin
     (html-output "\n")
     (tag ,@args)))


(defmacro (doc title . body)
  `(env html
	(lenv head
	      (env title
		   (html-output ',title)))
	(lenv body  
	      ,@body)))

