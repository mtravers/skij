;;; add-on fading for object-graph

;;; to use as history-thing: 
; fade automatically 
; color must be restored if node is re-accessed.
; fade lines and labels as well
; eventually delete things that fade to gray?
; un-fading should be transitive; that is, linked-to objects should partially unfade

(define (fade-test c0 c1)
  (define alpha 0.0)
  (color-test (lambda () 
		(let ((res (blend-colors c0 c1 alpha)))
		  (set! alpha (+ alpha .1))
		  res))))

(define (fade-node node)
  (invoke *object-graph* 'setNodeColor node 
	  (blend-colors (invoke *object-graph* 'getNodeColor node)
			background-color
			.9)))

(define (unfade node)
  (invoke *object-graph* 'setNodeColor node (object-color (node-ob node))))

(define (fade-all-nodes)
  (for-each fade-node (all-nodes))
  (invoke *object-graph* 'repaint))

(define (all-nodes)
  (define result '())
  (map-hashtable (lambda (ob node) 
		   (push node result))
		 (ob-node ':hashtable))
  result)

(define (blend-colors c0 c1 alpha)
  (define (blend-component component-name)
    (integer (+ (* (invoke c0 component-name) alpha)
		(* (invoke c1 component-name) (- 1 alpha)))))
  (new 'java.awt.Color
       (blend-component 'getRed)
       (blend-component 'getGreen)
       (blend-component 'getBlue)))

