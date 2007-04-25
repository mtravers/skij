;;; NOTE: this is radically improved from defstruct built into base Skij

;;; This file is part of Skij.
;;; Author: Michael Travers (mt@watson.ibm.com)

;;; Licensed Materials - See the file license.txt.
;;; (c) Copyright IBM Corp. 1997, 1998. All rights reserved.

; Elementary form of defstruct. 
; structures are implemented using vectors, tagged with type

;;; Todo

; make now takes class arg, how about is?
; use adaptors to give reasonable printed representations (at cost of extra references)
; make inspector know about defstructs
; since we are ghastly slow anyway, maybe the representation should be alist/hashtable
;   and then multiple inheritance would be possible.
; some equivalent of with-slots?

;;; 10 Nov 2000 -- added single inheritance
;;; 12 Nov 2000 -- added type identifiers and checker functions
;;; 14 Dec 2000 -- added defmethod!
;;; 22 Nov 2004 -- error check base class (do I only work on this stuff to console myself after bad elections?)

(define *struct-fields* (make-hashtable))
(define *struct-parents* (make-hashtable)) ;this could be flushed; just call the check functions

(define (structure-type struct)
  (vector-ref struct 0))  

;;; even better
(define (make type . initforms)
  (let ((fields (hashtable-get *struct-fields* type #f)))
    (if (not fields)
	(error `(no defstruct for ,type)))
    (define new (make-vector (+ 1 (length fields))))
    (setf (vector-ref new 0) type)
    (init-slots new)			
    (do ((rest initforms (cddr rest)))
	((null? rest) new)
      (setf (vector-ref new (+ 1 (position (car rest) fields eq?)))
	    (cadr rest)))))

(defmacro (defstruct name-and-base? . field-specs)
  (let* ((name (if (list? name-and-base?) (car name-and-base?) name-and-base?))
	 (base (if (list? name-and-base?) (cadr name-and-base?) #f))
	 (base-fields (if base
			  (hashtable-get *struct-fields* base #f)
			  '()))
	 (fields (map (lambda (spec) 
			(if (list? spec) (car spec) spec))
		      field-specs))
	 (nfields (length fields))
	 (all-fields (begin (if (eq? base-fields #f)
				(error `(defstruct ,base does not exist)))
			    (append base-fields fields)))
	 (i (length base-fields)))
    `(begin
       (hashtable-put *struct-fields* ',name ',all-fields)
       ,@(if base
	     `((hashtable-put *struct-parents* ',name ',base))
	     '())
       (define (,(symbol-conc 'make- name) ,@all-fields)
	 (list->vector (cons ',name (list ,@all-fields))))
       (define (,(symbol-conc 'is- name '?) thing)
	 (and (vector? thing)
	      (substruct? (structure-type thing) ',name)))
       (defmethod (init-slots (thing ,name))
	 (call-next-method)
	 ,@(map (lambda (spec)
		  `(setf (,(symbol-conc name '- (car spec)) thing)
			 ,(cadr spec)))
		(filter list? field-specs)))
       ,@(apply nconc
		(map (lambda (field)
		       (set! i (+ i 1))
		       (define getter-name (symbol-conc name '- field))
		       (define setter-name (symbol-conc 'set- name '- field '!))
		       (list
			`(define (,setter-name thing new-val)
			   (vector-set! thing ,i new-val))
			`(define (,getter-name thing)
			   (vector-ref thing ,i))
			`(def-setf (,getter-name thing) new-val
			   `(,',setter-name ,thing ,new-val))
			))
		     fields)))))

(define (substruct? t1 t2)
  (cond ((eq? t1 t2) #t)
	((not t1) #f)
	(#t
	 (substruct? (base-type t1) t2))))

(define (base-type type)
  (hashtable-get *struct-parents* type #f))

;;; ooh methods...really slow but who cares
 
(define-memoized (method-ht name)
  (make-hashtable))

(define (add-method fname type method)
  (setf (hashtable-get (method-ht fname) type #f) method))

(define (lookup-method fname type)
; good trace point
;  (print `(lookup-method ,fname ,type))
  (or (hashtable-get (method-ht fname) type #f)
      (aand (base-type type)
	    (lookup-method fname it))))

(define (run-method name . args)
  (let ((type (structure-type (car args))))
    (aif (lookup-method name type)
	 (apply it args)
	 (error `("No method found for" ,name on ,type)))))

(defmacro (defmethod form . body)
  (let* ((name (car form))
	 (arg1 (cadr form))
	 (argrest (cddr form))
	 (arg1var (car arg1))
	 (type (cadr arg1)))
    `(begin
	 (define (,name . args)
	   (apply run-method ',name args))
       (let* ((%%type ',type)		;for call-next-method
	      (%%fname ',name)
	      (method (lambda (,arg1var ,@argrest)
			,@body)))
	 ;; should allow lists as lambda names, but restricted to symbols for now
	 (poke method 'name ',(symbol-conc 'method- name '- type))
	 (add-method ',name ',type method)
	 method))))

(defmacro (call-next-method)
  '(let ((method (lookup-method %%fname (base-type %%type)))
	 (args (find-method-args (current-environment)))) 
    (if method
	(apply method args)
	(error "No next method"))))

;;; looks up the environment chain for the method call.
(define (find-method-args env)
  (let ((parent (peek env 'parent)))
    (cond ((%%null? parent)
	   (error "Can't find method args"))
	  ((memv '%%fname (peek parent 'names))
	   (peek env 'values))
	  (else
	   (find-method-args parent)))))



(defmethod (init-slots (obj #f))
  )

;;; additions to describe/inspect
(define (structure? thing)
  (and (vector? thing)
       (hashtable-get *struct-parents* (structure-type thing) #f)))

;;; load before patching
(require 'inspect)
(require 'describe)

(define (inspect-data object)
  (cond ((structure? object)
	 (inspect-data-structure object))
	((vector? object)
	 (inspect-data-vector object))
	((list? object)
	 (inspect-data-list object))
	((instanceof object 'java.util.Enumeration)
	 (inspect-data-list (map-enumeration (lambda (x) x) object)))
	((instanceof object 'java.util.Vector)
	 (inspect-data-list (map-enumeration (lambda (x) x) (invoke object 'elements))))
	((instanceof object 'java.util.Hashtable)
	 (inspect-data-ht object))
	(#t
	 (inspect-data-obj object))))

(define (structure-fields type) 
  (hashtable-get *struct-fields* type #f))  

(define (inspect-data-structure structure)
  (let* ((type (structure-type structure))
	 (fields (structure-fields type)))
    (cons '(Field Value)
	  (map list fields (cdr (vector->list structure))))))
