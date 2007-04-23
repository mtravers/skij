(require 'window)
(define w  (make-window 'tree 400 400))
(define p (new 'java.awt.Panel))
(invoke p 'setLayout (new 'java.awt.GridLayout #e1 #e1))
(invoke w 'add p)
(define tree (new '"com.roguewave.widgets.tree.v3_0b2.TreeControl"))
(invoke tree 'setSize #e300 #e300)
(invoke p 'add tree)
(define root (invoke tree 'setRootNode '"God"))
(invoke tree 'addNode root '"Bill Gates")

(invoke w 'setVisible #t)		;necessary to do this for redisplay?

(require 'lists)

; make a tree outline of all classes recursively visible from here
(define (graph-class-walker class)
  (define done-classes '())
  (define todo-classes (cons class '()))
  (define top-node (invoke tree 'setRootNode 'Everything))
  (define (there? class)
    (assq class done-classes))
  (define (see-class class)
    (if (there? class) '()
	(if (memq class todo-classes) '()
	    (begin
	     (print (cons 'see (cons class '())))
	     (set! todo-classes (cons class todo-classes))))))
  (define (do-class class)
    (define there (there? class))
    (if there
	(cadr there)
	(begin
	 (print (cons 'do (cons class '())))
	 (define superclass (invoke class 'getSuperclass))
	 (define node
	   (invoke tree 'addNode (if (eq? superclass '())
				     top-node
				     (do-class superclass))
		   (invoke class 'getName)))
	 (set! done-classes (cons (cons class (cons node '()))
				  done-classes))
	 (walk-class class see-class)
	 node)))
  (define (do-it)
    (if (eq? todo-classes '()) 'done
	(begin
	 (define temp (car todo-classes))
	 (set! todo-classes (cdr todo-classes))
	 (do-class temp)
	 (do-it))))
  (do-it))

(require 'vector)

; finds classes "mentioned" by this class (excluding superclass relation,
; since that's handled above) and applies FUNCTION to them.
(define (walk-class class function)
  (print (cons 'walk (cons class '())))
  (define (acc-vector vector)
    (for-vector function vector))
  (for-vector (lambda (field) (function (invoke field 'getType)))
	      (invoke class 'getDeclaredFields))
  (for-vector function (invoke class 'getInterfaces))
  (define methods (invoke class 'getDeclaredMethods))
  (for-vector (lambda (method) 
		(function (invoke method 'getReturnType))
		(for-vector function (invoke method 'getParameterTypes))) methods))

    

;;; the above sucks, let's try again. Better to be depth-first, I think.
(define (graph-class-walker1 class)
  (define done-classes '())
  (define top-node (invoke tree 'setRootNode 'Everything))
  (define (there? class)
    (assq class done-classes))

  (define (do-class class)
    (define there (there? class))
    (if there
	(cadr there)
	(begin
	 (print (cons 'do (cons class '())))
	 (define superclass (invoke class 'getSuperclass))
	 (define node
	   (invoke tree 'addNode (if (eq? superclass '())
				     top-node
				     (do-class superclass))
		   (invoke class 'getName)))
	 (set! done-classes (cons (cons class (cons node '()))
				  done-classes))
	 (print (length done-classes))
	 (print (map car done-classes))
	 (if (i> (length done-classes) #e8) (car 1.0)
	     (walk-class class do-class))
	 node)))
  (do-class class))

