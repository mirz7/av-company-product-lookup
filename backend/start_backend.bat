@echo off
cd /d "%~dp0"
call venv\Scripts\activate
python -u serve.py > waitress.log 2>&1