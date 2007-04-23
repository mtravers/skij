package com.ibm.jikes.skij.lib;
class tree extends SchemeLibrary {
  static {
    evalStringSafe("(define node-class '#,(swing-class 'tree.DefaultMutableTreeNode))");
    evalStringSafe("(define (make-tree-window title top) (define tree (make-tree top)) (define panel (make-tree-panel tree)) (make-swing-window-for-panel title panel) tree)");
    evalStringSafe("(define (make-tree-panel tree) (define panel (new '#,(swing-class 'JPanel))) (invoke panel 'setLayout (new 'java.awt.GridLayout 1 1)) (define scroller (new '#,(swing-class 'JScrollPane))) (invoke (invoke scroller 'getViewport) 'add tree) (invoke panel 'add scroller) panel)");
    evalStringSafe("(define (make-tree top) (if (not top) (set! top (new node-class 'top))) (new '#,(swing-class 'JTree) top))");
    evalStringSafe("(define (node? n) (instanceof n '#,(class-named node-class)))");
    evalStringSafe("(define (make-node thing) (new node-class thing))");
    evalStringSafe("(define (coerce-node thing) (if (node? thing) thing (make-node thing)))");
    evalStringSafe("(define (set-root tree thing) (if (node? thing) (error '\"can\\'t set root of tree to new node\")) (invoke (root-node tree) 'setUserObject thing) (root-node tree))");
    evalStringSafe("(define (root-node tree) (invoke (invoke tree 'getModel) 'getRoot))");
    evalStringSafe("(define (add-child tree node child) (define nchild #f) (synchronized tree (set! nchild (coerce-node child)) (invoke node 'add nchild)) (if tree (invoke (invoke tree 'getModel) 'reload)) nchild)");
    evalStringSafe("(define (node-parent node) (invoke node 'getParent))");
    evalStringSafe("(define (set-open tree node open?) (define path (new '#,(swing-class 'tree.TreePath) (invoke node 'getPath))) (invoke tree (if open? 'expandPath 'collapsePath) path))");
    evalStringSafe("(define (generate-tree root child-generator node-content-generator) (define (generate-tree-1 item) (define node (make-node (node-content-generator item))) (for-each (lambda (child) (add-child #f node (generate-tree-1 child))) (child-generator item)) node) (generate-tree-1 root))");
    evalStringSafe("(define (make-adaptor name contents) (define a (new 'com.ibm.jikes.skij.misc.Adaptor contents)) (invoke a 'addBinding 'toString (lambda () name)) a)");
    evalStringSafe("(define (tree-add-mouse-listener tree proc) (define listener (new 'com.ibm.jikes.skij.misc.GenericCallback (lambda (evt) (if (and (eq? tree (invoke evt 'getComponent)) (= (invoke evt 'getID) #,(peek-static 'java.awt.event.MouseEvent 'MOUSE_CLICKED))) (begin (define path (%or-null (invoke tree 'getPathForLocation (invoke evt 'getX) (invoke evt 'getY)) #f)) (awhen path (define node (invoke path 'getLastPathComponent)) (proc node evt))))))) (invoke tree 'addMouseListener listener) listener)");
  }
}