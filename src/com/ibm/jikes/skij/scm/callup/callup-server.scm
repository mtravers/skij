(load-resource 'scm/callup.scm)
(require 'server)
(require 'runtime)

(define (make-callup-server port)
  (make-server 
   port
   (lambda (socket)
     (define in (new 'com.ibm.jikes.skij.InputPort (invoke socket 'getInputStream)))
     (define args (read-line in))
     (print (string-append '"CALLUP server: " args))
     (define out (new 'com.ibm.jikes.skij.OutputPort (invoke socket 'getOutputStream)))
     (define result (callup-string args))
     (print (string-append '"--> " result))
     (write result out)
     (newline out)
     (invoke socket 'close))))

