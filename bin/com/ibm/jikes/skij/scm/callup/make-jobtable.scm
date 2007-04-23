;;; incomplete

; try to get all of research
(load-resource 'scm/callup/callup-configure.scm)
(load-resource 'scm/callup/callup.scm)
(configure-callup)

(all-subordinates (car (get-employees-by-name "horn, paul")))

