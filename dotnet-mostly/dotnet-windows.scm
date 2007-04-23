(invoke-static 'System.Reflection.Assembly 'LoadFrom
   "c:/WINNT/assembly/GAC/System.Windows.Forms/1.0.3300.0__b77a5c561934e089/System.Windows.Forms.dll")

(define w (new 'System.Windows.Forms.Form))

; need to do this to have the window come alive, but it takes over the thread.
(invoke-static 'System.Windows.Forms.Application 'Run w)

;; making a new thread requires supplying a delegate, which I don't know how to
;; do from skij yet...argh.

(define b (new 'System.Windows.Forms.Button))

(define (dotnet-add window thing)
  (let ((controls (invoke window 'get_Controls)))
    (invoke controls 'Add thing)))