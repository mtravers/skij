package com.ibm.jikes.skij.lib;
class swing extends SchemeLibrary {
  static {
    evalStringSafe("(define (class-exists? class-name) (instanceof (catch (class-named class-name)) 'java.lang.Class))");
    evalStringSafe("(define swing-package (cond ((class-exists? 'javax.swing.JFrame) 'javax.swing) ((class-exists? 'com.sun.java.swing.JFrame) 'com.sun.java.swing) ((class-exists 'java.awt.swing.JFrame) 'java.awt.swing) (else (error \"Swing classes not found\"))))");
    evalStringSafe("(define (swing-class name) (symbol-conc swing-package \".\" name))");
    evalStringSafe("(define (make-swing-window name width height) (define w (new '#,(swing-class 'JFrame) (string name))) (primp-window w width height #f) w)");
    evalStringSafe("(define (make-swing-window-for-panel name panel) (define w (new '#,(swing-class 'JFrame) (string name))) (define content-pane (invoke w 'getContentPane)) (invoke content-pane 'add panel) (invoke w 'pack) (invoke w 'show) w)");
    evalStringSafe("(define (make-swing-button name action) (define b (new '#,(swing-class 'JButton) (string name))) (define listener (new 'com.ibm.jikes.skij.misc.GenericCallback action)) (invoke b 'addActionListener listener) b)");
    evalStringSafe("(define (make-table data columns) (define data (lists->array data)) (define columns (list->vector columns)) (new '#,(swing-class 'JTable) data columns))");
    evalStringSafe("(define (make-table-panel table width height) (define panel (new '#,(swing-class 'JPanel))) (invoke table 'setPreferredScrollableViewportSize (new 'java.awt.Dimension width height)) (define scroller (invoke table 'createScrollPaneForTable table)) (invoke panel 'setLayout (new 'java.awt.GridLayout 1 1)) (invoke panel 'add scroller) panel)");
    evalStringSafe("(define (lists->array lists) (define len (length lists)) (define wid (if (null? lists) (error '\"No elements for array\") (length (car lists)))) (define array (%make-array (list len wid) (class-named 'java.lang.Object))) (define i 0) (for-each (lambda (lst) (define j 0) (for-each (lambda (elt) (aset array elt i j) (set! j (+ 1 j))) lst) (set! i (+ 1 i))) lists) array)");
    evalStringSafe("(define (containers component) (if component (cons component (containers (invoke component 'getParent))) '()))");
  }
}