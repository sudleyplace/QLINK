;' $Header$
;
; (C) Copyright 1998-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_DEF.INC
;
; Definitions File flags
;

DEF_REC record	\
$DEF_INST:2,   \
$DEF_SEGS:1,   \
$DEF_DATA:1,   \
$DEF_CODE:1,   \
$DEF_RMODE:1,  \
$DEF_PMODE:1,  \
$DEF_XTYPE:2,  \
$DEF_APLOD:1,  \
$DEF_NSTUB:1,  \
$DEF_STUB:1,   \
$DEF_DESC:1,   \
$DEF_PLIB:1,   \
$DEF_NEWF:1,   \
$DEF_NTYPE:2,  \
$DEF_ETYPE:2

@DEF_INST   equ mask $DEF_INST  ; 00060000:  DATA [NONE | SINGLE | MULTIPLE]; see @DEF_INST_xxx
@DEF_SEGS   equ mask $DEF_SEGS  ; 00010000:  SEGMENTS statement present
@DEF_DATA   equ mask $DEF_DATA  ; 00008000:  DATA     ...
@DEF_CODE   equ mask $DEF_CODE  ; 00004000:  CODE     ...
@DEF_RMODE  equ mask $DEF_RMODE ; 00002000:  REALMODE ...
@DEF_PMODE  equ mask $DEF_PMODE ; 00001000:  PROTMODE ...
@DEF_XTYPE  equ mask $DEF_XTYPE ; 00000C00:  EXETYPE:	see @DEF_XTYPE_xxx
@DEF_APLOD  equ mask $DEF_APLOD ; 00000200:  APPLOADER ...
@DEF_NSTUB  equ mask $DEF_NSTUB ; 00000100:  STUB NONE ...
@DEF_STUB   equ mask $DEF_STUB  ; 00000080:  STUB	...
@DEF_DESC   equ mask $DEF_DESC  ; 00000040:  DESCRIPTION ...
@DEF_PLIB   equ mask $DEF_PLIB  ; 00000020:  PRIVATELIB  ...
@DEF_NEWF   equ mask $DEF_NEWF  ; 00000010:  NEWFILES or LONGNAMES ...
@DEF_NTYPE  equ mask $DEF_NTYPE ; 0000000C:  NAME Apptype:  see @DEF_NTYPE_xxx
@DEF_ETYPE  equ mask $DEF_ETYPE ; 00000003:  Executable type: see @DEF_ETYPE_xxx

@DEF_ETYPE_NONE equ 0		; No type specified
@DEF_ETYPE_NAME equ 1		; NAME
@DEF_ETYPE_LIB	equ 2		; LIBRARY

@DEF_NTYPE_NONE equ 0		; No type specified
@DEF_NTYPE_NOVIO equ 1		; NAME NOTWINDOWCOMPAT (NOVIO) = @NE_AFLAG_ATYPE_FSCRN
@DEF_NTYPE_VIO	equ 2		; NAME WINDOWCOMPAT    (VIO)   = @NE_AFLAG_ATYPE_COMP
@DEF_NTYPE_PM	equ 3		; NAME WINDOWAPI       (PM)    = @NE_AFLAG_ATYPE_WPMAPI

@DEF_XTYPE_NONE equ 0		; No type specified
@DEF_XTYPE_WIN	equ 1		; EXETYPE WINDOWS
@DEF_XTYPE_DOS	equ 2		; EXETYPE DOS
@DEF_XTYPE_UNK	equ 3		; EXETYPE UNKNOWN

@DEF_INST_NONE	equ 0		; No type specified
@DEF_INST_NDGR	equ 1		; NONE
@DEF_INST_SING	equ 2		; SINGLE
@DEF_INST_MULT	equ 3		; MULTIPLE

