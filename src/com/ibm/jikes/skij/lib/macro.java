package com.ibm.jikes.skij.lib;
class macro extends SchemeLibrary {
  static {
    evalStringSafe("(define defmacro (new 'com.ibm.jikes.skij.Macro (current-environment) 'defmacro '(ignore name args . body) '(begin (if (symbol? name) '() (begin (set! body (cons args body)) (set! args (cdr name)) (set! name (car name)))) `(define ,name (new 'com.ibm.jikes.skij.Macro (current-environment) ',name ',(cons 'ignore args) '(begin ,@body))))))");
    evalStringSafe("(define (macroexpand form) (if (instanceof (eval (car form)) 'com.ibm.jikes.skij.Macro) (apply (eval (car form)) form) form))");
    evalStringSafe("(define macro (new 'com.ibm.jikes.skij.Macro (current-environment) 'macro '(ignore args . body) ''`(new 'com.ibm.jikes.skij.Macro (current-environment) '<anon-macro> ',(cons 'ignore args) '(begin ,@body))))");
  }
}