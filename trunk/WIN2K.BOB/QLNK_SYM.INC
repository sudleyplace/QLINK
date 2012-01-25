;' $Header:   P:/PVCS/MISC/QLINK/QLNK_SYM.INV   1.2   07 Aug 1998 16:00:16   BOB  $
;
; (C) Copyright 1987-2000 Qualitas, Inc.  All rights reserved.
;
; QLNK_SYM.INC
;
; Equates and structures for Symbol Table Management
;

@SYM_NEW equ	-1		; SYM_PERITEM flag for a new symbol


SYM_STR struc			; Internal structure of symbol table

SYM_FLAG dd	?		; 00:  Flags (see SYMFL_REC below)
SYM_NEXTNH dd	-1		; 04:  Offset of next name hash bucket entry or -1
SYM_PERITEM dd	@SYM_NEW	; 08:  LA of PER-item data:
				;	 for class SYM, PEROBJ_STR until public
				;	 ...	   SYM, PUBDEF_STR when public
				;	 ...	   SYM, SYM_STR    if weak extrn
				;	 ...	   BKPTR, SYM_STR  if aliased
				;	 ...	   SEG, PERSEG_STR
				;	 ...	   CLS, PERCLS_STR
				;	 ...	   New, @SYM_NEW
				;	 ...	   GRP, PERGRP_STR
				;	 ...	   MOD, PERMOD_STR
SYM_SUBST dd	?		; 0C:  LA of SYM_STR of alias/weak extrn (0=none)
SYM_TYPE dd	?		; 10:  Type index (0=none)
SYM_NAMLEN dd	?		; 14:  Length in bytes of the symbol name
SYM_PNAM dd	?		; 18:  LA of name (CC_STR)
SYM_PPEROBJ dd	?		; 1C:  LA of PEROBJ_STR of PUBDEF (0=none)

SYM_STR ends


; Flags used for SYM_FLAG

SYMFL_REC record \
$SYMFL_IMP:1,	\
$SYMFL_BKPTR:1, \
$SYMFL_CL_SYM:1, \
$SYMFL_CL_SEG:1, \
$SYMFL_CL_CLS:1, \
$SYMFL_CL_GRP:1, \
$SYMFL_CL_MOD:1, \
$SYMFL_CODE:1,	\
$SYMFL_SUBST:1, \
$SYMFL_ABSCON:1, \
$SYMFL_LOCAL:1, \
$SYMFL_COM:1,	\
$SYMFL_END:1,	\
$SYMFL_PUB:1,	\
$SYMFL_EXT:1,	\
$SYMFL_WEAK:1,	\
$SYMFL_SCC:1,	\
$SYMFL_CLS:1,	\
$SYMFL_GRP:1,	\
$SYMFL_DGROUP:1, \
$SYMFL_FLAT:1,	\
$SYMFL_TEMP:1,	\
$SYMFL_ALIAS:1, \
$SYMFL_A:3,	\
$SYMFL_C:3,	\
$SYMFL_B:1,	\
$SYMFL_P:1



; The ACBP byte values must be in the low-order byte
; It is valid for Segment-Class-CombineType (@SYMFL_CL_SEG) symbols only
; except for @SYMFL_P which is also valid for pub/ext (@SYMFL_CL_SYM) symbols.

@SYMFL_IMP    equ mask $SYMFL_IMP     ; 40000000:  Symbol is imported from DLL
@SYMFL_BKPTR  equ mask $SYMFL_BKPTR   ; 20000000:  Symbol has back pointer
@SYMFL_CL_SYM equ mask $SYMFL_CL_SYM  ; 10000000:  Class is Symbol (public/ext)
@SYMFL_CL_SEG equ mask $SYMFL_CL_SEG  ; 08000000:  ...	    Segment-Class-Combinetype
@SYMFL_CL_CLS equ mask $SYMFL_CL_CLS  ; 04000000:  ...	    Class
@SYMFL_CL_GRP equ mask $SYMFL_CL_GRP  ; 02000000:  ...	    Group
@SYMFL_CL_MOD equ mask $SYMFL_CL_MOD  ; 01000000:  ...	    Module
@SYMFL_CL     equ @SYMFL_CL_SYM or \
		  @SYMFL_CL_SEG or \
		  @SYMFL_CL_CLS or \
		  @SYMFL_CL_GRP or \
		  @SYMFL_CL_MOD       ; Cover all classes
@SYMFL_CODE   equ mask $SYMFL_CODE    ; 00800000:  Segment contains code
@SYMFL_SUBST  equ mask $SYMFL_SUBST   ; 00400000:  Symbol is substituted
@SYMFL_ABSCON equ mask $SYMFL_ABSCON  ; 00200000:  ...	     Absolute Constant
@SYMFL_LOCAL  equ mask $SYMFL_LOCAL   ; 00100000:  ...	     local (LPUBDEF/LEXTDEF/LCOMDEF)
@SYMFL_COM    equ mask $SYMFL_COM     ; 00080000:  ...	     communal
@SYMFL_END    equ mask $SYMFL_END     ; 00040000:  ...	     MODEND-generated
@SYMFL_PUB    equ mask $SYMFL_PUB     ; 00020000:  ...	     PUBLIC
@SYMFL_EXT    equ mask $SYMFL_EXT     ; 00010000:  ...	     EXTRN
@SYMFL_WEAK   equ mask $SYMFL_WEAK    ; 00008000:  ...	     Weak EXTRN
@SYMFL_SCC    equ mask $SYMFL_SCC     ; 00004000:  ...	     Segment-Class-CombineType
@SYMFL_CLS    equ mask $SYMFL_CLS     ; 00002000:  ...	     Class
@SYMFL_GRP    equ mask $SYMFL_GRP     ; 00001000:  ...	     Group
@SYMFL_DGROUP equ mask $SYMFL_DGROUP  ; 00000800:  ...	     Group DGROUP
@SYMFL_FLAT   equ mask $SYMFL_FLAT    ; 00000400:  ...	     Group FLAT
@SYMFL_TEMP   equ mask $SYMFL_TEMP    ; 00000200:  ...	     temporary (can be
				      ; 	    overridden by PUBDEF)
@SYMFL_ALIAS  equ mask $SYMFL_ALIAS   ; 00000100:  ...	     aliased
@SYMFL_A      equ mask $SYMFL_A       ; 000000E0:  Alignment type
@SYMFL_C      equ mask $SYMFL_C       ; 0000001C:  Combine ...
@SYMFL_B      equ mask $SYMFL_B       ; 00000002:  Big bit
@SYMFL_P      equ mask $SYMFL_P       ; 00000001:  USE32 bit


; Flags for LOOKUP_SYM

LOOKUP_REC record $LOOKUP_APP:1,  \
		  $LOOKUP_ESI:1

@LOOKUP_APP equ mask $LOOKUP_APP     ; 00000002:  Append if not found
@LOOKUP_ESI equ mask $LOOKUP_ESI     ; 00000001:  Advance ESI past text on exit

