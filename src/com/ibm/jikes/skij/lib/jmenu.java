package com.ibm.jikes.skij.lib;
class jmenu extends SchemeLibrary {
  static {
    evalStringSafe("(define (make-jpopup-menu menu-items) (define menu (new 'com.sun.java.swing.JPopupMenu)) (for-each (lambda (menu-item) (invoke menu 'add menu-item)) menu-items) menu)");
    evalStringSafe("(define (display-jpopup-menu menu component x y) (invoke menu 'show component x y))");
    evalStringSafe("(define (make-jmenu-item title . keys) (key keys procedure #f) (key keys enabled? #t) (key keys bold? #f) (define menu-item (new 'com.sun.java.swing.JMenuItem title)) (if procedure (invoke menu-item 'addActionListener (new 'com.ibm.jikes.skij.misc.GenericCallback procedure))) (invoke menu-item 'setEnabled enabled?) (if bold? (invoke menu-item 'setFont (make-font (invoke menu-item 'getFont) #f (peek-static 'java.awt.Font 'BOLD) #f))) menu-item)");
    evalStringSafe("(define (make-font from-font name style size) (new 'java.awt.Font (or name (invoke from-font 'getName)) (or style (invoke from-font 'getStyle)) (or size (invoke from-font 'getSize))))");
  }
}