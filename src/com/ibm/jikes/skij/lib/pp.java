package com.ibm.jikes.skij.lib;
class pp extends SchemeLibrary {
  static {
    evalStringSafe("(define (pp obj) (generic-write obj #f 80 display))");
    evalStringSafe("(define (ppp proc) (pp (proc-form proc)))");
    evalStringSafe("(define (proc-form proc) (define (defform proc macro) (cons (%or-null (peek proc 'name) \"[unnamed]\") (if macro (cdr (peek proc 'args)) (peek proc 'args)))) (cond ((instanceof proc 'com.ibm.jikes.skij.Macro) `(defmacro ,(defform proc #t) ,@(proc-body proc))) ((instanceof proc 'com.ibm.jikes.skij.CompoundProcedure) `(define ,(defform proc #f) ,@(proc-body proc))) (#t proc)))");
    evalStringSafe("(define-memoized (proc-body proc) (let ((body (unmacro (peek proc 'body)))) (if (eq? (car body) 'begin) (cdr body) body)))");
    evalStringSafe("(define (process-tree tree func) (define new (map func tree)) (if (equal? new tree) tree new))");
    evalStringSafe("(define (unmacro item) (cond ((not (pair? item)) item) ((and (eq? (car item) 'begin) (pair? (cadr item)) (eq? (car (cadr item)) 'quote) (eq? (cadr (cadr item)) '%%macro-source)) (unmacro (caddr (cadr item)))) (#t (process-tree item unmacro))))");
    evalStringSafe("(define (generic-write obj display? width output) (define (read-macro? l) (define (length1? l) (and (pair? l) (null? (cdr l)))) (let ((head (car l)) (tail (cdr l))) (case head ('quasiquote #t) (else #f)))) (define (read-macro-body l) (cadr l)) (define (read-macro-prefix l) (let ((head (car l)) (tail (cdr l))) (case head ((quote) '\"\\'\") ((quasiquote) '\"`\") ((unquote) '\",\") ((unquote-splicing) '\",@\")))) (define (out str col) (and col (output str) (+ col (string-length str)))) (define (wr obj col) (define (wr-expr expr col) (if (read-macro? expr) (wr (read-macro-body expr) (out (read-macro-prefix expr) col)) (wr-lst expr col))) (define (wr-lst l col) (if (pair? l) (let loopx ((l (cdr l)) (col (wr (car l) (out '\"(\" col)))) (and col (cond ((pair? l) (loopx (cdr l) (wr (car l) (out '\" \" col)))) ((null? l) (out '\")\" col)) (else (out '\")\" (wr l (out '\" . \" col))))))) (out '\"()\" col))) (cond ((pair? obj) (wr-expr obj col)) ((null? obj) (wr-lst obj col)) ((vector? obj) (wr-lst (vector->list obj) (out '\"#\" col))) ((boolean? obj) (out (if obj '\"#t\" '\"#f\") col)) ((number? obj) (out (number->string obj) col)) ((symbol? obj) (out (symbol->string obj) col)) ((procedure? obj) (out '\"#[procedure]\" col)) ((string? obj) (if display? (out obj col) (let loopx ((i 0) (j 0) (col (out '\"\\\"\" col))) (if (and col (< j (string-length obj))) (let ((c (string-ref obj j))) (if (or (char=? c #\\\\) (char=? c #\\\")) (loopx j (+ j 1) (out '\"\\\\\" (out (substring obj i j) col))) (loopx i (+ j 1) col))) (out '\"\\\"\" (out (substring obj i j) col)))))) ((char? obj) (if display? (out (make-string 1 obj) col) (out (case obj (else (make-string 1 obj))) (out '\"#\\\\\" col)))) ((input-port? obj) (out '\"#[input-port]\" col)) ((output-port? obj) (out '\"#[output-port]\" col)) ((eof-object? obj) (out '\"#[eof-object]\" col)) (else (out '\"#<\" col) (out (invoke obj 'toString) col) (out \">\" col)))) (define (pp obj col) (define (spaces n col) (if (> n 0) (if (> n 7) (spaces (- n 8) (out '\"        \" col)) (out (substring '\"        \" 0 n) col)) col)) (define (indent to col) (and col (if (< to col) (and (out \"\\n\" col) (spaces to 0)) (spaces (- to col) col)))) (define (pr obj col extra pp-pair) (if (or (pair? obj) (vector? obj)) (let ((result '()) (left (min (+ (- (- width col) extra) 1) max-expr-width))) (generic-write obj display? #f (lambda (str) (set! result (cons str result)) (set! left (- left (string-length str))) (> left 0))) (if (> left 0) (let loopx ((ncol col) (rest (reverse result))) (if (null? rest) ncol (loopx (out (car rest) ncol) (cdr rest)))) (if (pair? obj) (pp-pair obj col extra) (pp-list (vector->list obj) (out '\"#\" col) extra pp-expr)))) (wr obj col))) (define (pp-expr expr col extra) (if (read-macro? expr) (pr (read-macro-body expr) (out (read-macro-prefix expr) col) extra pp-expr) (let ((head (car expr))) (if (symbol? head) (let ((proc (style head))) (if proc (proc expr col extra) (if (> (string-length (symbol->string head)) max-call-head-width) (pp-general expr col extra #f #f #f pp-expr) (pp-call expr col extra pp-expr)))) (pp-list expr col extra pp-expr))))) (define (pp-call expr col extra pp-item) (let ((col* (wr (car expr) (out '\"(\" col)))) (and col (pp-down (cdr expr) col* (+ col* 1) extra pp-item)))) (define (pp-list l col extra pp-item) (let ((col (out '\"(\" col))) (pp-down l col col extra pp-item))) (define (pp-down l col1 col2 extra pp-item) (let loopx ((l l) (col col1)) (and col (cond ((pair? l) (let ((rest (cdr l))) (let ((extra (if (null? rest) (+ extra 1) 0))) (loopx rest (pr (car l) (indent col2 col) extra pp-item))))) ((null? l) (out '\")\" col)) (else (out '\")\" (pr l (indent col2 (out '\".\" (indent col2 col))) (+ extra 1) pp-item))))))) (define (pp-general expr col extra named? pp-1 pp-2 pp-3) (define (tail1 rest col1 col2 col3) (if (and pp-1 (pair? rest)) (let* ((val1 (car rest)) (rest (cdr rest)) (extra (if (null? rest) (+ extra 1) 0))) (tail2 rest col1 (pr val1 (indent col3 col2) extra pp-1) col3)) (tail2 rest col1 col2 col3))) (define (tail2 rest col1 col2 col3) (if (and pp-2 (pair? rest)) (let* ((val1 (car rest)) (rest (cdr rest)) (extra (if (null? rest) (+ extra 1) 0))) (tail3 rest col1 (pr val1 (indent col3 col2) extra pp-2))) (tail3 rest col1 col2))) (define (tail3 rest col1 col2) (pp-down rest col2 col1 extra pp-3)) (let* ((head (car expr)) (rest (cdr expr)) (col* (wr head (out '\"(\" col)))) (if (and named? (pair? rest)) (let* ((name (car rest)) (rest (cdr rest)) (col** (wr name (out '\" \" col*)))) (tail1 rest (+ col indent-general) col** (+ col** 1))) (tail1 rest (+ col indent-general) col* (+ col* 1))))) (define (pp-expr-list l col extra) (pp-list l col extra pp-expr)) (define (pp-lambda expr col extra) (pp-general expr col extra #f pp-expr-list #f pp-expr)) (define (pp-if expr col extra) (pp-general expr col extra #f pp-expr #f pp-expr)) (define (pp-cond expr col extra) (pp-call expr col extra pp-expr-list)) (define (pp-case expr col extra) (pp-general expr col extra #f pp-expr #f pp-expr-list)) (define (pp-and expr col extra) (pp-call expr col extra pp-expr)) (define (pp-let expr col extra) (let* ((rest (cdr expr)) (named? (and (pair? rest) (symbol? (car rest))))) (pp-general expr col extra named? pp-expr-list #f pp-expr))) (define (pp-begin expr col extra) (pp-general expr col extra #f #f #f pp-expr)) (define (pp-do expr col extra) (pp-general expr col extra #f pp-expr-list pp-expr-list pp-expr)) (define indent-general 2) (define max-call-head-width 5) (define max-expr-width 50) (define (style head) (case head ((lambda let* letrec define) pp-lambda) ((if set!) pp-if) ((cond) pp-cond) ((case) pp-case) ((and or) pp-and) ((let) pp-let) ((begin) pp-begin) ((do) pp-do) (else #f))) (pr obj col 0 pp-expr)) (if width (out \"\\n\" (pp obj 0)) (wr obj 0)))");
  }
}