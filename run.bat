@echo off
title Servidor PetLink Web
echo Iniciando el servidor local de PetLink con Node.js portable...
set PATH=%~dp0node-v22.12.0-win-x64;%PATH%
call "%~dp0node-v22.12.0-win-x64\npm.cmd" run dev
pause
