*-- Save and configure environment.
*****
Lparameters enlace
Declare Integer GetWindowLong In user32;
	Integer HWnd, Integer nIndex

Declare Integer SetWindowLong In user32;
	Integer HWnd, Integer nIndex, Integer dwNewLong

Declare Integer SetLayeredWindowAttributes In user32;
	Integer HWnd, Integer crKey, ;
	SHORT bAlpha, Integer dwFlags
*****

*****
*Wait Window 'aca'
*Wait Window Vartype(enlace)
Set TABLEVALIDATE To 0
Set Talk Off
Set Delete On
Set Century To 19
Set Exclusive Off
Set Safety Off
Set Optimize On
Set Date To Dmy
Set Century On
Set Reprocess To 30 Seconds
Set Escape Off
Set Multilocks On
Set ENGINEBEHAVIOR 80
On Shutdown Do salida
On Error *
Set Procedure To CapaDatos, rngrifo, ple5 Additive
#Define MSGTITULO      "SISVEN"
#Define MENSAJE1 "NO Se envío el comprobante Por las siguientes razones"+Chr(13)+Chr(10)+" NO Hay Conexión a Internet "+Chr(13)+Chr(10)
#Define MENSAJE2 "NO Hay Respuesta desde la WEB SERVICE DE SUNAT"+Chr(13)+Chr(10)
#Define MENSAJE3 " Ya se envio correctamente pero la respuesta no se recibio Correctamente-(Consultar con Clave Sol en www.sunat.gob.pe)"
Close All
Try
	Local oErr As Exception
	#Define CRLF Chr(13)+Chr(10)
	#Define ERRORPROC "NO SE EJECUTO CORRECTAMENTE EL PROCEDIMIENTO"
	lcLastSetPath = Set("PATH")
	Cd "\xsysg\"
	Set Path To ;Include;Forms;GRAPHICS;LIBS;Menus;PROGS;REPORTS;Comp;
		Push Menu _Msysmenu
	lcLastSetClassLib = Set("CLASSLIB")
	lcMainClassLib = "libs\sisfotos"
	Set Classlib To (lcMainClassLib) Additive
*lcOnShutdown="ShutDown()"
*On Shutdown &lcOnShutdown
	_Shell = "DO Cleanup IN progs\sisven"
	On Key Label F5 Do cal
	Clear
*-- Instantiate application object.
	Set Procedure To CapaDatos, rngrifo, ple5 Additive
	Release goApp
	Release Ocontometro
	Public goApp
	Public Ocontometro
	Public cfieldsfesucu(1)
	Public cfieldsfetdoc(1)
	Public cfieldsfevend(1)

	goApp = Createobject("cApplication")
	AddProperty(goApp, 'conectasucursales', '')
	If Vartype(enlace) <> 'L' Then
		goApp.Xopcion = Val(enlace)
	Endif

	Ocontometro = Createobject("Contometro")
	_Screen.Visible = .F.
	Set Classlib To ("clasesvisuales") Additive
**********
	AddProperty(goApp, 'ejecutable', 'sisven')
	AddProperty(goApp, 'ruta', Addbs(Sys(5) + Sys(2003)))
	AddProperty(goApp, 'carpetaftp', 'xsysg')

	Set Class To vcx\VfpUpd.vcx Additive
	If Vartype(_Screen.oFtp) = "O"
		_Screen.RemoveObject('oFtp')
	Else &&VARTYPE(_SCREEN.oFtp) = "O"
	Endif &&VARTYPE(_SCREEN.oFtp) = "O"
	_Screen.Newobject('oFtp', 'FtpSettings')

&& Configuración de las Credenciales de la FTP
	_Screen.oFtp.Host 			= "ftp.companysysven.com"
	_Screen.oFtp.Login 			= "syscom"
	_Screen.oFtp.Password 		= "f2pwO0lao1D9"
	_Screen.oFtp.DirApp 		= "/sisven/xsysg/"
	_Screen.oFtp.AppName 		= "sisven.exe"
	_Screen.oFtp.RutaExe 		= Addbs(Sys(5) + Sys(2003))
	_Screen.oFtp.AppVersion		= "6"
	_Screen.oFtp.AppSubVersion	= "6"
	_Screen.oFtp.AppRevision	= "100"
	_Screen.oFtp.AppnameZiP     = 'sisven.zip'
	_Screen.oFtp.Apptxt         = "sisven_version.txt"
	Set Procedure To d:\capass\modelos\ventasgrifos, d:\capass\modelos\guiasremision, d:\capass\modelos\Rboletas  Additive
	AddProperty(_Screen, 'oventasg', Createobject("ventasgrifos"))
	AddProperty(_Screen, 'oguia', Createobject('guiaremision'))
	AddProperty(_Screen, 'orboletas', Createobject("Rboletas"))
	Set Procedure To ple5 Additive
*!*		MESSAGEBOX("hola 2")
	settingsclass()
*******
*!*	     MESSAGEBOX("hola 10")
	oconecta = Createobject("conectar")
*!*		Wait Window 'Aca '+ goApp.json
	oconecta.archivoconfiguracion()

	If !Empty(goApp.json) Then
		oconecta.Leerjson(goApp.json)
	Endif
*Wait Window 'Aca '+  oconecta.consucursales
*!*	     MESSAGEBOX("hola 1")
	If oconecta.consucursales = 'S' Then
		goApp.conectasucursales = 'S'
		Do Form acceso1
	Else
		Do Form acceso
	Endif
	Read Events
*-- Release application.
	Release goApp

*-- Restore default menu.
	Pop Menu _Msysmenu

*-- Restore environment.
	On Error
	On Shutdown
	If Not lcLastSetClassLib == Set("classlib")
		Release Classlib (lcMainClassLib)
	Endif
	If Empty(lcLastSetPath)
		Set Path To
	Else
		Set Path To &lcLastSetPath
	Endif
	If lcLastSetTalk == "ON"
		Set Talk On
	Else
		Set Talk Off
	Endif
Catch To m.oerror
	controlerrores(m.oerror)
Finally
	On Shutdown
	On Shutdown Clear Events
Endtry
Clear Events
Return
**********************
Procedure Errorbd(ccomando As String)
Local laError
Dimension laError(1)
= Aerror(laError)
lcError = laError(1, 3)
Messagebox("No se Pudo Conectar con la Base de Datos..Detalles:" + Chr(13) + ;
	  Alltrim(ccomando) + Chr(13) + Chr(13) + ;
	  lcError, 16 + 0 + 0, "SISVEN")
Endproc
**********************
Function Shutdown
Cleanup()
Quit
Endfunc
**********************
Function Cleanup
If Cntbar("_msysmenu") = 7
	Return
Endif
On Error
On Shutdown
Set Classlib To
Set Path To
Clear All
Close All
Pop Menu _Msysmenu
Return
Endfunc
*****************************
Procedure RemoteSPTCursor2RemoteView
*
* Convierte un cursor SPT en un vista remota actualizable
*
*  lParameters
*
*   tcCursorAlias (R) Alias del cursor SPT
*   tcTableName (R) Nombre de la tabla remota de la cual
*                   tcCursorAlias fue recuperado
*   tcPKFieldName (R) Nombre del campo en tcCursorAlias
*                     que es la llave (primaria)
*   tnBuffering (O) Especifica el modo de almacenamiento de buffer
*                   para tcCursorAlias,
*                   por defecto 3 - Optimista de Tabla
*   tnWhereType (O) Especifica la propiedad WhereType,
*                   por defecto 3 - Clave y Modificado
*   tlExcludePK (O) Bandera lógica que indica si hay que excluir el
*                   campo de PK del UpdatableFieldList - pasa este
*                   parámetro como .T. cuando el campo de PK es
*                   poblado en virtud de ser una columna de Identidad
*
Lparameters tcCursorAlias, tcTableName, tcPKFieldName, ;
	tnBuffering, tnWhereType, tlExcludePK
*
* propiedades de actualización - UpdateNameList y
* UpdatableFieldList, igual que una vista remota
*
Local lnSelect, lcUpdatableFieldList, lcUpdateNameList, ;
	lcField, xx, lnCount, llSuccess
lcUpdatableFieldList = Space(0)
lcUpdateNameList = Space(0)
lcField = Space(0)
lnSelect = Select(0)
lnCount = 0
Select (tcCursorAlias)
*
* añadir cada campo al UpdateNameList y
* las propiedades UpdatableFieldList
*
For xx = 1 To Fcount()
	lcField = Upper(Alltrim(Field(xx)))
	lnCount = lnCount + 1
	lcUpdatableFieldList = lcUpdatableFieldList + ;
		Iif(lnCount = 1, Space(0), ",") + lcField
	lcUpdateNameList = lcUpdateNameList + ;
		Iif(lnCount = 1, Space(0), ",") + lcField + ;
		Space(1) + tcTableName + "." + lcField
Endfor
If tlExcludePK
*
* Cuando las PKs no deben ser generadas a mano
* (como cuando el PK es una columna Identity),
* el campo PK tiene que ser quitado del
* UpdatableFieldList para prevenir un TableUpdate()
* e intentar actualizar el campo PK, que
* causaría un crash
*
*  ... por cualquier razón, el campo de PK
*  debe permanecer en el UpdateNameList...
*
	lcUpdatableFieldList = "," + Alltrim(lcUpdatableFieldList) + ","
	lcUpdatableFieldList = Strtran(lcUpdatableFieldList, ;
		  "," + Upper(tcPKFieldName) + ",", ",")
*
* asegurar que no dejamos una coma durante
* el principio o el final de la cadena
*
	If Leftc(lcUpdatableFieldList, 1) = ","
		lcUpdatableFieldList = Substrc(lcUpdatableFieldList, 2)
	Endif
	If Rightc(lcUpdatableFieldList, 1) = ","
		lcUpdatableFieldList = Leftc(lcUpdatableFieldList, Lenc(lcUpdatableFieldList) - 1)
	Endif
Endif
llSuccess = .F.
Do Case
Case Not CursorSetProp("KeyFieldList", tcPKFieldName)
	Assert .F. Message Program() + " no se puede configurar KeyFieldList"
Case Not CursorSetProp("Tables", tcTableName)
	Assert .F. Message Program() + " no se puede configurar Tables"
Case Not CursorSetProp("UpdatableFieldList", lcUpdatableFieldList)
	Assert .F. Message Program() + " no se puede configurar UpdatableFieldList"
Case Not CursorSetProp("UpdateNameList", lcUpdateNameList)
	Assert .F. Message Program() + " no se puede configurar UpdateNameList"
Case Not CursorSetProp("WhereType", ;
		  Iif(Vartype(tnWhereType) = "N", tnWhereType, 3))
	Assert .F. Message Program() + " no se puede configurar WhereType"
Case Not CursorSetProp("Buffering", ;
		  Iif(Vartype(tnBuffering) = "N", tnBuffering, 3))
	Assert .F. Message Program() + " no se puede configurar Buffering"
Case Not CursorSetProp("SendUpdates", .T.)
	Assert .F. Message Program() + " no se puede configurar SendUpdates"
Otherwise
	llSuccess = .T.
Endcase
Select (lnSelect)
Return llSuccess
Endproc
*******