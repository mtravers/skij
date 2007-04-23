;;; process items in CLASSPATH (zip/jar files or directories of class files)

(define *results* #f)

(define (classpath)
  (define classpath (invoke-static 'java.lang.System 'getProperty "java.class.path"))
  (define separator (invoke-static 'java.lang.System 'getProperty "path.separator"))
  (clean-classpath (parse-substrings classpath separator)))

; may contain duplicates
(define (all-class-names)
  (collecting
   (for-each 
    (lambda (path)
      (for-classes collect path))
    (classpath))))

(defmacro (collecting . body)
  `(let ((result '()))
     (define (collect x) (push x result))
     ,@body
     result))

; will actually load all classfiles it can find
(define all-classes
  (delay				;memoize
    (collecting
     (for-each (lambda (path-entry) 
		 (for-classes
		  (lambda (class-name)
		    (ignore-errors (collect (class-named class-name))))
		  path-entry))
	       (classpath)))))

(define (all-classes-from-path-entry path-entry)
  (let ((loader (loader-for-path-entry path-entry)))
    (collecting
     (for-classes
      (lambda (class-name)
	(ignore-errors-and-warn
	 (collect (invoke loader 'loadClass class-name #f))))
      path-entry))))

(define (class-named-from-path-entry class-name path-entry)
  (invoke (loader-for-path-entry path-entry)
	  'loadClass
	  class-name
	  #f))

(define-memoized (loader-for-path-entry path-entry)
  (let ((loader (new 'com.ibm.jikes.skij.misc.ExtendableClassLoader)))
    (invoke loader 'addClassPath path-entry)
    loader))

(define (xfind item lst compare key)
  (if (null? lst) #f
      (if (compare item (key (car lst)))
	  (car lst)
	  (xfind item (cdr lst) compare key))))

;;; remove apparently redundant elements (might remove something good, though)
(define (clean-classpath path)
  (define (file-namestring file)
    (car (parse-substrings (invoke (new 'java.io.File file) 'getName) (char->int #\.))))
  (if (null? path) '()
      (aif (xfind (file-namestring (car path)) (cdr path) equal? file-namestring)
	   (clean-classpath (delete it path))
	   (cons (car path)
		 (clean-classpath (cdr path))))))

(define (for-classes fun entry)
  (define file-type (file-type entry))
  (if (memq file-type '(zip jar))
      (for-zip-classes fun entry)
      (for-directory-classes fun entry)))

(define (for-zip-classes fun entry)
  (define file (new 'java.io.File entry))
  (define zip (new 'java.util.zip.ZipFile file))
  (for-enumeration (lambda (zippy)
		     (define filename (invoke zippy 'getName))
		     (when (eq? (file-type filename) 'class)
			   (fun (invoke (file-name filename)
					'replace 
					#\/ #\.))))
		   (invoke zip 'entries)))

(define (for-directory-classes fun dir)
  (define dirparts (directory-components dir))
  (for-all-files
   (lambda (fileobj)
     (when (eq? 'class (file-type  (invoke fileobj 'getName)))
	   (define fparts (directory-components (invoke fileobj 'getPath)))
	   (define dparts dirparts)
	   (let loop ()
	     (if (equal? (car fparts) (car dparts))
		 (begin (pop fparts) (pop dparts) (loop))
		 (fun (class-name-from-list fparts))
		 ))))
   dir))
		 
	   
(define (class-name-from-list package-list)
  (define buf (new 'java.lang.StringBuffer))
  (define list package-list)
  (define (output str) (invoke buf 'append str))
  (let loop ()
    (if (null? (cdr list))
	(output (file-name (car list)))
	(begin
	  (output (car list))
	  (output '".")
	  (pop list)
	  (loop))))
  (string buf))

(define (file-type filename)
  (define dotpos (invoke filename 'lastIndexOf #,(char->int #\.)))
  (if (> dotpos 0)
      (intern (substring filename (+ 1 dotpos) (string-length filename)))
      #f))

(define (file-name filename)
  (define dotpos (invoke filename 'lastIndexOf #,(char->int #\.)))
  (if (> dotpos 0)
      (substring filename 0 dotpos)
      filename))

(define dir-separator (string-ref (invoke-static 'java.lang.System 'getProperty "file.separator") 0))

(define (directory-components filename)
  (parse-substrings filename (char->int dir-separator)))
  
(define (dotify name)
  (invoke name 'replace dir-separator #\.))

