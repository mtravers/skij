;;; This file is part of Skij.
;;; Author: Michael Travers (mt@watson.ibm.com)

;;; Licensed Materials - See the file license.txt.
;;; (c) Copyright IBM Corp. 1997, 1998. All rights reserved.

;;; Note: this doesn't take any account of threads. robably a tracer should be
;;; specific to the thread it was created in, or something.
;;; also, it was written before I had macros. probably could use a redesign.
;;; see also dynamic-wind and dynamic variables...
;;; updating trees on the fly is kind of slow. perhaps we want a record and show mode...sigh.
;;; also, link to inspector from tree

(define trace-stack '((top)))

(define (traceprint msg)
  (setf (cdr (last-pair (car trace-stack))) (list msg)))

(define (tracein msg)
  (define new (list msg))
  (traceprint new)
  (push new trace-stack)
  new)

(define (traceout msg)
  (traceprint msg)
  (pop trace-stack))

(define (traced-proc procedure name)
  (define encapsulated (trace-encapsulate procedure))
  (lambda args
    (if (eq? (car args) 'magic-restore-argument)
	(eval `(set! ,name procedure))
	(apply encapsulated args))))

(define (trace-encapsulate procedure)
  (lambda args
    (define node (tracein `(Entering ,procedure with ,args)))
    (define result (apply procedure args))
    (traceout `(Exit with ,result))
    result))

;;; +++ not called in ptrace
(define (settrace procname)
  (set! saved-procs (cons (list procname (eval procname)) saved-procs))
  (eval `(set! ,procname
	       (traced-proc (eval procname) procname))))


;;; new, for use with internal procedures in code
(defmacro (ptrace procname)
  `(set! ,procname
	 (trace-encapsulate ,procname)))

; +++ not working
(define (unptrace procname)
  (restore-original procname))

; +++ this should be a hashtable

(define saved-procs '())

(define (save-original procname)
  (set! saved-procs
	(cons `(,procname ,(eval procname))
	      saved-procs)))

(define (restore-original procname)
  (eval `(set! ,procname
	       (cadr (assq procname saved-procs)))))

(define (untrace-all)
  (for-each (lambda (entry)
	      (restore-original (car entry)))
	    saved-procs))