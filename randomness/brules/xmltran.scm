;(require-resource 'scm/listlib.scm)
(require-resource 'brules/xmllib.scm)
    
;;; Utilities

(define (string-upcase string)
  (invoke string 'toUpperCase))

(define (string-downcase string)
  (invoke string 'toLowerCase))

(define (to-short-string object)
  (define string (to-string object))
  (define dot-pos (invoke string 'lastIndexOf (char->int #\.)))
  (if (positive? dot-pos)
      (string-replace-string string (substring string 0 (+ 1 dot-pos)) "")
      string))

(defmacro (%aif pred then . else)
  `(let ((it ,pred))
     (if (not (%%null? it))
	 ,then
	 ,@else)))

(define (jvector->list jvector)
  (if (%%null? jvector) '()
      (map-enumeration identity (invoke jvector 'elements))))

(define (for-jvector proc jvector)
  (unless (%%null? jvector) 
	  (for-enumeration proc (invoke jvector 'elements))))

;;; object -> XML system

; type lookup can deal with superclass inheritance but not interfaces

(define *xml-translators* (make-hashtable))

(defmacro (define-xml class-name . body)
  (let* ((class (class-named class-name)))	;+++ class loader built in
    `(setf (hashtable-get *xml-translators* ',class #f)
	   (lambda (this)
	     ,@body))))

(define (find-xml-handler object)
  (define (find-xml-handler1 class)
    (if (%%null? class) #f
	(or (hashtable-get *xml-translators* class #f)
	    (find-xml-handler1 (invoke class 'getSuperclass)))))
  (find-xml-handler1 (class-of object)))

(defmacro (elt head . body)
  (let ((dtag (if (list? head)
		  (car head)
		  head))
	(attributes (if (list? head) (cdr head) '())))
    `(let ((xml (make-elt ',dtag
			  (list ,@(map (lambda (attspec)
					 `(list ,(string (car attspec)) ,(cadr attspec)))
				      attributes)))))
				  
       (let ((*current-xml* xml))
	 ,@body)
       xml)))

(define (make-elt tag attributes)
  (let ((xml (new 'com.ibm.xml.parser.TXElement (string tag))))
    (for-each (lambda (attspec)
		(let ((name (car attspec))
		      (value (cadr attspec)))
		  (unless (eq? value #f) ;if value is #f, don't output
			  (if (eq? value #t) (set! value "yes"))
			  (invoke xml 'setAttribute (string name) value))))
	      attributes)

    xml))

(define (spit object)
  (spit-xml (obj->xml object)))

(define (spit-xml xml)
  (invoke (dynamic *current-xml*) 'appendChild xml)
  xml)
  
(define (spit-as tag object)
  (let ((xml (obj->xml object)))
    (invoke xml 'setTagName (string tag))
    (spit-xml xml)))

(define (spit-string thing)
  (spit-xml (new 'com.ibm.xml.parser.TXText (string thing))))

(define (obj->xml obj)
  (let ((handler (find-xml-handler obj)))
    (if handler
	(handler obj)
	(error `(no xml handler for ,obj)))))

;;; XML -> objects

; +++ this implementation is limited to a single DTD (conceptually)
; +++ could have a DTD vocabulary object to make it more general.
(define *xml-in-table* (make-hashtable))

(define (xml->obj xml)
  (xml->obj-as xml (intern (string-downcase (invoke xml 'getTagName)))))

(define (xml->obj-as xml type)
  (let ((entry (hashtable-get *xml-in-table* type #f)))
    (if entry
	(entry xml)
	(error `(cant handle tag ,type in ,xml)))))

(defmacro (define-xml-in tag . body)
  `(begin
     (setf (hashtable-get *xml-in-table* ',tag #f)
	   (lambda (this)
	     ,@body))
     ',tag))

; iterate over child tagged elements. Whitespace is ignored, other kinds of text give error
(define (for-xml-children proc xml)
  (for-vector 
   (lambda (child)
     (cond ((instanceof child 'com.ibm.xml.parser.TXElement)
	    (proc child))
	   ((instanceof child 'com.ibm.xml.parser.TXText)
	    (unless (xml-whitespace? child)
		    (error `(extraneous text in ,child))))
	   (else
	    (error `(weird child ,child of ,xml)))))
   (invoke xml 'getChildrenArray)))

(define (xml-whitespace? child)
  (let* ((str (xml-string child))
	 (len (string-length str)))
    (define (xml-whitespace1 i)
      (if (= i len) #t
	  (if (char-whitespace? (string-ref str i))
	      (xml-whitespace1 (+ i 1))
	      #f)))
    (xml-whitespace1 0)))

(define (find-child parent tag)
  (set! tag (string tag))
  (call-with-current-continuation 
   (lambda (return)
     (for-xml-children 
      (lambda (child)
	(if (equal? (invoke child 'getTagName) tag)
	    (return child)))
      parent)
     (return #f))))
   
	 

