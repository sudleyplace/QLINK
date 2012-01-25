;' $Header:   P:/PVCS/MISC/QLINK/QLNK_LCL.INV   1.2   07 Aug 1998 16:00:12   BOB  $
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_LCL.INC
;
; Local flags
;

LCL_REC record	\
$LCL_WINNT:1,	\
$LCL_OLIB:1,	\
$LCL_XOBJ:1,	\
$LCL_DEF:1,	\
$LCL_WIN95:1,	\
$LCL_ENV:1,	\
$LCL_CFG:1,	\
$LCL_START:1,	\
$LCL_CON32:1,	\
$LCL_SEG32:1,	\
$LCL_VCPIPREF:1,\
$LCL_VCPI:1,	\
$LCL_DPMI:1,	\
$LCL_XMS:1,	\
$LCL_RM:1,	\
$LCL_MC:1,	\
$LCL_DPMIERR:1, \
$LCL_ENDFLD:1,	\
$LCL_ARF:1,	\
$LCL_BRK:1,	\
$LCL_QUIT:1,	\
$LCL_MAPOUT:1,	\
$LCL_ERROUT:1,	\
$LCL_MODEND:1,	\
$LCL_ERROBJ:1,	\
$LCL_MEMMOD:1

@LCL_WINNT    equ (mask $LCL_WINNT)	; 02000000:  WinNT/2000/XP is active
@LCL_OLIB     equ (mask $LCL_OLIB)	; 01000000:  Processing .OBJ file from .LIB file
@LCL_XOBJ     equ (mask $LCL_XOBJ)	; 00800000:  Done processing .OBJ files
@LCL_DEF      equ (mask $LCL_DEF)	; 00400000:  Processing .DEF file
@LCL_WIN95    equ (mask $LCL_WIN95)	; 00200000:  Win95 is active
@LCL_ENV      equ (mask $LCL_ENV)	; 00100000:  Processing environment variable
@LCL_CFG      equ (mask $LCL_CFG)	; 00080000:  Processing .CFG file
@LCL_START    equ (mask $LCL_START)	; 00040000:  program has starting addr
@LCL_CON32    equ (mask $LCL_CON32)	; 00020000:  32-bit constant present
@LCL_SEG32    equ (mask $LCL_SEG32)	; 00010000:  ...    segment ...
@LCL_VCPIPREF equ (mask $LCL_VCPIPREF)	; 00008000:  Prefer VCPI over DPMI if VM
@LCL_VCPI     equ (mask $LCL_VCPI)	; 00004000:  VCPI services present
@LCL_DPMI     equ (mask $LCL_DPMI)	; 00002000:  DPMI ...
@LCL_XMS      equ (mask $LCL_XMS)	; 00001000:  XMS ...
@LCL_RM       equ (mask $LCL_RM)	; 00000800:  Starting from RM
@LCL_MC       equ (mask $LCL_MC)	; 00000400:  System is MC Architecture
@LCL_DPMIERR  equ (mask $LCL_DPMIERR)	; 00000200:  A DPMI error has occurred
@LCL_ENDFLD   equ (mask $LCL_ENDFLD)	; 00000100:  Input suppressed for trailing fields
@LCL_ARF      equ (mask $LCL_ARF)	; 00000080:  Running from .ARF file
@LCL_BRK      equ (mask $LCL_BRK)	; 00000040:  User pressed Ctrl-C or Ctrl-Break
@LCL_QUIT     equ (mask $LCL_QUIT)	; 00000020:  Time to quit
@LCL_MAPOUT   equ (mask $LCL_MAPOUT)	; 00000010:  All output goes to .MAP file
@LCL_ERROUT   equ (mask $LCL_ERROUT)	; 00000008:  ...		.ERR ..
@LCL_MODEND   equ (mask $LCL_MODEND)	; 00000004:  MODEND record encountered
@LCL_ERROBJ   equ (mask $LCL_ERROBJ)	; 00000002:  Error in .OBJ file encountered
@LCL_MEMMOD   equ (mask $LCL_MEMMOD)	; 00000001:  Memory model COMENT record present

