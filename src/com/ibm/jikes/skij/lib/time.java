package com.ibm.jikes.skij.lib;
class time extends SchemeLibrary {
  static {
    evalStringSafe("(define (now) (invoke-static 'java.lang.System 'currentTimeMillis))");
    evalStringSafe("(define (time thunk) (define start (now)) (define result (thunk)) (define end (now)) (display '\"Execution time (msec): \") (display (- end start)) (newline) result)");
    evalStringSafe("(defmacro (with-timeout time . body) `(let* ((result ':timed-out) (work-thread (in-own-thread (set! result (catch ,@body)))) (timer-thread (in-own-thread (catch (invoke work-thread 'join ,time) (if (invoke work-thread 'isAlive) (begin (print `(,work-thread timed out)) (invoke work-thread 'stop))))))) (catch (invoke work-thread 'join)) (invoke timer-thread 'stop) (if (instanceof result 'java.lang.Throwable) (throw result)) result))");
    evalStringSafe("(define date-format (invoke-static 'java.text.DateFormat 'getInstance))");
    evalStringSafe("(invoke date-format 'setTimeZone (invoke-static 'java.util.TimeZone 'getDefault))");
    evalStringSafe("(define (now-string) (invoke date-format 'format (now)))");
  }
}