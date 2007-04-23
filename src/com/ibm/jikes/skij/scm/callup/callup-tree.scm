(define callup-tree #f)		       


;(define separator "  •   ")
(define separator "   []   ")

(define (employee-display-string emp)
  (string-append (employee-name emp)
		 (if (equal? (employee-job emp) "")
		     ""
		     (string-append separator
				    (employee-job emp)))
		 (aif (employee-url emp)
		      (string-append separator
				     it)
		      "")))

;;; inserts employee and all superiors
(define-memoized (employee-node employee)
  (define node
    (add-child callup-tree
	       (if (autarch? employee)
		   (root-node callup-tree)
		   (employee-node (employee-manager employee)))
	       (employee-adaptor employee)))
  node)

(define (display-employee-node employee)
  (set-open callup-tree (employee-node employee) #t))

(define-memoized (employee-node employee)
  (define node
    (add-child callup-tree
	       (if (autarch? employee)
		   (root-node callup-tree)
		   (employee-node (employee-manager employee)))
	       (employee-adaptor employee)))
  (set-open callup-tree node #t)
  node)

;;; experimental, put at root if manager not there, then spawn process to fix...
(define-memoized (employee-node employee)
  (define node #f)
  (define parent
    (if (autarch? employee)
	(root-node callup-tree)
	(aif (employee-manager-lazy employee)
	     (employee-node it)
	     (begin
	       (in-own-thread
		(add-child callup-tree (employee-node (employee-manager employee)) node)
		(set-open callup-tree node #t))	;should not be necessary, but is
	       (root-node callup-tree)))))

  (set! node (add-child callup-tree
			parent
			(employee-adaptor employee)))
  (set-open callup-tree node #t)
  node)

;;; this makes employees appear in graph as soon as they are created
(define original-make-employee #f)

(if (not original-make-employee)
    (begin 
      (set! original-make-employee make-employee)

      (set! make-employee
	    (lambda args
	      (define emp (apply original-make-employee args))
	      (in-own-thread (employee-node emp))
	      emp))))

;;; conses a new procedure each time, does not really need to
(define (employee-adaptor emp)
  (define display (employee-display-string emp)) ;avoid computing this on display updates
  (define a (new 'com.ibm.jikes.skij.misc.Adaptor))
;  (invoke a 'addBinding 'toString (lambda () (employee-display-string emp)))
  (invoke a 'addBinding 'toString (lambda () display))
  (invoke a 'addBinding 'employee emp)
  a)

(define (show-group employee)
  (for-each employee-node (cow-orkers employee)))

(define (show-subordinates employee)
  (for-each employee-node (subordinates employee)))

(define (show-all-subordinates employee)
  (for-each employee-node (all-subordinates employee)))


(require 'menu)

(define (callup-tree-add-mouse-listener tree)
  (tree-add-mouse-listener 
   tree
   (lambda (node x y)
     (define emp (invoke (invoke node 'getUserObject) 'getBinding 'employee))
     (define menu (make-popup-menu (list (make-menu-item (employee-name emp) 'bold? #t)
					 (make-menu-item "Show Cow-orkers"
							 'procedure
							 (lambda (evt)
							   (in-own-thread
							    (show-group emp))))
					 (make-menu-item "Show Subordinates"
							 'procedure
							 (lambda (evt)
							   (in-own-thread
							    (show-subordinates emp)))
							 'enabled?
							 (employee-is-mgr? emp))
					 (make-menu-item "Show All Subordinates"
							 'procedure
							 (lambda (evt)
							   (in-own-thread 
							    (show-all-subordinates emp)))
							 'enabled?
							 (employee-is-mgr? emp)))))
     (display-popup-menu menu callup-tree x y))))

  
		    
  
