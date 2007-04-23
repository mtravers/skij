;;; A variety of useful constructs


(define designer (peek-static 'MDLInternal.Base.Framework.Design.Designer 'TheDesigner))

(invoke designer 'ListInputPins "$(down)form:component1")
(invoke designer 'InputPinLocation "$(down)form:component1" "StartSkijConsole")
(invoke designer 'ListInputPins "$(down)form:target")

;;; different ways to get a handle on local directory
(invoke (invoke-static 'System.AppDomain 'get_CurrentDomain) 'get_BaseDirectory)
(invoke-static 'MDLInternal.Base.Framework.ClientObjectStorage.FolderAndDocTree 'get_LocalBase)
(invoke-static 'MDLInternal.Base.Framework.ClientObjectStorage.FolderAndDocTree 'get_LocalWorking)
(invoke-static 'System.IO.Directory 'GetCurrentDirectory)