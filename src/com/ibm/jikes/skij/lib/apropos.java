package com.ibm.jikes.skij.lib;
class apropos extends SchemeLibrary {
  static {
    evalStringSafe("(define (apropos str) (set! str (to-string str)) (for-bindings (lambda (var) (when (>= (invoke (symbol->string var) 'indexOf str) 0) (newline) (display var) (awhen (where-is var) (display \" \") (display (list it))))) (global-environment)))");
    evalStringSafe("(define (for-bindings proc environment) (invoke environment 'forBindings proc))");
    evalStringSafe("(define (where-is symbol) (acond ((%or-null (invoke-static 'com.ibm.jikes.skij.TopEnvironment 'getAutoLoad symbol) #f) it) ((instanceof (eval symbol) 'com.ibm.jikes.skij.PrimProcedure) \"primitive\") (#t #f)))");
  }
}