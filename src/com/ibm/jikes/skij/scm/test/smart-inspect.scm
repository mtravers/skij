(require 'inspect)

(define plain-font (new 'java.awt.Font "Dialog" (peek-static 'java.awt.Font 'PLAIN) 12))
(define bold-font (new 'java.awt.Font "Dialog" (peek-static 'java.awt.Font 'BOLD) 12))

; this works, but for some reason the spacing before the text is lost.
;  this happens even if the procedure given to SkijCellRenderer is a no-op.
(define (hack-table table)
  (define nr (new (class-named (swing-class 'table.DefaultTableCellRenderer))
		  (lambda (table value row column component)
		    (invoke component
			    'setFont
			    (if (string-search (string value) 97 0)
				bold-font
				plain-font)))))
  (invoke table 'setDefaultRenderer (class-named 'java.lang.Object) nr))


(define (walk-components func from)
  (func from)
  (for-each (lambda (comp)
	      (walk-components func comp))
	    (vector->list (invoke from 'getComponents))))

(define (inspector-table inspector)
  (define result #f)
  (walk-components 
   (lambda (comp)
     (if (instanceof comp 'com.sun.java.swing.JTable)
	 (set! result comp)))
   inspector)
  result)


;;; history taker

(define *history* '())

(defstruct ievent time type params)

(define (record-event type . params)
  (print `(event: ,type ,@params))
  (push (make-ievent (now) type params)
	*history*)
  (update-interesting))

;;; event types
;; obviously important
; inspect an object
; inspect a field
;; maybe important
; select a field
; close an inspector
; select/deselect inspector window
; refresh

(define original-inspect inspect)

(define (inspect obj)
  (define window (original-inspect obj))
  (define table (inspector-table window))
  (record-event 'inspect-obj obj)
  (instrument-table table obj)
  (setup-table-simple table)
  (instrument-window window obj)
  window)
  
; redefined from inspect.scm      
(define (jump from link to)
  (record-event 'jump from link to)
  (in-own-thread (inspect to)))


; this sure is labyrthine plumbing.
(define (instrument-table table obj)
  (define listener
    (new 'com.ibm.jikes.skij.misc.GenericSwingCallback
	 (lambda (evt) 
	   (define row (invoke evt 'getFirstIndex))
	   (define model (invoke table 'getModel))
	   (record-event 'row-select obj 
			 (invoke model 'getValueAt row 0)
			 (invoke model 'getValueAt row 1)))))
  (define selection-model (invoke table 'getSelectionModel))
  (invoke selection-model 'addListSelectionListener listener))

			
(define (instrument-window window obj)
  (define listener 
    (new 'com.ibm.jikes.skij.misc.GenericSwingCallback
	 (lambda (evt) 
	   (define type (invoke evt 'getID))
	   (record-event 
	    (cond ((= type window-activate-event-id)
		   'window-select)
		  ((= type window-closing-event-id)
		   'window-close)
		  (#t 'window-deselect))
	    obj))))
  (invoke window 'addWindowListener listener))

(define (labelled-link table)
  (define model (invoke table 'getModel))
  (define row (invoke table 'getSelectedRow))
  (list (invoke model 'getValueAt row 0)
	(invoke model 'getValueAt row 1)))


;;; simple highlighter
(define *interesting-classes* '())

; proc returns #t to embolden
(define (setup-table table proc)
  (define nr (new 'com.ibm.jikes.skij.misc.SkijCellRenderer
		  (lambda (table value row column component)
		    (invoke component
			    'setFont
			    (if (proc value row column)
				bold-font
				plain-font)))))
  (invoke table 'setDefaultRenderer (class-named 'java.lang.Object) nr))


(define (setup-table-simple table)
  (setup-table 
   table
   (lambda (value row column)
     (and (= column 1)
	  (interesting? (deadapt value))))))

(define (interesting? value)
  (call-with-current-continuation 
   (lambda (k)
     (for-each (lambda (class) (if (instanceof value class)
				    (k #t)))
	       *interesting-classes*)
     (k #f))))
	       
; all classes mentioned in event history (arrays are not handled especially well)
(define (extract-classes)
  (define result '())
  (for-each 
   (lambda (event)
     (for-each 
      (lambda (param)
	(pushnew (class-of param) result))
      (ievent-params event)))
   *history*)
  result)

(define (sorted-classes)
  (define results (make-hashtable))
  (for-each 
   (lambda (event)
     (for-each 
      (lambda (param)
	(incf (hashtable-get results (class-of param) 0)))
      (ievent-params event)))
   *history*)
  (set! results (hashtable-contents results))
  (sort results (lambda (a b) (> (cdr a) (cdr b)))))

(define (update-interesting)
  (set! *interesting-classes* (extract-classes)))
	