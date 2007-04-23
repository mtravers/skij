; finds classes "mentioned" by this class 
; and applies FUNCTION to them.
(define (walk-class class function)
  (define (unvector class)
    (if (invoke class 'isArray)
	(invoke class 'getComponentType)
	class))
  (define (ffunction class)
    (function (unvector class)))
  (aif (invoke class 'getSuperclass)
       (function it))
  (for-vector (lambda (field) (ffunction (invoke field 'getType)))
	      (invoke class 'getDeclaredFields))
  (for-vector function (invoke class 'getInterfaces))
  (for-vector (lambda (method) 
		(ffunction (invoke method 'getReturnType))
		(for-vector ffunction (invoke method 'getParameterTypes)))
	      (invoke class 'getDeclaredMethods)))


; walk the graph as far as we can
(define (walk-from class function)
  (define todo (list class))
  (define-memoized (register class)
    (function class)
    (walk-class class (lambda (c) (pushnew c todo))))
  (loop
   (if (null? todo) (break))
   (register (pop todo))))

; breadth first
(define (walk-from-breadth-first class function)
  (define todo (list class))
  (define-memoized (register class)
    (function class)
    (define result '())
    (walk-class class (lambda (c) (pushnew c result)))
    (set! todo (nconc todo result))
    class)
  (loop
   (if (null? todo) (break))
   (register (pop todo))))

; Make a class tree

(define tree (make-tree-window '"Partial Class Hierarchy" #f))

(define root (set-root tree 'Top))

(define-memoized (class-node class)
  (if class
      (add-child tree
		 (class-node (invoke class 'getSuperclass))
		 (invoke class 'getName))
      root))
    
; make a tree outline of all classes recursively visible from here
; depth-first, more or less
(define (do-class class)
  (walk-from-breadth-first class class-node))

(define *subclasses* (make-hashtable))
(define (class-known-subclasses class)
  (hashtable-get *subclasses* class '()))
(define (subclass-register class)
  (define super (invoke class 'getSuperclass))
  (hashtable-put *subclasses* super
		 (cons class (class-known-subclasses super))))

(define (build-subclass-table from)
  (walk-from-breadth-first from subclass-register))

; generate a tree from the subclass data
(define (graph-subclasses)
  (make-tree-window '"Known Classes"
		    (generate-tree '() class-known-subclasses string)))
  
(define (find-classes-that-mention class)
  (define result '())
  (define (descend dclass)
    (walk-class dclass (lambda (border)
			 (if (eq? border class)
			     (pushnew dclass result))))
    (for-each descend (class-known-subclasses dclass)))
  (descend (class-named 'java.lang.Object))
  result)
