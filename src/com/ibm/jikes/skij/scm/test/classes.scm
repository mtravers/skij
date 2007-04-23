(define *results* #f)

(define (all-class-names)
  (define results '())
  (define (collect x) (push x results))
  (for-each process-path-entry (classpath))
  results)

(define (classpath)
  (define classpath (invoke '(class java.lang.System) 'getProperty 'java.class.path))
  (define separator (invoke '(class java.lang.System) 'getProperty 'path.separator))
  (parse-substrings classpath separator))
  
(define (process-path-entry entry)
  (define file-type (file-type entry))
  (if (memq file-type '(zip jar))
      (process-zip entry)
      (process-directory entry)))

(define (process-zip entry)
  (define file (new 'java.io.File entry))
  (define zip (new 'java.util.zip.ZipFile file))
  (for-enumeration (lambda (zippy)
		     (define filename (invoke zippy 'getName))
		     (when (eq? (file-type filename) 'class)
			   ((dynamic collect) (invoke (file-name filename)
						      'replace 
						      '#\/ '#\.))))
		   (invoke zip 'entries)))

(define (process-directory dir)
  (define dirparts (directory-components dir))
  (for-all-files
   (lambda (fileobj)
     (when (eq? 'class (file-type  (invoke fileobj 'getName)))
	   (define fparts (directory-components (invoke fileobj 'getPath)))
	   (define dparts dirparts)
	   (loop
	    (if (equal? (car fparts) (car dparts))
		(begin (pop fparts) (pop dparts))
		(begin ((dynamic collect) (class-name-from-list fparts))
		       (break))))))
   dir))
		 
	   
(define (class-name-from-list package-list)
  (define buf (new 'java.lang.StringBuffer))
  (define list package-list)
  (define (output str) (invoke buf 'append str))
  (loop
   (if (null? (cdr list))
       (begin 
	 (output (file-name (car list)))
	 (break))
       (begin
	 (output (car list))
	 (output '".")))
   (pop list))
  (string buf))

(define (file-type filename)
  (define dotpos (invoke filename 'lastIndexOf 46))	;.
  (if (> dotpos 0)
      (intern (substring filename (+ 1 dotpos) (string-length filename)))
      #f))

(define (file-name filename)
  (define dotpos (invoke filename 'lastIndexOf 46))	;.
  (if (> dotpos 0)
      (substring filename 0 dotpos)
      filename))

(define dir-separator (string-ref (invoke '(class java.lang.System) 'getProperty 'file.separator) 0))

(define (directory-components filename)
  (parse-substrings filename (char->int dir-separator)))
  
(define (dotify name)
  (invoke name 'replace dir-separator '#\.))
