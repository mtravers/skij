(require-resource 'scm/web/html-gen.scm)

(require 'server)

(define timeout (* 15 1000))		;15 second timeout on methods etc.

;;; Server

(define server-site (catch (local-host)))

(define start-time-string #f)

(define (start-webspect-service port)
  (start-http-service 
   port
   (lambda (out command url headers *socket*)
     (define *client-site* (invoke *socket* 'getInetAddress))
     (log-event `(request received: ,*client-site* ,url))
     (let ((*html-output* (lambda (thing) (display thing out)))
	   (*html-port* out))
       (define result
	 (catch
	  (process-url url)))
       (if (instanceof result 'java.lang.Throwable)
	   (output-error result #f))
       (close-output-port out))))
  (set! start-time-string (now-string))
  (set! unique-id (string-append (invoke (local-host) 'getHostName)
				 (string (integer (/ (now) 100000)))))
  (precompute-classpath-info)
  (log-event `(webspect server started)))

(define (precompute-classpath-info)
  (in-own-thread
   (log-event '(precomputing classpath info))
   (for-each (lambda (classpath-entry)
	       (ignore-errors-and-warn
		(log-event `(precomputing classpath entry ,classpath-entry))
		(classpath-entry-hierarchy classpath-entry))) ;this is memoized
	     (classpath))
   (log-event '(finished precomputing classpath info))))

(define (test-url url)
  (let ((*html-output* display)
	(*client-site* (catch (local-host))))
    (process-url url)))

(define (process-url url)
  (define ufields (cdr (parse-substrings url 47))) ;/
  (define pfields (parse-substrings (last ufields) 63)) ;?
  (cond ((equal? ufields '("robots.txt"))
	 ;;; blank robots.txt should allow robots in..
	 )
	((equal? "webspect" (car ufields))
	 (define bcommand (intern (car pfields))) ;+++ bad strings become permanent garbage.
	 (define params (if (null? (cdr pfields)) '() (parse-params (cadr pfields))))
	 (process-command bcommand params))
	(#t (error (string-append "Unknown URL " url)))))

(define *command-table* (make-hashtable))

(defmacro (define-command name args . body)
  `(hashtable-put *command-table* ',name
		  (lambda (params)
		    (define *command* ',name)
		    ,@(map (lambda (param)
			     `(pull-parameter params ,param))
			   args)
		    ,@body)))

(define (process-command command params)
  (log-event `(command ,command ,params))
  (aif (hashtable-get *command-table* command #f)
       (it params)
       (error (string-append "WebSpect: unknown command " command))))

; parse "class=foo&blither=blather"
(define (parse-params params)
  (define terms (parse-substrings params 38))
  (map (lambda (term)
	 (define param (parse-substrings term 61))	;=
	 (list (intern (car param)) (%decode (cadr param))))
       terms))

;;; Object management

(define *object-vector* (new 'java.util.Vector))

(define-memoized (object-code object)
  (invoke *object-vector* 'addElement object)
  (- (invoke *object-vector* 'size) 1))

(define (code-object code)
  (if (string? code)
      (set! code (invoke-static 'java.lang.Integer 'valueOf code)))
  (if (>= code (invoke *object-vector* 'size))
      (error (string-append "Reference to unknown object #" (string code)))
      (invoke *object-vector* 'elementAt code)))

(define (known-objects type)
  (define result '())
  (for-hashtable (lambda (obj code)
		   (if (instanceof obj type)
		       (push obj result)))
		 (object-code ':hashtable))
  result)

(define *history* '())

(define (register-history object)
  (set! *history*
	(cons object
	      (if (memq object *history*)
		  (delete object *history*)
		  *history*))))

;;; Name management

;;; could do this as regular bindings, but that's problematic (what if user
;;; overwrites a primitive function)?

(define *name-table* (make-hashtable))
(define *inverse-name-table* (make-hashtable))

(define (define-name name object)
  (hashtable-put *name-table* name object)
  (hashtable-put *inverse-name-table* object name))
	    
;(define-name 'empty-string-vector (list->string-vector '()))

(define *hidden-name-table* (make-hashtable))

(define (define-name-hidden name object)
  (hashtable-put *hidden-name-table* name object))

;;; Output utilities

(define (abbreviate-class-name class relative-to use-java.lang?)
  (if (invoke class 'isArray)
      (string-append (abbreviate-class-name (invoke class 'getComponentType) relative-to use-java.lang?) "[]")
      (begin
	(define name (invoke class 'getName))
	(define parts (parse-substrings name 46))
	(cond ((and use-java.lang?
		    (equal? (car parts) 'java)
		    (equal? (cadr parts) 'lang)
		    (null? (cdddr parts)))
	       (last parts))
	      (relative-to
	       (define rparts (parse-substrings (invoke relative-to 'getName) 46))
	       (define package (butlast parts))
	       (define rpackage (butlast rparts))
	       (if (equal? package rpackage)
		   (last parts)
		   name))
	      (#t name)))))

(define (output-type type relative-to)
  (env small
       (with-object-link type
	 (html-output (abbreviate-class-name type relative-to #t)))))

(define (output-value thing)
  (cond ((or (instanceof thing 'java.lang.Number)
	     (instanceof thing 'java.lang.Boolean))
	 (html-output (string thing)))
	((instanceof thing 'java.lang.String)
	 (if (invoke thing 'startsWith "http://")
	     (with-link thing
	       (html-output thing))
	     (html-output thing)))
	((invoke (class-of thing) 'isArray)
	 (with-object-link thing (html-output "["))
	 (html-output " ")
	 (do ((i 0 (+ 1 i))
	      (len (min (vector-length thing) 5)))
	     ((= i len))
	   (unless (= i 0) (tag br))
	   (output-value (vector-ref thing i))
	   (html-output " "))
	 (if (> (vector-length thing) 5) (html-output "..."))
	 (with-object-link thing (html-output "]")))
	(#t
	 (with-object-link thing
	    (html-output (safe-string thing))))))

(define (safe-string object)
  (define result (catch (string object)))
  (if (instanceof result 'java.lang.Throwable)
      (string-append "[[[" (string result) "]]]")
      result))

(define unique-id #f)

(defmacro (with-object-link object . body)
  `(with-env 'a (list (list 'href (string-append 'inspect?object= (string (object-code ,object)) "&uid=" unique-id)))
	     (lambda () ,@body)))

(defmacro (with-link link . body)
  `(with-env 'a (list (list 'href ,link)) (lambda () ,@body)))

(define *last-error* #f)

;;; title IS evaluated
(defmacro (wsdoc title . body)
  (if (string? title)
      (set! title `(lambda () (html-output ',title))))
  `(env html
	(lenv head
	      (env title
		   (let ((output-value (lambda (obj) 
					 (html-output (string obj)))))
		     (,title))))
	(lenv (body (bgcolor "#F2EEB7"))
	      (env (font (face "Arial,Helvetica"))
		   (env i
			(html-output "You're talking to ")
			(env (a (href /webspect/home.html))
			     (html-output "WebSpect"))
			(html-output " on host ")
			(output-value server-site))
		   (tag hr)
		   (env h1 (,title))
		   (define body-result (catch
					,@body
					#f))
		   (if (instanceof body-result 'java.lang.Throwable)
		       (output-error body-result #t))
		   (output-doc-end)
		   ))))


(define (output-doc-end)
  (tag hr)
  (env i
       (env (a (href /webspect/home.html))
	    (html-output "WebSpect Home"))))


(require 'dynamic)

; +++ should have a code too...
(define (output-error exception in-doc?)
  (set! *last-error* exception)
  (define (body)
    (tag hr)
    (html-output (string exception)))
  (if in-doc?
      (begin 
	(lenv h1 "WebSpect Error")
	(body))
      (wsdoc "Error"
	     (body)))
  (log-event `(error ,(string exception))))

;;; The pages



(defmacro (pull-parameter params name)
  `(define ,name (aand (assoc ',name ,params)
		       (cadr it))))


(define-command class-spec ()
  (wsdoc "Create an object"
	 (html-output "Enter a fully qualified class name (ie, ")
	 (with-link "constructors?classname=java.util.GregorianCalendar"
		    (html-output 'java.util.GregorianCalendar))
	 (html-output "):")
       (lenv (form (action constructors) (size 40))
	     (ltag input (type submit) (name create) (value new))
	     (ltag input (type input) (name classname) (size 30))
	     ;this covers a bug in Netscape: a URL that ends in "URL" gets stomped on!
	     (ltag input (type hidden) (name x) (value y))) 
       (html-output "or ")
       (with-link 'classpath
		  (html-output "browse available classes"))
       (html-output ".")
       ))


(define-command constructors (class classname)
  (if classname
      (set! class (class-named classname))
      (set! class (code-object class)))
  (wsdoc (lambda ()
	   (html-output "Create an instance of ")
	   ((dynamic output-value) class))
       (define constructors (vector->list (invoke class 'getConstructors)))
       (if (null? constructors)
	   (html-output "Sorry, there are no public constructors for this class.")
	   (for-each 
	    (lambda (constructor)
	      (output-method-form constructor #f class))
	    constructors))))

(define-command create (class)

  (set! class (code-object class))

  (define arguments (decode-parameters params))
  ;apply is broken  
  (define object (with-timeout timeout	;+++ better error handling
			       (apply new (print (cons (invoke class 'getName) arguments)))))


  (wsdoc (lambda ()
	   (lenv h3
		 (html-output "Here's your new instance of ")
		 (output-value class)))
	 
	 (output-standard-buttons object)

	 (tag hr)
	 ;; the meat
	 (register-history object)
	 (output-inspect-table object)
	 ))
       


;;; Name and Invoke buttons
(define (output-standard-buttons object)
  (html-output "\n")
  (html-output "You are inspecting ")
  (env b (html-output (string object)))
  (html-output ", an instance of ")
  (output-value (invoke object 'getClass))
  (html-output ".  ")
  (when (vector? object)
	(html-output " This array contains ")
	(output-numerical (vector-length object) "element")
	(html-output " of type ")
	(let ((elt-class (invoke (invoke object 'getClass) 'getComponentType)))
	  (with-object-link elt-class
			    (html-output (abbreviate-class-name elt-class #f #f))))
	(html-output "."))
  (ltag p)


  (with-link (string-append "invoke-page?object=" (object-code object))
	     (html-output "Invoke methods"))
  (html-output " on this object.")
  (html-output "\n")
  (aif (hashtable-get *inverse-name-table* object #f)
       (env p
	    (html-output "This object has been named ")
	    (env i (html-output it))
	    (html-output "."))
       (with-env 'form '((action name))
		 (lambda ()
		   (html-output "Give this object a name:  ")
		   (output-start-tag 'input `((type hidden)
					      (name object)
					      (value ,(object-code object))))
		   (output-start-tag 'input '((type input) ;+++ shorten
					      (name name)))
		   (output-start-tag 'input '((type submit)
					      (value Name))))))
  )


(define (output-numerical n unit-string)
  (html-output (string n))
  (html-output " ")
  (html-output unit-string)
  (unless (= n 1)			;+++ could use a smarter pluralized
	  (html-output "s")))

(define-command inspect (object)
; could check uid, but control flow is a pain
  (set! object (code-object object))

  (wsdoc (lambda ()
	   (html-output (string-append "Inspecting "
				       (string object))))



	 ;; buttons
	 (tag hr)
	 (output-standard-buttons object)

  ;;; Special case stuff
	 (if (instanceof object 'java.lang.Class)
	     (output-class-inspect object))
	 (if (instanceof object 'com.ibm.jikes.skij.CompoundProcedure)
	     (output-procedure-inspect object))
	 

	 (tag hr)
	 ;; the meat
	 (register-history object)
	 (output-inspect-table object)
	 ))

(define (output-class-inspect object)
  (with-link (string-append "constructors?class=" (object-code object))
	     (html-output "Create an instance"))
  (html-output " of this class.")
  (tag p)
  (with-link (string-append "static-methods?class=" (object-code object))
	     (html-output "Invoke static methods"))
  (html-output " for this class.")
  (tag p)
  (html-output "Browse ")
  (with-link (string-append "instances?class=" (object-code object))
	     (html-output "known instances"))
  (html-output " of this class.")
  (ltag p)
  (html-output "Superclasses:")
  (env ul
  (let loopx ((class object) (contents-proc #f))
    (aif class
	 (loopx (%or-null (invoke class 'getSuperclass) #f)
		(lambda () 
		  (env (li (type circle)) (output-value class))
		  (if contents-proc
		      (lenv ul
			    (contents-proc)))))
	 (contents-proc)))))

(define (output-procedure-inspect object) 
  (html-output "Browse the ")
  (with-link (string-append 'skijproc?obj= (string (object-code object)))
	     (html-output "source code"))
  (html-output " for this procedure."))


;;; For Skij/Webspect joint use:
;;; analagous to inspect
(define (webspect obj)
  (browse-url (string-append "http://"
			     (invoke (local-host) 'getHostAddress) 
			     ":"
			     "2341"
			     "/webspect/inspect?object="
			     (string (object-code obj)))))
			     


;;; bound to last object displayed (as in inspected)
(define webspected #f)

(define (output-inspect-table object)
  (define data (inspect-data object))
  (if (null? (cdr data))
      (env b (html-output "Sorry, there is nothing to display."))
      (output-inspect-fields (cdr data) (car data)))
  (set! webspected object))


(define (output-inspect-fields fields headers)
  (lenv table
	(lenv thead
	      (lenv tr
		    (env (th (align left)) (html-output (car headers)))
		    (env (th (align left)) (html-output (cadr headers)))))
	(lenv tbody
	(for-each 
	 (lambda (field)
	   (lenv tr
		 (env td
		      (html-output (car field)))
		 (env td
		      (output-annotated-value (%or-null (cadr field) "null")))))
	 fields))))


;;; fold this into output-value, which already does a lot for vectors
(define (output-annotated-value thing)
  (output-value thing)
  (cond ((vector? thing)
	 (define length (vector-length thing))
	 (html-output " (")
	 (html-output (string length))
	 (html-output "&nbsp;element")
	 (unless (= length 1)
		 (html-output "s"))
	 (html-output ")"))))
	
;;; Page utilities

(define numeric-primitive-classes
  (list (peek-static 'java.lang.Byte 'TYPE)
	(peek-static 'java.lang.Short 'TYPE)
	(peek-static 'java.lang.Integer 'TYPE)
	(peek-static 'java.lang.Long 'TYPE)
	(peek-static 'java.lang.Float 'TYPE)
	(peek-static 'java.lang.Double 'TYPE)))

(define (member-static? member)
  (invoke-static 'java.lang.reflect.Modifier 'isStatic
		 (invoke member 'getModifiers)))

; method or constructor
(define (output-method-form method object class)
  (define html-output (dynamic *html-output*)) ;save a few dynamic lookups
  (define constructor? (instanceof method 'java.lang.reflect.Constructor))
  (define static? (member-static? method))
  (define args (vector->list (invoke method 'getParameterTypes)))  
  (ltag hr)

  (with-env
   'form (list (list 'action (if constructor? 
				 'create
				 (if static? 'invoke-static 'invoke))))
   (lambda ()
     (output-start-tag 'input (list '(type hidden) (list 'name (if constructor? 'class 'object)) (list 'value (object-code (if constructor? class object)))))
     (html-output "  ")

     (lenv (table (align bleedright))
	   (lenv tr			;first row
		 (if constructor?
		     (begin
		       (env td
			    (output-start-tag 'input '((type submit) (name create) (value new))))
		       (env td
			    (html-output (invoke class 'getName))
			    (html-output "&nbsp;(")))
		     (begin		;regular method
		       (env (td	(align center))
			    (env i (html-output 'result))
			    )
		       (env td		;button
			    (output-start-tag 'input (list '(type submit) '(name method) (list 'value (invoke method 'getName))))
			    (html-output "&nbsp;("))))
		 (define i 0)			;input cells
		 (for-each 
		  (lambda (param-type)
		    (lenv (td (align center))
			  (output-param-specifier param-type i)
			  
			  (html-output "&nbsp;")
			  (set! i (+ i 1))
			  (when (not (= i (length args)))
				(html-output ",&nbsp;"))))
		  args)
		 (env td
		      (html-output "&nbsp;);"))
		 (env td
		      (if (equal? "java" (substring (invoke (invoke method 'getDeclaringClass) 'getName) 0 4))
			  (env i
			       (with-env 'a `((href ,(method-doc-url method))
					      (target "doc"))
					 (lambda () (html-output "Documentation"))))
			  )))
	   (lenv tr			;second row; types
		 (if constructor?
		     (env td)
		     (env (td (align center))		;return type
			  (output-type (invoke method 'getReturnType) class)))
		 (env td)		;blank
		 (define i 0)
		 (for-each 
		  (lambda (param-type)
		    (lenv (td (align center))
			  (output-type param-type class))
		    (set! i (+ i 1)))
		  args)
		 (env td)
		 (env td
		      (if (not (eq? (invoke method 'getDeclaringClass)
				      class))
			    (env i 
			    (html-output "Inherited from ") 
			    (output-type (invoke method 'getDeclaringClass) class))))
		 )

	   
	   )
     ))
)


;; for java package only. I suppose we might want a table for other packages.
;;; +++ should compute url based on JDK version.
(define doc-url "http://java.sun.com/products/jdk/1.1/docs/api/")

; works in Netscape, does not go to proper place in document in Explorer
; use version in browser.scm
(require-resource 'scm/browser.scm)
'(define (method-doc-url method param-types)
  (unless param-types
	  (set! param-types (vector->list (invoke method 'getParameterTypes))))
  (define buf (new 'java.lang.StringBuffer))
  (define constructor? (instanceof method 'java.lang.reflect.Constructor))
  (define (app string) (invoke buf 'append string))
; you'd think this would help, but it doesn't, and it breaks Netscape
;  (define (%app string) (invoke buf 'append (%encode string)))
  (define %app app)
  (app doc-url)
  (app (invoke (invoke method 'getDeclaringClass) 'getName))
  (app ".html#")
  (if constructor?
      (app (last (parse-substrings (invoke method 'getName) (char->int #\.))))
      (app (invoke method 'getName)))
  (%app "(")
  (define nparams (length param-types))
  (for-each (lambda (param)
	      (%app (abbreviate-class-name param #f #f))
	      (set! nparams (- nparams 1))
	      (if (not (= nparams 0))
		  (%app ", ")))
	    param-types)
  (%app ")")
  (invoke buf 'toString))

(define-command name (name object)
  (set! object (code-object object))
  (define-name name object)
  (wsdoc "Object Named"
	 (html-output "The object ")
	 (output-value object)
	 (html-output " has been given the name \"")
	 (html-output name)
	 (html-output "\".")

       (output-standard-buttons object)

       (tag hr)
       ;; the meat
       (register-history object)
       (output-inspect-table object)

       ))

(define-command invoke-page (object)
  (set! object (code-object object))
  (method-page object #f))

(define-command invoke-named (object method-name)
  (set! object (code-object object))
  (method-page object method-name))

(define (method-page object method-name)
  (wsdoc (lambda ()
	   (html-output "Invoke a method on ")
	   (output-value object))
	 (html-output "Each section below represents a method that can be invoked on ")
	 (output-value object)
	 (html-output ". Fill in the blanks as necessary, and press the button.  Numbers, strings, and booleans can be typed as literals. To specify other types of object, you must either select an object from the menu or type in the <i>name</i> of a suitable object. <p>Only instance methods are listed here; inspect ")
	 (define class (invoke object 'getClass))
	 (output-value class)
	 (html-output " for class (static) methods. Only public methods are listed; this is a limitation of the Java Reflection API.")
	 
	 (ltag p)
	 (if method-name
	     (begin
	       (html-output "This page only shows methods named ")
	       (env b (html-output method-name))
	       (html-output ". Here's the ")
	       (with-link (string-append "invoke-page?object="
					 (string (object-code object)))
			  (html-output "full list"))
	       (html-output "."))
						    

	   (begin
	    (html-output "If you know the name of the method you want to invoke and don't want to wait for this page to load, enter it here and press the button: ")
	    (env (form (action invoke-named))
		 (output-start-tag 'input `((type hidden) (name object) (value ,(object-code object))))
		 (tag input (type submit) (value "Methods named"))
		 (tag input (type input) (name method-name) (size 20)))))


	 (define methods (filter-out member-static? ;part of inspect
				     (vector->list (invoke class 'getMethods))))

	 (when method-name
	       (set! methods (filter (lambda (m)
				       (equal? (invoke m 'getName) method-name))
				     methods)))

	 (if (null? methods)
	     (begin 
	       (ltag hr) (env b (html-output "No methods found.")))
	     (for-each 
	      (lambda (method)
		(output-method-form method object class))
	      (sort methods (lambda (a b) 
			      (string<? (invoke a 'getName) (invoke b 'getName))))))))

;;; takes parameters from URL, returns list of arguments to pass to invoke or create
(define (decode-parameters parameters)
  (define arguments '())
  (for-each (lambda (p)
	      (define name (symbol->string (car p)))
	      (if (equal? (string-ref name 0) (int->char 112)) ;p
		  (push (list (read-from-string ;arg #
			       (substring name 2 (string-length name)))
			      (string-ref name 1) ;type code
			      (cadr p))
			arguments)))
	    parameters)
  (map (lambda (argspec)		;see param-type-codes)
	 (case (cadr argspec)
	   ((#\s) (caddr argspec))	;string
	   ((#\o)			;object name
	    (or (hashtable-get *name-table* (caddr argspec) #f)
		(hashtable-get *hidden-name-table* (caddr argspec) #f)
		(error (string-append "Unknown name " (caddr argspec)))))
	   ((#\b) (byte (read-from-string (caddr argspec))))
	   ((#\h) (short (read-from-string (caddr argspec))))
	   ((#\i) (integer (read-from-string (caddr argspec))))
	   ((#\l) (long (read-from-string (caddr argspec))))
	   ((#\f) (float (read-from-string (caddr argspec))))
	   ((#\d) (double (read-from-string (caddr argspec))))
	   (else
	    (error (string-append "Unknown param spec: " (string argspec))))))
       (sort arguments (lambda (a b) (< (car a) (car b))))))

(define-command invoke-static (object method)
  (set! object (code-object object))
  (define arguments (decode-parameters params))	;+++ ouch!
  (define result (no-bypassing-security
		  (with-timeout timeout
				(%or-null (apply invoke-static object method arguments)
					  ':null)))) ;+++ experiment with new null handling
  (output-invoke-results object method arguments result #t))

(define-command invoke (object method)
  (set! object (code-object object))
  (define arguments (decode-parameters params))	;+++ ouch!
  (define result (no-bypassing-security
		  (with-timeout timeout
				(%or-null (apply invoke object method arguments)
					  ':null)))) ;+++ experiment with new null handling
  (output-invoke-results object method arguments result #f))

(define (output-invoke-results object method arguments result static?)
  (wsdoc "Invoke results"
    (env form
	 (if static?
	     (with-object-link object
			       (html-output (invoke object 'getName)))
	     (output-value object))
	 (env b (html-output "&nbsp.&nbsp"))
	 (output-start-tag 'input `((type button) (value ,method)))

	 (html-output "&nbsp(")
	 (define l (length arguments))
	 (for-each (lambda (arg)
		     (output-value arg)
		     (set! l (- l 1))
		     (if (not (= l 0))
			 (html-output ", ")))
		   arguments)
	 (html-output "); ")		      
	 
	 (html-output "\ncompleted successfully.")
	 (if (eq? result ':null)
	     (html-output " No value was returned.")
	     (begin
	       (tag p)
	       (html-output " The returned value was ")
	       (output-value result)
	       (html-output " (a ")	;+++ sometimes should be AN
	       (output-type (class-of result) #f)
	       (html-output ").")
	       (tag hr)
	       (register-history result)
	       (output-inspect-table result)
	       )))))

;;; More pages

(define-command inventory ()
  (wsdoc "Inventory"
	 (env h1
	      "Object Inventory")
	 (output-inspect-table
	  (map car (hashtable-contents (object-code ':hashtable))))))

(define-command history ()
  (wsdoc "History"
	 (env h1
	      "History")
	 (output-inspect-table
	  *history*)))

(define-command properties ()
    (wsdoc "System Properties"
	  (output-inspect-fields
	   (cdr (inspect-data (invoke-static 'java.lang.System 'getProperties)))
	   '(Name Value))))

(define-command named-objects ()
  (wsdoc "Named Objects"
	 (output-inspect-fields
	  (cdr (inspect-data *name-table*))
	  '(Name Object))))

;;; Static pages
;;; this reads a file into a string. The idea is to load static pages into memory
;;; before turning off file access.
(require 'files)

(defmacro (define-static-page name file)
  `(define-command ,name ()
     (html-output
      ',(with-string-output-port 
	 (lambda (out)
	   (with-input-file 
	    file
	    (lambda (in)
	      (copy-until-eof in out))))))))
			    
;;; Obsolete more or less

;;; Class stuff (obsolete? or revive it?)

(define (output-class class)
  (env html
       (lenv head
	    (lenv title
		 (html-output "Class ")
		 (html-output (invoke class 'getName))))
       (lenv body
	    (lenv h1
		 (html-output "Class ")
		 (html-output (invoke class 'getName)))
	    ; picture of tree can go here
	    (tag hr)
	    (lenv dl
		 (lenv dt
		      ; class properties
		      (html-output " class ")
		      (env b (html-output (invoke class 'getName))))
		 (define super (invoke class 'getSuperclass))
		 (when super
		       (lenv dt
			     (html-output " extends ")
			     (class-link super)))
		 (define interfaces (vector->list (invoke class 'getInterfaces)))
		 (when (not (null? interfaces))
		       (lenv dt
			     (html-output " implements ")
			     (for-each (lambda (interface)
					 (class-link interface)
					 (html-output " "))
				       interfaces))))
	    (tag p)
	    (define constructors (vector->list (invoke class 'getConstructors)))
	    (when constructors
		  (env h2 (html-output "Constructors"))
		  (lenv dl
			(for-each (lambda (constructor)
				    (lenv dt (html-output (string constructor))))
				  constructors)))
	    (define methods (vector->list (invoke class 'getMethods)))
	    (when methods
		  (env h2 (html-output "Methods"))
		  (lenv dl
			(for-each (lambda (method)
				    (lenv dt (output-method method)))
				  methods))))))

(define (output-method method)
  (define meth-string (string method))
  (define name-end (invoke meth-string 'lastIndexOf 40)) ;left paren
  (define name-start (+ 1 (invoke meth-string 'lastIndexOf 46 name-end))) ;dot
  (html-output (invoke meth-string 'substring 0 name-start))
  (env b
       (html-output (invoke meth-string 'substring name-start name-end)))
  (html-output (invoke meth-string 'substring name-end)))

(define (class-link class)
  (with-link (string-append 'class? (invoke class 'getName))
	     (html-output (invoke class 'getName))))

;;; Security!

(defmacro (bypassing-security . body)
  `(let ((manager (%or-null (invoke-static 'java.lang.System 'getSecurityManager) #f))
	 (proc (lambda () ,@body)))
     (if manager
	 (invoke manager 'bypassing proc (current-environment))
	 (proc))))


(defmacro (no-bypassing-security . body)
  `(let ((manager (%or-null (invoke-static 'java.lang.System 'getSecurityManager) #f))
	 (proc (lambda () ,@body)))
     (if manager
	(invoke manager 'noBypassing proc (current-environment))
	(proc))))

(define *secure* #f)

(define (install-security)
  (define manager (new 'com.ibm.jikes.skij.misc.SkijSecurityManager
		       (lambda args
			 (security args))))
  (log-event '(security installed))
  (invoke-static 'java.lang.System
	  'setSecurityManager
	  manager)
  (set! *secure* #t))

(define security-ignore '(checkAwtEventQueueAccess
			  checkAccess
			  checkAccept
			  checkPropertiesAccess
			  checkPropertyAccess
			  ))

(define (security args)
  (define type (car args))
  (cond ((memq type security-ignore) #t)
	    ;no filenames, but we need to pass mysterious FileDescriptor obs
	    ((memq type '(checkRead checkWrite)) 
	     (not (string? (cadr args))))
	    ; allow server connections, but no outgoing
	    ((eq? type 'checkConnect)
	     (= (caddr args) -1))
	    (#t
	     (log-event `(security check ,@args))
	     #f)))

(define-command secure ()
  (install-security)
  (wsdoc "Security has been turned on."
	 ))

(unless (bound? 'original-load-resource)
   (define original-load-resource load-resource)
   (set! load-resource
	 (lambda args
	   (bypassing-security
	    (apply original-load-resource args)))))

;;; Classpath inspection

(require-resource 'scm/classfiles.scm)

(define-command classpath ()
  (wsdoc "CLASSPATH"
	 (html-output "These are the entries in Java's CLASSPATH. Each is a directory or file that contains Java classes (except some might not really exist). Clicking the links will show all of the classes. <i>Warning:</i> if WebSpect has just been started, you might have to wait a while for the page to be computed.")
	 (ltag hr)
	 (for-each (lambda (entry)
		     (with-link (string-append "classpath-entry-hierarchical?filename=" (%encode entry))
				(html-output entry)
				(tag p)))
		   (classpath))))

(define-command classpath-entry (filename)
  (wsdoc (lambda ()
	   (html-output "Classes in ")
	   (html-output filename))
	 (define (collect entry)	;referenced dynamically
	   (lenv li
		 (with-link (string-append "constructors?classname=" (%encode entry))
			    (html-output entry))
		       ))
	 (bypassing-security			;this might lock things a long time...can we bypass just on the open of the zip file?
	  (for-classes collect filename))))

;;; new hierarchical scheme

;(top (mt (Invoke) (skij (PrimProcedure) (CompoundProc))) (java (lang )))
; this is quite inefficient, so we memoize and run it on all classpath items at startup.
; +++ the result is space-inefficient, every terminal class has an unnecessary list around it
(define-memoized (classpath-entry-hierarchy filename)
  (define tree '())
  (define (add partial-item partial-tree)
    (cond ((null? partial-item)
	   partial-tree)
	  ((null? partial-tree)
	   (if (null? (cdr partial-item))
	       (list (car partial-item))	       
	       (list (car partial-item)
		     (add (cdr partial-item) partial-tree))))
	  ((equal? (car partial-item)
		(car partial-tree))
	   (cons (car partial-item)
		 (add1 (cdr partial-item)
		       (cdr partial-tree))))
	  (#t partial-tree)))

  (define (add1 partial-item partial-tree-list)
    (cond ((null? partial-tree-list)
	   (list (add partial-item partial-tree-list)))
	  ((equal? (car partial-item)
		(caar partial-tree-list))
	   (cons (add partial-item
		      (car partial-tree-list))
		 (cdr partial-tree-list)))
	  (#t
	   (cons (car partial-tree-list)
		 (add1 partial-item
		       (cdr partial-tree-list))))))

  (define (collect entry)
    (set! tree (add1 (parse-substrings entry (char->int #\.)) tree)))

  (define (sort-tree tree)
    (cons (car tree)
	  (sort (map sort-tree (cdr tree))
		(lambda (x y) (string<? (car x) (car y))))))

  (bypassing-security
   (for-classes collect filename))
  (set! tree
	(sort-tree (cons 'top tree)))
  tree)

(define-command classpath-entry-hierarchical (filename)
  (wsdoc (lambda ()
	   (html-output "Classes in ")
	   (html-output filename))
	 (let ((tree (classpath-entry-hierarchy filename))) ;+++ security
	   (define (output-tree tree parentage)
	     (define classname (unparse-substrings (reverse (cons (car tree) parentage)) #\.))
	     (if (null? (cdr tree))
		 (lenv li
		       (with-link (string-append "constructors?classname=" (%encode classname))
				  (html-output classname)))
		 (begin
		   (lenv li
			 (html-output classname))
		   (env ul
			(for-each (lambda (subtree) (output-tree subtree (cons (car tree) parentage)))
				  (cdr tree))))))
	   (for-each (lambda (subtree)
		       (output-tree subtree '()))
		     (cdr tree)))))


(define (unparse-substrings substrings separator)
  (with-string-output-port 
   (lambda (out)
     (display (car substrings) out)
     (let loopx ((strings (cdr substrings)))
       (unless (null? strings)
	       (display separator out)
	       (display (car strings) out)
	       (loopx (cdr strings)))))))

;;; Logging

(define log-file 
  (new 'java.io.File
       (invoke-static 'java.lang.System 'getProperty "user.dir")
       "webspect-log.txt"))

(define log-buffer '())
(define log-stream #f)
(define log-port #f)

(define (open-log)
  (set! log-stream
	(new 'java.io.FileOutputStream (invoke log-file 'getPath) #t)) ;open for append
  (set! log-port (new 'com.ibm.jikes.skij.OutputPort log-stream)))

(define (checkpoint-log)
  (synchronized 
   'log-buffer
   (unless (null? log-buffer)
	   (bypassing-security
	    (open-log)
	    (for-each (lambda (item)
			(print item log-port))
		      (reverse log-buffer))
	    (set! log-buffer '()))
	   (invoke log-stream 'close))))

(define (log-event item)
  (define ditem (cons (now-string)
		      item))
  (print ditem)
  (synchronized log (push ditem log-buffer)))

(log-event '(started logging))

(in-own-thread 
 (let loop ()
   (sleep (* 1000 30))			;checkpoint log every 30 seconds
   (checkpoint-log)
   (loop)))

;;; encode/decode

(define (%encode string)
  (invoke-static 'java.net.URLEncoder 'encode string))

; +++ this is grossly slow now that it uses recursion...sigh
(define (%decode string)
  (define result (new 'java.lang.StringBuffer))
  (define inlength (string-length string))
  (define i 0)
  (define (read-char)
    (define char (string-ref string i))
    (set! i (+ i 1))
    char)
  (define (hex-value char)
    (define ichar (- (char->int char)  #,(char->integer #\0)))
    (if (> ichar 9)
	(set! ichar (+ ichar #,(+ 10 (- (char->integer #\0) (char->integer #\A))))))
    ichar)
  (define (output-char char)
    (invoke result 'append char))
  (let loop ()
    (unless (= i inlength)
	    (define char (read-char))
	    (cond ((equal? char #\+)
		   (output-char #\ ))
		  ((equal? char #\%)
		   (output-char (int->char (+ (* 16 (hex-value (read-char)))
					      (hex-value (read-char))))))
		  
		  (#t (output-char char)))
	    (loop)))
  (invoke result 'toString))

;;;; pop-ups

(define (eligible-objects type)
  (define result '())
  (for-enumeration (lambda (obj)
		     (if (invoke type 'isAssignableFrom (class-of obj))
			 (push obj result)))
		   (invoke *object-vector* 'elements))
  result)

(define param-type-codes
  `((,(class-named 'java.lang.String) #\s)
    (,(peek-static 'java.lang.Byte 'TYPE) #\b)
    (,(peek-static 'java.lang.Short 'TYPE) #\h)
    (,(peek-static 'java.lang.Integer 'TYPE) #\i)
    (,(peek-static 'java.lang.Long 'TYPE) #\l)
    (,(peek-static 'java.lang.Float 'TYPE) #\f)
    (,(peek-static 'java.lang.Double 'TYPE) #\d)))

(define (param-type-code type)
  (aif (assq type param-type-codes)
       (cadr it)
       #\o))

(define (output-param-specifier type number)
  (define eligibles #f)
  (define type-code (param-type-code type))
  (cond ((memq type '#,(list (class-named 'java.lang.Boolean)
			     (peek-static 'java.lang.Boolean 'TYPE)))
	 (output-start-tag 'input (list '(type checkbox)
					(list 'name (string-append 'p
								   (param-type-code type)
								   (string number))))))
	((or (not (equal? (param-type-code type) #\o))
	     (> (length (define eligibles (eligible-objects type))) 20))
	 (output-start-tag 'input (list '(type input)
					'(size 10)
					(list 'name (string-append 'p 
								   type-code
								   (string number))))))
	(#t
	 (with-env 'select `((name ,(string-append 'p 
						   type-code
						   (string number))))
		   
		   (lambda () 
		     (if (null? eligibles)
			 (begin
			   (ltag option)
			   (html-output "*** Nothing available ***"))
			 (for-each (lambda (eligible)
				     (define name (trim-string (string eligible) 50))
				     (ltag option)
				     (define-name-hidden name eligible)
				     (html-output name))
			       eligibles)))))))


			    
; for check boxes			  
(define-name-hidden "on" #t)
(define-name-hidden "off" #f)


(define-command home.html ()
  (define ho html-output)
  (define (static link text)
    (with-link link (html-output text)))

  (wsdoc 
   "WebSpect Home Page"
   (html-output "You are talking to a remote Java Virtual Machine that is running a WebSpect server. WebSpect lets you use your web browser to inspect, create, and manipulate the Java objects that live in this machine.")
   (env h3
	(ho "Some places to start:"))
   (tag p)
   (env center
     (env (table (cols 2) (width "93%"))
	  (define (entry prolog link link-text)
	    (env td
		 (env li
		      (env (font (face "Arial,Helvetica"))
			   (ho prolog)
			   (static link link-text)
			   (ho ".")))))
	    
	  (env tr
	       (entry "Create an instance of " "class-spec" "some class")
	       (entry "See " "properties" "system properties"))
	  (env tr
	       (entry "Browse classes in the Java " "classpath" "CLASSPATH")
	       (entry "View the " 'history " inspect history"))
	  (env tr
	       (entry "See all " "named-objects" "named objects")
	       (entry "Check out the " "message-board" "message board"))
	  (env tr
	       (entry "See all " "inventory" "known objects")
	       (entry "Browse the " 'skijguts "Skij namespace"))))
   (tag p)
   (env center
   (env (table (border 4) (cols 2) (width "80%"))
	(env tr
	     (lenv td
		  (env center
		       (env (font (face "Arial,Helvetica"))
			    (env big
				 (html-output "Running since ")
				 (tag br)
				 (html-output start-time-string)))))
	     (lenv td
		  (env center
		      (env (font (face "Arial,Helvetica"))
		       (if *secure*
			   (env big
				(html-output "Running in secure mode."))
			   (begin
			     (env big
				  (html-output "Running in ")
				  (env i (html-output 'insecure))
				  (html-output " mode. "))
			     (tag br)
			     (env (a (href secure))
				  (html-output "Click to turn on security"))
			     (html-output ". (irreversible)")))))))))
   (env h3
    (ho "What's going on?"))
   (ho "The server machine (")
   (output-value server-site)
   (ho ") is running a Java VM, which is running a ")
   (static "http://w3.watson.ibm.com/~mt/skij"
	   'Skij)

   (ho " interpreter, which is running the WebSpect server. Skij is a Scheme-like language which includes extensions to the standard Java Reflection API that enable interactive creation and manipulation of arbitrary Java objects. Webspect creates a web-based interface to this capability. <p>You can gain access to your own programs on your own Java VM by downloading and running either Skij alone or Skij plus WebSpect.  Skij is already packaged for download; to run Webspect please <a href=#author>contact the author</a>.")

   (env h3
	(ho "What's the point?"))

   (ho "You may have noticed that there has been revolution in computer interfaces that's been going on for a couple of decades now. Beginning with Doug Englebart's Augment work, and continuing on through the Xerox Star, Macintosh, and Windows, the thrust of this revolution has to make computational objects appear as graphic objects in the interface and allow users to perform operations on them through direct manipulation.")
   (tag p)

   (ho "Oddly, this revolution has largely bypassed one class of people who have a great need for it: programmers. Despite the obvious need for it, most programmers have very poor interactive access to the workings of their machines. The exceptions have been confined to programming environments based on dynamic languages like Smalltalk and Lisp, which make reflective tools easy to implement.")
   (tag p)

   (ho "Now comes Java, which has some but not all of the capacity for dynamic reflection found in Lisp or Smalltalk. Can tools be built that give Java more powerful reflective capabilities? It turns out that the answer is yes. Skij shows that the Java reflection API can be extended to allow fully dynamic method invocation. WebSpect builds on this by providing a graphic interface to this capability, albeit not an ideal one. More ways to access these capabilities are in the works.")
   (tag a (name "author"))
   (env h3
	(ho "Who is responsible?"))
   (ho "WebSpect and Skij are the creations of ")
   (static "http://w3.watson.ibm.com/~mt"
	   "Michael Travers")
   (ho " who works in the ")
   (static "http://w3.research.ibm.com/JavaTools/"
	   "Java Tools Group")
   (ho " at the ")
   (static "http://w3.watson.ibm.com"
	   "IBM T.J Watson Research Center")
   (ho ". Special thanks to Christopher Fry for feedback and encouragement.")))

(define-command static-methods (class)
  (set! class (code-object class))
  ; +++ intro text
  (wsdoc (lambda ()
	   (html-output "Invoke static methods of ")
	   (output-value class))
	 (define methods (filter member-static? ;part of inspect
				 (vector->list (invoke class 'getMethods))))
	 (for-each 
	  (lambda (method)
	    (output-method-form method class class))
	  (sort methods (lambda (a b) (string<? (invoke a 'getName) (invoke b 'getName)))))))

(define-command instances (class)
  (set! class (code-object class))
  ; +++ intro text
  (wsdoc (lambda ()
	   (html-output "Known instances of ")
	   (output-value class))
	 (output-inspect-table (eligible-objects class))))

;;; more features in these files
(require-resource 'scm/web/msg-board.scm)
(require-resource 'scm/web/skijout.scm)

(define-command skijguts ()
  (wsdoc "Skij Top-Level Defines"
	 (output-inspect-fields
	  (map (lambda (pair)
		 (cond ((eq? (car pair) '*object-vector*)
			(list (car pair) "[[[ unprintable ]]]"))
		       (#t
			(list (car pair) (cdr pair)))))
	       (invoke (global-environment) 'getLocalBindings))
	  '(Name Value))))


;;; some hairy class stuff (not yet used)

(define (known-classes)
  (define classes '())
  (for-hashtable (lambda (obj code)
		   (if (instanceof obj 'java.lang.Class)
		       (pushnew obj classes))
		   (pushnew (invoke obj 'getClass) classes))
		 (object-code ':hashtable))
  classes)


;;; trimmed names


(define (trim-string string max-length)
  (if (> (string-length string) max-length)
      (string-append (substring string 0 (- max-length 3)) "...")
      string))

(define (make-webspect-url command . params)
  (define buf (new 'java.lang.StringBuffer))
  (define (app str) (invoke buf 'append (string str)))
  (app "/webspect/")
  (app command)
  (for-each (lambda (p)
	      (if (eq? p (car params))
		  (app "?")
		  (app "&"))
	      (app (car p))
	      (app "=")
	      (app (%encode (string (cadr p)))))
	    params)
  (string buf))