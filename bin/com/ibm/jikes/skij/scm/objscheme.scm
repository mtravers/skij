; From Object Scheme paper
; an object is a list of frames
; a frame is a list whose car is a list of bindings
; a binding is a pair of a swapper proc and a shadow-finder proc

(define make-object 
  (lambda superiors
    (letrec ((remove-leading-duplicates
	      (lambda (frames)
		(cond ((null? frames) '())
		      ((memq (first frames) (rest frames))
		       (remove-leading-duplicates (rest frames)))
		      (#t (cons (car frames)
				(remove-leading-duplicates (cdr frames))))))))
      (cons (make-empty-frame)
	    (remove-leading-duplicates (apply append superiors))))))
    
(define object-own-frame car)

(define (make-empty-frame) (cons '() 'ignore))
(define frame-bindings car)
(define set-frame-bindings! set-car!)

(define make-binding cons)
(define binding-swapper car)
(define binding-shadow-finder cdr)
  
(define *current-object* (list (make-empty-frame)))

(defmacro (have! var value)
  `(add-binding-to-current-object!
    (let ((saved-val ,value))
      (make-binding 
       (lambda () 
	 (define temp saved-val)
	 (set! saved-val ,var)
	 (set! ,var temp))
       (lambda (return)
	 (if (eq? ,var *id-token*)
	     (return saved-val)))))))

; this can't be right?
(define add-binding-to-current-object!
  (let ((own-frame (object-own-frame *current-object*)))
    (lambda (binding)
      (set-frame-bindings! own-frame (cons binding (frame-bindings own-frame)))
      ((binding-swapper) binding))))



     