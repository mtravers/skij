(require-resource 'scm/xml.scm)

(defstruct element-def
  (name					;aka type
   description
   root?				;can this be a document root
   
   attributes
   contents				;open or closed, but no way to infer this...
   model				;oneof: empty, any, data, elements, mixed. Data means only text, confusingly enough...
   ;; these only apply if model=data
   datatype
   default
   fixed
   ;; only applies if model=elements
   group


(defstruct attribute-def
  (name
   


;;; a hand-built dcd for OFX

(dcd ((ElementDef Type "SOFTPKG")
      (AttributeDef Name "Name")
      (AttributeDef Name "Version")
      (Model Elements)
      (Group ((Group Occurs 
    