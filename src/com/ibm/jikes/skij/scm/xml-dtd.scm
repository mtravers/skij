(require-resource 'scm/xml.scm)

(define (structure xml)
  (list (dcd-id xml)
	(filter identity
		(map-vector dcd-id (invoke xml 'getChildrenArray)))))

(define (dcd-id xml)
  (cond ((instanceof xml 'com.ibm.xml.parser.TXText)
	 (if (whitespace? (invoke xml 'getText))
	     #f '#,(intern "#PCDATA")))
	((instanceof xml 'com.ibm.xml.parser.TXComment)
	 #f)
	((instanceof xml 'com.ibm.xml.parser.TXElement)
	 (intern (invoke xml 'getTagName)))
	(#t `(unknown ,xml))))

(require-resource 'scm/listlib.scm)

(define (all-structure xml)
  (if (instanceof xml 'com.ibm.xml.parser.Parent)
      (cons (structure xml)
	    (append-map! all-structure
			 (element-children xml)))
      '()))

(define (select-structure struct type)
  (collecting
   (for-each (lambda (s) (if (eq? (car s) type) (collect s))) struct)))

;;; new
(define (ematch? pattern thing)
  (cond ((null? pattern) 
	 (null? thing))
	((list? (car pattern))
	 (let ((op (caar pattern))
	       (args (cdar pattern)))
	   (cond 
	    ((eq? op 'or)
	     (let loop ((choices args))
	       (and (not (null? choices))
		    (or (ematch? (append (car choices) (cdr pattern)) thing)
			(loop (cdr choices))))))
	    ((eq? op '+)
	     (ematch? `(,@args (* ,@args) ,@(cdr pattern)) thing))
	    ((eq? op '*)
	     (or (ematch? (cdr pattern) thing) ;no instances
		 (ematch? (append (list (car pattern)) args (cdr pattern)) thing)))
	    ((eq? op '?)
	     (or (ematch? (cdr pattern) thing)
		 (ematch? (append args (cdr pattern)) thing)))
	    (else (error `(unknown pattern ,pattern))))))
	((symbol? (car pattern))
	 (and (eq? (car pattern) (car thing))
	      (ematch? (cdr pattern) (cdr thing))))
	(else
	 (error `(unknown pattern ,pattern)))))


;;; damn, that's not right either
(define (ematch? pattern thing)
  (cond ((null? pattern) 
	 (null? thing))
	((list? (car pattern))
	 (let ((op (caar pattern))
	       (args (cdar pattern)))
	   (cond 
	    ((eq? op 'or)
	     (let loop ((choices args))
	       (and (not (null? choices))
		    (or (ematch? (append (car choices) (cdr pattern)) thing)
			(loop (cdr choices))))))
	    ((eq? op '+)
	     (ematch? `(,@args (* ,@args) ,@(cdr pattern)) thing))
	    ((eq? op '*)
	     (or (ematch? (cdr pattern) thing) ;no instances
		 (aand (ematch-partial? args pattern)
		       (ematch? pattern it))))
	    ((eq? op '?)
	     (or (ematch? (cdr pattern) thing)
		 (ematch? (append args (cdr pattern)) thing)))
	    (else (error `(unknown pattern ,pattern))))))
	((symbol? (car pattern))
	 (and (eq? (car pattern) (car thing))
	      (ematch? (cdr pattern) (cdr thing))))
	(else
	 (error `(unknown pattern ,pattern)))))

;;; match 
(define (ematch-partial? pattern thing)
  (cond ((null? pattern) 
	 (null? thing))
	((list? (car pattern))
	 (let ((op (caar pattern))
	       (args (cdar pattern)))
	   (cond 
	    ((eq? op 'or)
	     (let loop ((choices args))
	       (and (not (null? choices))
		    (or (ematch? (append (car choices) (cdr pattern)) thing)
			(loop (cdr choices))))))
	    ((eq? op '+)
	     (ematch? `(,@args (* ,@args) ,@(cdr pattern)) thing))
	    ((eq? op '*)
	     (or (ematch? (cdr pattern) thing) ;no instances
		 (aand (ematch-partial? args pattern)
		       (ematch? pattern it))))
	    ((eq? op '?)
	     (or (ematch? (cdr pattern) thing)
		 (ematch? (append args (cdr pattern)) thing)))
	    (else (error `(unknown pattern ,pattern))))))
	((symbol? (car pattern))
	 (and (eq? (car pattern) (car thing))
	      (ematch? (cdr pattern) (cdr thing))))
	(else
	 (error `(unknown pattern ,pattern)))))


(defstruct theory for current data)

(defmacro (pushnew-equal thing place)
  `(if (member ,thing ,place) #f
       (setf ,place (cons ,thing ,place))))

(define (induce-trivial theory new-data)
  (acond ((not (theory-current theory))	;no theory yet
	  (setf (theory-current theory) (compress-repititions new-data))
	  (pushnew-equal new-data (theory-data theory)))
	 ((ematch? (theory-current theory) new-data) ;matches current theory, no prob
	  (pushnew-equal new-data (theory-data theory)))
	 ((let ((new-theory (compress-repititions new-data))) ;no match, so..
	    (print `(theory ,(theory-current theory) for ,(theory-for theory) failed to match ,new-data))
	    (call-with-current-continuation
	     (lambda (exit)
	       (for-each (lambda (data)
			   (unless (ematch? new-theory data)
				   (print `(new theory ,new-theory failed to match ,data))
				   (exit #f)))
			 (theory-data theory))
	       new-theory)))
	  ;; new theory matches all data
	  (print `(updating theory for ,(theory-for theory) from ,(theory-current theory) to ,it))
	  (setf (theory-current theory) it)
	  (pushnew-equal new-data (theory-data theory))
	  #t)
	 (#t (print `(,new-data does not match theory ,(theory-current theory))))))


(define (induce-better theory new-data)
  (acond ((not (theory-current theory))	;no theory yet
	  (setf (theory-current theory) (compress-repititions new-data))
	  (pushnew-equal new-data (theory-data theory)))
	 ((ematch? (theory-current theory) new-data) ;matches current theory, no prob
	  (pushnew-equal new-data (theory-data theory)))
	 ((let ((new-theory (compress-repititions new-data))) ;no match, so..
	    (print `(theory ,(theory-current theory) for ,(theory-for theory) failed to match ,new-data))
	    (call-with-current-continuation
	     (lambda (exit)
	       (for-each (lambda (data)
			   (unless (ematch? new-theory data)
				   (print `(new theory ,new-theory failed to match ,data))
				   (exit #f)))
			 (theory-data theory))
	       new-theory)))
	  ;; new theory matches all data
	  (print `(updating theory for ,(theory-for theory) from ,(theory-current theory) to ,it))
	  (setf (theory-current theory) it)
	  (pushnew-equal new-data (theory-data theory))
	  #t)
	 (#t (print `(,new-data does not match theory ,(theory-current theory))))))

(define (induce-grammar structure)
  (define-memoized (theory type)
    (make-theory type #f '()))
  (for-each (lambda (item)
	      (induce-trivial (theory (car item)) (cadr item)))
	    structure)
  (theory ':hashtable))
 	   
; replace '(... x x ...) with (... (+ x) ...)
(define (compress-repititions theory)
  (cond ((null? theory) '())
	((null? (cdr theory)) theory)
	((eq? (car theory) (cadr theory))
	 (cons `(+ ,(car theory))
	       (let loop ((rest (cddr theory)))
		 (if (and (pair? rest) 
			  (eq? (car rest) (car theory)))
		     (loop (cdr rest))
		     (compress-repititions rest)))))
	(#t (cons (car theory)
		  (compress-repititions (cdr theory))))))

; (do-it "d:/XML/shakespeare.1.02.xml/short-hamlet.xml")

(define (do-it file)
  (define doc (parse-xml-file file))
  (define struct (all-structure doc))
  (set! struct 
	(sort struct (lambda (a b) (string>? (string (car a)) (string (car b))))))
  (print-grammar (induce-grammar struct)))

(define (print-grammar ht)
  (map-hashtable
   (lambda (key val)
     (print `(,key ,(theory-current val))))
   ht))


;;; instrumented ematch-- returns failure info.
;;; doesn't work, the results returned are too low-level...perhaps we need
;;; to use dynamic binding, get the stack of patterns?
;;; also, just plain wrong: (instrumented-ematch? '(a (+ b)) '(a b b))
;;;   returns a failure (because ORs aren't handled right -- any low-level failure
;;; exits...
	 
;;; idea of the moment:

;;; make a full trace (a la ptrace). if a match fails, look up the tree
;;; through all failure chains. For each place, see what change to the 
;;; pattern might fix things.  We might want to use pattern-matching for
;;; this step.

(require-resource 'scm/ptrace.scm)

(define (instrumented-ematch? pat thing)
  (fluid-let ((ematch? (trace-encapsulate ematch?))
	      (trace-stack (list (list 'top))))
    (ematch? pat thing)
;    (find-failures trace-stack)
    trace-stack))

(defmacro (collecting . body)
  `(let ((result '()))
     (define (collect x) (push x result))
     ,@body
     (reverse result)))

(define (find-failures trc)
  (collecting
  (define (find-failures1 trace)
    (if (and (pair? trace)
	     (pair? (car trace))
	     (eq? (caar trace)
		  'Entering))
	(let ((exit-clause (last trace)))
	  (if (eq? #f (caddr exit-clause))
	      (collect (last (car trace))))))
    (when (pair? trace)
	  (for-each find-failures1 trace)))
   (find-failures1 trc)))

