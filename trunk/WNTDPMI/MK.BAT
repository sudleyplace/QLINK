@echo off
echo Running NMAKE
if "%_NT_TARGET_VERSION%" == "" call N:\WINDDK\SETENV.BAT
r:
nmaker /f wntstub.mak %1 %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto END
build
copy objfre_wnet_x86\i386\wntvdd.dll ret\wntdpmi.*
copy ret\wntdpmi.dll r:\lib\.
:END
