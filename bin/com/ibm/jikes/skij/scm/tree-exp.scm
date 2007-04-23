(define (treetest)
  (define tree (new 'com.sun.java.swing.JTree))
  (define panel (new 'com.sun.java.swing.JPanel))
  (invoke panel 'setLayout (new 'java.awt.GridLayout 1 1))
  (invoke panel 'add tree)
  (make-window 'SampleTree panel))

(define (treetest1)
  (define top (new 'com.sun.java.swing.tree.DefaultMutableTreeNode 'top))
  (define child (new 'com.sun.java.swing.tree.DefaultMutableTreeNode 'child))
  (invoke top 'add child)
  (define tree (new 'com.sun.java.swing.JTree top))
  (set! bar tree)
  (define panel (new 'com.sun.java.swing.JPanel))
  (invoke panel 'setLayout (new 'java.awt.GridLayout 1 1))
  (invoke panel 'add tree)
  (make-window 'SampleTree panel)
  top)

(define (add-child tree parent val)
  (define child (new 'com.sun.java.swing.tree.DefaultMutableTreeNode val))
  (invoke parent 'add child)
  (invoke (invoke tree 'getModel) 'reload)
  child)


;;; try this version... no not good
(define (add-child tree parent val index)
  (define child (new 'com.sun.java.swing.tree.DefaultMutableTreeNode val))
  (invoke (invoke tree 'getModel) 'insertNodeInto parent child index)
  child)

; this doesn't seem to be necessary ....
(define (frob tree)
  (define model (invoke tree 'getModel))
  (define ui (invoke tree 'getUI))
  (invoke model 'addTreeModelListener ui))

;;;
(define (chart-components from)
  (generate-tree from (lambda (comp) (vector->list (invoke comp 'getComponents)))
		 (lambda (x) (string x))))