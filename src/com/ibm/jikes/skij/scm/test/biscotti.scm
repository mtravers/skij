;(require 'classpath)
;(add-to-classpath '"d:\\java\\qt\\QTJava.zip")

(require 'thread)
(require 'io)
(require 'numeric)

;;; doing this alone will cause a hang
'(invoke '(class com.qt.QTSession) 'open)

(define (notes-tone-test)
  (invoke '(class com.qt.QTSession) 'open)
  (define na (new 'com.qt.std.music.NoteAllocator))
  (print na)

  (print '"pick instrument:")
  (define nr (new 'com.qt.std.music.NoteRequest))
  (invoke nr 'pickInstrument na '"Choose an Instrument..." 0)
  (print nr)
  
  (define td (new 'com.qt.std.music.ToneDescription na 25))
  (print td)
  
  (define nc (new 'com.qt.std.music.NoteChannel na 25))
  (invoke nc 'playNote (float 60) 127)
  (sleep 2000)
  (invoke nc 'playNote (float 60) 0)

  (invoke '(class com.qt.QTSession) 'close))
