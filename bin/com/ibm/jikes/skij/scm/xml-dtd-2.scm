;New cut- multiple theories

(defstruct learner
  for
  theories
  discarded-theories			;to save work
  data)

; add an instance, adjusting hypotheses as necessary
(define (add-example learner example)
  (print `(add-example for ,(learner-for learner) ,example))
  (unless (member example (learner-data learner))
    (if (null? (learner-theories learner))
	(add-theory learner (initial-theory example))
	(for-each 
	 (lambda (theory)
	   (unless (ematch? theory example)
		   (discard-theory learner theory)
		   (generate-new-theories learner example theory)))
	 (learner-theories learner)))
    (push example (learner-data learner))))

(define (initial-theory example)
  (compress-repititions example))

(define (add-theory learner theory)
  (print `(add-theory for ,(learner-for learner) ,theory ,learner))
  (push theory (learner-theories learner)))

(define (discard-theory learner theory)
  (print `(discard-theory for ,(learner-for learner) ,theory ,learner))
  (deletef theory (learner-theories learner)))

; try all known examples against theory, return first failure if there is one
(define (invalidate-theory learner theory)
  (print `(invalidate theory ,theory ,learner))
  (call-with-current-continuation 
   (lambda (return)
     (for-each 
      (lambda (ex)
	(unless (ematch? theory ex) (return ex)))
      (learner-data learner))
     (return #f))))

; this is the hard part
(define (generate-new-theories learner example bad-theory)
  (define (try-theory theory)
    (print `(try-theory ,theory ,learner))
    (cond ((member theory (learner-theories learner)))
	  ((member theory (learner-discarded-theories learner)))
	  ((invalidate-theory learner theory)
	   => (lambda (invalidator)
		(print `(theory ,theory invalidated by ,invalidator ,learner))))
	  (else
	   (add-theory learner theory))))
  (try-theory (initial-theory example))
  (try-theory `((or ,bad-theory ,(initial-theory example))))
  (aif (theory-match-tails bad-theory example)
       (try-theory `((? ,@(firstn example (- (length example (length it)))))
		     ,@bad-theory)))
  (aif (theory-match-heads bad-theory example)
       (try-theory `(,@bad-theory
		     (? ,@(lastn example (- (length example) (length it))))))))
;;; Simplify

(define (simplify-theory theory)
  (map simplify-term theory))

(define (simplify-term term)
  (if (and (pair? term) (eq? (car term) 'or))
      ))


;;; try to match theory against all substrings of the example

;;; match against example tails
(define (theory-match-tails theory example)
  (if (null? example) #f
      (if (ematch? theory example)
	  theory
	  (theory-match-tails theory (cdr example)))))

(define (theory-match-heads theory example)
  (define (theory-match-heads1 n)
    (if (= n 0) #f
	(if (ematch? theory (firstn example n) )
	    theory
	    (theory-match-heads1 (- n 1)))))
  (theory-match-heads1 (length example)))

(define (firstn list n)
  (if (= n 0) '()
      (cons (car list)
	    (firstn (cdr list) (- n 1)))))

(define (lastn list n)
  (list-tail list (- (length list) n)))

;;; setup
(require-resource 'scm/xml-dtd.scm)
(define xml (parse-xml-file "e:/brules2/examples/bertelsmann3.xml"))
(define struct (all-structure xml))

(define (learn-tag struct tag)
  (let ((examples (select-structure struct tag))
	(learner (make-learner tag '() '() '())))
    (for-each (lambda (ex) (add-example learner (cadr ex))) examples)
    learner))
    

;;; debug: this structure gets munged
(define tstruct '((erule (head)) 
		  (erule (head body) )))

(learn-tag tstruct 'erule)