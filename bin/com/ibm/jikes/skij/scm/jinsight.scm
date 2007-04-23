;;; This code lets Skij control JInsight, giving you 
;;; finer control of tracing.
;;;
;;; Instructions:
;;; 1) Run Skij in Jinsight's instrumented VM (with tracing off initially):
;;;      jinsight_trace.bat com.ibm.jikes.skij.Scheme
;;; 2) Load this file:
;;;     (load ".../jinsight.scm")
;;; 3) Do what you need to set up your application. To trace something:
;;;     (with-tracing ...)
;;;    for example, to trace a single method call:
;;;     (with-tracing (invoke parser 'parse "foo.xml"))
;;; 4) Exit Skij:
;;;     (exit)
;;; 5) View the trace file normally.

(require-resource 'lib/runtime.scm)	;force *runtime* to be bound

(defmacro (with-tracing . body)
  `(dynamic-wind (lambda ()
		   (invoke *runtime* 'traceMethodCalls #t))
		 (lambda () ,@body)
		 (lambda ()
		   (invoke *runtime* 'traceMethodCalls #f))))


