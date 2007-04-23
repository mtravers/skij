;;; would be nice if we could deduce this, but this seems hard for directories
(define lib-dir "d:/java/misc/com/ibm/jikes/skij/lib")

;;; Remove init.scm!!!!
;;; macros!

;;; new java file version:
;;; +++ some class names can't work (char, anything with a hyphen)
;;; what would be nice:
;;;  - a reader mode that didn't do #, (instead, made special form that printer knew about)
;;; do classes get unloaded? Can we force them somehow?
;;; try doing JIVE, and then JAXing the whole thing...

(define (lib-files)
  (filter (lambda (filename)
	    (define len (invoke filename 'length))
	    (and (>= len 4)
		 (equal? ".scm"
			 (substring filename (- len 4) len))
		 (not (equal? filename "init.scm"))))
	  (vector->list (invoke (new 'java.io.File lib-dir) 'list))))

(define (for-defines file func)
  (define file-name (substring file 0 (- (invoke file 'length) 4)))
  (define (process-form form)
    (cond ((eof-object? form) form)
	  ((memq (car form) '(define defmacro))
	   (if (pair? (cadr form))
	       (func (car form) (caadr form) file-name)
	       (func (car form) (cadr form) file-name)))
	  ((instanceof (catch (eval (car form))) 'com.ibm.jikes.skij.Macro)
	   (let ((expansion (macroexpand form)))
	     (if (eq? (car expansion) 'begin)
		 (map process-form (cdr expansion))
		 (process-form expansion))))
	  (#t #f)))
  (process-forms file process-form))

(define (process-forms file func)
  (call-with-input-file (string-append lib-dir "/" file )
    (lambda (in)
      (invoke in 'setReadEval #\W)
      (let loop ((form (read in)))
	(unless (eof-object? (%or-null (func form)))
		(loop (read in)))))))
		
(define *autoload-table* '())

(define (autoload-definer)
  (set! *autoload-table* '())
  ;; grovel through files
  (for-each (lambda (file)
	      (print file)
	      (load-resource (string-append "lib/" file))
	      (for-defines file 
			   (lambda (type name file)
			     (when (procedure? (eval name))
				   (print name)
				   (push (list name file) *autoload-table*)))))
	    (lib-files))
  *autoload-table*)

;(print (autoload-definer))

;;; autoload from class files

(define (make-java-library lib)
  (let ((source-file (string-append lib-dir "/" lib ".java")))
  (call-with-output-file source-file
    (lambda (out)
      (define (ndisplay thing)
	(newline out)
	(display thing out))
      ;;; heading
      (display "package com.ibm.jikes.skij.lib;" out)
      (ndisplay "class ")
      (display lib out)
      (display " extends SchemeLibrary {" out)
      (ndisplay "  static {")
      ;;; meat
      (process-forms 
       (string-append lib ".scm")
       (lambda (form)
	 (if (eof-object? form) form
	     (begin
	       (ndisplay "    evalStringSafe(\"")
	       (write-form-in-java form out)
	       (display "\");" out)))))
      ;;; closing
      (ndisplay "  }")
      (ndisplay "}")
      ))
  (shell (string-append "jikes "
			(string-replace source-file #\/ #\\)))))
  

(require 'write)
(set! *print-string-escapes* #t)

;;; this would be better written as transforming ports...
(define (write-form-in-java form out)
  (let* ((basic-string
	  (with-string-output-port 
	   (lambda (temp-out)
	     (write form temp-out))))
	 (transformed-string
	  (transform-string basic-string
			    `((#\\ "\\\\")
			      (#\" "\\\"")
			      (,eol-character "\\\\\\\\n"))))) ;has to be doubly quoted
    (display transformed-string out)))


(define (trim-extension name-ext)
  (substring name-ext 0 (invoke name-ext 'indexOf (char->int #\.))))

;;; +++ there is still a bug: write's char clause is missing a backslash (2 when quoted)
(define (make-java-libraries)
  (for-each (lambda (x)
	      (ignore-errors-and-warn 
	       (print x)
	       (make-java-library (trim-extension x))))
	    (cons "init.scm" (lib-files))))

;;; transforms are (char string)
(define (transform-string string transforms)
  (with-string-output-port 
   (lambda (out)
     (with-input-from-string
      string
      (lambda (in)
	(let loop ((char (read-char in)))
	  (unless (eof-object? char)
	    (define xform (assoc char transforms))
	    (if xform
		(display (cadr xform) out)
		(write-char char out))
	    (loop (read-char in)))))))))
