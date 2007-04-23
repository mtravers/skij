package com.ibm.jikes.skij.lib;
class menu extends SchemeLibrary {
  static {
    evalStringSafe("(define (make-popup-menu menu-items) (define menu (new 'java.awt.PopupMenu)) (for-each (lambda (menu-item) (invoke menu 'add menu-item)) menu-items) menu)");
    evalStringSafe("(define (make-menu title menu-items . keys) (key keys enabled? #t) (key keys bold? #f) (define menu (new 'java.awt.Menu title)) (for-each (lambda (menu-item) (invoke menu 'add menu-item)) menu-items) (set-menu-item-properties menu enabled? bold?) menu)");
    evalStringSafe("(define (display-popup-menu menu component x y) (invoke (invoke component 'getParent) 'add menu) (invoke menu 'show component x y))");
    evalStringSafe("(define (make-menu-item title . keys) (key keys procedure #f) (key keys enabled? #t) (key keys bold? #f) (define menu-item (new 'java.awt.MenuItem title)) (if procedure (invoke menu-item 'addActionListener (new 'com.ibm.jikes.skij.misc.GenericCallback procedure))) (set-menu-item-properties menu-item enabled? bold?) menu-item)");
    evalStringSafe("(define (set-menu-item-properties menu-item enabled? bold?) (invoke menu-item 'setEnabled enabled?) (if bold? (invoke menu-item 'setFont (make-font (invoke menu-item 'getFont) #f (peek-static 'java.awt.Font 'BOLD) #f))))");
    evalStringSafe("(define (make-font from-font name style size) (new 'java.awt.Font (or name (invoke from-font 'getName)) (or style (invoke from-font 'getStyle)) (or size (invoke from-font 'getSize))))");
  }
}