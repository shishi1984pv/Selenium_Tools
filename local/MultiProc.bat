@echo off

:top

cd /d %~dp0
"C:\Ruby23-x64\bin\ruby.exe" "MultiProc.rb"

goto top
