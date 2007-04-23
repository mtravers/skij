(define (make-callup-tree)
  (define tree (make-tree #f))
  (invoke tree 'setRootVisible #f)	; deus absconditus
  (set! callup-tree tree)
  (callup-tree-add-mouse-listener tree)
  (clear-hashtable (employee-node ':hashtable))
  tree)

(define (error? thing)
  (instanceof thing 'java.lang.Throwable))

(define (make-callup-panel)
  (define tree (make-callup-tree))
  (define tree-panel (make-tree-panel tree))
  
  (define input-area (new 'com.sun.java.swing.JTextField))
  (define output-area (new 'com.sun.java.swing.JLabel))

  (invoke input-area 'setBorder (new 'com.sun.java.swing.border.LineBorder 
				     (peek-static 'java.awt.Color 'cyan)))

  (define (read-string)
    (invoke input-area 'getText))
  (define (write-string string)
    (invoke output-area 'setText string))

  (define button 
    (make-swing-button 
     'Find 
     (lambda (evt)
       (in-own-thread
	(define name (string-trim (read-string)))
	(write-string (string-append '"Getting info for " name))
	(define emps (catch (get-employees-by-name name)))
	(write-string
	 (string-append 
	  name
	  '": "
	  (cond ((null? emps)
		 '"Nobody found")
		((error? emps)
		 (string emps))
		((= 1 (length emps))
		 '"1 person found.")
		(#t
		 (string-append (length emps)
				'" people found.")))))
	;;; make sure nodes get created
	(for-each display-employee-node emps)))))

  (define panel (new 'com.sun.java.swing.JPanel))
  (define bottom-panel (new 'com.sun.java.swing.JPanel))
  (invoke bottom-panel 'setLayout (new 'java.awt.BorderLayout))
  (invoke bottom-panel 'add button 'East)
  (invoke bottom-panel 'add input-area 'Center)
  (invoke bottom-panel 'add output-area 'North)

  (invoke panel 'setLayout (new 'java.awt.BorderLayout))
  (invoke panel 'add bottom-panel 'South)
  (invoke panel 'add tree-panel 'Center)

  (write-string '"Enter a name (last name first) and press Find:")

  panel
  )
	       
(define (make-callup-window)
  (define p (make-callup-panel))
  (define w (make-swing-window-for-panel '"Management Structure Browser" p))
  (invoke w 'setVisible #t))



