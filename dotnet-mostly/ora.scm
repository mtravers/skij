;;; copy of ics.scm but works directly to Oracle!

(define *oconnection* #f)

(define (open-odatasource)
  ;; Make sure some stuff is loaded 
  (class-named "oracle.jdbc.driver.OracleDriver")
  (class-named "java.sql.DriverManager")
  (set! *oconnection* 
	(invoke-static 'java.sql.DriverManager 'getConnection "jdbc:oracle:thin:@(description=(address=(host=gcs-nsx.mdli.com)(protocol=tcp)(port=1521))(connect_data=(SERVICE_NAME=ORA817)))" "isis" "isis"))
  ;; Magic to make structure retrieval work
  (invoke (invoke *oconnection* 'createStatement) 'executeQuery "select cdcaux.ctenvinit('isisrc2d') from dual")
  )

(define (oquery query-string limit)
  (let* ((stmt (invoke *oconnection* 'createStatement))
	 (rset (invoke stmt 'executeQuery query-string))
	 (count (invoke (invoke rset 'getMetaData) 'getColumnCount)))
      (map-ors rset 
	      (lambda ()
		(newline)
		(do ((i 1 (+ i 1)))	;1-based, iCS is 0-based
		    ((> i count))
		  (display (ovalue->string (invoke rset 'getObject i)))
		  (display " : ")))
	      limit)))

(define (ovalue->string v)
  (if (instanceof v 'java.sql.Clob)
      (invoke v 'getSubString (long 1) (integer (invoke v 'length))) ;gah!
      v))
	       
(define (oqueryx query-string limit)
  (let* ((stmt (invoke *oconnection* 'createStatement))
	 (rset (invoke stmt 'executeQuery query-string))
	 (count (invoke (invoke rset 'getMetaData) 'getColumnCount)))
      (map-ors rset 
	      (lambda ()
		(do ((i 1 (+ i 1)))	;1-based, iCS is 0-based
		    ((> i count))
		  (ovalue->string (invoke rset 'getObject i))))
	      limit)))

(define (map-ors rset proc limit)
  (let loop ()
    (if (invoke rset 'next)
	(begin
	  (proc)
	  (if (or (not limit)
		  (> (begin (incf limit -1) limit) 0))
	      (loop))))))

(define (dump-ors rset columns limit)
  (map-ors rset 
	  (lambda ()
	    (define v #f)
	    (map (lambda (column)
		   (set! v (invoke rset 'getString column))
		   (display (%or-null v "<null>")) (display "  "))
		 columns)
	    (newline))
	  limit))

