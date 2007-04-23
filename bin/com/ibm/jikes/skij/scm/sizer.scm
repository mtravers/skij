
; crude, parasiting on inspect
(define (neighbors obj)
  (map cadr (inspect-data obj)))

(define *special-case-classes* '())

(define (filtered-neighbors obj)
  (define temp (assq (class-of obj) *special-case-classes*))
  (if temp
      ((cadr temp) obj)
      (filter-out (lambda (elt) 
		    (or (instanceof elt 'java.lang.Class)
			(instanceof elt 'java.lang.Number)
			(instanceof elt 'java.lang.Character)
			(instanceof elt 'java.lang.Boolean)))
		  (neighbors obj))))

; define special procedures for certain classes
(define (special-case class proc)
  (push (list (class-named class) proc)
	*special-case-classes*))

; recurses, producing a new Dimension object each time
(special-case 'java.awt.Dimension
	      (lambda (obj) '()))

; has a get method that blocks!
(special-case 'java.awt.EventQueue
	      (lambda (obj) '()))

      
(define (display-tree walker-output)
  (define tree
    (make-tree-window 'wow (generate-tree
			    walker-output
			    (lambda (node) 
			      (define temp (caddr node))
			      (if temp temp
				  '()))
			    (lambda (entry)
			      (make-adaptor
			       (string-append (string (entry-size entry)) '"  •   " (string (car entry)))
			       entry)))))

  (tree-add-mouse-listener
   tree
   (lambda (node x y)
     (define thing (car (invoke (invoke node 'getUserObject) 'getBinding 'contents)))
     (inspect thing))))

(define (entry-size entry)
  (+ (object-size (car entry))
     (if (caddr entry)
	 (sum (map entry-size (caddr entry)))
	 0)))

(define (sum args)
  (if (null? args) 0
      (+ (car args)
	 (sum (cdr args)))))

;;; this is implementation dependent, and I'm guessing
;;; entries are (class array-size field-size)
;;; the assumption is that every field takes a word (or more)
;;; but arrays pack things better
(define field-sizes
  `((,(peek '(class java.lang.Boolean) 'TYPE) 1 4) 
    (,(peek '(class java.lang.Character) 'TYPE) 2 4)
    (,(peek '(class java.lang.Byte) 'TYPE) 1 4)
    (,(peek '(class java.lang.Short) 'TYPE) 2 4)
    (,(peek '(class java.lang.Integer) 'TYPE) 4 4)
    (,(peek '(class java.lang.Long) 'TYPE) 8 8)
    (,(peek '(class java.lang.Float) 'TYPE) 4 4)
    (,(peek '(class java.lang.Double) 'TYPE) 8 8)))

(define (type-field-size type)
  (define temp (assq type field-sizes))
  (if temp
      (caddr temp)
      4))

(define (type-array-size type)
  (define temp (assq type field-sizes))
  (if temp
      (cadr temp)
      4))

(define (field-static? field)
  (invoke '(class java.lang.reflect.Modifier) 'isStatic 
	  (invoke field 'getModifiers)))

(define-memoized (class-size class)
  (if class
      (+ (class-size (invoke class 'getSuperclass))
	 (begin
	   (define sum 0)
	   (for-vector (lambda (field)
			 (if (field-static? field) '()
			     (set! sum
				   (+ sum (type-field-size (invoke field 'getType))))))
		       (invoke class 'getDeclaredFields))
	   sum))
      0))

;;; size of the object itself
(define (object-size thing)
  (define class (class-of thing))
  (if (invoke class 'isArray)
      (* (vector-length thing)
	 (type-array-size (invoke class 'getComponentType)))
      (class-size class)))

(define (walk root function neighbors max)

  (define parent '())

  (define-memoized (entry obj)
    (list obj 1 #f parent))

  (define count 0)
  (define todo (list (entry root)))

  (loop
   (if (null? todo) (break))
   (if (> count max) (break))
   (define from-ent (pop todo))
   (define from (car from-ent))
   (if (caddr from-ent)
       (set-car! (cdr from-ent) (+ 1 (cadr from-ent)))
       (begin 
	 (function from)
	 (define new-neighbors '())
	 (set! parent from)
	 (for-each (lambda (n)
		     
		     (define n-ent (entry n))
		     (if (and (eq? (cadddr n-ent) parent)
			      (not (caddr n-ent))
			      (not (memq n-ent todo))
			      (not (memq n-ent new-neighbors)))
			 (push n-ent new-neighbors)))
		   (neighbors from))
	 (set-car! (cddr from-ent) new-neighbors)
	 (set! todo (append todo new-neighbors))
	 (set! count (+ count 1)))))
  (entry root))