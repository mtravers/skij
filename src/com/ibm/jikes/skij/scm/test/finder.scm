;;; given the large and hairy APIs out there,
;;; I want to be able to find the answers to questions like this:
;;; Given a JTree and a MouseEvent, how do I find the node of the tree the MouseEvent 
;;;  deals with?
;;; Sadly, this isn't easy.
;;; So how about searching the class metadata for methods that accept MouseEvents or Points, or return nodes, or whatever...

(define (methods-that-deal-with in-class dealt-class)
  (define result '())
  (for-vector 
   (lambda (method)
     (if (or (eq? dealt-class (invoke method 'getReturnType))
	     (memq-vector dealt-class (invoke method 'getParameterTypes)))
	 (push method result)))
   (invoke in-class 'getMethods))
  result)
     

