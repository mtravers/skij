;;; Hacking the CLR

;;; Mapping in CLR environment
;;; Unfortunately this often fails due to access problems. Damn.
(define (map-collection proc collection)
  (map-enumeration proc (invoke collection 'GetEnumerator)))

;;; avoids access problem for arraylists 
(define (map-arraylist proc arraylist)
  (do ((count (invoke arraylist 'get_Count))
       (i 0 (+ i 1)))
      ((= i count))
    (proc (invoke arraylist 'get_Item i))))

(define (map-enumeration proc enum)
  (if (invoke enum 'MoveNext)
      (begin 
	(proc (invoke enum 'get_Current))
	(map-enumeration proc enum))))

(define (type-named name)
  (invoke (class-named name) 'ToType))

(define (type-of object)
  (invoke (invoke object 'getClass) 'ToType))

;;; map-collection doesn't work on this due to access problems, but map-vector is OK. Weird.
(define (.net-method-apropos object string)
    (map-vector (lambda (method)
		  (catch
		      (let ((name (invoke method 'get_Name)))
			(if (> (invoke name 'IndexOf string) 0)
			    (print method)))))
		     (invoke (type-of object) 'GetMethods)))

(define (list->arraylist lst)
  (let ((result (new 'System.Collections.ArrayList)))
    (map (lambda (elt) (invoke result 'Add elt))
	 lst)
    result))
		    

(define (load-assembly path)
  (invoke-static 'System.Reflection.Assembly 'LoadFrom path))


