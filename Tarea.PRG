LOCAL lccomando
LOCAL lshell

#define SW_SHOW_HIDDEN 0
#define SW_SHOW_NORMAL 1
lccomando='SCHTASKS /CREATE /SC ONCE /TN "Copia" /TR c:\xsysg\copia.exe /ST 11.00 /F'
loshell=CREATEOBJECT("WScript.shell")
loshell.run(lccomando,SW_SHOW_NORMAL,.T.)
loshell=null
RELEASE loshell
RETURN 