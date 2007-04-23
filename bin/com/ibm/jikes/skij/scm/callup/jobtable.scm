(log-event '(reading jobs))
; defines *jobs*
; +++ takes 6 minutes to read this file on AIX, too long!
; +++ even longer on windoze
; +++ delays startup of server too...
(load-resource 'scm/callup/research-jobs.scm)

(define (search-jobs str)
  (set! str (invoke str 'toLowerCase))
  (let ((results '()))
    (for-each 
     (lambda (entry)
       (if (not (negative? (invoke (vector-ref entry 1) 'indexOf str)))
	   (push entry results)))
     *jobs*)
    results))

; this is interface used by rest of callup system
(define (get-employees-by-job topic)
  (let ((entries (search-jobs topic)))
    (map (lambda (entry)
	   (get-employee (vector-ref entry 0)))
	 entries)))