;;; Path Finder (& generator)

;;; Build an object graph (from the graphical graph)
;;; works only under JDK1.2


;;; current toplevel. From and to should be objects that are displayed
;;; in the object graph. 
(define (make-path-prog from to)
  (path->skij (find-path (ob-graph *object-graph*) from to)))

(define (ob-graph graph-panel)
  (map-enumeration (lambda (edge)
		     (list (peek (peek edge 'from) 'object)
			   (peek (peek edge 'to) 'object)
			   (peek edge 'label)))
		   (invoke (peek graph-panel 'edges) 'elements)))
    

(require-resource 'scm/listlib.scm)

;;; depth-first search (breadth-first would be better; this could be smarter in general)
(define (find-path graph from to)
  (print `(find-path ,from ,to))
  (call-with-current-continuation
   (lambda (return)
     (if (eq? from to) '()
	 (begin
	   (for-each (lambda (edge)
		     (if (eq? (car edge) from)
			 (aif (find-path graph (cadr edge) to)
			      (return (cons edge it)
				      #f))))
		   graph)
	   #f)))))

(define (path->skij path)
  `(lambda (x)
     ,(path->skij1 (reverse path))))

(define (path->skij1 path)
  (if (null? path) 'x
      (path-element->skij (car path) (path->skij1 (cdr path)))))

(define (path-element->skij elt arg)
  (let ((from (car elt))
;	(to (cadr elt))
	(label (caddr elt)))
    (cond ((vector? from)
	   `(vector-ref ,arg ,(read-from-string label)))
	  ((instanceof from 'java.util.Hashtable)
	   `(hashtable-get ,arg ,label)) ; usually wrong!
	  ((>= (invoke label 'indexOf #\() 0) ;+++ static methods
	   `(invoke ,arg ',(substring label 0 (invoke label 'indexOf #\())))
	  (else
	   `(peek ,arg ',label)))))	;+++ static fields

;;; translation to Java:
;;; should do necessary casting as well as the obvious translation.


;;; here's an example from CLP
(lambda (x) 
  (invoke (invoke (invoke x "getHead") "getPredicate") "getSymName"))

  public String foo(ERule rule){
    return ((Literal)rule.getHead()).getPredicate().getSymName();
  }

Note that coercion is needed, since getHead returns Formula but getPredicate
is defined only for Literal, which is a specialization.