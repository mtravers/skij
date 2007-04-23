



; Norvig version

(define (parse words)
  (unless (null? words)
	  (mapcan (lambda (rule)
		    (extend-parse rule (list (car words))
				  (cdr words) '()))
		  (rules-starting-with (car words)))))

(define (extend-parse rule rhs rem needed)
  (if (null? needed)
      (let ((parse (make-parse (new-tree (car rule) rhs) rem)))
	(cons parse
	      (mapcan
	       (lambda (irule)
		 (extend-parse irule
			       (list (parse-tree parse))
			       rem (cdr (rule-rhs irule))))
	       (rules-starting-with rule))))
      (mapcan
       (lambda (p)
	 (if (eq? (parse-lhs p) (car needed))
	     (extend-parse rule (append1 rhs (parse-tree p))
			   (parse-rem p) (cdr needed))))
       (parse rem))))



(define (parse words)
  (let-amb rule (rules-starting-with (car words))
     (match (cdr (rule-rhs rule)) (cdr words))

(define (match pattern data)
  




(define make-parse list)
(define parse-tree car)
(define parse-rem cadr)

(define (new-tree cat rhs) (cons cat rhs))
(define tree-lhs car)
(define tree-rhs cdr)

(define (lexicalize thing)
  (if (symbol? thing) (list 'word thing) thing))
(define (mapcan func . lists)
  (apply nconc (apply map (cons func lists))))



(define (parse-as type rest)

(define (start-parse tokens)
  (print `(start-parse ,tokens))
  (let-amb rule (rules-starting-with (car tokens))
     (print `(rule: ,rule))	   
     (let ((parse (make-parse (list (rule-lhs rule) (car tokens))
			      rule
			      (if (list? (rule-rhs rule))
				  (cdr (rule-rhs rule))
				  '())
			      ':bindings ;+++ need new theory of bindings, skip for now
			      (cdr tokens))))
       (extend-parse parse))))