(load-resource 'scm/callup/callup-configure.scm)
(load-resource 'scm/callup/callup.scm)
(load-resource 'scm/callup/callup-tree.scm)
(load-resource 'scm/callup/callup-frame.scm)

(require 'tree)
(configure-callup)
(make-callup-window)
