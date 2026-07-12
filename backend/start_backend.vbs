Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\AVSERVER\av-company-backend\backend"
WshShell.Run "cmd.exe /c " & chr(34) & "C:\Users\AVSERVER\av-company-backend\backend\start_backend.bat" & chr(34) & " > waitress.log 2>&1", 0, False