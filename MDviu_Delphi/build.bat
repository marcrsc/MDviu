@echo off
rem Compila o MDviu pela linha de comando do mesmo jeito que a IDE (MSBuild +
rem MDviu.dproj): gera o MDviu.res com icone, estilo VCL e manifesto e poe o
rem MDviu.exe nesta pasta. Uso: build.bat [Release|Debug]  (padrao Release)
setlocal
set CFG=%1
if "%CFG%"=="" set CFG=Release
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild "%~dp0MDviu.dproj" /t:Build /p:Config=%CFG% /p:Platform=Win64 /nologo /v:minimal
exit /b %ERRORLEVEL%
