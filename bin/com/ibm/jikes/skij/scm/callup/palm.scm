;;; Generate an import file for palm

;;; +++
;;; web page documentation
;;; location/address not getting through
;;; category (business) not getting through
;;;   starting/stopping with dummy entries?

(define (split-name name)
  (let ((comma-pos (invoke name 'indexOf (char->int #\,))))
    (if comma-pos
	(list (substring name 0 comma-pos)
	      (substring name (+ 2 comma-pos) (string-length name)))
	(list name ""))))

(define (emp-fields emp fields)
  (callup-fields fields (string-append "=" (employee-id emp))))

; not really PROGV, vars are fixed at "compile" time
(defmacro (progv vars vals . body)
  `(apply (lambda ,vars ,@body) ,vals))

(defmacro (field-bind emp fields . body)
  `(let ((%fields (emp-fields ,emp ',fields)))
     (progv ,fields %fields
	    ,@body)))
	
(define (write-emp-palm-line emp out)
  (define names (split-name (employee-name emp)))
  (field-bind emp (tie faxtie mailid bldg office)
    (for-each 
     (lambda (fieldv)
       (display fieldv out)
       (write-char (int->char 9) out))
     (list
      (car names)
       (cadr names)
       (employee-job emp)
       "IBM"
       (string-append "t/l " tie)
       ""
       faxtie
       ""
       mailid
       (string-append bldg "/" office)
       ""
       ""
       ""
       ""
       ""
       ""
       ""
       ""
       ""
       ""
       "Business")))
  (newline out))

(define (write-dept-palm-lines mgr out)
  (for-each (lambda (emp)
	      (write-emp-palm-line emp out))
	    (cons mgr (all-subordinates mgr))))

;;; WebSpect interface


;;; Revised version, use regular callup-tree to marshal names
(define-command palm-transfer (uid)
  (wsdoc "Callup->WorkPad"
	 (html-output "This page lets you import callup data into a IBM WorkPad or Palm Pilot. The mechanism relies on the WorkPad Desktop software (Windows version) supplied with the WorkPad; if you use some other synchronization software you may have to revise the process.")

	 (ltag p)
	 (html-output "Here's how to use it:")
	 (env ol
	      (ltag li)
	      (html-output "Click on the link below.")
	      (ltag li)
	      (html-output "You'll have to wait a bit; quite a long bit if you have a lot of people to process.")
	      (ltag li)
	      (html-output "Eventually another browser window will come up with a page of ugly-looking text.  Save this page in a file using your browser's <b>Save As...</b> command.")
	      (ltag li)
	      (html-output "Start the WorkPad Desktop application and select the Address Book.")
	      (ltag li)
	      (html-output "Select the <b>Import...</b> command from the File menu.")
	      (ltag li)
	      (html-output "You'll see a file dialog. Select <b>Tab Separated Values</b> from the popup menu, and choose the file you saved earlier.")
	      (ltag li)
	      (html-output "You'll see a dialog box called <b>Specify Import Fields</b>. Click the <b>Reset</b> button, then the <b>OK</b> button.")
	      (ltag li)
	      (html-output "Synchronize your WorkPad to download the data."))

	 (ltag p)
	 (with-env 'a `((href ,(make-webspect-url 'callup-import.txt (list 'uid uid)))
			(target "callup-data"))
		   (lambda () 
		     (html-output "Click here to generate the import file")))))

(define-command callup-import.txt (uid)
  (let* ((page (uid-page uid))
	 (emps (flatten-page page))
	 (out (dynamic *html-port*)))
    (for-each (lambda (emp)
		(write-emp-palm-line emp out))
	      emps)))

(define (flatten-page page)
  (letrec ((result '())
	   (record (lambda (emp) (push emp result)))
	   (flatten-tree 
	    (lambda (tree)
	      (record (car tree))
	      (for-each (lambda (subtree)
			  (flatten-tree subtree))
			(cdr tree)))))
    (for-each (lambda (tree)
		(flatten-tree tree))
	      (cdr page))
    result))
		
  

      