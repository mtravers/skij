;;; invoke expressed in scheme, for experimentation

(define (m-invoke obj method-name args)
  (define class (invoke obj 'getClass))
  (define arg-classes (make-class-array args))
  ;; try exact match
  (define method (lookup-method class method-name arg-classes))
  method)
  
(define class-class (invoke '(class java.lang.Class) 'forName 'java.lang.Class))

(define (make-class-array arglist)
  (define v (invoke '(class java.lang.reflect.Array) 'newInstance class-class (length arglist)))
  (define index 0)
  (for-each (lambda (arg)
	      (vector-set! v index (invoke arg 'getClass))
	      (set! index (+ index 1)))
	    arglist)
  v)

(define (lookup-method class name arg-classes)
  (invoke class 'getMethod name arg-classes))