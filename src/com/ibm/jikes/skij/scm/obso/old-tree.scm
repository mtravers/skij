(define node-class '"com.roguewave.widgets.tree.v3_0b2.TextAndImageNode")
(define tree-class '"com.roguewave.widgets.tree.v3_0b2.TreeControl")

(define (make-tree-window title)
  (define w  (make-window title 400 400))
  (define p (new 'java.awt.Panel))
  (invoke p 'setLayout (new 'java.awt.GridLayout 1 1))
  (invoke w 'add p)
  (define tree (new tree-class))
  (invoke p 'add tree)
  (invoke w 'setVisible #t)
  tree)

(define (node? n)
  (instanceof n node-class))

(define (set-root tree node)
  (if (node? node) #f			;for compatibility
      (set! node (make-node node)))
  (invoke tree 'setRootNode node))

(define (add-child node child)
  (if (node? child) #f
      (set! child (make-node child)))
  (invoke node 'addChildNode child)
  child)

(require 'string)

(define (make-node thing)
  (new node-class (display-to-string thing)))

(define (node-parent node)
  (invoke node 'getParentNode))

(define (set-open node open?)
  (invoke node 'setOpen open?))





