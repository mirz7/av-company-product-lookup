Set WshShell = CreateObject("WScript.Shell")
strPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.Run """" & strPath & "\venv\Scripts\pythonw.exe"" """ & strPath & "\serve.py""", 0, False