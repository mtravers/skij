;;; Classpath hacking

(define (get-classpath)
  (define rawpath (system-property "java.class.path"))
  (define separator (system-property "path.separator"))
  (parse-path rawpath (char->int (invoke separator 'charAt 0))))

; break up a string into components, return as a list
(define (parse-path string separator)
  (define result '())
  (define finger1 0)
  (loop
   (define finger2 (invoke string 'indexOf separator finger1))
   (if (> finger2 0)
       (begin
	 (push (substring string finger1 finger2) result)
	 (set! finger1 (+ finger2 1)))
       (begin
	 (push (substring string finger1 (string-length string)) result)
	 (break))))
  (reverse result))

;;; this does not work, I'm afraid
(define (add-to-classpath item)
  (define props (invoke-static 'java.lang.System 'getProperties))
  (define classpath (invoke props 'get 'java.class.path))
  (define separator (invoke props 'get 'path.separator))
  (invoke props 'put 'java.class.path
	  (string-append item separator classpath)))

;;; new hack -- doesn't work either

(define e-loader (new 'com.ibm.jikes.ExtendableClassLoader))

(define (add-to-classpath dir)
  (invoke e-loader 'addClassPath dir))

(define (e-load-class class-name)
  (invoke e-loader 'loadClass class-name))

; works up to here, but class so loaded does not respond to (class-named <name>),
; or any Invoke methods. Argh.
; can't handle Zip or Jar files (yet)
