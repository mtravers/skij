(((lambda (len)
    (lambda (l)
      (if (null? l) 0
	  (+ 1 (len (cdr l))))))
  ((lambda (len)
     (lambda (l)
       (if (null? l) 0
	   (+ 1 (len (cdr l))))))
   ((lambda (len)
     (lambda (l)
       (if (null? l) 0
	   (+ 1 (len (cdr l))))))
    hukairs)))
 '())


(define (mk-len1 len0)
  (lambda (l)
    (if (null? l) 0
	(+ 1 (len0 (cdr l))))))

(((lambda (mk-len1)
   (mk-len1 hukairs))
 (lambda (len)
   (lambda (l)
     (if (null? l) 0
	 (+ 1 (len (cdr l)))))))
 '())


(((lambda (mk-len1)
    (mk-len1
     (mk-len1
      (mk-len1 hukairs))))
  (lambda (len)
    (lambda (l)
      (if (null? l) 0
	  (+ 1 (len (cdr l)))))))
 '())

Here's where the miracle occurs....

(((lambda (mk-len1)
    (mk-len1 mk-len1))
  (lambda (len)
    (lambda (l)
      (if (null? l) 0
	  (+ 1 ((len len) (cdr l)))))))
 '())


This is length!

Why? 


((lambda (mk-len1)
    (mk-len1 mk-len1))
 (lambda (len)
   (lambda (l)
     (if (null? l) 0
	 (+ 1 ((len len) (cdr l)))))))


Damn, it's hard to see how that works, I can sort of get a part of it...

(Y
 (lambda (len)
   (lambda (l)
     (if (null? l) 0
	 (+ 1 (Y (cdr l)))))))


OK, let's go on...


((lambda (mk-len1)
   (mk-len1 mk-len1))
 (lambda (len)
   ((lambda (length)
      (lambda (l)
	(if (null? l) 0
	    (+ 1 (length (cdr l))))))
    (lambda (x)
      ((len len) x)))))


((lambda (le)
   ((lambda (mk-len1)
      (mk-len1 mk-len1))
    (lambda (len)
      (le
       (lambda (x)
	 ((len len) x))))))
 (lambda (length)
   (lambda (l)
     (if (null? l) 0
	 (+ 1 (length (cdr l)))))))

; ok, now we have Y!

(define y
(lambda (le)
  ((lambda (mk-len)
     (mk-len mk-len))
   (lambda (mk-len)
     (le
      (lambda (x)
	((mk-len mk-len) x)))))))

;;; no, it's actually...

(define y 
  (lambda (le)
    ((lambda (f)
       (le (lambda (x) ((f f) x))))
     (lambda (f)
       (le (lambda (x) ((f f) x)))))))

; this produces the length function, without any define to mess up our language...
(y (lambda (len)
     (lambda (l)
       (if (null? l) 0
	   (+ 1 (len (cdr l)))))))

(y (lambda (fact)
     (lambda (n)
       (if (= n 0) 1 (* n (fact (+ n -1)))))))

