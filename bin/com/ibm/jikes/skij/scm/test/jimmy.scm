(define (class-info file)
  (new 'com.ibm.jikes.bmtk.ClassInfo file))

(define ci (class-info 'java.util.GregorianCalendar))
(define methods (map-enumeration (lambda (x) x) (invoke (invoke ci 'getMethods) 'elements)))

(define (class-methods class-name)
  (map-enumeration 
   (lambda (x) x)
   (invoke (invoke (class-info class-name) 'getMethods) 'elements)))


(define (class-vector . classes)
  (define v (%make-vector (length classes) (class-named 'java.lang.Class)))
  (%fill-vector v classes)
  v)

(define rmethod (invoke (class-named 'java.util.GregorianCalendar) 'getMethod 'getMaximum (class-vector (peek '(class java.lang.Integer) 'TYPE))))

(define (find-jimmy-method rmethod methods)
  (filter (lambda (meth)
	    (equal? (invoke rmethod 'getName)
		    (invoke meth 'getName)))
	  methods))

(define (method-parameters meth)
  (vector->list (peek (peek meth 'parmSection) 'parameter)))









Jimmy bugs and comments:

- the documentation for the ClassInfo(String) constructor is confusing;
the parameter is a class name, not a class FILE name

- the toString method for ClassInfo produces a string that is much
too long. 

- why isn't MethodVector a subclass of java.util.Vector?

- it would be nice if there was a clean connection to reflection objects (ie, given
a reflect Method object, get the corresponding Jimmy Method object)

- Method.getParameterDescriptors is not there, despite being in the online doc
(not in the downloaded doc, so web version is just out of date)

- after threading through the Jimmy structures, I find that the real class
parameter names aren't there. Is this Jimmy's fault or are they compiled out?
