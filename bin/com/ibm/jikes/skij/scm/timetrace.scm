(require 'trace)
(require 'time)

; load some stuff over trace.scm to keep track of time
; status: crude
; big problem is that node creation is really slow, so numbers are skewed. Sigh.
; the slowness seems proportional to the size of the tree, too.
; ok, so we have to store the info elsewhere and build the tree after-the-fact

(define (tracein tracer msg)
  (define nnode (add-child (cadr tracer) msg))
  (set-start-time nnode (now))
  (set-current-node tracer nnode)
  nnode)

(define (traceout node msg)
  (if node '() 
      (set! node (cadr tracer)))
  (set-end-time node (now))
  (set-current-node tracer (node-parent node))
  (traceprint tracer msg))

(define (trace-extend node msg)
  (invoke node 'setText (string-append (invoke node 'getText) msg)))

;;; this is a lousy implementation

(require 'hashtable)
(define *time-ht* (make-hashtable))

(define (set-start-time node time)
  (hashtable-put *time-ht* node time))

(define (set-end-time node time)
  (trace-extend node
		(string-append '" (" 
			       (invoke (- time (hashtable-get *time-ht* node #f)) 'toString)
			       '" msec)")))

;;; new version

