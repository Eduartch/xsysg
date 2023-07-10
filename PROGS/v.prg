
* Ejemplo de convertir un cursor SPT en una "vista remota"
*
* El código interesante está en el procedimiento local
* RemoteSPTCursor2RemoteView(), que hace todo el
* trabajo, y que puede modificar para su propio uso
*
CLEAR
LOCAL lnHandle, lnGNM
*
* IMPORTANTE!
* La línea siguiente del código tendrá que ser modificada
* para especificar una cadena válida SQLSTRINGCONNECT()
* para establecee una conexión a la base de datos Pubs
*
WAIT WINDOW "Intentanto conectar a la base de datos Pubs." + CHR(13) + ;
  "Si este intento falla, debera modificar el programa en " + CHR(13) + ;
  "la línea SQLSTRINGCONNECT(<string>) para especificar una " + CHR(13) + ;
  "cadena de conexión que funcione en su computadora." NOWAIT
*
LOCAL lcServidor,lcBaseDatos,lcUsuarioSQL,lcPass ,lcCnxStr
lcServidor   = "localhost"
lcBaseDatos  = "sysven"
lcUsuarioSQL = "root"
lcPass       = "123"
lcCnxStr = "Driver={MySQL ODBC 5.1 Driver};Port=3306;Server=" + lcServidor + ";Database=" + ALLTRIM(lcBaseDatos) + ";Uid=" + lcUsuarioSQL + ";Pwd=" + lcPass + ";OPTION=131329;"
  
SQLSETPROP(0,"DispLogin",3)
lnHandle = SQLSTRINGCONNECT(lcCnxstr)
*
WAIT CLEAR
IF lnHandle < 1
  MESSAGEBOX("No puede establecer una conexión a la base de datos Pubs en " + ;
    "SQL Server. Modifique la línea SQLSTRINGCONNECT() para especificar " + ;
    "una cadena de conexión que funcione en su computadora.", 16, "Aviso")
  RETURN
ENDIF
IF SQLEXEC(lnHandle,"SELECT * FROM fe_art ORDER BY descri","SQLResult") < 0
  MESSAGEBOX("No puede hacer SELECT * FROM AUTHORS", 16, "Aviso")
  SQLDISCONNECT(0)
  RETURN
ENDIF
SELECT SQLResult
*
* Aquí está donde convertimos el cursor SPT en una vista remota
*
IF NOT RemoteSPTCursor2RemoteView("SQLResult", "fe_art", "idart", 5)
  MESSAGEBOX("No puede convertir SQLResult en una vista remota.", 16, "Aviso")
  SQLDISCONNECT(0)
  RETURN
ENDIF
*WAIT WINDOW "Haga cambios a los datos," + CHR(13) + ;
  "(Insert/Update/Delete)" + CHR(13) + ;
  "y cierre la ventana Examinar" NOWAIT NOCLEAR
BROWSE LAST
WAIT CLEAR
lnGNM = GETNEXTMODIFIED(0,"SQLResult")
IF lnGNM = 0
  MESSAGEBOX("El buffer esta limpio, aparentemente no hizo cambios.", 48, "Aviso")
ELSE
  *
  * El buffer esta 'sucio'
  *
  GOTO (lnGNM)
  MESSAGEBOX('GetNextModified(0,"SQLResult"): ' + ;
    TRANSFORM(GETNEXTMODIFIED(0,"SQLResult")) + CHR(13) + ;
    'GetFldState(-1,"SQLResult"): ' + TRANSFORM(GETFLDSTATE(-1,"SQLResult")) + CHR(13) + ;
    'Presione "OK" para intentar el TABLEUPDATE(.t.,.t.,"SQLResult")', 48, "Aviso")
  IF TABLEUPDATE(.T.,.T.,"SQLResult")
    *
    * Tuvo éxito!
    *
    MESSAGEBOX("Todas las modificaciones se hicieron exitosamente " + ;
      "con TABLEUPDATE() - La ventana Examinar muestra " + ;
      "un nuevo SELECT * FROM AUTHORS.", 48, "Please Note")
    SQLEXEC(lnHandle,"SELECT * FROM AUTHORS ORDER BY Au_LName")
    WAIT WINDOW "Nuevo " + CHR(13) + "SELECT * FROM AUTHORS" + CHR(13) + ;
      "conteniendo cualquier cambio " + CHR(13) + "que Ud. hizo." NOWAIT NOCLEAR
    BROWSE LAST
    WAIT CLEAR
  ELSE
    *
    * Falló
    *
    LOCAL laError[1]
    AERROR(laError)   &&& laError[1] = 1526
    MESSAGEBOX("El TABLEUPDATE() falló porque " + ;
      TRANSFORM(laError[2]) + "/" + TRANSFORM(laError[3]), 16, "Aviso")
  ENDIF
ENDIF
SQLDISCONNECT(0)
RETURN
*
* --
*
PROCEDURE RemoteSPTCursor2RemoteView
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
  LPARAMETERS tcCursorAlias, tcTableName, tcPKFieldName, ;
    tnBuffering, tnWhereType, tlExcludePK
  *
  * propiedades de actualización - UpdateNameList y
  * UpdatableFieldList, igual que una vista remota
  *
  LOCAL lnSelect, lcUpdatableFieldList, lcUpdateNameList, ;
    lcField, xx, lnCount, llSuccess
  lcUpdatableFieldList = SPACE(0)
  lcUpdateNameList = SPACE(0)
  lcField = SPACE(0)
  lnSelect = SELECT(0)
  lnCount = 0
  SELECT (tcCursorAlias)
  *
  * añadir cada campo al UpdateNameList y 
  * las propiedades UpdatableFieldList
  *
  FOR xx = 1 TO FCOUNT()
    lcField = UPPER(ALLTRIM(FIELD(xx)))
    lnCount = lnCount + 1
    lcUpdatableFieldList = lcUpdatableFieldList + ;
      IIF(lnCount=1,SPACE(0),",") + lcField
    lcUpdateNameList = lcUpdateNameList + ;
      IIF(lnCount=1,SPACE(0),",") + lcField + ;
      SPACE(1) + tcTableName + "." + lcField
  ENDFOR
  IF tlExcludePK
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
    lcUpdatableFieldList = "," + ALLTRIM(lcUpdatableFieldList) + ","
    lcUpdatableFieldList = STRTRAN(lcUpdatableFieldList, ;
      "," + UPPER(tcPKFieldName) + "," , ",")
    *
    * asegurar que no dejamos una coma durante 
    * el principio o el final de la cadena
    *
    IF LEFTC(lcUpdatableFieldList,1) = ","
      lcUpdatableFieldList = SUBSTRC(lcUpdatableFieldList,2)
    ENDIF
    IF RIGHTC(lcUpdatableFieldList,1) = ","
      lcUpdatableFieldList = LEFTC(lcUpdatableFieldList,LENC(lcUpdatableFieldList)-1)
    ENDIF
  ENDIF
  llSuccess = .F.
  DO CASE
    CASE NOT CURSORSETPROP("KeyFieldList",tcPKFieldName)
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar KeyFieldList"
    CASE NOT CURSORSETPROP("Tables",tcTableName)
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar Tables"
    CASE NOT CURSORSETPROP("UpdatableFieldList",lcUpdatableFieldList)
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar UpdatableFieldList"
    CASE NOT CURSORSETPROP("UpdateNameList",lcUpdateNameList)
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar UpdateNameList"
    CASE NOT CURSORSETPROP("WhereType", ;
        IIF(VARTYPE(tnWhereType)="N",tnWhereType,3))
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar WhereType"
    CASE NOT CURSORSETPROP("Buffering", ;
        IIF(VARTYPE(tnBuffering)="N",tnBuffering,3))
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar Buffering"
    CASE NOT CURSORSETPROP("SendUpdates",.T.)
      ASSERT .F. MESSAGE PROGRAM() + " no se puede configurar SendUpdates"
    OTHERWISE
      llSuccess = .T.
  ENDCASE
  SELECT (lnSelect)
  RETURN llSuccess
ENDPROC