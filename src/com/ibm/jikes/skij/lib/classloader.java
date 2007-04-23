package com.ibm.jikes.skij.lib;
class classloader extends SchemeLibrary {
  static {
    evalStringSafe("(define (make-class-loader . path-entries) (let ((loader (new 'com.ibm.jikes.skij.util.ExtendableClassLoader))) (map (lambda (path-entry) (invoke loader 'addClassPath path-entry)) path-entries) loader))");
    evalStringSafe("(define (cl-class-named cl class-name) (invoke cl 'loadClass (string class-name)))");
    evalStringSafe("(define (class-from-paths class-name . path-entries) (cl-class-named (apply make-class-loader path-entries) class-name))");
    evalStringSafe("(define (new-cl cl name . args) (apply new (cl-class-named cl name) args))");
  }
}