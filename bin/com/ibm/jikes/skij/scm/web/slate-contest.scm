; todos
; limit reading to html files! 
; heuristics to get off site:
;  look for shorter URLS (more likely to be home)

(load-resource 'scm/web/web-walker.scm)
(load-resource 'scm/web/html-parser.scm)

(define start-node #f)
(define end-node #f)

(define (set-start url)
  (set! start-node (intern-url url))
  (set-webnode-distance! start-node 0))

(define (set-end url)
  (set! end-node (intern-url url))
  (set-webnode-distance! end-node 0))

(define (fringe)
  (filter-out webnode-links-out
	      (map-hashtable (lambda (key val) val) (intern-url ':hashtable))))


(define (random-element list)
  (list-ref list (random (length list))))


(define (search)
  (loop 
   (catch (explore-out (random-element (fringe))))))

(define (search-from url)
  (define cstart (intern-url url))
  (set-webnode-distance! cstart 0)
  (loop (explore-out (random-element (fringe)))))

(define (display-search)
  (define done (make-hashtable))
  (make-tree-window 
   '"Search Me!"
   (generate-tree (list start-node 'Top)
		  (lambda (link)
		    (define webnode (car link))
		    (if (hashtable-get done webnode) '()
			(begin
			  (hashtable-put done webnode 'done)
			  (or (webnode-links-out webnode) '()))))
		  (lambda (link)
		    (string-append (webnode-url (car link))
				   '"  []   "
				   (cadr link))))))


(define (print-search)
  (define done '())
  (letrec ((print-node 
	    (lambda (link level)
	      (define webnode (car link))
	      (if (memq webnode done) '()
		  (begin
		    (newline)
		    (repeat level (display '" "))
		    (display (webnode-url webnode))
		    (display '"  []   ")
		    (display (cadr link))
		    (push webnode done)
		    (for-each (lambda (x) (print-node x (+ level 1)))
			      (or (webnode-links-out webnode) '())))))))
    (print-node (list start-node 'top) 0)))
			 
	   
	   

	   generate-tree (list start-node 'Top)
		  (lambda (link)
)
		  (lambda (link)
)))  


(define (explore-in-recursive node)
  (map explore-in-recursive
       (explore-in node)))
	

      
