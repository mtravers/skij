(require 'hashtable)

; (<ob> 'getv <slot>)
; (<ob> 'putv <slot> <value>)
; (<ob> 'geta <slot> <anname>)
; (<ob> 'puta <slot> <anname> <value>)


(define (make-obj parent)
  (define slots (make-hashtable))
  (define annotations (make-hashtable))
  (letrec ((self (lambda args
		   (define op (car args))
		   (cond ((eq? op 'getv)
			  (hashtable-get slots (cadr args) #f))
			 ((eq? op 'putv)
			  (hashtable-put slots (cadr args) (caddr args)))
			 ((eq? op 'get-annotator)
			  (hashtable-lookup annotations (cadr args) 
					    (lambda (name)
					      (make-obj (and parent (parent 'get-annotator))))
					    ))
			 ((eq? op 'geta)
			  ((self 'get-annotator (cadr args)) 'getv (caddr args)))
			 ((eq? op 'puta)
			  ((self 'get-annotator (cadr args)) 'putv (caddr args) (cadddr args)))))))
    self))


;;; Oh forget it
(define (make-obj parent)
  (list parent (make-hashtable) (make-hashtable)))

(define (parent obj)
  (car obj))

(define (slots obj)
  (cadr obj))

(define (annotations obj)
  (caddr obj))

(define (getv obj slot)
  (hashtable-get (slots obj) slot #f))

(define (putv obj slot val)
  (hashtable-put (slots obj) slot val))

(define (ann-block obj slot)
  (hashtable-lookup (annotations obj)
		    slot
		    (lambda (name)
		      (make-obj (and (parent obj) (ann-block (parent obj)))))))

(define (geta obj slot ann)
  (getv (ann-block obj slot) ann))

(define (puta obj slot ann val)
  (putv (ann-block obj slot) ann val))

;;; recurse
(define (get-path obj path)
  (if (null? (cdr path))
      (getv ob (car path))
      (geta (geta ob (car path)
    

