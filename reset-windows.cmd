@echo off
rem Double-click launcher for reset-windows.ps1 (must be in the same folder).
rem Reads the script as UTF-8 explicitly so Korean text works on any Windows locale.
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText('%~dp0reset-windows.ps1', [Text.Encoding]::UTF8))"
