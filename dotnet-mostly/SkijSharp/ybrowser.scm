;;; Define good stuff for debugging XBrowser

(load "d:/mt/projects/skij/SkijSharp/clr.scm")

(define (partfor thing)
  (invoke-static 'MDLInternal.Base.Framework.Wires.Part 'PartFor thing))

(define (controlfor part)
  (invoke part 'get_Encapsulated))

(define (def-all-parts)
  (def-parts (partfor (invoke-static 'MDLInternal.Base.Framework.YBrowser.Base 'get_TheBase))))

;;; YBrowser has hierarchical names, so this won't work in the general case.
(define (def-parts part)
  (let ((name (invoke part 'get_Name)))
    (set! name (intern name))
    (if (or (not (bound? name))
            (instanceof (toplevel-value name) (class-named 'MDLInternal.Base.Framework.Wires.Part)))
        (define-toplevel name part)))
  ;; map-arraylist because map-collection has security problem
  ;; catch because not all Children lists are arraylists...argh argh argh!
  (catch (map-arraylist def-parts (invoke part 'get_Children))))

(define (for-all-parts top proc)
  (proc top)
  (catch 
  (map-arraylist (lambda (child) (for-all-parts child proc))
                 (invoke top 'get_Children))))

(define (for-all-pins part proc)
  (map-arraylist proc (invoke part 'get_Pins)))

(define (find-multi-pins)
  (for-all-parts top
               (lambda (part)
                 (for-all-pins part
                               (lambda (pin)
                                 (if (> (invoke (peek pin 'connections) 'get_Count) 1)
                                     (print `(,part ,pin))))))))

(define (define-toplevel symbol value)
  (print `(,symbol = ,value))
  (invoke (global-environment) 'addBinding symbol value))

(define (toplevel-value symbol)
  (invoke (global-environment) 'getBinding symbol 0))



