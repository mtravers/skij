;;; Define good stuff for debugging XBrowser

(load "d:/mt/projects/skij/SkijSharp/clr.scm")

(define (def-all-widgets)
  (def-widgets (peek-static 'MDL.XBrowser 'Current)))

(define (def-widgets widget)
  (let ((tag (invoke widget 'get_Tag)))
    (if (not (%%null? tag))
	(begin
	  (set! tag (intern tag))
	  (if (or (not (bound? tag))
		  (instanceof (toplevel-value tag) (class-named 'System.Windows.Forms.Control)))
	      (define-toplevel tag widget))))
    (map-collection def-widgets (invoke widget 'get_Controls))))

;;; Need something that does this safely so it doesn't kill important procedures!
;;; +++ Move these.
(define (define-toplevel symbol value)
  (print symbol)
  (print value)
  (invoke (global-environment) 'addBinding symbol value))

(define (toplevel-value symbol)
  (invoke (global-environment) 'getBinding symbol 0))




;;; Querylets

(define (make-querylet table)	   
  (let ((qlet (new 'MDL.Querylet)))
    (poke qlet 'topConstraint (new 'MDL.QueryletCombinationConstraint))
    (poke qlet 'table table)
    qlet))

;;; would be nice if we could package lambdas as Delegates!
(define (show-widgets from)
  (letrec ((show-widgets-1 
	    (lambda (from n)
	      (newline)
	      (do ((nn n (- nn 1)))
		  ((= nn 0))
		(display "  "))
	      (display from)
	      (display ": ")
	      (display (%or-null (invoke from 'get_Tag) ""))
	      (map-collection (lambda (sub)
				(show-widgets-1 sub (+ n 1)))
			      (invoke from 'get_Controls)))))
    (show-widgets-1 from 0)))


;;; This is broken
;;; Doing this (in browse.xml) gets an exception, and breaks the normal Next button!
;(invoke XBrowser 'browserNext (%null) (%null))
;;; Same here (I think)
;(invoke (peek XBrowser 'mapper) 'readNextRow)


;;; Wiring

(define-memoized (encapsulate widget)
  (let ((part (new 'MDL.WidgetPart)))
    (poke part 'widget widget)
    (invoke part 'Instrument)
    part))

;;; optional pin-name
(define (property-pin part property in? . rest)
  (let ((pin-name (if (null? rest)
		      (string property)
		      (string (car rest))))
	(class (if in? 'MDL.InputPropertyPin 'MDL.OutputPropertyPin)))
    (%or-null (invoke part 'GetPinNamed pin-name)
	      (let ((pin (new class)))
		(invoke part 'AddPin pin)
		(poke pin 'name pin-name)
		(poke pin 'part part)
		(poke pin 'propertyName (string property))
		pin))))

;;; see xml/wiretest.xml
(define (wtest)
  (let ((p1 (encapsulate width))
	(p2 (encapsulate target)))
    (wire p1 "Text" p2 "Width")
    (list p1 p2)))
  
(define (wire part1 name1 part2 name2)
  (let ((pin1 (property-pin part1 name1 #f))
	(pin2 (property-pin part2 name2 #t)))
    (invoke pin1 'Wire pin2)))

;;; wire components and properties without ever knowing about the part/pin objects
(define (pwire comp1 prop1 comp2 prop2)
  (let ((pin1 (property-pin (encapsulate comp1) prop1 #f))
	(pin2 (property-pin (encapsulate comp2) prop2 #t)))
    (invoke pin1 'Wire pin2)))  

;;; Not even close to working, requires hairy introspection and delegate munging
(define (wire-event obj event-name)
  (let* ((type (invoke (invoke obj 'getClass) 'ToType))
	 (event (invoke type 'GetEvent event-name))
	 (addmethod (invoke event 'GetAddMethod))
	 (handler (new 'System.EventHandler obj <intptr>))) ;requires IntPtr???
    ))

;;; doesn't work (doesn't understand IntPtr primitive type)
;;; (new 'System.EventHandler width (new 'System.IntPtr 200))


(define (adder-test)
  (define adder (new 'MDL.Adder))
  (define addend (invoke adder 'GetPropertyPin "Addend" #t))
  (define augend (invoke adder 'GetPropertyPin "Augend" #t))
  (define sum (invoke adder 'GetPropertyPin "Sum" #f))
  (print sum)
  (invoke sum 'Wire (invoke (invoke-static 'MDL.WidgetPart 'Encapsulate color) 'GetPropertyPin "Text" #t))
  (invoke (invoke (invoke-static 'MDL.WidgetPart 'Encapsulate width) 'GetPropertyPin "Text" #f) 'Wire augend)
  (invoke (invoke (invoke-static 'MDL.WidgetPart 'Encapsulate height) 'GetPropertyPin "Text" #f) 'Wire addend))



(def-all-widgets)			;might as well do this on load

(define (test)
  (invoke-static 'MDL.GenericEventAdaptor 'MakeEventHandler button "Click" target "Dispose"))



;;; DAF testing

; (load "d:/mt/projects/skij/SkijSharp/xbrowser.scm")

(define (do-daf)
  (def-all-widgets)
  (define dafpart (invoke-static 'MDL.FieldWidgetPart 'Encapsulate DAF))
  (define fieldpart (invoke-static 'MDL.FieldWidgetPart 'Encapsulate field))
  (wire dafpart "CurrentRecord" fieldpart "Record")
  (wire queryobject "Result" DAF "Value")
  )

  ;; make 


;;; NEW versions of these that actually work today (6/15)
(define (wire part1 name1 part2 name2)
  (invoke-static 'MDL.Part 'Wire part1 name1 part2 name2))

(define (wtrace) 
  (poke-static 'MDL.Pin 'tracing #t))

(define (print-pins widget)
  (let ((part (invoke-static 'MDL.EncapsulatingPart 'Encapsulate widget)))
    (map-arraylist print (peek part 'pins))))