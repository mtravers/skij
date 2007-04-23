; interface to XML4J

; cleaned up version of scm/xml.scm Thu Feb 04 14:58:52 1999

(define (parse-xml-url url)
  (unless (instanceof url 'java.net.URL)
	  (set! url (new 'java.net.URL (string url))))
  (parse-xml-stream (invoke url 'openStream)
		    (string url)))
  

(define (parse-xml-file file)
  (parse-xml-stream (new 'java.io.FileInputStream file)
		    file))

(define (write-xml-file xml file)
  (call-with-output-file file
    (lambda (port)
      (invoke xml 'toXMLString (peek port 'writer)))))

(define (xml-string xml)
  (with-string-output-port
   (lambda (port)
     (invoke xml 'toXMLString (peek port 'writer)))))

(define (parse-xml-stream stream name)
  (define parser (new 'com.ibm.xml.parser.Parser name))
  (define doc (invoke parser 'readStream stream))
  (invoke stream 'close)
  doc)

(define (element-children elt)
  (if (instanceof elt 'com.ibm.xml.parser.Parent)
      (vector->list (invoke elt 'getChildrenArray))
      '()))

(define (display-document doc . options)
  (key options ignore-whitespace? #t)
  (define tree
    (generate-tree doc
		   (if ignore-whitespace?
		       (lambda (parent) 
			 (filter-out (lambda (child)
				       (and (instanceof child 'com.ibm.xml.parser.TXText)
					    (invoke child 'getIsIgnorableWhitespace)))
				     (element-children parent)))
		       element-children)
		   (lambda (x)
		     (make-adaptor (xml-short-string x) x)))) 
  (define win (make-tree-window (invoke doc 'toString) tree))
  (tree-add-mouse-listener
   win
   (lambda (node evt)
     (if (> (invoke evt 'getClickCount) 1)
	 (inspect (peek (invoke node 'getUserObject) 'object))))))


;;; output the opening tag only. How many objects do we have to create for this?
(define (xml-short-string elt)
  (cond ((instanceof elt 'com.ibm.xml.parser.TXDocument)
	 "<DOCUMENT>")
	((instanceof elt 'com.ibm.xml.parser.TXElement)
	 (xml-tag-string elt))
	(else
	 (xml-string elt))))


(define (xml-tag-string elt)
  (with-string-output-port
   (lambda (out)
     (let* ((writer (peek out 'writer))
	    (visitor (new 'com.ibm.xml.parser.ToXMLStringVisitor writer (%null))))
       (invoke visitor 'visitElementPre elt)))))

(define (for-all-elements func start)
  (func start)
  (for-each (lambda (elt) (for-all-elements func elt))
	    (element-children start)))

;;; finds terminal text elements that contain a given string (why is this so slow?) 
(define (find-elements string start)
  (define result '())
  (for-all-elements (lambda (elt)
		      (if (and (instanceof elt 'com.ibm.xml.parser.TextElement)
			       (>= (invoke (invoke elt 'getText) 'indexOf string) 0))
			   (push elt result)))
		    start)
  result)

(define (get-attribute xml att-name)
  (let ((raw (invoke xml 'getAttribute (string att-name))))
    (cond ((%%null? raw) #f)
	  ((equal? raw "") #f)
	  (else raw))))


(define (make-xml-doc root child-generator element-generator)
  (define doc (new 'com.ibm.xml.parser.TXDocument))
  (define (doit node)
    (define elt (element-generator node))
    (for-each (lambda (child)
		(invoke elt 'addElement (doit child)))
	      (child-generator node))
    elt)
  (invoke doc 'addElement (doit root))
  doc)


;;; XML in Lisp notation (ex. from DCD document)
'(dcd
  ((ElementDef Type "DL" Model "Elements" Content "Closed")
   (Description
    "A simple 'definition list' construct...")
   ((Group Occurs "OneOrMore" RDF:Order "Seq")
    (Element "DT")
    ((Group Occurs "Optional")
     (Element "DD"))))
  )

(define (xml->list xml)
  (cond ((instanceof xml 'com.ibm.xml.parser.TXText)
	 (reduce-whitespace (invoke xml 'getText))) ;+++ optional
	((instanceof xml 'com.ibm.xml.parser.TXComment)
	 (list 'comment (invoke xml 'getNodeValue)))
	((instanceof xml 'com.ibm.xml.parser.TXDocument)
	 (cons 'xml 
	       (map xml->list (vector->list (invoke xml 'getChildrenArray)))))
	((instanceof xml 'com.ibm.xml.parser.TXElement)
	 (let ((tag (intern (invoke xml 'getTagName)))
	       (attributes (vector->list (invoke xml 'getAttributeArray))))
	   (cons (if (null? attributes)
		     tag
		     (cons tag (xml-attributes->list attributes)))
		 (remove-empties	;+++ optional
		  (map-vector xml->list (invoke xml 'getChildrenArray))))))
	(#t
	 (print `(unknown xml item ,xml))
	 xml)))

;;; not working; addElement gets error
(define (list->xml xlist)
  (cond ((string? xlist)
	 (new 'com.ibm.xml.parser.TXText xlist))
	((eq? (car xlist) 'comment)	;+++ not sure of this clause
	 (new 'com.ibm.xml.parser.TXComment (cadr xlist)))
	(#t
	 (let* ((tag (if (pair? (car xlist)) (caar xlist) (car xlist)))
		(attributes (if (pair? (car xlist)) (cdr (car xlist)) '()))
		(elt (new 'com.ibm.xml.parser.TXElement (string tag))))
	   (do ((rest attributes (cddr rest)))
	       ((null? rest))
	     (invoke elt 'setAttribute (string (car rest)) (string (cadr rest))))
	   (for-each (lambda (subelt)
		       (invoke elt 'appendChild (list->xml subelt)))
		     (cdr xlist))
	   elt))))

(define (xml-attributes->list att-list)
  (if (null? att-list)
      '()
      (cons (intern (invoke (car att-list) 'getName))
	    (cons (invoke (car att-list) 'getValue)
		  (xml-attributes->list (cdr att-list))))))
  
(define (whitespace? string)
  (equal? "" (reduce-whitespace string)))

(define (reduce-whitespace string)
  (invoke string 'trim))
  
(define (remove-empties list)
  (cond ((null? list) list)
	((equal? (car list) "")
	 (remove-empties (cdr list)))
	(#t (cons (car list)
		  (remove-empties (cdr list))))))
	
;;; some DTD hacking  

; note, this is just like parse-xml-file, except readDTDStream is called instead of readStream. Perhaps these should be consolidated (and combined with URL versions)
(define (parse-dtd-file file)
  (define is (new 'java.io.FileInputStream file))
  (define parser (new 'com.ibm.xml.parser.Parser file))
  (define doc (invoke parser 'readDTDStream is))
  (invoke is 'close)
  doc)

;(parse-dtd-file "d:/XML/limon/limon.dtd")

; +++ couls be smarter about text
(define (insert-whitespace xml)
  (define (whitespace-string n)		;+++ stupid in several respects
    (substring "\n                                               " 0 (+ (* 2 n) 1)))
  (define (insert1 parent n)
    (let ((children (element-children parent)))
      (for-each (lambda (child)
		  (insert1 child (+ n 1))
		  (invoke parent 'insertBefore 
			  (new 'com.ibm.xml.parser.TXText (whitespace-string n))
			  child))
		children)
      (unless (null? children)
	      (invoke parent 'insertAfter
		      (new 'com.ibm.xml.parser.TXText (whitespace-string (- n 1)))
		      (last (element-children parent))))))
  (insert1 xml 1))
