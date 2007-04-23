package com.ibm.jikes.skij.lib;
class setf extends SchemeLibrary {
  static {
    evalStringSafe("(define setf-ht (make-hashtable))");
    evalStringSafe("(defmacro (def-setf form val body) `(hashtable-put setf-ht ',(car form) (lambda ,(cons val form) ,body)))");
    evalStringSafe("(defmacro (setf place value) (cond ((symbol? place) `(set! ,place ,value)) ((pair? place) (let ((proc (hashtable-get setf-ht (car place) #f))) (if proc (apply proc value place) (error `(cant setf ,place))))) (#t (error `(cant setf ,place)))))");
    evalStringSafe("(def-setf (vector-ref var index) val `(vector-set! ,var ,index ,val))");
    evalStringSafe("(defmacro (push thing place) `(setf ,place (cons ,thing ,place)))");
    evalStringSafe("(defmacro (pushnew thing place) `(if (memq ,thing ,place) #f (setf ,place (cons ,thing ,place))))");
    evalStringSafe("(defmacro (pop place) `(let ((result (car ,place))) (setf ,place (cdr ,place)) result))");
    evalStringSafe("(defmacro (deletef thing place) `(setf ,place (delete ,thing ,place)))");
    evalStringSafe("(defmacro (incf place . amt) (set! amt (if (null? amt) 1 (car amt))) `(setf ,place (+ ,amt ,place)))");
    evalStringSafe("(defmacro (decf place . amt) (set! amt (if (null? amt) 1 (car amt))) `(setf ,place (- ,amt ,place)))");
    evalStringSafe("(def-setf (hashtable-get ht key default) val `(hashtable-put ,ht ,key ,val))");
    evalStringSafe("(def-setf (car place) val `(set-car! ,place ,val))");
    evalStringSafe("(def-setf (cdr place) val `(set-cdr! ,place ,val))");
  }
}