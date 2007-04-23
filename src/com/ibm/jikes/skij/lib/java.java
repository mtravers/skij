package com.ibm.jikes.skij.lib;
class java extends SchemeLibrary {
  static {
    evalStringSafe("(defmacro (%or-null . clauses) (if (null? clauses) '(%null) `(let ((temp ,(car clauses))) (if (%%null? temp) (%or-null ,@(cdr clauses)) temp))))");
    evalStringSafe("(defmacro (catch . body) `(%catch (lambda () ,@body)))");
    evalStringSafe("(define (error msg) (throw msg))");
    evalStringSafe("(define (map-enumeration func enum) (class-named 'com.ibm.jikes.skij.misc.Hashpatch) (map-enumeration func enum))");
    evalStringSafe("(define (for-enumeration func enum) (class-named 'com.ibm.jikes.skij.misc.Hashpatch) (for-enumeration func enum))");
    evalStringSafe("(define (enumeration->list enum) (let ((lst '())) (for-enumeration (lambda (x) (push x lst)) enum) (reverse lst)))");
    evalStringSafe("(define (exit) (invoke-static 'java.lang.System 'exit 0))");
    evalStringSafe("(define (start-application class . args) (if (not (instanceof class 'java.lang.Class)) (set! class (class-named class))) (let ((arg-vector (%make-vector (length args) (class-named 'java.lang.String)))) (%fill-vector arg-vector args) (invoke-static class 'main arg-vector)))");
    evalStringSafe("(defmacro (ignore-errors . body) `(catch ,@body))");
    evalStringSafe("(defmacro (ignore-errors-and-warn . body) `(let ((result (catch ,@body #f))) (if (instanceof result 'java.lang.Throwable) (begin (display \"\\nIgnoring exception: \") (display (invoke result 'getMessage)))) result))");
    evalStringSafe("(define (get-method obj mname . args) (invoke-static 'com.ibm.jikes.skij.util.Invoke 'getMethod obj (string mname) (invoke-static 'com.ibm.jikes.skij.PrimProcedure 'makeArray args)))");
    evalStringSafe("(define (coerce-class thing) (cond ((instanceof thing 'java.lang.Class) thing) ((symbol? thing) (class-named thing)) (#t (class-of thing))))");
    evalStringSafe("(define (method-apropos class mname) (set! mname (to-string mname)) (for-vector (lambda (method) (if (>= (invoke (invoke method 'getName) 'indexOf mname) 0) (print method))) (invoke (coerce-class class) 'getMethods)))");
    evalStringSafe("(define (backtrace-inspect . exception) (set! exception (if (null? exception) (peek-static 'com.ibm.jikes.skij.SchemeException 'lastForUser) (car exception))) (inspect (reverse (peek exception 'backtrace))))");
    evalStringSafe("(define (java-backtrace . exception) (set! exception (if (null? exception) (peek-static 'com.ibm.jikes.skij.SchemeException 'lastForUser) (car exception))) (invoke (peek exception 'encapsulated) 'printStackTrace))");
    evalStringSafe("(define (trace on?) (invoke-static 'com.ibm.jikes.skij.util.Tracer 'setOn on?))");
  }
}