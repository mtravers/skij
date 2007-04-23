(poke-static 'com.ibm.jikes.skij.Evaluator 'saveMacroSource #t)

(load-resource 'scm/web/webspect.scm)
(load-resource 'scm/web/web-callup.scm)	
(load-resource 'scm/web/web-eval.scm) ;get debuggable!
(load-resource 'scm/callup/jobtable.scm)
(load-resource 'scm/callup/palm.scm)	;feeping creaturitis

(start-webspect-service 2341)

; get unsafe!
; (install-security)
