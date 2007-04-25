;;; redefs etc for patblocks

(define (path-to-poly path x y head scale)
  (let ((xs '()) (ys '())
	(unit-dist (* unit scale)))
    (letrec
	((collect (lambda ()
		   (push x xs)
		   (push y ys)))
	(turn (lambda (amt)
		(incf head (d2r amt))))
	(move (lambda (dist)
		(incf x (* unit-dist dist (cos head)))
		(incf y (* unit-dist dist (sin head))))))
      (collect)
      (move 1)				;++++
      (collect)
      (for-each (lambda (elt)
		  (let ((corner (if (list? elt) (car elt) elt))
			(dist (if (list? elt) (cadr elt) 1)))
		    (turn corner)
		    (move dist)
		    (collect)))
		path)
      (make-polygon xs ys))))

(define shapes
  `((right (90 (135 ,(sqrt 2))) (80 120 70) 44 52 0.0)
    (diamond (120 60 120) (0 0 200) 44 52 0.0)
    (trapezoid (60 60 120 0) (200 0 0) 13 134 11.52)
    (square (90.0 90.0 90.0) (255 134 0) 34 158 0.0)
    (triangle (120 120) (0 200 0) 73 244 21.991148575128552)
    (skinny-diamond (150 30 150) (220 220 200) 56 287 21.991148575128552)
    (hexagon (60 60 60 60 60) (220 220 0) 39 311 0.0)
    ;; By request of Ben
;    (pentagon (72 72 72 72) (0 0 0) 38 400 0)
    (octagon (45 45 45 45 45 45 45) (220 0 220) 42 400 0.0)
    ))
