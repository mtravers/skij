;;; variety of XML stuff
;;; requires some functions in connect.scm

;;; Doesn't work, reason mysterious
;;; no, works on some things, not others. See below
(define (xml-serialize thing)
  (let ((serializer (new 'System.Xml.Serialization.XmlSerializer
			 (.net-type-of thing))))
    (with-.net-string-output 
     (lambda (writer)
       (invoke serializer 'Serialize writer thing)))))

;;; This works...
; (invoke-static 'System.Reflection.Assembly 'LoadFrom "c:/mt/cs/serial.exe")
; (xml-serialize (new 'PurchaseOrder))
; xbrowser molecules DON'T work, although they are perfectly ordinary objects. Blah, what gives?
; but doing the same thing with an XBrowser molecule doesn't. ARGH!
;;; Note: these also get errors when done from regular C#, but the errors are more informative.

(define (xml-serialize-to-file thing file)
  (let ((serializer (new 'System.Xml.Serialization.XmlSerializer
			 (.net-type-of thing)))
	(writer (new 'System.IO.StreamWriter file)))
    (invoke serializer 'Serialize writer thing)
    (invoke write 'Close)))

(define (.net-type-of thing)
  (invoke (class-of thing) 'ToType))

(define (with-.net-string-output func)
  (let ((writer (new 'System.IO.StringWriter)))
    (func writer)
    (invoke writer 'ToString)))

;;; Argh. Use streams instead of Writers (for SOAP)
(define (with-.net-string-output-stream func)
  (let ((stream (new 'System.IO.MemoryStream)))
    (func stream)
    (bytes->string (invoke stream 'ToArray))))

(define (with-.net-string-input-stream string func)
  (let ((stream (new 'System.IO.MemoryStream))
	(bytes (string->bytes string)))
    (invoke stream 'Write bytes 0 (vector-length bytes))
    (invoke stream 'set_Position 0)	;rewind
    (func stream)))



;;; SOAP serialization (more useful since it preserves object identity)

(invoke-static 'System.Reflection.Assembly 'LoadFrom "c:/WINNT/assembly/GAC/System.Runtime.Serialization.Formatters.Soap/1.0.3300.0__b03f5f7f11d50a3a/System.Runtime.Serialization.Formatters.Soap.dll")

(define (soap-serialize thing)
  (let ((serializer (new 'System.Runtime.Serialization.Formatters.Soap.SoapFormatter)))
    (with-.net-string-output-stream
     (lambda (writer)
       (invoke serializer 'Serialize writer thing)))))

;;; Doesn't work (even given the output of soap-serialize on a molecule. Argh
;;; Seems to work from C#, but not here?  No clue why.
(define (soap-deserialize string)
  (let ((serializer (new 'System.Runtime.Serialization.Formatters.Soap.SoapFormatter)))
    (with-.net-string-input-stream string
     (lambda (stream)
       (invoke serializer 'Deserialize stream)))))