(define celltest 
  (lambda (vis?)
    (define w (make-window 'cell 300 300 vis?))
    (define p (new 'java.awt.Panel))
    (invoke w 'add p)
    (define c (new 'Cell 'x))
    (define v (new 'CellView c))
    (invoke p 'add v)
    (if vis? '() (invoke w 'setVisible #t))
    w))
  

