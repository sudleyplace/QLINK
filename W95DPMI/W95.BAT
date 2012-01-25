@echo off
Set NMAKE=nmake
if "%_windir%" == "" Set NMAKE=nmaker

%NMAKE% /f w95.mak %1 %2 %3 %4 %5 %6 %7 %8 %9
