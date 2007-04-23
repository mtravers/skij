;;; Failed attempt to survey event data (for wiring model).
;;; Did not work due to security crapola.

(define (show-events type)
  (let ((events (vector->list (invoke type 'GetEvents)))
        (event-handler 
         (lambda (event)
           (let* ((method (invoke type 'GetMethod (string-append "add_" (invoke event 'get_Name))))
                  (params (invoke method 'GetParameters))
                  (param0 (aref params 0)))
             (invoke param0 'ParameterType)))))
    (map event-handler events)))