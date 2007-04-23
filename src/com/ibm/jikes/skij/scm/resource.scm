; just trying to get resources to work a little

;;; when class is in a zip file, this returns a magic URL that points to it.
(define (class-resource-url class)
  (invoke class 'getResource '""))

(define sc (invoke 'java.lang.Class 'forName 'com.ibm.jikes.skij.Scheme))

(invoke sc 'getResource "Scheme.class")  ; this works

(invoke sc 'getResource "lib/init.scm")  ; this doesn't, goddamn it

(invoke c 'getResource '"lib/")  ; this works, oddly enough (not without the slash)