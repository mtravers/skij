;;; Todo:
;  more declarative way of expressing grammar?
; eliminate emptyLabel
; some compaction could be done (ie, heads are always literals so one level could be eliminated)
;;; xml back in:
; 0-arg functions come out with parens?
; string quoting

;;; Setup

(if (%%null? (invoke (class-named "com.ibm.jikes.skij.brules.BRules") 'getMethods))
    (error "BRules class not loaded properly, probably because CLP classes not on classpath"))

(require-resource 'brules/xmltran.scm)

;;; reimplementation of TestTransformer.java 
(define (parse-clp-file filename)
  (let* ((file (new 'java.io.File filename))
	 (stream (new 'java.io.FileInputStream file))
	 (parser (new 'clpparser.CLPParser stream)))
    (invoke parser 'clp)))

(define (write-clp-file clp filename)
  (call-with-output-file filename
    (lambda (out)
      (display (invoke clp 'toString) out))))

;(define clp (parse-clp-file "e:/brules2/examples/bertelsmann3.clp"))

;;; Top level

(define (xmlfile->clp infile)
  (xml->obj (car (element-tagged-children (parse-xml-file infile)))))

(define (clp->xmlfile clp outfile)
  (let ((xml (obj->xml clp)))
    (insert-whitespace xml)
    (write-xml-file xml outfile)))

;;; Utils

(define clp-constants
  '((0 . noop)				;logical operators
    (1 . cneg)
    (2 . fneg)
    (3 . and)
    (4 . or)
    (5 . impliedby)))

(define (int->clp-constant int)
  (cdr (assv int clp-constants)))

(define (rassq thing alist)
  (find (lambda (entry) (eq? thing (cdr entry))) alist))

;;; from scm/listlib
(define (find pred list)
  (cond ((find-tail pred list) => car)
        (else #f)))

(define (find-tail pred list)
  (let lp ((list list))
    (and (pair? list)
         (if (pred (car list)) list
             (lp (cdr list))))))

(define (clp-constant->int symbol)
  (car (rassq symbol clp-constants)))

;;; Grammer

(define-xml clpkrep.CLP 
  (elt clp
       (for-jvector spit (invoke this 'getERuleSet))
       (for-jvector spit (invoke this 'getMutexSet))))
 
(define-xml-in clp
  (let ((clp (new 'clpkrep.CLP)))
    (for-xml-children
     (lambda (child)
       (case (intern (string-downcase (invoke child 'getTagName)))
	 ((erule) (invoke clp 'addERule (xml->obj child)))
	 ((mutex) (invoke clp 'addMutex (xml->obj child)))
	 (else (error `(unknown element ,(invoke child 'getTagName) within clp)))))
     this)
    clp))

(define-xml clpkrep.Mutex
  (elt mutex
       (spit (invoke this 'get1stCLit))
       (spit (invoke this 'get2ndCLit))))

(define-xml-in mutex
  (apply new 'clpkrep.Mutex
	 (get-child-objects this)))

(define-xml clpkrep.Formula
  (let* ((operator (int->clp-constant (invoke this 'getOperator)))
	 (subforms (jvector->list (invoke this 'getSubFormulae)))
	 (xml (make-elt operator '())))
    (if (eq? operator 'noop) (error "NOOP seen"))
    (for-each (lambda (subform)
		(invoke xml 'appendChild (obj->xml subform)))
	      subforms)
    xml))
    
(define-xml-in and
  (new 'clpkrep.Formula (clp-constant->int 'and) (list->formulalist (get-child-objects this))))

(define-xml-in or
  (new 'clpkrep.Formula (clp-constant->int 'or) (list->formulalist (get-child-objects this))))

(define-xml clpkrep.ERule
  (elt (erule (rulelabel (invoke this 'getRuleName)))
       (spit-xml (elt head
		      (spit (invoke this 'getHead))))  ; this is a formula
       (%aif (invoke this 'getBody)
	     (spit-xml (elt body
			    (spit it))))))

(define-xml-in erule
  (let* ((body (find-child this 'body))
	 (label (get-attribute this 'rulelabel))
	 (erule (if body
		    (new 'clpkrep.ERule
			    (xml->obj (find-child this 'head))
			    (xml->obj body)) 
		    (new 'clpkrep.ERule
			    (xml->obj (find-child this 'head))))))
    (if label
	(invoke erule 'setRuleName label))
    erule))

(define-xml-in head			;head is always a single literal (I think)
  (xml->obj (car (element-tagged-children this))))

(define-xml-in body
  (xml->obj (car (element-tagged-children this))))

(define-xml clpkrep.FCLiteral
  (elt (fcliteral (predicate (invoke (invoke this 'getPredicate) 'getSymName))
		  (fneg (not (invoke this 'isPositive)))
		  (cneg (not (invoke (invoke this 'getCLiteral) 'isPositive))))
       (for-each spit (jvector->list (invoke this 'getArgList)))))

(define-xml-in fcliteral
  (new 'clpkrep.FCLiteral
       (boole->clpsign (not (get-attribute this 'fneg)))
       (boole->clpsign (not (get-attribute this 'cneg)))
       (get-attribute this 'predicate)
       (list->termlist (get-child-objects this))))
  
(define-xml clpkrep.CLiteral
  (elt (cliteral (predicate (invoke (invoke this 'getPredicate) 'getSymName))
		 (cneg (not (invoke this 'isPositive))))
       (for-each spit (jvector->list (invoke this 'getArgList)))))

; returns a list of converted children
(define (get-child-objects xml)
  (map xml->obj (element-tagged-children xml)))

(define (element-tagged-children xml)
  (let ((result '()))
    (for-xml-children
     (lambda (child)
       (push child result))
     xml)
    (reverse result)))

(defmacro (define-list-type type adder)
  `(define (,(symbol-conc 'list-> (string-downcase (to-short-string type))) lst)
     (let ((xlist (new ',type)))
       (for-each (lambda (x)
		   (invoke xlist ',adder x))
		 lst)
       xlist)))

(define-list-type clpkrep.TermList addTerm)
(define-list-type clpkrep.FormulaList addFormula)

;;; why don't they use booleans?
(define (boole->clpsign boole)
  (if boole 1 -1))

(define-xml-in cliteral
  (let ((predicate (get-attribute this 'predicate))
	(cneg (get-attribute this 'cneg))
	(args (get-child-objects this)))
    (new 'clpkrep.CLiteral (boole->clpsign (not cneg)) predicate (list->termlist args))))

;;; placeholder
(define-xml clpkrep.Literal
  (elt (literal (predicate (invoke (invoke this 'getPredicate) 'getSymName)))
       (for-each spit (jvector->list (invoke this 'getArgList)))))

;;; placeholder
(define-xml clpkrep.Term
  (elt term
       (spit-string this)))

(define-xml clpkrep.LVariable
  (elt (variable (name (invoke this 'toString)))))

(define-xml-in variable
  (new 'clpkrep.LVariable (get-attribute this 'name)))

(define-xml clpkrep.StringTerm
  (let ((str (string this)))
    (elt (function (name (substring str 1 (- (string-length str) 1)))
		   (string "yes")))))

(define-xml clpkrep.FuncTerm
  (elt (function (name (invoke (invoke this 'getLFunction) 'getSymName)))
       (for-jvector spit (invoke this 'getArgList))))

(define-xml-in function
  (let ((name (get-attribute this 'name))
	(string? (get-attribute this 'string))
	(args (get-child-objects this)))
    (if string?
	(new 'clpkrep.StringTerm name)	;+++ quoting
	(if (null? args)
	    (new 'clpkrep.FuncTerm name)
	    (new 'clpkrep.FuncTerm name (list->termlist args))))))
