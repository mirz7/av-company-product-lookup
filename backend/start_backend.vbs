Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\AVSERVER\av-company-backend\backend"
WshShell.Run chr(34) & "C:\Users\AVSERVER\av-company-backend\backend\start_backend.bat" & chr(34), 0, False