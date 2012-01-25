@echo off
REM Edit QLNK*.ASM and QLNK*.INC files
REM   To edit a .ASM file only, use   %0 xxx   where xxx
REM	is the three-letter file ID (e.g. EXE for QLNK_EXE.ASM).
REM   To edit a .INC file only, use   %0 . xxx	where xxx
REM	is the three-letter file ID (e.g. IWF for QLNK_IWF.INC).
REM   To edit both the .ASM and .INC files, use   %0 xxx yyy
REM	where xxx and yyy are the three-letter file IDs.

if "%1" == "" goto MAIN
if "%2" == "" goto ASM
if "%1" == "." goto INC

Set PQLNKASM=
if not exist QLNK%1.ASM Set PQLNKASM=%QLNKDIR%
Set PQLNKINC=
if not exist QLNK%2.INC Set PQLNKINC=%QLNKDIR%

call p %PQLNKASM%QLNK%1.ASM %PQLNKINC%QLNK%2.INC

goto END


:INC
Set PQLNKINC=
if not exist QLNK%2.INC Set PQLNKINC=%QLNKDIR%

call p %PQLNKINC%QLNK%2.INC

goto END


:MAIN
Set PQLNKASM=
if not exist QLINK.ASM Set PQLNKASM=%QLNKDIR%
call p %PQLNKASM%QLINK.ASM

goto END


:ASM
Set PQLNKASM=
if not exist QLNK%1.ASM Set PQLNKASM=%QLNKDIR%
call p %PQLNKASM%QLNK%1.ASM

:END
