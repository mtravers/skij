;;; uses pilotbead (see d:\java\pilotbean)

(define my-pilot #f)

(define (init-pilotbean directory username)
  (set! my-pilot (new 'com.ibm.pilotbean.PilotBean directory username)))

(init-pilotbean '"d:/workpad/" '"TraverM")

(inspect my-pilot)			;crash!

