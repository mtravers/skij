(define (start-xbrowser)
  (invoke-static 'System.Reflection.Assembly 'LoadFrom "e:/NewClientPrototype/XBrowser/bin/Debug/XBrowser.exe")
  (let* ((threadstart (%ThreadStart (lambda ()
				      (invoke-static 'MDL.XBrowser 'Main (%null)))))
	 (thread (new 'System.Threading.Thread threadstart)))
    (display "Starting thread..."
    (invoke thread 'Start))))

;;; gives you browser
(define xb (peek-static 'MDL.XBrowser 'Current))

(load "c:/mt/projects/skij/ics.scm")

