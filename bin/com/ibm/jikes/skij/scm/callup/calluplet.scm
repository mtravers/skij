(load-resource 'scm/callup/callme.scm) 

(for-each (lambda (comp)
	    (print (string-append '"Removing " (string comp)))
	    (invoke *applet-pane* 'remove comp))
	  (vector->list (invoke *applet-pane* 'getComponents)))

(invoke *applet-pane* 'add (make-callup-panel))
