;;; Patches to Skij Lib code
;;; see also new defstruct.scm, which has some inspector additions

(require 'lists)			;must load first 
(define (position elt lst . optional)
  (let ((test (or (car optional) eq?)))
    (call/cc 
     (lambda (break)
       (do ((rest lst (cdr rest))
	    (i 0 (+ 1 i)))
	   ((null? rest) #f)
	 (if (test elt (car rest))
	     (break i)))))))

;;; new for lists.scm
(define (find elt lst . optional)
  (let ((test (or (car optional) eq?)))
    (call/cc 
     (lambda (break)
       (do ((rest lst (cdr rest)))
	   ((null? rest) #f)
	 (if (test elt (car rest))
	     (break (car rest))))))))
       
(require 'setf)
(defmacro (decf place . amt)
  (set! amt (if (null? amt) 1 (car amt)))
  `(setf ,place (- ,place ,amt)))

;;; addition for windows.scm
(define (all-windows)
  (vector->list (invoke-static 'java.awt.Frame 'getFrames)))

;;; Memoization

(define (clear-memoization proc)
  (clear-hashtable (proc ':hashtable)))

;;;
;;; dotimes and fortimes

(defmacro (dotimes var-until . body)
  `(for-times (lambda (,(car var-until)) ,@body)
	      ,(cadr var-until)))

(define (for-times proc n)
  (letrec ((pproc (lambda (nn)
		    (unless (= nn n)
			    (proc nn)
			    (pproc (+ nn 1))))))
    (pproc 0)))
