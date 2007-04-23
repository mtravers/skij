;;; Interface to Callup (IBM directory service) via rsh or local shell (on AIX)

(define *fields* #f)

; it takes forever to get these, so let's cheat and assume the format won't change drastically
(set! *fields* '((name 45) (qname 45) (directory 8) (xphone 16) (tie 8) (div 2) (dept 6) (deptm 199) (bldg 10) (imad 15) (floor 2) (office 10) (nodeid 8) (userid 8) (mailid 100) (serial 6) (mgr 6) (ismgr 1) (additional 70) (location 40) (secnum 6) (empcc 3) (mgrcc 3) (emptype 1) (nodea 8) (userida 8) (afsid 20) (xphonea 16) (tiea 8) (desctiea 36) (fax 16) (faxtie 8) (jobresponsib 70) (backup 30) (pager 16) (pagertype 1) (pagerid 10) (cellular 16) (display 40) (calendar 50) (url 255) (workloc 3) (loccity 9) (pdif 1) (intaddr 1) (datetime 14) (territory 3) (infophones 30) (pagercarrier 20) (teamid 40) (iamheredir 8)))


(define (callup-command args)
  (string-append *callup-command*
		 args))

(define (callup-location-arg)
  (string-append "-l"
		 *location*
		 " "))


(define (get-fields)
  (synchronized 
   'get-fields
   (or *fields*
       (begin (set! *fields* (read-field-info))
	      *fields*))))

(define (read-field-info)
  (print "Reading field info, please wait...")
  (define field-string (callup-string "-C"))
  (define fields '())
  (with-input-from-string field-string
    (lambda (in)
      (catch
       (loop				;+++ no longer works, but we don't call this anyway.
	(define name (read in))
	(if (eof-object? name) (break))
	(define cols (read in))
	(set! fields (cons (list name cols) fields))))))
  (cdddr (reverse fields)))

;;; returns a list (in out)
(define (make-pipe)
  (define in (new 'java.io.PipedInputStream))
  (define out (new 'java.io.PipedOutputStream in))
  (list (new 'com.ibm.jikes.skij.InputPort in)
	(new 'com.ibm.jikes.skij.OutputPort out)))

;;; returns in inputport...this is what you want
(define (callpipe args)
  (define pipe (make-pipe))
  (run-in-thread (lambda () (call args (cadr pipe)))) ;this is nice!
  (car pipe))

; output to console, user command
(define (callup name)
  (define in (callpipe name))
  (catch 
   (copy-until-eof in (current-output-port))))

(define (callup-string string)
  (with-string-output-port
   (lambda (out)
     (call string out))))

(define (format-fields fields)
  (if (null? (cdr fields)) 
      (string-append (car fields) " ")
      (string-append (car fields)
		     ","
		     (format-fields (cdr fields)))))
  
; return list of fields
(define (callup-fields fields name)
  (define string
    (callup-string (string-append (callup-location-arg)
				  "-h -c " 
				  (format-fields fields)
				  name)))
  (define index 0)
  (map (lambda (field-name)
	 (define field-len (cadr (assq field-name (get-fields))))
	 (define field-val (catch (string-trim (substring string index (+ index field-len)))))
	 (if (not (string? field-val))
	     (error (string-append "Error getting field "
				   field-name
				   " for "
				   name
				   "; result was too short ("
				   string
				   ")")))
	 (set! index (+ 1 (+ index (max 5 field-len))))
	 field-val)
       fields))

;;; employee objects

(defstruct employee
  name
  id
  mgr
  job
  is-mgr?
  url
  empcc)

(define (employee-fields string)
  (callup-fields '(name serial mgr jobresponsib ismgr url empcc) string))

(define (make-employee-from-fields fields)
  (make-employee (list-ref fields 0)
		 (list-ref fields 1)
		 (list-ref fields 2)
		 (list-ref fields 3)
		 (equal? (list-ref fields 4) "Y")
		 (if (equal? (list-ref fields 5) "")
		     #f
		     (list-ref fields 5))
		 (list-ref fields 6)
		 ))

(define (intern-string string) (invoke string 'intern))

(define-memoized (get-employee id intern-string)
  (make-employee-from-fields (employee-fields (string-append '= id))))

(define (employee-present? id)
  (hashtable-get (get-employee ':hashtable) id #f))

; properly handle multiple or no match
(define (get-employees-by-name name)
  (map (lambda (line)
	 (get-employee (string-trim line)))
       (parse-lines
	(callup-string (string-append (callup-location-arg) "-h -c serial " name)))))

(define (parse-lines string)
  (parse-substrings (string-trim string) 10))

; getting entries by department is too slow
(define (cow-orkers emp)
  (define dept (car (callup-fields '(dept) (string-append '= (employee-id emp)))))
  (employees-by-field 'dept dept))

; so use this method
(define (cow-orkers emp)
  (subordinates (employee-manager emp)))

; note: for some unimaginable reason, the double quotes have to go when
; called on AIX by the exec method.
(define (employees-by-field field-name field-value)
  (define idlines 
    (callup-string 
     (string-append (callup-location-arg)
		    "-h -c serial -w "
		    (if (eq? *remote-os* 'AIX) "" "\"")
		    field-name
		    "='"
		    field-value
		    "'"
		    (if (eq? *remote-os* 'AIX) "" "\"")
		    )))
  (map get-employee (map string-trim (parse-lines idlines))))
	 
;;; records don't keep downlinks, but this makes it easy...
(define-memoized (subordinates emp)
  (if (employee-is-mgr? emp)
      (employees-by-field 'mgr (employee-id emp))
      '()))

;;; incorrect for non-tree graphs, but we are a hierarchy here.
(define (transitive-closure relation)
  (letrec ((finder (lambda (thing)
		     (define immeds (relation thing))
		     (nconc immeds
			    (apply nconc
				   (map finder immeds))))))
    finder))


(define all-subordinates
  (transitive-closure subordinates))

;;; regularize names
(define employee-subordinates subordinates)
(define employee-all-subordinates all-subordinates)

;;; all subordinates with a more incremental display
(define all-subordinates-inc
  (transitive-closure
   (lambda (emp)
     (define result (subordinates emp))
     (for-each employee-node result)
     result)))

; those who manage themselves
(define (autarch? employee)
  (equal? (employee-mgr employee)
	  (employee-id employee)))

; returns an employee object, climbing the corporate ladder as necessary
(define (employee-manager emp)
  (get-employee (employee-mgr emp)))

(define (employee-all-managers emp)
  (if (autarch? emp) '()
      (cons (employee-manager emp)
	    (employee-all-managers (employee-manager emp)))))

(define (employee-manager-lazy emp)
  (employee-present? (employee-mgr emp)))

;;; play with department titles
(define-memoized (employee-dept-title emp)
  (define string (callup-string (string-append (callup-location-arg) "-h -c name -T =" (employee-id emp))))
  (string-trim (substring string 46 (string-length string))))

  
(define (dept-test)
  (map-hashtable (lambda (id emp) 
		   (if #t ; (employee-is-mgr? emp)
		       (print `(,(employee-name emp)
				,(string-trim (employee-dept-title emp))))))
		 (get-employee ':hashtable)))

; ok, here's a theory: dept names percolate up to the first *** NOT AVAILABLE ***. But when and where to do this?
