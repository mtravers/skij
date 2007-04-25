;;; Redone to use methods

;;; Sprites

(defstruct sprite x y)

;;; defgeneric paint

;;; Poorly named
(defmethod (move (sprite sprite) dx dy)
  (incf (sprite-x sprite) dx)
  (incf (sprite-y sprite) dy))

(defmethod (clock (sprite sprite))
  )

(define (random-color)
  (new 'java.awt.Color (float (random #f)) (float (random #f)) (float (random #f))))

;;; Mousing

(define mouse-clicked-event-id (peek-static 'java.awt.event.MouseEvent 'MOUSE_CLICKED))
(define mouse-pressed-event-id (peek-static 'java.awt.event.MouseEvent 'MOUSE_PRESSED))
(define mouse-released-event-id (peek-static 'java.awt.event.MouseEvent 'MOUSE_RELEASED))
(define mouse-dragged-event-id (peek-static 'java.awt.event.MouseEvent 'MOUSE_DRAGGED))
(define button-3-mask (peek-static 'java.awt.event.InputEvent 'BUTTON3_MASK))

;;; build drag in here, because we don't have mixins, sigh
(defmethod (handle-event (sprite sprite) evt)
  (let ((man (dynamic *manager*)))
    (case (invoke evt 'getID)
      ((#,mouse-dragged-event-id)
       (let ((x (invoke evt 'getX))
	     (y (invoke evt 'getY))
	     (rotate? (sprite-drag-manager-rotate? man)))
	 (if rotate?
	     (rotate sprite x y)
	     (drag sprite x y))
	 (manager-repaint man)))
      ((#,mouse-pressed-event-id)
       (start-drag man sprite 
		   (invoke evt 'getX)
		   (invoke evt 'getY) 
		   (= (invoke evt 'getModifiers)
		      button-3-mask)))
      ((#,mouse-released-event-id)
       (stop-drag man)))))

;;; Sprite manager handles most stuff

(defstruct sprite-manager (sprites '()) (window #f) buffer)

;;; exp -- this does not fix resize problem (but would make a new image when necessary) +++
(defmethod (initialize (manager sprite-manager))
  (unless (sprite-manager-window manager)
	  (setf (sprite-manager-window manager)
		(make-window "Sprites" 800 600)))
  (let* ((w (sprite-manager-window manager))
	 (listener
	  (new 'com.ibm.jikes.skij.misc.GenericCallback
	       (lambda (evt)
		 (handle-event manager evt))))

	 (xlistener (new 'com.ibm.jikes.skij.misc.GenericCallback
			 (lambda (evt)
			   (manager-repaint manager))))
	 )
    (invoke w 'addMouseListener listener)
    (invoke w 'addMouseMotionListener listener)
;    (invoke w 'addWindowListener xlistener)

;;; +++ add resize handler?
;    (set-sprite-manager-buffer! manager (invoke w 'createImage (invoke w 'getWidth) (invoke w 'getHeight)))
    ))



(defmethod (manager-clock (man sprite-manager))
  (for-each clock (sprite-manager-sprites man))
  (manager-repaint man))

(defmethod (sprite-at (manager sprite-manager) x y)
  (call/cc 
   (lambda (return)
     (for-each  
      (lambda (sprite)
	(if (point-in-sprite? sprite x y)
	    (return sprite)))
      (reverse (sprite-manager-sprites manager)))
     #f)))

;;; +++ this does too much work, finding the sprite on every mouse motion
(defmethod (handle-event (manager sprite-manager) evt)
  ;; +++ do all events have x/y?
  (let* ((x (invoke evt 'getX))
	 (y (invoke evt 'getY))
	 (moused-sprite (sprite-at manager x y))
	 (*manager* manager))
    (if moused-sprite
	(handle-event moused-sprite evt)
;	(print `(,manager got ,evt))
	)))
			 
(defmethod (add-sprite (manager sprite-manager) sprite)
  ;; +++ verify that sprite is sprite
  (set-sprite-manager-sprites! 
   manager
   (nconc (sprite-manager-sprites manager) (list sprite)))
;  (manager-repaint manager)
  )

(defmethod (remove-sprite (manager sprite-manager) sprite)
  (set-sprite-manager-sprites! manager (delete sprite (sprite-manager-sprites manager)))
;  (manager-repaint manager)
  )

'(defmethod (manager-repaint (man sprite-manager))
  (write 'repaint)
  (synchronized man			;make sure only one thread at a time does this.
    (let* ((buffer (sprite-manager-buffer man))
	   (window (sprite-manager-window man))
	   ;; Kludge class is necessary workaround to an access problem (+++ no longer necessary)
	   (graphics (invoke-static 'com.ibm.jikes.skij.misc.Kludge 'imageGraphics buffer))
	   (*manager* man))
      ; clear the offscreen buffer
      (invoke graphics 'setColor (invoke window 'getBackground))
      (invoke graphics 'fillRect 0 0 (invoke window 'getWidth) (invoke window 'getHeight))
      ; paint everything into offscreen buffer
      (draw-contents man graphics)
      ; copy onto window
      (invoke (invoke window 'getGraphics) 'drawImage buffer 0 0 window)
      )))

;;; a version without double-buffering
(defmethod (manager-repaint (man sprite-manager))
  (synchronized man			;make sure only one thread at a time does this.
    (let* (
	   (window (sprite-manager-window man))
	   ;; Kludge class is necessary workaround to an access problem (+++ no longer necessary)
	   (graphics (invoke window 'getGraphics))
	   (*manager* man))
      ; clear the offscreen buffer
      (invoke graphics 'setColor (invoke window 'getBackground))
      (invoke graphics 'fillRect 0 0 (invoke window 'getWidth) (invoke window 'getHeight))
      ; paint everything into offscreen buffer
      (draw-contents man graphics)
      )))

(defmethod (manager-repaint (man sprite-manager))
  (invoke (sprite-manager-window man) 'repaint))

(defmethod (draw-contents (man sprite-manager) graphics)
  (for-each (lambda (sprite) (paint sprite graphics))
	    (sprite-manager-sprites man)))


(defstruct (sprite-drag-manager sprite-manager)
  (dragged #f) (drag-x-offset 0) (drag-y-offset 0) (rotate? #f))

;;; used to be a handle-event for sprite-drag-maanger, but most of that logic is now in the sprite itself...

(defmethod (start-drag (manager sprite-drag-manager) sprite x y rotate?)
  ;; crock -- this fixes a rotate bug with group sprites that I am too lazy to do right
  (when rotate?
	(start-drag manager sprite x y #f))
  (setf (sprite-drag-manager-dragged manager) sprite)
  (setf (sprite-drag-manager-rotate? manager) rotate?)
  (setf (sprite-drag-manager-drag-x-offset manager) (- (sprite-x sprite) x))
  (setf (sprite-drag-manager-drag-y-offset manager) (- (sprite-y sprite) y))
  (bring-to-top manager sprite)
  (manager-repaint manager)
  (start-drag sprite x y rotate?))

(defmethod (bring-to-top (man sprite-manager) sprite)
  (setf (sprite-manager-sprites man)
	(nconc (delete sprite (sprite-manager-sprites man))
	       (list sprite))))

;;; see group-sprite
(defmethod (start-drag (sprite sprite) x y rotate?)
  )

;;; used?
(defmethod (stop-drag (manager sprite-drag-manager))
  (setf (sprite-drag-manager-dragged manager) #f))  
  
;; Poorly named -- should be move-to or something 
(defmethod (drag (sprite sprite) x y)
  (let ((manager (dynamic *manager*)))
    (set-sprite-x! sprite (+ x (sprite-drag-manager-drag-x-offset manager)))
    (set-sprite-y! sprite (+ y (sprite-drag-manager-drag-y-offset manager)))))

;;; Some sprites and demos

(defstruct (size-sprite sprite) xs ys)

;;; used?
(defmethod (point-in-sprite? (sprite size-sprite) x y)
  (and (<= (sprite-x sprite) x)
       (<= (sprite-y sprite) y)
       (<= x (+ (sprite-x sprite) (size-sprite-xs sprite)))
       (<= y (+ (sprite-y sprite) (size-sprite-ys sprite)))))

(defstruct (shape-sprite size-sprite) color)

(defstruct (rect-sprite shape-sprite))

(defmethod (paint (sprite rect-sprite) g)
  (invoke g 'setColor (shape-sprite-color sprite))
  (invoke g 'fillRect 
	  (integer (sprite-x sprite))
	  (integer (sprite-y sprite))
	  (integer (size-sprite-xs sprite))
	  (integer (size-sprite-ys sprite))))

;;; Text sprites

(defstruct (text-sprite size-sprite) text font color)

(define descent 0)			;+++

(defmethod (initialize (sprite text-sprite))
  (let* ((font (text-sprite-font sprite))
	 (text (text-sprite-text sprite))
	 (bounds (invoke font 'getStringBounds text (frc)))
	 (linemetrics (invoke font 'getLineMetrics text (frc)))
	 ;; +++ needs to get added in at paint time
	 (descent (invoke linemetrics 'getDescent)))
    ;; +++ probably not quite right, x and y of bounds are not necc. 0
    (setf (size-sprite-xs sprite) (invoke bounds 'getWidth))
    (setf (size-sprite-ys sprite) (invoke linemetrics 'getAscent))))

 ;+++ float is due to a constructor lookup bug.
(define bigfont (new 'java.awt.Font "Dialog" 0 (float 48) #t)) 

;;; Kludge to have a globally available FontRenderContext
;;; +++ will fail if first window is hidden, blech.
(define *frc* #f)
(define (frc)
  (or *frc*
      (begin
	(set! *frc*
	      (invoke (invoke (sprite-manager-window (dynamic *manager*)) 'getGraphics) 'getFontRenderContext))
	*frc*)))

(defmethod (paint (sprite text-sprite) g)
  (invoke g 'setFont (text-sprite-font sprite))
  (invoke g 'setColor (text-sprite-color sprite))
  (invoke g 'drawString 
	  (text-sprite-text sprite)
	  (integer (sprite-x sprite))
	  (integer (+ (sprite-y sprite)
		      (size-sprite-ys sprite)
		      (- descent)
		      ))))

(define (make-random-rect)
  (make 'rect-sprite 
    'x (random 300) 'y (random 300) 
    'xs (+ 20 (random 100)) 'ys (+ 20 (random 100)) 
    'color (random-color)))

(define (make-rect-window)
  (define manager (make-sprite-window "Sprites" 300 300))
  (repeat 10 (add-sprite manager (make-random-rect)))
;  (manager-clock man)
  manager)
