;;; tester for design mode

(load "d:/mt/projects/skij/SkijSharp/ybrowser.scm")
(load-assembly "e:/za_view/mdl-base/experimentation/NewClient2003/Designer/bin/Debug/Designer.dll")
(def-all-parts)
(new 'MDL.Design.BaseDesignerHost (controlfor browsepane))
