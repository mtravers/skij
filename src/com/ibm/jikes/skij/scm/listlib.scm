;;; List utils
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Copyright (c) 1998 by Olin Shivers. You may do as you please with
;;; this code as long as you do not remove this copyright notice or
;;; hold me liable for its use. Please send bug reports to shivers@ai.mit.edu.
;;;     -Olin

;;; This is a library of list- and pair-processing functions. I wrote it after
;;; carefully considering the functions provided by the libraries found in
;;; R4RS/R5RS Scheme, MIT Scheme, Gambit, RScheme, MzScheme, slib, Common
;;; Lisp, Bigloo, guile, T, APL and the SML standard basis. It is a pretty
;;; rich toolkit, providing a superset of the functionality found in any of
;;; the various Schemes I considered.

;;; This is carefully tuned code; do not modify casually.
;;; - It is careful to share storage when possible;
;;; - Side-effecting code tries not to perform redundant writes.

;;; This implementation is intended as a portable reference implementation
;;; of my list-lib package. See the porting notes below for more information.

;;; Exported:
;;;   xcons tree-copy make-list list-tabulate list* list-copy
;;;   first second third fourth fifth sixth seventh eighth ninth tenth nth
;;;   take drop take! drop! last last-pair
;;;   append! reverse-append reverse-append!
;;;   unfold unfold/tail foldl foldr pair-foldl pair-foldr reducel reducer
;;;   append-map append-map! map! pair-for-each filter-map
;;;   filter  partition  remove
;;;   filter! partition! remove! 
;;;   find find-tail any? every?
;;;   del  delq  delv  delete 
;;;   del! delq! delv! delete!
;;;   mem ass acons alist-copy
;;;   alist-delete  del-ass  del-assq  del-assv  del-assoc
;;;   alist-delete! del-ass! del-assq! del-assv! del-assoc!
;;;   reverse!
;;; 
;;; In principle, the following R4RS list- and pair-processing procedures
;;; are also part of this package's exports, although they are not defined
;;; in this file:
;;;   cons pair? null? list? list length append reverse
;;;   car cdr ... cdddar cddddr set-car! set-cdr! 
;;;   member memq memv assoc assq assv
;;;   map for-each
;;; The remaining two R4RS list-processing procedures are not included: 
;;;   list-tail (use drop) list-ref (use nth)

;;; A note on recursion and iteration/reversal:
;;; Many iterative list-processing algorithms naturally compute the elements
;;; of the answer list in the wrong order (left-to-right or head-to-tail) from
;;; the order needed to cons them into the proper answer (right-to-left, or
;;; tail-then-head). One style or idiom of programming these algorithms, then,
;;; loops, consing up the elements in reverse order, then destructively 
;;; reverses the list at the end of the loop. I do not do this. The natural
;;; and efficient way to code these algorithms is recursively. This trades off
;;; intermediate temporary list structure for intermediate temporary stack
;;; structure. In a stack-based system, this improves cache locality and
;;; lightens the load on the GC system. Don't stand on your head to iterate!
;;; Recurse, where natural. Multiple-value returns make this even more
;;; convenient, when the recursion/iteration has multiple state values.

;;; Porting:
;;; A port of this library to a specific Scheme system might wish to tune
;;; this code to exploit particulars of the implementation. In particular,
;;; the n-ary mapping functions are particularly slow and cons-intensive,
;;; and are good candidates for tuning.
;;;
;;; The code has only two non-R4RS dependencies:
;;;   A single call to an ERROR procedure in MAKE-LIST;
;;;   Uses of the R5RS multiple-value functions CALL-WITH-VALUES and VALUES
;;;     in the multiple-value-returning PARTITION and PARTITION! procedures. 
;;;
;;; If there's a way to mark these procedures as candidates for integration,
;;; they should be so marked. It would also be nice if the n-ary ops could
;;; be unfolded by the compiler into a chain of binary-op applications. But
;;; this kind of compiler technology no longer exists in the Scheme world as 
;;; far as I can see.



;;; Constructors
;;;;;;;;;;;;;;;;

;;; Occasionally useful as a value to be passed to a fold or other
;;; higher-order procedure.
(define (xcons d a) (cons a d))

;;; Recursively copy every cons.
(define (tree-copy x)
  (let recur ((x x))
    (if (not (pair? x)) x
        (cons (recur (car x)) (recur (cdr x))))))

;;; Make a list of length LEN.

(define (make-list len . maybe-elt)
  (let ((elt (cond ((null? maybe-elt) #f) ; Default value
                   ((null? (cdr maybe-elt)) (car maybe-elt))
                   (else (error "Too many arguments to MAKE-LIST"
                                (cons len maybe-elt))))))
    (do ((i len (- i 1))
         (ans '() (cons elt ans)))
        ((<= i 0) ans))))

;;; Make a list of length LEN. Elt i is (PROC i) for 0 <= i < LEN.

(define (list-tabulate len proc)
  (do ((i (- len 1) (- i 1))
       (ans '() (cons (proc i) ans)))
      ((< i 0) ans)))

;;; (list* a1 a2 ... an) = (cons a1 (cons a2 (cons ... an)))
;;; (list* a1) = a1     (list* a1 a2 ...) = (cons a1 (list* a2 ...))

(define (list* first . rest)
  (let recur ((x first) (rest rest))
    (if (not (pair? rest)) x
        (cons x (recur (car rest) (cdr rest))))))

(define (list-copy lis)                         ; Can't use (foldr cons '() l)
  (let recur ((lis lis))                        ; because we want to do an
    (if (pair? lis)                             ; exact copy even when LIS is
        (cons (car lis) (recur (cdr lis)))      ; not a proper list.
        lis)))

;;; Selectors
;;;;;;;;;;;;;

(define first  car)
(define second cadr)
(define third  caddr)
(define fourth cadddr)
(define (fifth   x) (car    (cddddr x)))
(define (sixth   x) (cadr   (cddddr x)))
(define (seventh x) (caddr  (cddddr x)))
(define (eighth  x) (cadddr (cddddr x)))
(define (ninth   x) (car  (cddddr (cddddr x))))
(define (tenth   x) (cadr (cddddr (cddddr x))))

(define nth list-ref)

;;; take & drop
;;; K >= 0: Take and drop  K elts from the front of the list.
;;; K <= 0: Take and drop -K elts from the end   of the list.

(define (take lis k)
  (if (negative? k)
      (list-tail lis (+ k (length lis)))
      (let recur ((lis lis) (k k))
        (if (zero? k) '()
            (cons (car lis)
                  (recur (cdr lis) (- k 1)))))))

(define (drop lis k)
  (if (negative? k)
      (let recur ((lis lis) (nelts (+ k (length lis))))
        (if (zero? nelts) '()
            (cons (car lis)
                  (recur (cdr lis) (- nelts 1)))))
      (list-tail lis k)))


(define (take! lis k)
  (cond ((zero? k) '())
        ((positive? k)
         (set-cdr! (list-tail lis (- k 1)) '())
         lis)
        (else (list-tail lis (+ k (length lis))))))

(define (drop! lis k)
  (if (negative? k)
      (let ((nelts (+ k (length lis))))
        (if (zero? nelts) '()
            (begin (set-cdr! (list-tail lis (- nelts 1)) '())
                   lis)))
      (list-tail lis k)))


(define (last lis) (car (last-pair lis)))

(define (last-pair lis)
  (let lp ((lis lis))
    (let ((tail (cdr lis)))
      (if (pair? tail) (lp tail) lis))))


;;; append reverse-append
;;;;;;;;;;;;;;;;;;;;;;;;;

(define (append! . lists)
  ;; First, scan through lists looking for a non-empty one.
  (let lp ((lists lists))
    (if (not (pair? lists)) '()
        (let ((first (car lists))
              (rest (cdr lists)))
          (cond ((not (pair? first)) (lp rest))

                ;; Now, do the splicing.
                (else (let lp ((tail-chunk first)
                               (rest rest))
                        (if (pair? rest)
                            (let ((next (car rest))
                                  (rest (cdr rest)))
                              (cond ((pair? next)
                                     (set-cdr! (last-pair tail-chunk) next)
                                     (lp next rest))
                                    (else (lp tail-chunk rest))))))
                      first))))))


(define (reverse-append rev-head tail) (foldl cons tail rev-head))

(define (reverse-append! rev-head tail)
  (pair-foldl (lambda (pair tail) (set-cdr! pair tail) pair)
              tail
              rev-head))


;;; fold/unfold
;;;;;;;;;;;;;;;

(define (unfold/tail p f g e seed)
  (let recur ((seed seed))
    (if (p seed) (e seed)
        (cons (f seed) (recur (g seed))))))

(define (unfold p f g seed)
  (let recur ((seed seed))
    (if (p seed) '()
        (cons (f seed) (recur (g seed))))))

(define (foldl kons knil lis)
  (let lp ((lis lis) (ans knil))
    (if (pair? lis)
        (lp (cdr lis) (kons (car lis) ans))
        ans)))

(define (foldr kons knil lis)
  (let recur ((lis lis))
    (if (pair? lis)
        (let ((head (car lis)))
          (kons head (recur (cdr lis))))
        knil)))


(define (pair-foldr f zero lis)
  (let recur ((lis lis))
    (if (pair? lis) (f lis (recur (cdr lis))) zero)))

(define (pair-foldl f zero lis)
  (let lp ((lis lis) (ans zero))
    (if (pair? lis)
        (let ((tail (cdr lis)))         ; Grab the cdr now,
          (lp tail (f lis ans)))        ; in case F SET-CDR!s LIS.
        ans)))
      

;;; REDUCEL and REDUCER only use RZERO in the empty-list case.
(define (reducel f rzero lis)
  (if (pair? lis)
      (foldl f (car lis) (cdr lis))
      rzero))

(define (reducer f rzero lis)
  (if (pair? lis)
      (let recur ((head (car lis)) (lis (cdr lis)))
        (if (pair? lis)
            (f head (recur (car lis) (cdr lis)))
            head))
      rzero))



;;; Mappers: append-map append-map! pair-for-each map! filter-map
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; These two little internal utilities are used *by* the general mapper funs.
;;; It'd be nice if they got inlined.

(define (%cars lists)   ; (map car lists)
  (let recur ((lists lists))
    (if (pair? lists) (cons (caar lists) (recur (cdr lists))) '())))

(define (%cdrs lists)   ; (map cdr lists)
  (let recur ((lists lists))
    (if (pair? lists) (cons (cdar lists) (recur (cdr lists))) '())))


(define (append-map f lis1 . lists)
  (if (pair? lists)
      (let recur ((lists (cons lis1 lists)))
        (if (every? pair? lists)
            (append (apply f (%cars lists))
                    (recur (%cdrs lists)))
            '()))
      
      (foldr (lambda (elt ans) (append (f elt) ans)) '() lis1))) ; Fast path

(define (append-map! f lis1 . lists)
  (if (pair? lists)
      (let recur ((lists (cons lis1 lists)))
        (if (every? pair? lists)
            (append! (apply f (%cars lists))
                     (recur (%cdrs lists)))
            '()))

      (foldr (lambda (elt ans) (append! (f elt) ans)) '() lis1)))  ; Fast path


(define (pair-for-each f lis1 . lists)
  (if (pair? lists)

      (let lp ((lists (cons lis1 lists)))
        (if (every? pair? lists)
            (let ((tails (%cdrs lists)))        ; Grab the cdrs now,
              (apply f lists)                   ; in case F SET-CDR!s its args.
              (lp tails))))

      ;; Fast path.
      (let lp ((lis lis1))
        (if (pair? lis) (let ((tail (cdr lis))) ; Grab the cdr now,
                          (f lis)               ; in case F SET-CDR!s LIS.
                          (lp tail))))))

;;; We stop when LIS1 runs out, not when any list runs out.
(define (map! f lis1 . lists)
  (if (pair? lists)
      (let lp ((lis1 lis1) (lists lists))
        (if (pair? lis1)
            (let ((tail1 (cdr lis1))
                  (tails (%cdrs lists)))
              (set-car! lis1 (apply f (car lis1) (%cars lists)))
              (lp tail1 tails))))

      ;; Fast path.
      (pair-for-each (lambda (pair) (set-car! pair (f (car pair)))) lis1))
  lis1)


;;; Map F across L, and save up all the non-false results.
(define (filter-map f lis1 . lists)
  (if (pair? lists)
      (let recur ((lists (cons lis1 lists)))
        (if (every? pair? lists)
            (let ((tails (%cdrs lists)))
              (cond ((apply f (%cars lists)) =>
                     (lambda (x) (cons x (recur tails))))
                    (else (recur tails))))
            '()))
            
      ;; Fast path.
      (foldr (lambda (elt ans) (cond ((f elt) => (lambda (x) (cons x ans)))
                                     (else ans)))
             '() lis1)))



;;; filter, remove, partition
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FILTER, REMOVE, PARTITION and their destructive counterparts do not
;;; disorder the elements of their argument.

;;; Simple version that allocates the entire answer.
;(define (filter pred lis)
;  (foldr (lambda (x l) (if (pred x) (cons x l) l)) '() lis))


;; This FILTER shares the longest tail of L that has no deleted elements.
;; If Scheme had multi-continuation calls, they could be made more efficient.

(define (filter pred lis)                       ; Sleazing with EQ? makes this
  (let recur ((lis lis))                        ; one faster.
    (if (pair? lis)
        (let ((head (car lis))
              (tail (cdr lis)))
          (if (pred head)
              (let ((new-tail (recur tail)))    ; Replicate the RECUR call so
                (if (eq? tail new-tail) lis
                    (cons head new-tail)))
              (recur tail)))                    ; this one can be a tail call.
        '())))

;;; Another version that shares longest tail.
;(define (filter pred lis)
;  (receive (ans no-del?)
;      ;; (recur l) returns L with (pred x) values filtered.
;      ;; It also returns a flag NO-DEL? if the returned value
;      ;; is EQ? to L, i.e. if it didn't have to delete anything.
;      (let recur ((l l))
;       (if (not (pair? l)) (values '() #t)
;           (let ((x  (car l))
;                 (tl (cdr l)))
;             (if (pred x)
;                 (receive (ans no-del?) (recur tl)
;                   (if no-del?
;                       (values l #t)
;                       (values (cons x ans) #f)))
;                 (receive (ans no-del?) (recur tl) ; Delete X.
;                   (values ans #f))))))
;    ans))



;(define (filter! pred lis)                     ; Things are much simpler
;  (let recur ((lis lis))                       ; if you are willing to
;    (if (pair? lis)                            ; push N stack frames & do N
;        (cond ((pred (car lis))                ; SET-CDR! writes, where N is
;               (set-cdr! lis (recur (cdr lis))); the length of the answer.
;               lis)                            
;              (else (recur (cdr lis))))
;        '())))


;;; This implementation of FILTER!
;;; - doesn't cons, and uses no stack;
;;; - is careful not to do redundant SET-CDR! writes, as writes to memory are 
;;;   usually expensive on modern machines, and can be extremely expensive on 
;;;   modern Schemes (e.g., ones that have generational GC's).
;;; It just zips down contiguous runs of in and out elts in LIS doing the 
;;; minimal number of SET-CDR!s to splice the tail of one run of ins to the 
;;; beginning of the next.

(define (filter! pred lis)
  (let lp ((ans lis))
    (cond ((not (pair? ans))      ans)                  ; Scan looking for
          ((not (pred (car ans))) (lp (cdr ans)))       ; first cons of result.

          ;; ANS is the eventual answer.
          ;; SCAN-IN: (CDR PREV) = LIS and (CAR PREV) satisfies PRED.
          ;;          Scan over a contiguous segment of the list that
          ;;          satisfies PRED.
          ;; SCAN-OUT: (CAR PREV) satisfies PRED. Scan over a contiguous
          ;;           segment of the list that *doesn't* satisfy PRED.
          ;;           When the segment ends, patch in a link from PREV
          ;;           to the start of the next good segment, and jump to
          ;;           SCAN-IN.
          (else (letrec ((scan-in (lambda (prev lis)
                                    (if (pair? lis)
                                        (if (pred (car lis))
                                            (scan-in lis (cdr lis))
                                            (scan-out prev (cdr lis))))))
                         (scan-out (lambda (prev lis)
                                     (let lp ((lis lis))
                                       (if (pair? lis)
                                           (if (pred (car lis))
                                               (begin (set-cdr! prev lis)
                                                      (scan-in lis (cdr lis)))
                                               (lp (cdr lis)))
                                           (set-cdr! prev lis))))))
                  (scan-in ans (cdr ans))
                  ans)))))



;;; Answers share common tail with LIS where possible; 
;;; the technique is slightly subtle.

(define (partition pred lis)
  (let recur ((lis lis))
    (if (not (pair? lis)) (values '() '())
        (let ((elt (car lis))
              (tail (cdr lis)))
          (call-with-values (lambda () (recur tail))
            (lambda (in out)
              (if (pred elt)
                  (values (if (pair? out) (cons elt in) lis) out)
                  (values in (if (pair? in) (cons elt out) lis)))))))))



;(define (partition! pred lis)                  ; Things are much simpler
;  (let recur ((lis lis))                       ; if you are willing to
;    (if (not (pair? lis)) (values '() '())     ; push N stack frames & do N
;        (let ((elt (car lis)))                 ; SET-CDR! writes, where N is
;          (receive (in out) (recur (cdr lis))  ; the length of LIS.
;            (cond ((pred elt)
;                   (set-cdr! lis in)
;                   (values lis out))
;                  (else (set-cdr! lis out)
;                        (values in lis))))))))


;;; This implementation of PARTITION!
;;; - doesn't cons, and uses no stack;
;;; - is careful not to do redundant SET-CDR! writes, as writes to memory are
;;;   usually expensive on modern machines, and can be extremely expensive on 
;;;   modern Schemes (e.g., ones that have generational GC's).
;;; It just zips down contiguous runs of in and out elts in LIS doing the
;;; minimal number of SET-CDR!s to splice these runs together into the result 
;;; lists.

(define (partition! pred lis)
  (if (not (pair? lis)) (values '() '())

      ;; This pair of loops zips down contiguous in & out runs of the
      ;; list, splicing the runs together. The invariants are
      ;;   SCAN-IN:  (cdr in-prev)  = LIS.
      ;;   SCAN-OUT: (cdr out-prev) = LIS.
      (letrec ((scan-in (lambda (in-prev out-prev lis)
                          (let lp ((in-prev in-prev) (lis lis))
                            (if (pair? lis)
                                (if (pred (car lis))
                                    (lp lis (cdr lis))
                                    (begin (set-cdr! out-prev lis)
                                           (scan-out in-prev lis (cdr lis))))
                                (set-cdr! out-prev '()))))) ; Done.

               (scan-out (lambda (in-prev out-prev lis)
                           (let lp ((out-prev out-prev) (lis lis))
                             (if (pair? lis)
                                 (if (pred (car lis))
                                     (begin (set-cdr! in-prev lis)
                                            (scan-in lis out-prev (cdr lis)))
                                     (lp lis (cdr lis)))
                                 (set-cdr! in-prev '())))))) ; Done.

        ;; Crank up the scan&splice loops.
        (if (pred (car lis))
            ;; LIS begins in-list. Search for out-list's first pair.
            (let lp ((prev-l lis) (l (cdr lis)))
              (cond ((not (pair? l)) (values lis '()))
                    ((pred (car l)) (lp l (cdr l)))
                    (else (scan-out prev-l l (cdr l))
                          (values lis l))))     ; Done.

            ;; LIS begins out-list. Search for in-list's first pair.
            (let lp ((prev-l lis) (l (cdr lis)))
              (cond ((not (pair? l)) (values '() lis))
                    ((pred (car l))
                     (scan-in l prev-l (cdr l))
                     (values l lis))            ; Done.
                    (else (lp l (cdr l)))))))))


;;; Inline us, please.
(define (remove  pred l) (filter  (lambda (x) (not (pred x))) l))
(define (remove! pred l) (filter! (lambda (x) (not (pred x))) l))



;;; Here's the taxonomy for the DELETE/ASSOC/MEMBER functions.
;;; (I don't actually think these are the world's most important
;;; functions -- the procedural FILTER/REMOVE/FIND/FIND-TAIL variants
;;; are far more general.)
;;;
;;; Pure                linear-update        Action
;;; ---------------------------------------------------------------------------
;;; remove pred lis     remove! pred lis     Delete by general predicate
;;; del  = x lis        del!  = x lis        Delete by general comparison
;;; delq   x lis        delq!   x lis        Delete by EQ?    comparison
;;; delv   x lis        delv!   x lis        Delete by EQV?   comparison
;;; delete x lis        delete! x lis        Delete by EQUAL? comparison
;;;                                          
;;; find-tail pred lis                       Search by general predicate
;;; mem  = x lis                             Search by general comparison
;;; memq   x lis                             Search by EQ?    comparison
;;; memv   x lis                             Search by EQV?   comparison
;;; member x lis                             Search by EQUAL? comparison
;;;                                          
;;; find pred lis                            Search alist by general predicate
;;; ass = x lis                              Search alist by general comparison
;;; assq  x lis                              Search alist by EQ?    comparison
;;; assv  x lis                              Search alist by EQV?   comparison
;;; assoc x lis                              Search alist by EQUAL? comparison
;;;                                          
;;; remove pred alist   remove! pred alist   Alist-delete by general predicate
;;; del-ass = x alist   del-ass! = x alist   Alist-delete by general comparison
;;; del-assq  x alist   del-assq!  x alist   Alist-delete by EQ?    comparison
;;; del-assv  x alist   del-assv!  x alist   Alist-delete by EQV?   comparison
;;; del-assoc x alist   del-assoc! x alist   Alist-delete by EQUAL? comparison

(define (del  = x lis) (filter  (lambda (y) (not (= x y))) lis))
(define (del! = x lis) (filter! (lambda (y) (not (= x y))) lis))

;;; The DEL and then FILTER call should definitely be inlined for DELQ & DELV.
(define (delq  x lis) (del  eq? x lis))
(define (delq! x lis) (del! eq? x lis))

(define (delv  x lis) (del  eqv? x lis))
(define (delv! x lis) (del! eqv? x lis))

(define (delete  x lis) (del  equal? x lis))
(define (delete! x lis) (del! equal? x lis))


(define (mem = x lis) (find-tail (lambda (y) (= x y)) lis))

;;; R4RS, hence we don't bother to define.
;;; The MEM and then FIND-TAIL call should definitely
;;; be inlined for MEMQ & MEMV.
;(define (memq    x lis) (mem eq?    x lis))
;(define (memv    x lis) (mem eqv?   x lis))
;(define (member  x lis) (mem equal? x lis))


;;; alist stuff
;;;;;;;;;;;;;;;

(define (ass = x lis) (find (lambda (entry) (= x (car entry))) lis))

;;; R4RS, hence we don't bother to define. 
;;; The ASS and then FIND call should definitely be inlined for ASSQ & ASSV.
;(define (assq  x lis) (ass eq?    x lis))
;(define (assv  x lis) (ass eqv?   x lis))
;(define (assoc x lis) (ass equal? x lis))

(define (acons key datum alist) (cons (cons key datum) alist))  ; Alist-cons

(define (alist-copy alist)
  (map (lambda (elt) (cons (car elt) (cdr elt)))
       alist))

(define (alist-delete = key alist)
  (filter (lambda (elt) (not (= (car elt) key))) alist))
(define (alist-delete! = key alist)
  (filter! (lambda (elt) (not (= (car elt) key))) alist))

(define del-ass  alist-delete)
(define del-ass! alist-delete!)

(define (del-assq  key alist) (alist-delete  eq?    key alist))
(define (del-assq! key alist) (alist-delete! eq?    key alist))

(define (del-assv  key alist) (alist-delete  eqv?   key alist))
(define (del-assv! key alist) (alist-delete! eqv?   key alist))

(define (del-assoc  key alist) (alist-delete  equal? key alist))
(define (del-assoc! key alist) (alist-delete! equal? key alist))



;;; find find-tail any? every?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ANY? returns the first true value produced by PRED.
;;; FIND returns the first list elt passed by PRED.

(define (find pred list)
  (cond ((find-tail pred list) => car)
        (else #f)))

(define (find-tail pred list)
  (let lp ((list list))
    (and (pair? list)
         (if (pred (car list)) list
             (lp (cdr list))))))

(define (any? pred list)
  (let lp ((list list))
    (and (pair? list)
         (or (pred (car list))
             (lp (cdr list))))))

;(define (every? pred list)             ; Simple definition.
;  (let lp ((list list))                ; Doesn't return the last PRED value.
;    (or (not (pair? list))
;       (and (pred (car list))
;            (lp (cdr list))))))

(define (every? pred list)                      ; This one tail-calls the last
  (or (not (pair? list))                        ; PRED call.
      (let lp ((list list)) ; LIST is a pair.
        (let ((tail (cdr list))
              (head (car list)))
          (if (pair? tail)
              (and (pred head) (lp tail))
              (pred head))))))


;;; Reverse
;;;;;;;;;;;

;R4RS, so not defined here.
;(define (reverse lis) (foldl cons '() lis))
                                      
(define (reverse! lis)
  (pair-foldl (lambda (pair tail) (set-cdr! pair tail) pair) '() lis))

