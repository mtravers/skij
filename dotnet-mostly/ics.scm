;;; global for convenience
(define *account* "guest")
(define *pwd* "_guest")
(define *host* "mt-nt")
(define *port* "23221")

(define *session* #f)
(define *factory* #f)
(define *datasource* #f)

;"ISISRC2D" 
(define (open-datasource datasource)
  (set! *session* (invoke-static 'com.mdli.isentris.sessionmanager.client.IsentrisLogin
				 'connect
				 *account*
                                 *pwd*
                                 "DataSource Example"
                                 (string-append "IsentrisSessionManager@" *host* ":" *port*)))
  (set! *factory* (invoke *session* 'getServiceInstance "DataSourceFactoryService"))
  (set! *datasource* (invoke *factory* 'createDataSourceByName datasource (%null)))
  *datasource*)

(define (rs-to-xml recordset filename)
  (let ((filewriter (invoke *factory* 'createObject (peek-static 'com.mdli.isentris.datasource.client.IDataSourceFactory 'DBFILEWRITER)))
	(props (invoke *datasource* 'createPropertySet)))
    (invoke props 'putProperty (peek-static 'com.mdli.isentris.datasource.client.IDBDataSource 'SOURCE)
	    "<Source><DataSource>ISISRC2D Test</DataSource></Source>")
    (invoke props 'putProperty (peek-static 'com.mdli.isentris.datasource.client.IDBFileWriter 'BLOCKSIZE) "15")
    (invoke filewriter 'writeXMLFile recordset filename -1 props)))

(define (make-ps pairs)
  (let ((props (invoke *datasource* 'createPropertySet)))
    (map (lambda (pair)
	   (invoke props 'putProperty (car pair) (cadr pair)))
	 pairs)
    props))


;;; this usually returns blanks
(define (get-metadata table)
  (let ((props (invoke *datasource* 'createPropertySet)))
    (invoke props 'putProperty "TABLE_NAME" table)
    (invoke (invoke (invoke *datasource* 'getCatalog) 'getMetaData props) 'toXML "")))

;;; try this way
;See file:///D:/ClearCase%20Views/mt_afferent_view/icsdoc/dev/docs/CoreInterface/devguide/ixampdss11.html#1029531

;;; do what xbrowser does 
(define (foo)
  (define newconn (invoke *factory* 'createDataSourceByType "RELATIONAL"))
  (invoke newconn 'initializeFromXML "   <Connection>   <ConnectionAttributes     USERNAME=\"CWMAIN\"    PASSWORD=\"CWMAIN\"    ALIAS=\"(description=(address=(host=bart.uk.mdli.com)(protocol=tcp)(port=1521))(connect_data=(SERVICE_NAME=B8171A)))\"    OCI_DLL_NAME=\"thin\"/>    <StructureFieldNames AUTOFIELDMAP=\"OFF\"/>    <ReactionFieldNames AUTOFIELDMAP=\"OFF\"/>    <KeyFieldNames>      <KeyField>CDBREGNO</KeyField>    </KeyFieldNames>  </Connection>")
  (define stmt (invoke newconn 'createStatement))
  (invoke stmt 'setNativeQuery "select table_name from all_tables" (%null))
  (define rset (invoke stmt 'executeQuery))
  (let loop ()
    (define v (invoke rset 'getFieldString "table_name"))
    (print v)
    (when (not (%%null? v))
	  (invoke rset 'moveNext)
	  (loop)))
  (invoke newconn 'releaseResources)	;let's be good
  )

(define (foofoo table columns limit)
  (define stmt (invoke *datasource* 'createStatement))
  (invoke stmt 'setNativeQuery (format-query table columns) (%null))
  (define rset (invoke stmt 'executeQuery))
  (dump-rs rset columns limit)
;;; Oddly, no way to do this?
;  (invoke rset 'releaseResources)	;let's be good
  )

;;; Map proc over a recordset
(define (map-rs rset proc limit)
  (invoke rset 'moveFirst)		;go to beginning
  (let loop ()
    (proc)
    (when (and (invoke rset 'moveNext)
	       (or (not limit)
		   (> (begin (incf limit -1) limit) 0)))
	  (loop))))

(define (dump-rs rset columns limit)
  (unless columns
	  (set! columns (rs-fields rset))
	  (pp columns))
  (map-rs rset 
	  (lambda ()
	    (define v #f)
	    (map (lambda (column)
;		   (set! v (invoke rset 'getFieldString column))
		   (set! v (invoke rset 'getFieldObject column))
		   (display (%or-null v "<null>")) (display "  "))
		 columns)
	    (newline))
	  limit))

(define (display-rs rset)
  (define columns (rs-fields rset))
  (define data '())
  (map-rs rset
	  (lambda ()
	    (define record '())
	    (map (lambda (column)
		   (push (invoke rset 'getFieldObject column) record))
		 columns)
	    (push (reverse record) data))
	  #f)
  (set! data (reverse data))
  (define table (make-table data columns))
  (define table-panel (make-table-panel table 400 400))
  (make-swing-window-for-panel "RecordSet" table-panel)
;  data
  )
  

	    

(define (format-query table columns)
  (with-string-output-port 
   (lambda (out)
     (display "select " out)
     (display (car columns) out)
     (map (lambda (column)
	    (display ", " out)
	    (display column out))
	  (cdr columns))
     (display " from " out)
     (display table out))))

;;; this  works to get metadata user_tables, and other things in the  "static data dictionary views", see  http://download-west.oracle.com/docs/cd/A87860_01/doc/server.817/a76961/ch284.htm
;;; But it won't work for ordinary tables.
;;; It works if you select particular fields instead of "select *", but that defeats the whole purpose!
;;; FUCK, sometimes it DOES work (like if I've previously done dump-metadata???
(define (foo-meta table)
  (define stmt (invoke *datasource* 'createStatement))
  (invoke stmt 'setNativeQuery (string-append "select * from " table) (%null))
  (define rset (invoke stmt 'executeQuery))
  (define meta (invoke rset 'getMetaData))
  (invoke meta 'toXML "")
  )

;;; Proc takes one argument, a Field object
(define (map-metadata meta proc)
  (let ((count (invoke meta 'count)))
    (do ((i 0 (+ i 1)))
	((= i count))
      (proc (invoke meta 'getFieldInfo i)))))
      
(define (dump-metadata meta)
  (map-metadata meta
		(lambda (field)
		  (display "-- Field ")
		  (newline)
		  (dump-ps field))))
		  
	
(define (dump-ds)
  (define stmt (invoke *datasource* 'createStatement))
  (invoke stmt 'setNativeQuery (string-append "select * from " table) (%null))
  (define rset (invoke stmt 'executeQuery))
  (define meta (invoke rset 'getMetaData))
  (invoke meta 'toXML "")
  )


;;; Dump a property set
(define (dump-ps ps)
  (let ((count (invoke ps 'getPropertyCount)))
    (do ((i 0 (+ i 1)) 
	 (prop #f))
	((= i count))
      (set! prop (invoke ps 'getPropertyByIndex i))
      (display (invoke prop 'getName))
      (display ":  ")
      (display (%or-null (invoke prop 'getValue)  "<null>"))
      (newline))))

;;; Get table structure for relational datasource
;;; I should write a hierarchical accesor to do this type of thing...
;;; Apparently the catalog really only contains table names, no columns or anything. Weird.
(define (foo-catalog)
  (define cat (invoke *datasource* 'getCatalog))
  (define catdata (invoke cat 'getCatalogData))	;this is an rs
  (define schemas (invoke catdata 'getFieldObject "Schemas")) ;this is another rs
;  (dump-rs schemas '("SchemaName") #f))    ; ISIS
  (define types (invoke schemas 'getFieldObject "Types")) ;yet another rs
;  (dump-rs types '("Type") #f))   ; TABLE/VIEW/SYNONYM
  (define tables (invoke types 'getFieldObject "Tables")) ;guess what! another rs
  (dump-rs tables '("TableName") #f))


;;; YES! This gives you tables and fields using approved iCS routines (but it makes a bunch of assumptions which
;;; might not always be valid).
(define (red-catalog)
  (define cat (invoke *datasource* 'getCatalog))
  (define catdata (invoke cat 'getCatalogData))	;this is an rs
  (define schemas (invoke catdata 'getFieldObject "Schemas")) ;this is another rs
  (define types (invoke schemas 'getFieldObject "Types")) ;yet another rs
  (define tables (invoke types 'getFieldObject "Tables")) ;guess what! another rs
  (define tablenames '())
  (map-rs tables (lambda ()
		   (push (invoke tables 'getFieldString "TableName") tablenames))
	  #f)
  (map (lambda (tablename)
	 (newline)
	 (display " -------- ")
	 (display tablename)
	 (map-metadata (invoke cat 'getMetaData (make-ps `(("TABLE_NAME" ,tablename))))
		       (lambda (field)
			 (newline)
			 (display (invoke field 'getProperty "NAME"))
			 (display ":   ")
			 (display (invoke field 'getProperty "TYPE")))))
       tablenames))

;;; For HView data sources, you need something different
(define (hview-catalog)
  (define cat (invoke *datasource* 'getCatalog))
  (define meta (invoke cat 'getMetaData (%null)))
  (dump-metadata meta))

(define (rs-fields rs)
  (let ((result '()))
  (map-metadata (invoke rs 'getMetaData)
		(lambda (field)
		  (push (invoke field 'getProperty "NAME") result)))
  (reverse result)))

;;; Argh, why isn't this here already
(defmacro (dotimes (var end) . body)
  `(do ((,var 0 (+ 1 ,var)))
       ((= ,var ,end))			;end will be evaluated repeatedly, is this right?
     ,body))

(define (query query-string limit)
  (let ((stmt (invoke *datasource* 'createStatement)))
    (invoke stmt 'setNativeQuery query-string (%null))
    (let* ((rset (invoke stmt 'executeQuery))
	   (count (invoke (invoke rset 'getMetaData) 'count)))
      (map-rs rset 
		(lambda ()
		       (newline)
		       (do ((i 0 (+ i 1)))
			   ((= i count))
			 (display (invoke rset 'getFieldString i))
			 (display " : ")))
		limit))))

;;; Same as above but no display...for timing
(define (queryx query-string limit)
  (let ((stmt (invoke *datasource* 'createStatement)))
    (invoke stmt 'setNativeQuery query-string (%null))
    (let* ((rset (invoke stmt 'executeQuery))
	   (count (invoke (invoke rset 'getMetaData) 'count)))
      (map-rs rset 
	      (lambda ()
		(do ((i 0 (+ i 1)))
		    ((= i count))
		  (invoke rset 'getFieldString i)))
	      limit))))
				
; (query  "select molname, mp_num1, bp_num1 from ISISRC2D_MELTING_POINT, ISISRC2D_MOL, ISISRC2D_BOILING_POINT where ISISRC2D_MOL.cdbregno = ISISRC2D_MELTING_POINT.cdbregno AND  ISISRC2D_MOL.cdbregno = ISISRC2D_BOILING_POINT.cdbregno" 100)			 

(define (check-error obj)
  (let ((err (invoke obj 'getLastError)))
    (when (and (not (%%null? err))
	       (invoke err 'isError))
	  (print (invoke err 'getErrorString)))))

(define (all-datasources) 
  (invoke *factory* 'getKnownDataSources))

(define (do-query xql uql?)
  (define stmt (invoke *datasource* 'createStatement))
  (if (not
       (invoke stmt
	       (if uql?
		   'setUnifiedQuery
		   'setNativeQuery)
	       xql
	       (%null)))
      (print `("Failed to set query" ,(check-error stmt)))
      (begin
       (define rset (invoke stmt 'executeQuery))
       (if (%%null? rset)
	   (print `("Failed to execute query" ,(check-error stmt))))
       rset)))


(define (acd)
  (set! *host* "mt-nt")
  (open-datasource "acd"))

(define (usual)
  (set! *host* "mt-nt")
  (open-datasource "ISISRC2D"))

(define (mtacd)
  (set! *host* "mt-nt")
  (open-datasource "acd"))

(define (caribou)
  (set! *host* "caribou")
  (open-datasource "ISISRC2D_HVIEW"))