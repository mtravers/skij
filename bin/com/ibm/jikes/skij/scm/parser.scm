; modelled after bottom-up parser in Norvig, PAIP

(require 'amb)

(define *syntax* '())

;; internal rhs rep: lists are terms to expand, chars or symbols are literals.
(defmacro (defsyntax name expansion . body)
  (set! expansion (map (lambda (term)
			 (cond ((character? term) term)
			       ((symbol? term) (list term term))
			       ((eq? (car term) 'quote)
				(cadr term))
			       (#t term)))
		       expansion))
  `(push '(,name ,expansion ,body) *syntax*))

(define rule-lhs car)
(define rule-rhs cadr)
(define rule-body caddr)

(define (set-syntax)
  (set! *syntax* '())

  (defsyntax command (expression)
    expression)
  (defsyntax command (word #\= expression)
    `(define ,word ,expression))

  (defsyntax vref (expression #\[ expression #\])
    (list word expression))
  (defsyntax expression (vref)
    `(vector-ref ,(car vref) ,(cadr vref)))
  (defsyntax command (vref #\= expression)
    `(vector-set! ,(car vref) ,(cadr vref) ,expression))

  (defsyntax expression ('new classname arglist)
    `(new ',classname ,@arglist))
  (defsyntax expression ((word obj) #\. (word method) arglist)
    `(invoke ,obj ',method ,@args))

  (defsyntax arglist (#\( explist #\))
    explist)

  (define explist ()
    '())
  (define explist (expression)
    (list expression))
  (define explist (expression #\, explist)
    (cons expression explist))

  (defsyntax classname (word) 
    word)
  (defsyntax classname (word #\. classname)
    (symbol-conc word #\. classname))

  (defsyntax expression (word)
    word)

  (defsyntax expression (#\( expression #\))
    expression)

  (defsyntax expression ((expression e1) #\+ (expression e2))
    `(+ ,e1 ,e2))
  (defsyntax expression ((expression e1) #\* (expression e2))
    `(* ,e1 ,e2))
  ;etc
  )

(set-syntax)

;a rhs is a list of elements which can be:
; (quote word)  for literal words
; character     for literal chars
; type
; (type name)


; a thing is either a terminal or a list meaning a partial parse, ie:
;       (expression (word foo) #\+ (word bar))


(define (rules-starting-with thing)
  (if (list? thing)
      (filter (lambda (rule)
		(let ((start (car (rule-rhs rule))))
		  (if (list? start)
		      (eq? (car start) (car thing))
		      (eq? start (car thing)))))
	      *syntax*)
      (add-terminal-rules
       thing
       (filter (lambda (rule)
		 (let ((start (car (rule-rhs rule))))
		   (eq? start thing)))
	       *syntax*))))

(define (add-terminal-rules thing rules)
  (if (or (symbol? thing) (number? thing))
      (cons (list 'word thing) rules)
      rules))

;The algorithm: start with the string of tokens, find rules that could
;include the first token. 
; For each rule, if it's complete, use its type as basis for the next level up
;      which should mean just doing a parse with the parse-tree substituted for the token
;  if it's not complete try to extend it

;IN other words: start bottom up, but when we have a rule work top-down, sort of.      


; a parse is:
;   a tree (type <word-or-parse>)
;   a rule
;   a list of unmatched parts of rule
;   a list of bindings
;   a list of leftover tokens
(defstruct parse tree rule rule-rest bindings rest)

; a partial parse has data tokens left, but no incomplete rules.
; an unfinished parse is one that's still working on its rule.

(extend-parse #((vref (word a))
		(vref ((word word) #\[ (expression expression) #\]) ((list word expression)))
		((expression expression) #\])
		(word word a)
		(3 #\] #\= b #\. foo #\( x #\+ 23 #\) #\;)))




(define (full-parse tokens)
  (start-parse-cps 
   tokens
   (lambda (parse)
     (if (null? (parse-rest parse))
	 (begin (traceprint `(success: ,parse))
		(fail "looking for more parses"))
	 (full-parse (cons (parse-tree parse) ;go up a level
			   (parse-rest parse)))))))

	 
;;; parse a complete rule, possibly leaving tokens remaining.  Does not go up.
(define (complete-parse tokens cont)
  (start-parse-cps tokens
		   (lambda (parse)
		     (extend-parse parse cont))))
  
(define (complete-parses-up tokens cont)
  

ARGH, my brain doesn't work...


; tokens may actually start with a parse tree
;;; Given a string of tokens, come up with partial parses and call cont with them
(define (start-parse-cps tokens cont)
  (let-amb rule (rules-starting-with (car tokens))
    (with-traceprint `(rule: ,rule)
     (let ((parse (make-parse (list (rule-lhs rule) (car tokens))
			      rule
			      (if (list? (rule-rhs rule))
				  (cdr (rule-rhs rule))
				  '())
			      ':bindings ;+++ need new theory of bindings, skip for now
			      (cdr tokens))))
       (set! parse (extend-parse parse cont))
       (cont parse)))))



(define (extend-parse-up-to-type parse cont)
  (if (null? (parse-rule-rest parse))
      (cont parse)
      (let ((reqd-type (car (car (parse-rule-rest parse)))))
	(start-parse-cps (parse-rest parse)
			 (lambda (subparse)
			   (extend-parse subparse
				(lambda (extended-subparse)
				  (if (eq? (car (parse-tree extended-subparse)) reqd-type)
				      (cont (merge-parses parse extended-subparse))
				      (begin (traceprint `(found ,(car (parse-tree subparse)) but looking for ,reqd-type))
					     (extend-parse-up-to-subtype
					     (start-parse-cps (cons (parse-tree subparse) (parse-rest subparse))
							      (lambda (subsubparse)
							 (extend-parse-up-to-type subsubparse cont))))))))))

;;; parse2 should be a parse of parse1's next term...
(define (merge-parse parse1 parse2)
  (make-parse (cons (car (parse-tree parse1))
		    (nconc (cdr (parse-tree parse1))
			   (list (parse-tree parse2))))
	      (parse-rule parse1)
	      (cdr (parse-rule-rest parse1))
	      ':bindings
	      (parse-rest parse2)))

(define (extend-parse parse cont)
;  (print `(extend-parse ,parse))
  (if (null? (parse-rule-rest parse))
      (cont parse)
      ;; rule is incomplete
      (if (list? (car (parse-rule-rest parse)))
	  ;; we have a type, so parse again until we have something appropriate
	  (extend-parse-up-to-type parse cont)
	  ;we have a literal, so...
	  (if (equal? (car (parse-rule-rest parse))
		      (car (parse-rest parse)))
	      (begin (set-parse-rule-rest! parse (cdr (parse-rule-rest parse)))
		     (set-parse-rest! parse (cdr (parse-rest parse)))
		     (extend-parse parse cont))
	      ;mismatched literal
	      (fail `(mismatched literal: wanted ,(car (parse-rule-rest parse)) but got ,(car (parse-rest parse))))))))


(define tt-eof (peek '(class java.io.StreamTokenizer) 'TT_EOF))
(define tt-number (peek '(class java.io.StreamTokenizer) 'TT_NUMBER))
(define tt-word (peek '(class java.io.StreamTokenizer) 'TT_WORD))

(define (tokenize-string string)
  (let* ((reader (new 'java.io.StringReader string))
	 (tokenizer (new 'java.io.StreamTokenizer reader)))
    (invoke tokenizer 'resetSyntax)
    (invoke tokenizer 'whitespaceChars 0 (char->integer #\ ))
;    (invoke tokenizer 'wordChars (char->integer #\-) (char->integer #\.))
    ;; parse numbers as words, then Scheme reader turns them into numbers...yeesh.
    ;; but that's the cheapest way to get int/float distinction.
    (invoke tokenizer 'wordChars (char->integer #\0) (char->integer #\9))
    (invoke tokenizer 'wordChars (char->integer #\a) (char->integer #\z))
    (invoke tokenizer 'wordChars (char->integer #\A) (char->integer #\Z))
    (invoke tokenizer 'quoteChar (char->integer #\"))
    (do ((ttype 0.0)
	 (result '()))
	((= ttype tt-eof)
	 (reverse result))
      (set! ttype (invoke tokenizer 'nextToken))
      (cond ((= ttype tt-number)
	     (push (peek tokenizer 'nval) result))
	    ((= ttype tt-word)
	     (push (read-from-string (peek tokenizer 'sval)) result))
	    ((= ttype (char->integer #\"))
	     (push (peek tokenizer 'sval) result))
	    ((> ttype 0) (push (int->char ttype) result))))))
    
(define (symbol-conc . args)
  (intern (apply string-append (map string args))))

(define tokens (tokenize-string "a[3] = b.foo(x + 23);"))


  
