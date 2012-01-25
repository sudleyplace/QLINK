;' $Header:   P:/PVCS/MISC/QLINK/QLNK_ARG.INV   1.2   07 Aug 1998 16:00:08   BOB  $
;
; (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_ARG.INC
;
; Argument flags
;

ARG_REC record	\
$ARG_XFCT:1,	\
$ARG_OPTHDR:1,	\
$ARG_DBGMSG:1,	\
$ARG_NOI:1,	\
$ARG_NOEXE:1,	\
$ARG_PACKF:1,	\
$ARG_PACKD:1,	\
$ARG_PACKC:1,	\
$ARG_FCT:1,	\
$ARG_BATCH:1,	\
$ARG_LINE:1,	\
$ARG_MAP:1,	\
$ARG_MAPADDR:1, \
$ARG_MAPFULL:1, \
$ARG_TINY:1,	\
$ARG_NOSWAP:1,	\
$ARG_NODLS:1,	\
$ARG_DOSSEG:1,	\
$ARG_NEWOMF:1,	\
$ARG_DBGERR:1,	\
$ARG_DBGSTA:1,	\
$ARG_NOEXT:1,	\
$ARG_NONULLS:1, \
$ARG_INFO:1

@ARG_XFCT  equ	 (mask $ARG_XFCT)	; 00800000:  No Far Call Translation
@ARG_OPTHDR equ  (mask $ARG_OPTHDR)	; 00400000:  Optimize .EXE header
@ARG_DBGMSG equ  (mask $ARG_DBGMSG)	; 00200000:  Display debugging messages
@ARG_NOI  equ	 (mask $ARG_NOI)	; 00100000:  NOIGNORERCASE
@ARG_NOEXE equ	 (mask $ARG_NOEXE)	; 00080000:  No EXE on error
@ARG_PACKF equ	 (mask $ARG_PACKF)	; 00040000:  Pack Functions
@ARG_PACKD equ	 (mask $ARG_PACKD)	; 00020000:  Pack Data
@ARG_PACKC equ	 (mask $ARG_PACKC)	; 00010000:  Pack Code
@ARG_FCT   equ	 (mask $ARG_FCT)	; 00008000:  Far Call Translation
@ARG_BATCH equ	 (mask $ARG_BATCH)	; 00004000:  Running in batch mode
@ARG_LINE equ	 (mask $ARG_LINE)	; 00002000:  LINE specified
@ARG_MAP  equ	 (mask $ARG_MAP)	; 00001000:  MAP specified
@ARG_MAPADDR equ (mask $ARG_MAPADDR)	; 00000800:  MAP:ADDRESS specifed
@ARG_MAPFULL equ (mask $ARG_MAPFULL)	; 00000400:  MAP:FULL specifed
@ARG_TINY    equ (mask $ARG_TINY)	; 00000200:  Create .COM file
@ARG_NOSWAP  equ (mask $ARG_NOSWAP)	; 00000100:  Turn off 386MAX's swapfile
@ARG_NODLS equ	 (mask $ARG_NODLS)	; 00000080:  No Default Library Search
@ARG_DOSSEG  equ (mask $ARG_DOSSEG)	; 00000040:  Use DOS segment ordering
@ARG_NEWOMF  equ (mask $ARG_NEWOMF)	; 00000020:  Use "New OMF" extensions
@ARG_DBGERR  equ (mask $ARG_DBGERR)	; 00000010:  Send errors to .ERR file
@ARG_DBGSTA  equ (mask $ARG_DBGSTA)	; 00000008:  Send statistics ...
@ARG_NOEXT   equ (mask $ARG_NOEXT)	; 00000004:  No extended dictionaries
@ARG_NONULLS equ (mask $ARG_NONULLS)	; 00000002:  No NULL para in segment _TEXT
@ARG_INFO    equ (mask $ARG_INFO)	; 00000001:  Display information about
					;	      link process

