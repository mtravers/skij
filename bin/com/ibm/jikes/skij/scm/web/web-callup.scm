; todo

;  manage what's visible, up/down buttons, etc
; choose location (currently location is a global var, this has to change)

; interface theory.
; four basic buttons, show superior, show all superiors, and same for subords.
;   and then they can be in a hide state.
;   also a remove button, to get rid of subtrees we aren't interested in.


; a NODE is an employee plus a list of subordinates to show
; a PAGE is defined by a list of top-level nodes

;;; an HTML interface to my callup stuff

; (load-resource 'scm/callup/load-callup.scm)

(load-resource 'scm/callup/callup.scm)
(load-resource 'scm/callup/callup-configure.scm)

(print (catch
	(configure-callup)
	'(callup configured)))

(define-command callup-tree (uid name emp command topic)

  (unless uid
	  (set! uid (string-append (dynamic *client-site*) (string (now)))))

  (wsdoc "IBM People Browser"
	 
	 (html-output "This page lets you view portions of the IBM management tree. For now, it's limited to US employees. You start with an ")
	 (with-link "/webspect/callup-tree"
		    (html-output "empty listing"))
	 (html-output " and iteratively add people to it. There are several ways to add people:")
	 (ltag p)
	 (html-output "Add by name (last name first):")
	 (lenv (form (action callup-tree) (size 40))
	       (output-start-tag 'input `((type hidden) (name uid) (value ,uid)))
	       (ltag input (type submit) (name foo) (value "Lookup by Name"))
	       (ltag input (type input) (name name) (size 30)))
	 
	 (html-output "Or, type a subject word (or phrase) to find people who have that word in their job description. For now, this finds only people in the research division.")
	 (lenv (form (action callup-tree) (size 40))
	       (output-start-tag 'input `((type hidden) (name uid) (value ,uid)))
	       (ltag input (type submit) (name foo) (value "Lookup by Job"))
	       (ltag input (type input) (name topic) (size 30))
	       )
	 
	 (if (not (page-empty? (uid-page uid)))
	     (html-output "Or, click on an arrow icon to add managers or managees."))
	 
	 (ltag br)
	 (html-output "Here's some ")
	 (with-link "http://w3.watson.ibm.com/~mt/webspect/mgt-browser-blurb.html"
		    (html-output "additional documentation"))
	 (html-output ". ")
	 (ltag br)
	 (define page (uid-page uid))
	 
	 (define (wait-msg text)
	   (env i
		(html-output "Please wait while I ")
		(html-output text))
	   (tag br))	   
	 
	 (define new-this-page '())
	 
	 (define (add-emp emp)
	   (set! page (add-to-page page emp))
	   (pushnew emp new-this-page))
	 
	 (when name
	       (set! name (string-trim name))
	       (if (= 0 (string-length name))
		   (html-output "You need to type a name in the box before doing a lookup")
		   (begin
		     (env i 
			  (html-output "Please wait while I look up people named \"")
			  (html-output name)
			  (html-output "\"..."))
		     (tag br)
		     (define new-emps  (get-employees-by-name name))
		     (for-each add-emp new-emps)
		     (html-output "Found ")
		     (html-output (string (length new-emps)))
		     (html-output (if (= 1 (length new-emps)) " person" " people"))
		     (html-output " named ")
		     (env i (html-output name))))
	       (tag br))
	 
	 (when topic
	       (set! topic (string-trim topic))
	       (if (= 0 (string-length topic))
		   (html-output "You need to type a topic in the box before doing a lookup topic")
		   (begin
		     (env i 
			  (ltag br)
			  (html-output "Please wait while I look up people with \"")
			  (html-output topic)
			  (html-output "\" in their job description..."))
		     (tag br)
		     (define new-emps (get-employees-by-job topic))
		     (for-each add-emp new-emps)
		     (html-output "Found ")
		     (html-output (string (length new-emps)))
		     (html-output (if (= 1 (length new-emps)) " person" " people"))
		     )))
	 
	 (when emp
	       (set! emp (get-employee emp)))
	 
	 (when command
	       (define (wait-msg type)
		 (ltag br)
		 (env i
		      (html-output "Please wait while I look up ")
		      (html-output type)
		      (html-output " ")
		      (html-output (employee-name emp))
		      (html-output "..."))
		 (tag br))
	       (case (intern command)
		 ((show-manager)
		  (wait-msg "the manager of")
		  (add-emp (employee-manager emp)))
		 ((show-all-managers)
		  (wait-msg "all managers of")
		  (for-each add-emp
			    (employee-all-managers emp)))
		 ((show-subordinates)
		  (wait-msg "people who report directly to")
		  (for-each add-emp
			    (employee-subordinates emp)))
		 ((show-all-subordinates)
		  (wait-msg "all people who report directly or indirectly to")
		  (for-each add-emp
			    (employee-all-subordinates emp))))
	       (env i (html-output "Done!"))
	       
	       )
	 
	 (output-emp-page page new-this-page)
	 (unless (null? (cdr page))
		 (output-legend)
		 (output-palm-link uid)
		 )
	 ))

; a tree is (emp subord subord ...) where subord can be an emp or a tree
; a page is (uid subord subord ...)

; +++ it will never let go of old pages...I suppose a timeout is needed. Argh.
(define-memoized (uid-page uid)
  (list uid))

(define (page-empty? page)
  (null? (cdr page)))

(define (add-to-page page new-emp)
  (define (over? emp1 emp2)
    (and (vector? emp1) (vector? emp2)	;should be employee?
	 (not (autarch? emp2))
	 (equal? (employee-id emp1) (employee-mgr emp2))))
  (define (add-subtree add-to new-subtree)
    (set-cdr! add-to (sort (cons new-subtree (cdr add-to))
			   (lambda (a b) (string<? (employee-name (car a))
						   (employee-name (car b)))))))
  (let ((new-emp-tree (list new-emp)))
    ;; see if new-emp is OVER any extant subtrees
    (for-each (lambda (subtree)
		(cond ((over? new-emp (car subtree))
		       (set! page (ndelete subtree page))
		       (add-subtree new-emp-tree subtree))))
	      (cdr page))
    ;; see if new-emp is under anybody
    (define under?
      (loop				;this is the only way to do non-local return of value, sigh
       (letrec ((walk-subtree (lambda (tree)
				(cond ((eq? new-emp (car tree))	
				       (break 'present)) ;already there
				      ((over? (car tree) new-emp) ;this is manager
				       (for-each (lambda (subtr) ;make sure not there already
						   (if (eq? new-emp (car subtr)) 
						       (break 'present))) 
						 (cdr tree))
				       (break tree)) ;ok, add here
				      (#t	;go down moses
				       (for-each (lambda (subtr) (walk-subtree subtr))
						 (cdr tree)))
				      ))))
	 (walk-subtree page)
	 (break #f))))
    (if under?
	(if (eq? under? 'present)
	    #f
	    (add-subtree under? new-emp-tree))
	(add-subtree page new-emp-tree)))
  page)

;;; non-iterator version
(define (add-to-page page new-emp)
  (define (over? emp1 emp2)
    (and (vector? emp1) (vector? emp2)	;should be employee?
	 (not (autarch? emp2))
	 (equal? (employee-id emp1) (employee-mgr emp2))))
  (define (add-subtree add-to new-subtree)
    (set-cdr! add-to (sort (cons new-subtree (cdr add-to))
			   (lambda (a b) (string<? (employee-name (car a))
						   (employee-name (car b)))))))
  (let ((new-emp-tree (list new-emp)))
    ;; see if new-emp is OVER any extant subtrees
    (for-each (lambda (subtree)
		(cond ((over? new-emp (car subtree))
		       (set! page (ndelete subtree page))
		       (add-subtree new-emp-tree subtree))))
	      (cdr page))
    ;; see if new-emp is under anybody
    (define under? #f)
    (catch				;a kludgy way to do nonlocal exit
     (letrec ((result (lambda (val) 
			(set! under? val)
			(throw (new 'com.ibm.jikes.skij.SchemeException))))
	      (walk-subtree (lambda (tree)
			      (cond ((eq? new-emp (car tree))	
				     (result 'present)) ;already there
				    ((over? (car tree) new-emp) ;this is manager
				     (for-each (lambda (subtr) ;make sure not there already
						 (if (eq? new-emp (car subtr)) 
						     (result 'present))) 
					       (cdr tree))
				     (result tree)) ;ok, add here
				    (#t	;go down moses
				     (for-each (lambda (subtr) (walk-subtree subtr))
					       (cdr tree)))
				    ))))
       (walk-subtree page)))
    (if under?
	(if (eq? under? 'present)
	    #f
	    (add-subtree under? new-emp-tree))
	(add-subtree page new-emp-tree)))
  page)

(define (output-emp-page page newbies)
  (lenv (font (size -1))
	(for-each (lambda (subtree)
		    (ltag hr)
		    (env ul
			 (output-employee-tree subtree #t newbies)))
		  (cdr page))))

(define (output-palm-link uid)
  (ltag p)
  (env (font (size "+1") (color "#FF0000"))
       (env b
	    (html-output "New: ")))
  (with-link (make-webspect-url 'palm-transfer (list 'uid uid))
	     (html-output "Transfer phone and address information"))
  (html-output " for everyone listed to an IBM WorkPad or Palm Pilot"))

(define (output-employee-tree emp-tree top? newbies)
  (define emp (car emp-tree))
  (define emp-param  (list 'emp (string (employee-id emp))))
  (define uid-param (list 'uid (dynamic uid)))
  (lenv li

	(when (and top? (not (autarch? emp)))
	      (with-link (make-webspect-url 'callup-tree (list 'command 'show-all-managers) emp-param uid-param)
			 (tag img (alt "[Show All Managers]") (height 11) (width 11)
				   (src "http://w3.watson.ibm.com/~mt/images/up2arrow.gif")
				   (border 0)))
	      (with-link (make-webspect-url 'callup-tree (list 'command 'show-manager) emp-param uid-param)
			 (tag img (alt "[Show Manager]") (height 11) (width 11)
			      (src "http://w3.watson.ibm.com/~mt/images/uparrow.gif")
			      (border 0))))


	(with-link (string-append "http://w3-2.austin.ibm.com/cgi-bin/call/All/ed?"
				  (string (employee-id emp))
				  "+"
				  (string (employee-empcc emp)))

		   (if (memq emp newbies)
		       (env b (html-output (employee-name emp)))
		       (html-output (employee-name emp))))


	(when (employee-is-mgr? emp)
	      (with-link (make-webspect-url 'callup-tree (list 'command 'show-subordinates) emp-param uid-param)
			 (tag img (alt "[Show Subordinates]") (height 11) (width 11)
			      (src "http://w3.watson.ibm.com/~mt/images/downarrow.gif")
			      (border 0)))
	      (with-link (make-webspect-url 'callup-tree (list 'command 'show-all-subordinates) emp-param uid-param)
			 (tag img (alt "[Show All Subordinates]") (height 11) (width 11)
				   (src "http://w3.watson.ibm.com/~mt/images/down2arrow.gif")
				   (border 0))))

	(unless (equal? (employee-job emp) "")
		(html-output "  ")
		(html-output (employee-job emp)))
	(awhen (employee-url emp)
		(html-output "  ")
		(with-link it
			   (env i (html-output it))))
; +++
;	(html-output "  ")
;	(env i (html-output (string-trim (employee-dept-title emp))))
; +++
	(define subs (cdr emp-tree))
	(unless (null? subs)
	  (lenv (ul (type disc))
	       (for-each (lambda (sub) (output-employee-tree sub #f newbies))
			 subs)))))
  

;;; should be in callup

(define (employee-known-subordinates emp)
  (define id (employee-id emp))
  (define result '())
  (for-hashtable (lambda (key psub)
		   (if (equal? (employee-mgr psub) id)
		       (push psub result)))
		 (get-employee ':hashtable))
  result)

(define (output-legend)
  (ltag hr)
  (env b (html-output "Legend:"))
  (tag br)
  (env (font (size -1))
       (tag IMG (SRC "http://w3.watson.ibm.com/~mt/images/up2arrow.gif") (ALIGN ABSCENTER))
       (html-output "show all managers")
;       (env i (html-output " (recommended)"))
       (ltag br)
       (tag IMG (SRC "http://w3.watson.ibm.com/~mt/images/uparrow.gif") (ALIGN ABSCENTER))       
       (html-output "show immediate managers")
       (ltag br)
       (tag IMG (SRC "http://w3.watson.ibm.com/~mt/images/downarrow.gif") (ALIGN ABSCENTER))       
       (html-output "show immediate managees")
       (ltag br)
       (tag IMG (SRC "http://w3.watson.ibm.com/~mt/images/down2arrow.gif") (ALIGN ABSCENTER))       
       (html-output "show all managees")
       (env i (html-output " (may take a very long time)"))))

