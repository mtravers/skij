;;; Author: Michael Travers 

;;; (c) Copyright Michael Travers 2000, 2003, 2004. All right reserved.

;;; History
;;; originally done around 2000
;;; revived Nov 2003
;;; and again Nov 2004

;;; TODOs:
; - need shift keys for rotate/clone etc.
; - needs undo, or at least some protection from accidental deletion
; - usability stinks: instead of a "clone" mode, have a command to add a group to the palette. Etc.
; - needs help or documentation
; - color/scale on right context menu (started)
; - save/restore (innards working)
; - alternate starting palettes (ie, penrose, power polygons)
; - drop is too slow when there are tons of parts
; - group highlighting is hard to see in adjacent parts; need something better
; - various z-order problems (back/front commands?)
; - OH FUCK I think the applet goes tries to go back to the server for compiled SCM files, or tries to!  No wonder it's slow.

(load-resource "nlib/skij-patches.scm")
(load-resource "nlib/ndefstruct.scm")
(load-resource "nlib/sprites.scm")

;;; (name turtle-path rgb palette-x palete-y palette-heading)
(define shapes
  '(
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

;;; Penrose (not even close to right)
'(define shapes
  '((kite (108 36 108) (205 134 50))
    (dart (108 144 -36) (220 220 0))))

(define (angle-inc shapes)
  (apply gcd (remove-duplicates (apply append (map cadr shapes)))))

;;; Constants
(define pi (peek-static 'java.lang.Math 'PI))
(define black (new 'java.awt.Color 0 0 0))
(define white (new 'java.awt.Color 255 255 255))

(define	(d2r d)
  (* d #,(/ pi 180.0)))

;;; Parameters
(define unit 30)
(define palette-scale .7)
(define palette-max 150.0)
(define snap-in-epsilon 10)
(define head-snap (d2r 15))		;+++ 30 OK for standard set; octagons need 15.


(define (path-to-poly path x y head scale)
  (let ((xs '()) (ys '())
	(distance (* unit scale)))
    (letrec
	((collect (lambda ()
		   (push x xs)
		   (push y ys)))
	(turn (lambda (amt)
		(incf head (d2r amt))))
	(move (lambda ()
		(incf x (* distance (cos head)))
		(incf y (* distance (sin head))))))
      (collect)
      (move)
      (collect)
      (for-each (lambda (corner)
		  (turn corner)
		  (move)
		  (collect))
		path)
      (make-polygon xs ys))))



(define (make-polygon xs ys)
  (let ((poly (new 'java.awt.Polygon)))
    (for-each (lambda (x y)
		(invoke poly 'addPoint (integer x) (integer y)))
	      xs ys)
    poly))



;;; Common superclass of poly-sprite and group-sprite
(defstruct (mpoly-sprite shape-sprite) (heading 0) (scale 1))

(defmethod (rescale (sprite mpoly-sprite) by)
  (setf (mpoly-sprite-scale sprite)
	(* (mpoly-sprite-scale sprite) by)))

(defmethod (handle-event (sprite mpoly-sprite) evt)
  (case (invoke evt 'getID)
    ((#,mouse-dragged-event-id)
     (call-next-method))
    ((#,mouse-pressed-event-id)
;      (if (= (invoke evt 'getModifiers)
; 	    button-3-mask)
; 	 (sprite-context-menu sprite)
     (let* ((man (dynamic *manager*)))
       (case (patblock-manager-mode man)
	 ((select) (toggle-selection man sprite))
	 ((rotate drag)
	  (start-drag man sprite
		      (invoke evt 'getX) (invoke evt 'getY)
		      (or (eq? (patblock-manager-mode man) 'rotate)
		 	  (= (invoke evt 'getModifiers)
			     button-3-mask))))
	 ((clone)
	  (clone-and-drag sprite evt))
	 ((delete)
	  (remove-sprite man sprite)
	  (manager-repaint man)))))
    ((#,mouse-released-event-id)
     (stop-drag (dynamic *manager*)))))


(defstruct (poly-sprite mpoly-sprite) path poly (xoff 0) (yoff 0))

(defmethod (initialize (sprite poly-sprite))
;  (call-next-method)
  (let ((bounds (compute-bounds sprite)))
    (setf (poly-sprite-xoff sprite)
	  (- (sprite-x sprite) (peek bounds 'x)))
    (setf (poly-sprite-yoff sprite)
	  (- (sprite-y sprite) (peek bounds 'y)))
    (setf (size-sprite-xs sprite) (peek bounds 'width))
    (setf (size-sprite-ys sprite) (peek bounds 'height))))

(defmethod (compute-bounds (sprite poly-sprite))
  (let* ((poly (compute-poly sprite))
	 (bounds (invoke poly 'getBounds)))
    bounds))

(defmethod (compute-poly (sprite poly-sprite))
  (let ((poly (path-to-poly 		;+++ might be better to not do this on every paint!
	       (poly-sprite-path sprite)
	       (+ (sprite-x sprite) (poly-sprite-xoff sprite))
	       (+ (sprite-y sprite) (poly-sprite-yoff sprite))
	       (mpoly-sprite-heading sprite)
	       (mpoly-sprite-scale sprite))))
    (setf (poly-sprite-poly sprite) poly) ;save for detection
    poly))


(defmethod (paint (sprite poly-sprite) g)
  (let ((poly (compute-poly sprite)))

    ;; debug
    '(invoke g 'setColor white)
    '(invoke g 'drawRect 
	  (integer (sprite-x sprite))
	  (integer (sprite-y sprite))
	  (integer (size-sprite-xs sprite))
	  (integer (size-sprite-ys sprite)))

    (invoke g 'setColor (shape-sprite-color sprite))
    (invoke g 'fillPolygon poly)
    (invoke g 'setColor black)
    (invoke g 'drawPolygon poly)
    ))

(defmethod (paint-highlight (sprite poly-sprite) g)
  (let ((poly (poly-sprite-poly sprite)))
    ;; +++ want to do thickness, but it's not supported by java.awt.Graphics!
    ;; need Java2D. Blah.
    (invoke g 'setColor white)		
    (invoke g 'drawPolygon poly)
    ))



(defmethod (point-in-sprite? (poly-sprite poly-sprite) x y)
  (invoke (poly-sprite-poly poly-sprite)
	  'contains x y))

; x,y are current mouse coords
; manager offsets are difference between sprite origin and original click point
(defmethod (rotate (sprite mpoly-sprite) x y)
  (let* ((manager (dynamic *manager*))
	 (x-off (sprite-drag-manager-drag-x-offset manager))
	 (y-off (sprite-drag-manager-drag-y-offset manager))
	 (old-heading (mpoly-sprite-heading sprite))
	 (new-heading (d2r (- (* 5 y) (sprite-y sprite))))
	 (dtheta (- new-heading old-heading))
	 (transformed
	  (rotate-about sprite dtheta x-off y-off)))
    (setf (sprite-drag-manager-drag-x-offset manager) (car transformed))
    (setf (sprite-drag-manager-drag-y-offset manager) (cadr transformed))
    ))

;;; x and y are relative to the sprite
(defmethod (rotate-about (sprite mpoly-sprite) dtheta x y)
  (let* ((sin-t (sin dtheta))
	 (cos-t (cos dtheta))
	 (transformed-x (- (* x cos-t) (* y sin-t)))
	 (transformed-y (+ (* x sin-t) (* y cos-t))))
    (incf (mpoly-sprite-heading sprite) dtheta)
    (incf (sprite-x sprite) (- transformed-x x))
    (incf (sprite-y sprite) (- transformed-y y))
    (list transformed-x transformed-y)
    ))





;;; Palette
(defstruct (poly-source poly-sprite))

(defmethod (handle-event (sprite poly-source) evt)
  (clone-and-drag sprite evt)
  )

(defmethod (clone (sprite poly-source))
  (let ((newbie (call-next-method)))*
    (setf (vector-ref newbie 0) 'poly-sprite) ;change to regular shape
    (setf (mpoly-sprite-scale newbie) 1.0)
    ;; unfortunately having an offset breaks rotation, so reset offset of cloned things to zero.
    (incf (sprite-x newbie) (poly-sprite-xoff newbie))
    (incf (sprite-y newbie) (poly-sprite-yoff newbie))
    (setf (poly-sprite-xoff newbie) 0)
    (setf (poly-sprite-yoff newbie) 0)
    newbie))



(defmethod (clone-and-drag (sprite mpoly-sprite) evt)
  (let ((newbie (clone sprite))
	(man (dynamic *manager*)))
    (add-sprite man newbie)
    (start-drag man newbie 
		(invoke evt 'getX)
		(invoke evt 'getY) 
		#f)))

(define (make-patblocks)
  (make-patblocks-in (make-window "Pattern Blocks" 600 700 )))

(define (make-patblocks-in window)
  (define manager #f)
  (define panel (new 'com.ibm.jikes.skij.misc.DBPanel 
		     (lambda (graphics)
		       (let ((win (sprite-manager-window manager)))
			 (invoke graphics 'setColor (new 'java.awt.Color 100 100 100))
			 (invoke graphics 'fillRect 0 0 (invoke win 'getWidth) (invoke win 'getHeight))
			 (draw-contents manager graphics)))))
  (set! manager
	(make 'patblock-manager 'window panel))
  (let ((*manager* manager))
    (invoke window 'add panel)
    (initialize manager)
					;  (invoke (sprite-manager-window manager) 'setBackground (new 'java.awt.Color 130 130 130))
    (make-palette manager)

    (invoke window 'validate)
    (set! button-x 60)
    (make-mode-button manager "Drag" 'drag)
    (make-mode-button manager "Rotate" 'rotate)
    (make-mode-button manager "Group" 'select
		      (lambda ()
			(if (eq? 'select (patblock-manager-mode manager))
			    (begin
			      (create-group manager)
			      (set-mode manager 'drag)
			      #t)
			    #f)))
    (make-mode-button manager "Clone" 'clone )
    (make-mode-button manager "Delete" 'delete)
    (if (not (instanceof window 'java.awt.Frame))
	(let ((detach-button #f))
	  (set! detach-button
		(make-text-button manager "Window" (lambda () 
						     (detach (dynamic *manager*))
						     (remove-sprite manager detach-button))))))
    (set-mode manager 'drag)
    (sleep 10)				;wait for it (+++)
    (manager-clock manager)
    manager))

(define (make-palette manager)
  (map (lambda (shape)
	 (let* ((path (cadr shape))
		(color (apply new 'java.awt.Color (caddr shape)))
		(sprite (make 'poly-source
			  'x 0
			  'y 0
			  'scale palette-scale
			  'heading (double (caddr (cdddr shape)))
			  'color color ; (random-color)
			  'path path)))
	   (add-to-palette manager sprite)))
       shapes))

;;; ok, dumb.
(defmethod (clone (struct sprite))	;+++ how to specify a method that applies to any object?
  (list->vector (vector->list struct)))	

(defmethod (clone-into (struct sprite) new-type)
  (let ((args (list new-type))
	(i 1))
    (for-each (lambda (slot)
		(push slot args)
		(push (vector-ref struct i) args)
		(incf i))
	      (structure-fields (structure-type struct)))
    (print args)
    (apply make (reverse args))))

  
(defstruct (group-sprite mpoly-sprite) (elements '()))

(defmethod (initialize (sprite group-sprite))
  (compute-bounds sprite))

(defmethod (rotate-about (sprite group-sprite) dtheta x y)
  (for-each (lambda (elt)
	      (rotate-about elt 
			    dtheta
			    (- (sprite-x elt) (sprite-x sprite))
			    (- (sprite-y elt) (sprite-y sprite))))
	    (group-sprite-elements sprite))
  (call-next-method))

(defmethod (rescale (sprite group-sprite) by)
  (for-each (lambda (elt)
	      (rescale elt by)
	      (setf (sprite-x elt) (* (sprite-x elt) by))
	      (setf (sprite-y elt) (* (sprite-y elt) by))
	      )
	    (group-sprite-elements sprite))
  (call-next-method))

(defmethod (paint (sprite group-sprite) g)
  (for-each (lambda (elt) 
	      (paint elt g))
	    (group-sprite-elements sprite))
  ;; debug
  '(let ((bounds  (compute-bounds sprite)))
    (invoke g 'setColor white)
    (invoke g 'drawRect (peek bounds 'x) (peek bounds 'y) (peek bounds 'width) (peek bounds 'height))))

(defmethod (paint-highlight (sprite group-sprite) g)
  (for-each (lambda (elt) 
	      (paint-highlight elt g))
	    (group-sprite-elements sprite)))

(define (make-group sprites)
  (let ((group (make 'group-sprite 
		 'elements sprites
		 'x 0 'y 0)))
    group))

(define (make-group sprites)
  (let ((group (make 'group-sprite 
		 'elements (apply nconc (map sprite-primitives sprites))
		 'x 0 'y 0)))
    group))

(defmethod (sprite-primitives (sprite sprite))
  (list sprite))

(defmethod (sprite-primitives (sprite group-sprite))
  (group-sprite-elements sprite))

(defmethod (create-group (man patblock-manager))
  (let* ((sprites (patblock-manager-selection man))
	 (group (make-group sprites)))
    (for-each (lambda (s) (remove-sprite man s)) sprites)
    (add-sprite man group)
    (setf (patblock-manager-selection man) '())
    (make-palette-source group)
    (manager-repaint man)))

(defmethod (ungroup (sprite group-sprite))
  (let ((man (dynamic *manager*)))
    (for-each (lambda (s) (add-sprite man s))
	      (group-sprite-elements sprite))
    (remove-sprite man sprite)
    (manager-repaint man)))

;;; do a deep copy
(defmethod (clone (sprite group-sprite))
  (let ((new (call-next-method)))
    (setf (group-sprite-elements new)
	  (map clone (group-sprite-elements sprite)))
    new))

(defmethod (point-in-sprite? (sprite group-sprite) x y)
  (let ((xp x)				;+++
	(yp y))
    (call/cc 
     (lambda (exit)
       (for-each
	(lambda (elt)
	  (when (point-in-sprite? elt xp yp)
		(exit #t)))
	(group-sprite-elements sprite))
       #f))))

;;; should remove duplicates using approximation, or something.
(defmethod (sprite-corners (sprite group-sprite))
  (apply nconc (map sprite-corners (group-sprite-elements sprite))))

(defmethod (start-drag (sprite group-sprite) x y rotate?)
  (setf (sprite-x sprite) x)
  (setf (sprite-y sprite) y))

(defmethod (move (sprite group-sprite) dx dy)
  (setf (sprite-x sprite) 0)
  (setf (sprite-y sprite) 0)
  (drag sprite dx dy))

(defmethod (drag (sprite group-sprite) x y)
  (let ((dx (- x (sprite-x sprite)))
	(dy (- y (sprite-y sprite))))
    (for-each (lambda (elt)
		(move elt dx dy))
	      (group-sprite-elements sprite))
  (setf (sprite-x sprite) x)
  (setf (sprite-y sprite) y)    
  ))

(defmethod (compute-bounds (sprite group-sprite))
  (define bounds (compute-bounds (car (group-sprite-elements sprite))))
  (for-each (lambda (elt)
	      (let ((rect (compute-bounds elt)))
		(setf bounds (invoke bounds 'createUnion (compute-bounds elt)))))
	    (cdr (group-sprite-elements sprite)))
  (setf (size-sprite-xs sprite) (peek bounds 'width))
  (setf (size-sprite-ys sprite) (peek bounds 'height))
  bounds)


(defmethod (make-palette-source (sprite group-sprite))
  (let* ((clone (clone sprite))
	 (bounds #f))
    (setf (vector-ref clone 0) 'group-source)
    (rescale clone .6)
    (set! bounds (compute-bounds clone))
    ;; This makes the geometry of the clone saner (zero-based)
    (drag clone (-  (peek bounds 'x)) (- (peek bounds 'y)))
    (setf (sprite-x clone) 0)
    (setf (sprite-y clone) 0)
    (add-to-palette (dynamic *manager*) clone)
    clone))


(defmethod (make-palette-source (sprite group-sprite))
  (let* ((clone (clone-into sprite 'group-source))
	 (bounds #f))
;    (setf (vector-ref clone 0) 'group-source)
    (set! bounds (compute-bounds clone))
    (let* ((max-dim (max (peek bounds 'width) (peek bounds 'height)))
	   (scale (min (/ palette-max max-dim) palette-scale)))
      (rescale clone scale))
    (set! bounds (compute-bounds clone))
    ;; This makes the geometry of the clone saner (zero-based)
    (drag clone (-  (peek bounds 'x)) (- (peek bounds 'y)))
    (setf (sprite-x clone) 0)
    (setf (sprite-y clone) 0)
    (add-to-palette (dynamic *manager*) clone)
    clone))

;;; sigh, wish for multiple inheritance
(defstruct (group-source group-sprite) (scale 1.0))

(defmethod (handle-event (sprite group-source) evt)
  (clone-and-drag sprite evt)
  )

(defmethod (clone (sprite group-source))
  (let ((newbie (call-next-method)))
    (setf (vector-ref newbie 0) 'group-sprite) ;change to regular shape
;    (setf (mpoly-sprite-scale newbie) 1.0)
    (rescale newbie (/ 1.0 (mpoly-sprite-scale sprite)))
    (let ((nbounds (compute-bounds newbie)))
      (move newbie (- (sprite-x sprite) (peek nbounds 'x)) (- (sprite-y sprite) (peek nbounds 'y))))
      newbie))


(defstruct (patblock-manager sprite-drag-manager) 
  (mode 'drag)
  (palette-y 50)
  (selection '()))

(defmethod (add-to-palette (manager patblock-manager) sprite)
    (initialize sprite)
;    (setf (sprite-x sprite) 20.0)
;    (setf (sprite-y sprite) (patblock-manager-palette-y manager))
    (drag sprite 20.0 (patblock-manager-palette-y manager))
    (add-sprite manager sprite)
    (incf (patblock-manager-palette-y manager) 
	  (+ (size-sprite-ys sprite) 20)))

(defmethod (draw-contents (manager patblock-manager) graphics)
  (call-next-method)
  (for-each (lambda (sprite)
	      (paint-highlight sprite graphics))
	    (patblock-manager-selection manager)))

(defmethod (remove-sprite (manager patblock-manager) sprite)
;;; This fixes a bug, but Ben likes it better with the bug.
  (deletef sprite (patblock-manager-selection manager))
  (call-next-method)
  )

;;; doesn't work for groups +++
(defmethod (snap-in-heading (sprite mpoly-sprite))
  (setf (mpoly-sprite-heading sprite)
	(* head-snap (round (/ (mpoly-sprite-heading sprite) head-snap)))))

;;; better?
(defmethod (snap-in-heading (sprite mpoly-sprite))
  (let ((manager (dynamic *manager*)))
    (rotate-about sprite
		  (- (* head-snap (round (/ (mpoly-sprite-heading sprite) head-snap)))
		     (mpoly-sprite-heading sprite))
		  (sprite-drag-manager-drag-x-offset manager)
		  (sprite-drag-manager-drag-y-offset manager))))


(defmethod (snap-in (manager patblock-manager) sprite)
  (snap-in-heading sprite)
  (call/cc 
   (lambda (return)
     (let ((rest (sprite-manager-sprites manager))
	   (our-corners (sprite-corners sprite)))
       (map (lambda (other)
	      (when (and (is-mpoly-sprite? other)
			 (not (is-poly-source? other));; exclude palette
			 (not (is-group-source? other))
			 (not (eq? other sprite)))
	      (map (lambda (other-corner)
		     (map (lambda (our-corner)
			    ;; +++ actually this fast test doesn't make much difference...it's the n^2 effect when dragging a big group
			    (when (and (< (fast-distance-bound our-corner other-corner) snap-in-epsilon)
				       (< (distance our-corner other-corner) snap-in-epsilon))
				  (move sprite 
					(- (car other-corner) (car our-corner))
					(- (cdr other-corner) (cdr our-corner)))
				  (return other)))
			  our-corners))
		   (sprite-corners other))))
	    rest)))))

(defmethod (stop-drag (manager patblock-manager))
  (awhen (sprite-drag-manager-dragged manager)
	 (snap-in manager it))
  (manager-repaint manager)
  (setf (sprite-drag-manager-dragged manager) #f))

;; could be more efficient
(defmethod (sprite-corners (sprite poly-sprite))
  (map cons 
       (vector->list (peek (poly-sprite-poly sprite) 'xpoints))
       (vector->list (peek (poly-sprite-poly sprite) 'ypoints))))

(defmethod (sprite-corners (sprite poly-sprite))
  (let* ((poly (poly-sprite-poly sprite))
	 (npoints (- (peek poly 'npoints) 1)) ;omit closing point
	 (xs (peek poly 'xpoints))
	 (ys (peek poly 'ypoints)))
    (letrec ((build 
	      (lambda (n)
		(if (= n npoints) '()
		    (cons (cons (vector-ref xs n)
				(vector-ref ys n))
			  (build (+ n 1)))))))
      (build 0))))

(define (distance p1 p2)
  (let ((square (lambda (x) (* x x))))
    (sqrt (+ (square (- (car p1) (car p2)))
	     (square (- (cdr p1) (cdr p2)))))))

(define (fast-distance-bound p1 p2)
  (+ (abs (- (car p1) (car p2)))
     (abs (- (cdr p1) (cdr p2)))))

;;; Commands


(defmethod (handle-event (man patblock-manager) evt)
  (let ((*manager* man))
    (cond ((sprite-drag-manager-dragged man)
	   (handle-event (sprite-drag-manager-dragged man) evt))
	  ((= (invoke evt 'getID) mouse-pressed-event-id)
	   (let ((sprite (sprite-at man (invoke evt 'getX) (invoke evt 'getY))))
	     (if sprite
		 (handle-event sprite evt)
		 (call-next-method))))
	  ;; ignore everything else (I think)
	  (else
	   ))))

(defmethod (toggle-selection (man patblock-manager) sprite)
  (if (memq sprite (patblock-manager-selection man))
      (deletef sprite (patblock-manager-selection man))
      (push sprite (patblock-manager-selection man)))
  (manager-repaint man))

;;; Save restore     
(defmethod (dump-form1 (man patblock-manager))
  `(restore-saved-patblocks
    ',(map dump-form1 (sprite-manager-sprites man))))

(define (restore-saved-patblocks sprites)
  (let ((m (make-patblocks)))
    (for-each (lambda (spritedef)
		(if spritedef
		    (let ((sprite (list->vector spritedef)))
		      (undump-fixup sprite)
		      (add-sprite m sprite))))
	      sprites)
    m))
		    


(defmethod (dump-form1 (sprite sprite))
  (vector->list sprite))

(defmethod (dump-form1 (sprite mpoly-sprite))
  (let ((saved-color (shape-sprite-color sprite))
	(result #f))
    (setf (shape-sprite-color sprite) `(make-color ,(invoke c 'getRed) ,(invoke c 'getGreen) ,(invoke c 'getBlue)))
    (set! result (call-next-method))
    (setf (shape-sprite-color sprite) saved-color)
    result))

(defmethod (dump-form1 (sprite poly-sprite))
  (setf (poly-sprite-poly sprite) #f)
  (call-next-method))
  
;;; not these
(defmethod (dump-form1 (sprite poly-source))
  #f)

(defmethod (dump-form1 (thing button))
  #f)

(defmethod (undump-fixup (sprite sprite))
  )

(defmethod (undump-fixup (sprite mpoly-sprite))
  (setf (shape-sprite-color sprite)
	(eval (shape-sprite-color sprite))))

(define (make-color r g b)
  (new 'java.awt.Color r g b))


;--------

(defmethod (dump-form (sprite poly-source))
  #f)

(defmethod (dump-form (sprite poly-sprite))
  `(poly-sprite
    ,(sprite-x sprite)
    ,(sprite-y sprite)
    ,(mpoly-sprite-heading sprite)
    ,(aif (find (poly-sprite-path sprite)
		shapes
		(lambda (path shapedef) 
		  (equal? path (cadr shapedef))))
	  (car it)
	  'unknown)))

(defmethod (dump-form (thing mode-button))
  #f)

(defmethod (dump-form (sprite group-sprite))
  `(group-sprite
    ,@(map dump-form (group-sprite-elements sprite))))

;;; Buttons
(defstruct (button text-sprite) command)

(defmethod (handle-event (sprite button) evt)
  (if (= (invoke evt 'getID) mouse-pressed-event-id)
      ((button-command sprite))))

(define button-font (new 'java.awt.Font "Dialog" 0 18))
(define button-x 10)

(define (make-text-button manager name command)
  (let ((button (make 'button
		  'text name
		  'command command
		  'x button-x
		  'y 10
		  'font button-font
		  'color white)))
    (initialize button)
    (incf button-x 80)
    (add-sprite manager button)
    button))
	    
(defstruct (modal-button button)
 (on? #f)
 mode)

(defmethod (paint (sprite modal-button) g)
  (when (modal-button-on? sprite)
	(invoke g 'setColor white)
	(invoke g 'drawRect 
		(integer (- (sprite-x sprite) 1))
		(integer (sprite-y sprite))
		(integer (+ (size-sprite-xs sprite) 1))
		(integer (+ (size-sprite-ys sprite) 6))))
  (call-next-method))

(defstruct (mode-button modal-button) mode)

;;; optional arg is an additional action (as a thunk). 
;;; If it returns #t, no other action is taken. #f means act normal.
;;; dotted args don't work with defmethods (not sure why?)
(define (make-mode-button manager name mode . optional)
  (let ((button (make 'mode-button
		  'mode mode
		  'text name
		  'x button-x
		  'y 10 ; (- (invoke (sprite-manager-window manager) 'getHeight) 50)
		  'font button-font
		  'mode mode
		  'color white)))
    (initialize button)
    (setf (button-command button)
	  (lambda ()
	    (when (or (null? optional)
		      (not ((car optional))))
		  (set-mode manager mode)
		  (setf (modal-button-on? button) #t)
		  (manager-repaint manager))))
    (incf button-x 80)
    (add-sprite manager button)
    button))

(defmethod (detach (man patblock-manager))
  (let* ((ow (sprite-manager-window man))
	 (nw (make-window "Pattern Blocks" (invoke ow 'getWidth) (invoke ow 'getHeight))))
    (invoke nw 'add (sprite-manager-window man))))

(defmethod (set-mode (man patblock-manager) new-mode)
  (setf (patblock-manager-mode man) new-mode)
  ;; turn off all buttons; the right one gets turned on by button command
  (for-each (lambda (sprite)
	      (when (is-mode-button? sprite)
		    (setf (modal-button-on? sprite) (eq? (mode-button-mode sprite) new-mode))))
	    (sprite-manager-sprites man)))
  


;;; Tester
(define (pattest) 
  (let ((man (make-patblocks)))
    (sleep 10)
    (manager-repaint man)))

(define (applet-patblocks)
  (define w (invoke *applet* 'getParent))
  (define l  (vector-ref (invoke w 'getComponents) 0))
  ;; show the listener (for debug only)
;  (define xw (make-window "Listener" 300 300))
;  (invoke xw 'add l)
  (invoke w 'remove l)
  (make-patblocks-in w))


;;; Not yet
(defmethod (sprite-context-menu (sprite mpoly-sprite))
  (display-popup-menu
   (make-popup-menu
    (list (make-menu-item "Foo")
	  (make-menu-item "Bar")))
   (sprite-manager-window (dynamic *manager*))
   (integer (sprite-x sprite))
   (integer (sprite-y sprite))))
