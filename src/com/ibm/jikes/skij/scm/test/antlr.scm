
  
(define (parse-file filename)
  (define file-obj (new 'java.io.File filename))
  (define stream (new 'java.io.FileInputStream file-obj))
  (define lexer (new 'JavaLexer stream))
  (define parser (new 'JavaRecognizer lexer))
  (invoke parser 'compilationUnit)
  parser)

(invoke parser 'getAST)

; stupid thing comes out as linear list! Why?

(define (ast-list ast)
  (if ast
      (cons ast (ast-list (invoke ast 'getNextSibling)))
      '()))