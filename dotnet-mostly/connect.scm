;;; Network stuff for Skij#

;;; Translate a string to a Byte array...argh
;;; works but result is unprintable...hah
(define (string->bytes str)
  (invoke (invoke-static 'System.Text.Encoding 'get_ASCII)
	  'GetBytes str))

(define (bytes->string bytes)
  (invoke (invoke-static 'System.Text.Encoding 'get_ASCII)
	  'GetString bytes))


(define (make-buffer size)
  (%make-array (list size) (class-named 'System.Byte)))

;;;; OH NEVER MIND, there is higher-level class, Duh!

(define (tcp-transact host socket string)
  (let ((client (new 'System.Net.Sockets.TcpClient))
	(bytes  (string->bytes string))
	(inbuffer (make-buffer 100))
	(stream #f))
  (invoke client 'Connect host socket)
  (set! stream (invoke client 'GetStream))
  (invoke stream 'Write bytes 0 (vector-length bytes))
  (display "Waiting...")
  (invoke stream 'Read inbuffer 0 100)
  (invoke stream 'Close)
  (bytes->string inbuffer)
  ))

;;; This works with Sobeck's XML API server.
; (tcp-transact "mt-nt" 8001 "<document><DeleteRequest id=\"2323\"></DeleteRequest></document>\nEOF\n")

