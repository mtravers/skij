;;; For playing with xbrowser from Skij!

(load "connect.scm")
(load "xml.scm")

(invoke-static 'System.Reflection.Assembly 'LoadFrom "c:/xbrowser/xbrowser.exe")

(define mol (new 'MDL.FUtility.Molecule "pyrazine\n\n\n  6  6  0  0  0  0           0999 V2000\n 0003.0000 0003.0000    0.0000 C   0  0  0  0  0  0  0  0\n 0003.0000 0004.6999    0.0000 C   0  0  0  0  0  0  0  0\n 0004.4722 0002.1500    0.0000 N   0  0  0  0  0  0  0  0\n 0005.9445 0003.0000    0.0000 C   0  0  0  0  0  0  0  0\n 0005.9445 0004.6999    0.0000 C   0  0  0  0  0  0  0  0\n 0004.4722 0005.5500    0.0000 N   0  0  0  0  0  0  0  0\n  1  2  2  0  0  0\n  1  3  1  0  0  0\n  3  4  2  0  0  0\n  4  5  1  0  0  0\n  5  6  2  0  0  0\n  6  2  1  0  0  0\nM  END\n"))

;;; This is weird:

;skij> (class-named 'XBrowser)
;  <<< #<class XBrowser>
;skij> (new 'XBrowser)

;com.ibm.jikes.skij.SchemeException: Failed to create instance of XBrowser with args (): java.lang.ClassNotFoundException
;Type (backtrace) or (java-backtrace) for more information.
