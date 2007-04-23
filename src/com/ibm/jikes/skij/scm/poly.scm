
(define (make-poly points)
  (new 'java.awt.Polygon
       (list->int-vector (map car points))
       (list->int-vector (map cadr points))
       (length points)))

(invoke g 'fillPolygon (make-poly '((10 30) (40 59) (10 100) (100 35))))
