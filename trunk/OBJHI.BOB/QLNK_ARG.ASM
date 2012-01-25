;' $Header:   P:/PVCS/MISC/QLINK/QLNK_ARG.ASV   1.2   07 Aug 1998 16:00:06   BOB  $
	title	QLNK_ARG -- QLINK Argument Processor
	page	58,122
	name	QLNK_ARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2002 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, August, 1994.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include DOSCALL.INC
	include BITFLAGS.INC
	include OPEN.INC
	include ALLMEM.INC
	include WINSTR.INC

	include QLNK_COM.INC
	include QLNK_LIN.INC
	include QLNK_LI2.INC
	include QLNK_SEG.INC
.list

PSPGRP	group	PSP_SEG

; Define record and equates used in GET_TOKN, et. al.

TOK_REC record	\
$TOK_UC:1,	\
$TOK_RQ:1,	\
$TOK_QU:1

@TOK_UC equ	(mask $TOK_UC)	; Convert token to uppercase
@TOK_RQ equ	(mask $TOK_RQ)	; Require quotations marks around
@TOK_QU equ	(mask $TOK_QU)	; Strip quotations marks from around and within


BUFINP_STR struc		; DOS Function 0Ah (@BKEYIN) structure

BUFINP_MAX db	?		; Maximum # characters buffer can hold
				; (including CR)
BUFINP_LEN db	?		; Actual length (excluding CR)
BUFINP_BUF db	?		; Buffer contents start here

BUFINP_STR ends


FSAMAC	macro	SYM,ACT

if FSA_CNT eq 0
	public	FSATAB
FSATAB	label	dword
endif				; IF FSA_CNT eq 0

SYM	=	FSA_CNT 	;; Define the symbol *MUST* use "=" not "equ"
FSA_CNT =	FSA_CNT+(type FSATAB) ;; Next index in FSATAB
	dd	offset NGROUP:CONV_ARF_&ACT ;; Entry in ACTION table

	endm			; FSAMAC


PSP_SEG segment use16 para at 0 ; Start PSP_SEG segment
	assume	cs:PSPGRP

.xlist
	public	PSP_TERMINATE
	include PSP.INC 	; Define PSP area
.list

PSP_SEG ends			; End PSP_SEG segment


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	DEF_FLAG:dword
	include QLNK_DEF.INC

	extrn	MINSTACK:dword
	extrn	MINHEAP:dword
	extrn	NEXTSEG:word
	extrn	HIGHSEG:word
	extrn	PSPSEG:word
	extrn	LaLIBENV:dword
	extrn	NONULLS_OFF:dword
	extrn	LMB_EXPDEF:tbyte
	extrn	LMB_DEFSEG:tbyte
	extrn	TXT_CODE:tbyte

	public	ARG_FLAG
	include QLNK_ARG.INC
ARG_FLAG dd	0		; Argument flags

@DPL3	equ	3 shl $NE_SEGTAB_IOPL ; DPL = 3

	public	SEG_CODE,SEG_DATA
SEG_CODE dd	@DPL3		; Definitions file CODE
SEG_DATA dd	@DPL3 or @NE_SEGTAB_DC ; ...	   DATA

	public	LaLIBENVLast
LaLIBENVLast dd 0		; LA of last LIBDIR entry (0=none)

	public	LNKENV_VEC
LNKENV_VEC dd	?		; Seg:Off of QLINK= environment variable

	public	DEFEXT_VEC,EXEFIL_EXTVEC
DEFEXT_VEC dd	?		; Seg:off where default extension appended
EXEFIL_EXTVEC dd ?		; DEFEXT_VEC for .EXE/.COM file

	public	LAST_EXPDEF,LAST_DEFSEG
LAST_EXPDEF dd	?		; LA of last EXPDEF_STR
LAST_DEFSEG dd	?		; LA of last DEFSEG_STR

	public	NUMBERS_LO,NUMBERS_HI
NUMBERS_LO db	'0123456789abcdef' ; Conversion table
NUMBERS_HI db	'0123456789ABCDEF' ; ...

	public	LaLIB_1ST,LaLIB_LAST
LaLIB_1ST dd	0		; LA of 1st .LIB file
LaLIB_LAST dd	?		; ...	last ...

	public	PFLDS
PFLDS	dd	@NFLDS dup (?)	; Pointers to field entries

	public	FIELDNO
FIELDNO dd	0		; Field #:  0=objfiles,
				;	    1=exefile,
				;	    2=mapfile,
				;	    3=libraries,
				;	    4=deffile

	public	PMAP_DEF
PMAP_DEF dd	?		; Offset of default .MAP file name

	public	PFID_FVEC,PFID_LEN
PFID_FVEC df	?		; Seg:Off to main filename.ext
PFID_LEN dw	?		; Length of ...

	public	PNUL_FVEC
PNUL_FVEC label fword		; Seg:Off to NUL filename
	dd	offset DGROUP:PMTNUL ; Offset of NUL filename
	dw	seg DGROUP	; Segment of ...
PNUL_LEN dw	PMTNUL_LEN	; Length of

	public	PDISP
PDISP	dw	offset NGROUP:DISPOBJ ; Display routine for .OBJ
	dw	offset NGROUP:DISPEXE ; ...		    .EXE/.COM
	dw	offset NGROUP:DISPMAP ; ...		    .MAP
	dw	offset NGROUP:DISPLIB ; ...		    .LIB
	dw	offset NGROUP:DISPDEF ; ...		    .DEF

	public	WINVER
WINVER	dw	030Ah		; Minimum Windows version #

	public	SEGOBJ_1ST,SEGOBJ_LAST,SEQOBJ
SEGOBJ_1ST dw	0		; Segment of 1st .OBJ file
SEGOBJ_LAST dw	?		; ...	     last ...
SEQOBJ	dw	0		; Sequence # of .OBJ files

	public	INPBUF_VEC
INPBUF_VEC dd	?		; Seg:Off of input buffer
@BUFSEG_LEN equ 256		; Length in bytes of input buffer (/16)

	public	CUR_STATE
CUR_STATE dd	@INI		; Current state, starting with the initial one

; The following table represents a Finite State Automaton for
; processing the .ARF file contents

; Symbols & Actions for FSA states

FSA_CNT =	0			; Initialize counter

; Recurring states

	FSAMAC	@INI,  NEXT	; 00:  Initial state
	FSAMAC	@WHT,  NEXT	; 04:  White space
	FSAMAC	@FLD,  SAVE	; 08:  Field marker
	FSAMAC	@PL1,  NEXT	; 0C:  Plus
	FSAMAC	@PLF,  NEXT	; 10:  Plus, LF
	FSAMAC	@NAM,  SAVE	; 14:  Name
	FSAMAC	@NAMW, NEXT	; 18:  Name, white space

	FSAMAC	@INIS, SAVE	; 1C:  Initial state, switch
	FSAMAC	@WHTS, SAVE	; 20:  White space, switch
	FSAMAC	@FLDS, SAVE	; 24:  Field marker, switch
	FSAMAC	@PL1S, SAVE	; 28:  Plus, switch
	FSAMAC	@PLFS, SAVE	; 2C:  Plus, LF, switch
	FSAMAC	@NAMS, SAVE	; 30:  Name, switch
	FSAMAC	@NAMWS,SAVE	; 34:  Name, white space, switch

; One-time states

	FSAMAC	@WNAM, WNAM	; 38:  White space, name
	FSAMAC	@PNAM, PNAM	; 3C:  Plus, name or plus, LF, name
	FSAMAC	@INIF, INIF	; 40:  Save Field marker, goto INI state

	public	FSASTM
FSASTM	label	dword		; State Transition Matrix
; Char in AL is
;   ' '    '+'    ','    '/'    LF    Name
dd @WHT,  @PL1, @FLD,	@INIS, @INIF, @NAM    ; INI:   Initial state
dd @WHT,  @PL1, @FLD,	@WHTS, @INIF, @WNAM   ; WHT:   White space
dd @FLD,  @PL1, @FLD,	@FLDS, @WHT,  @NAM    ; FLD:   Field marker
dd @PL1,  @PL1, @FLD,	@PL1S, @PLF,  @PNAM   ; PL1:   Plus
dd @PLF,  @PL1, @FLD,	@PLFS, @INIF, @PNAM   ; PLF:   Plus LF
dd @NAMW, @PL1, @FLD,	@NAMS, @INIF, @NAM    ; NAM:   Name
dd @NAMW, @PL1, @FLD,	@NAMWS,@INIF, @PNAM   ; NAMW:  Name, white space

dd @WHT,  @PL1, @FLD,	@INIS, @INIF, @INIS   ; INIS:  Initial state, switch
dd @WHT,  @PL1, @FLD,	@WHTS, @INIF, @WHTS   ; WHTS:  White space, switch
dd @FLD,  @PL1, @FLD,	@FLDS, @WHT,  @FLDS   ; FLDS:  Field marker, switch
dd @PL1,  @PL1, @FLD,	@PL1S, @PLF,  @PL1S   ; PL1S:  Plus, switch
dd @PL1,  @PL1, @FLD,	@PLFS, @INIF, @PLFS   ; PLFS:  Plus LF, switch
dd @NAMW, @PL1, @FLD,	@NAMS, @INIF, @NAMS   ; NAMS:  Name, switch
dd @NAMW, @PL1, @FLD,	@NAMWS,@INIF, @NAMWS  ; NAMWS: Name, white space, switch

	public	LASTKEY,LASTCHAR
LASTKEY dd	?		; Offset of last keyword
LASTCHAR db	?		; Last character in DISPOBJ input

	public	FSASPEC
FSASPEC db	' +,/',LF,LF    ; Special characters for FSA
				; Note LF is repeated, the 2nd one is the
				; placeholder for name
FSASPEC_LEN equ $-FSASPEC	; Length of each row in the FSA_TAB

	public	MSG_SEP,MSG_UNK,MSG_UNKCFG,MSG_UNKENV,MSG_OVF,MSG_UNF
	public	MSG_FLD,MSG_OBJ,MSG_NSERR,MSG_DEF
MSG_SEP db	'様> FAIL:  Missing separator.',CR,LF,EOS
MSG_UNK db	'様> FAIL:  Unknown keyword:  ',EOS
MSG_UNKCFG db	'様> FAIL:  Unknown keyword in .CFG file:  ',EOS
MSG_UNKENV db	'様> FAIL:  Unknown keyword in ',@PRODNAME,'= variable:  ',EOS
MSG_OVF db	'様> FAIL:  Value too large:  ',EOS
MSG_UNF db	'様> FAIL:  Value too small:  ',EOS
MSG_FLD db	'様> FAIL:  Too many fields.',CR,LF,EOS
MSG_OBJ db	'様> FAIL:  No .OBJ files specified.',CR,LF,EOS
MSG_NSERR db	'様> FAIL:  Syntax error in /NS: arguments.',CR,LF,EOS
MSG_DEF db	'様> FAIL:  Unknown keyword in .DEF file:  ',EOS

	public	PMTNUL
PMTNUL	db	'NUL'           ; NUL filename
PMTNUL_LEN equ	$-PMTNUL	; Length of ...

	public	PMTOBJ,PMTEXE1,PMTEXE2,PMTMAP2,PMTMAP2,PMTLIB,PMTDEF
PMTOBJ	db     'Object Module [.OBJ]: ',EOS
PMTEXE1 db     'Run File [',EOS
PMTEXE2 db     '.EXE]: ',EOS
PMTMAP1 db     'Map File [',EOS
PMTMAP2 db     '.MAP]: ',EOS
PMTLIB	db     'Libraries [.LIB]: ',EOS
PMTDEF	db     'Definition File [.DEF]: ',EOS

	public	ERR_ARF1,ERR_ARF2,ERR_CFG,ERR_CFGSW,ERR_ENVSW
	public	ERR_DEF1,ERR_DEF2,ERR_DEF3,ERR_DEF_TOKN,ERR_DEF_SYNT
ERR_ARF1 db	'様> FAIL:  Unable to open response file.',CR,LF,EOS
ERR_ARF2 db	'様> FAIL:  Unable to read response file.',CR,LF,EOS
ERR_CFG db	'様> FAIL:  Unable to read ',@PRODNAME,'.CFG file.',CR,LF,EOS
ERR_CFGSW db	'様> FAIL:  Invalid switch in ',@PRODNAME,'.CFG file.',CR,LF,EOS
ERR_ENVSW db	'様> FAIL:  Invalid switch in ',@PRODNAME,'= variable.',CR,LF,EOS
ERR_DEF1 db	'様> FAIL:  Unable to open .DEF file.',CR,LF,EOS
ERR_DEF2 db	'様> FAIL:  Unable to read .DEF file.',CR,LF,EOS
ERR_DEF3 db	'様> FAIL:  Unable to allocate memory for .DEF file.',CR,LF,EOS
ERR_DEF_TOKN db '様> FAIL:  Unable to recognize token in .DEF file.',CR,LF,EOS
ERR_DEF_SYNT db '様> FAIL:  Extra tokens in .DEF file.',CR,LF,EOS

	public	ERR_DEFNAME_DUP_KWD
	public	ERR_DEFNAME_DUP_NAME
ERR_DEFNAME_DUP_KWD  db '様> FAIL:  Duplicate NAME/LIBRARY keywords in .DEF file.',CR,LF,EOS
ERR_DEFNAME_DUP_NAME db '様> FAIL:  Duplicate <app/dllnames> in NAME/LIBRARY keyword in .DEF file.',CR,LF,EOS
ERR_DEFLIB_DUP_KWD  equ ERR_DEFNAME_DUP_KWD
ERR_DEFLIB_DUP_NAME equ ERR_DEFNAME_DUP_NAME

	public	ERR_DEFNAME_OVF
ERR_DEFNAME_OVF db '様> FAIL:  <app/dllname> in NAME/LIBRARY keyword too long in .DEF file.',CR,LF,EOS
ERR_DEFLIB_OVF equ ERR_DEFNAME_OVF

	public	ERR_DEFDESC_DUP_KWD
	public	ERR_DEFDESC_NOTEXT
	public	ERR_DEFDESC_OVF
ERR_DEFDESC_DUP_KWD db '様> FAIL:  Duplicate DESCRIPTION keywords in .DEF file.',CR,LF,EOS
ERR_DEFDESC_NOTEXT  db '様> FAIL:  No <text> in DESCRIPTION keyword in .DEF file.',CR,LF,EOS
ERR_DEFDESC_OVF     db '様> FAIL:  <text> in DESCRIPTION keyword too long in .DEF file.',CR,LF,EOS

	public	ERR_DEFSTUB_DUP_KWD
	public	ERR_DEFSTUB_NOTEXT
	public	ERR_DEFSTUB_OVF
ERR_DEFSTUB_DUP_KWD db '様> FAIL:  Duplicate STUB keywords in .DEF file.',CR,LF,EOS
ERR_DEFSTUB_NOTEXT  db '様> FAIL:  No <text> in STUB keyword in .DEF file.',CR,LF,EOS
ERR_DEFSTUB_OVF     db '様> FAIL:  <text> in STUB keyword too long in .DEF file.',CR,LF,EOS

	public	ERR_DEFAPLOD_DUP_KWD
	public	ERR_DEFAPLOD_NOTEXT
	public	ERR_DEFAPLOD_OVF
ERR_DEFAPLOD_DUP_KWD db '様> FAIL:  Duplicate APPLOADER keywords in .DEF file.',CR,LF,EOS
ERR_DEFAPLOD_NOTEXT  db '様> FAIL:  No <text> in APPLOADER keyword in .DEF file.',CR,LF,EOS
ERR_DEFAPLOD_OVF     db '様> FAIL:  <text> in APPLOADER keyword too long in .DEF file.',CR,LF,EOS

	public	ERR_DEFEXP_OVF1,ERR_DEFEXP_OVF2
ERR_DEFEXP_OVF1 db '様> FAIL:  <name> in EXPORTS keyword too long in .DEF file.',CR,LF,EOS
ERR_DEFEXP_OVF2 db '様> FAIL:  <number> in EXPORTS keyword too large in .DEF file.',CR,LF,EOS

	public	ERR_DEFSEGS_OVF
ERR_DEFSEGS_OVF db '様> FAIL:  <name> in SEGMENTS keyword too long in .DEF file.',CR,LF,EOS

	public	ERR_DEFXTYPE_DUP_KWD
	public	ERR_DEFXTYPE_NOTEXT
ERR_DEFXTYPE_DUP_KWD db '様> FAIL:  Duplicate EXETYPE keywords in .DEF file.',CR,LF,EOS
ERR_DEFXTYPE_NOTEXT  db '様> FAIL:  No <text> in EXETYPE keyword in .DEF file.',CR,LF,EOS

	public	ERR_DEF_NOXDOS
ERR_DEF_NOXDOS db '様> FAIL:  PROTMODE/REALMODE keyword not allowed with EXETYPE DOS in .DEF file.',CR,LF,EOS

	public	ERR_DEFSIZE_NOTEXT
	public	ERR_DEFSIZE_OVF
ERR_DEFSIZE_NOTEXT  db '様> FAIL:  No <text> in STACKSIZE/HEAPSIZE keyword in .DEF file.',CR,LF,EOS
ERR_DEFSTACKSIZE_NOTEXT equ ERR_DEFSIZE_NOTEXT
ERR_DEFHEAPSIZE_NOTEXT	equ ERR_DEFSIZE_NOTEXT
ERR_DEFSIZE_OVF     db '様> FAIL:  <number> in STACKSIZE/HEAPSIZE keyword too large in .DEF file.',CR,LF,EOS
ERR_DEFSTACKSIZE_OVF	equ ERR_DEFSIZE_OVF
ERR_DEFHEAPSIZE_OVF	equ ERR_DEFSIZE_OVF

;;;;;;; public	ERR_DEFCODE_DUP_KWD,ERR_DEFDATA_DUP_KWD
;;;_DEFCODE_DUP_KWD db '様> FAIL:  Duplicate CODE keywords in .DEF file.',CR,LF,EOS
;;;_DEFDATA_DUP_KWD db '様> FAIL:  Duplicate DATA keywords in .DEF file.',CR,LF,EOS

	public	ERR_DEFCODE_SEQ
ERR_DEFCODE_SEQ db '様> FAIL:  All CODE and DATA statements in the definitions file must',CR,LF
		db '           precede the first SEGMENTS statement.',CR,LF,EOS
ERR_DEFDATA_SEQ equ ERR_DEFCODE_SEQ

	public	EXT_OBJ,EXT_EXE,EXT_COM,EXT_MAP,EXT_LIB,EXT_DEF
EXT_OBJ db	'.OBJ'          ; Default extension for .OBJ file
EXT_EXE db	'.EXE'          ; ...                   .EXE ...
EXT_COM db	'.COM'          ; ...                   .COM ...
EXT_MAP db	'.MAP'          ; ...                   .MAP ...
EXT_LIB db	'.LIB'          ; ...                   .LIB ...
EXT_DEF db	'.DEF'          ; ...                   .DEF ...

	public	CFGNAME
CFGNAME db	@PRODNAME,'.CFG',0 ; Configuration file name
CFGNAME_LEN equ $-CFGNAME	; Length of ...

	public	ENVNAME
ENVNAME db	@PRODNAME,'='   ; Environment variable name
ENVNAME_LEN equ $-ENVNAME	; Length of ...

	public	MSG_CRLF
MSG_CRLF db	CR,LF,EOS

	public	LCLFID
LCLFID	db	128 dup (0)	; Local storage for main FID

	public	CMD_TOKL,CMD_TOKN,CMD_TOKZ
CMD_TOKL db	?		; Length in bytes of following token
CMD_TOKN db	255 dup (' ')   ; Save area for a token
CMD_TOKZ dw	0		; Terminator (double-zero)

	public	WIN_NAME,WIN_DESC,WIN_STUB,WIN_APLOD
WIN_NAME db	0,255 dup (?)	; Application name (CC_STR)
WIN_DESC db	0,255 dup (?)	; Description (CC_STR)
WIN_STUB db	255 dup (?),0	; Stub
WIN_APLOD db	255 dup (?),0	; Apploader

	public	EXE_WIN
EXE_WIN db	0		; 1 = In Windows, 0 = not

DATA	ends			; End DATA segment


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 DEF
  LINARG_MA2 'APPLOADER',   'APPLOADER',   DEF_APPLOADER,   LCL
  LINARG_MA2 'CODE',        'CODE',        DEF_CODE,        LCL
  LINARG_MA2 'DATA',        'DATA',        DEF_DATA,        LCL
  LINARG_MA2 'DESCRIPTION', 'DESCRIPTION', DEF_DESCRIPTION, LCL
  LINARG_MA2 'EXETYPE',     'EXETYPE',     DEF_EXETYPE,     LCL
  LINARG_MA2 'EXPORTS',     'EXPORTS',     DEF_EXPORTS,     LCL
;;LINARG_MA2 'FUNCTIONS',   'FUNCTIONS',   DEF_FUNCTIONS,   LCL
  LINARG_MA2 'HEAPSIZE',    'HEAPSIZE',    DEF_HEAPSIZE,    LCL
;;LINARG_MA2 'IMPORTS',     'IMPORTS',     DEF_IMPORTS,     LCL
;;LINARG_MA2 'INCLUDE',     'INCLUDE',     DEF_INCLUDE,     LCL
  LINARG_MA2 'LIBRARY',     'LIBRARY',     DEF_LIBRARY,     LCL
  LINARG_MA2 'NAME',        'NAME',        DEF_NAME,        LCL
;;LINARG_MA2 'OLD',         'OLD',         DEF_OLD,         LCL
  LINARG_MA2 'PROTMODE',    'PROTMODE',    DEF_PROTMODE,    LCL
  LINARG_MA2 'REALMODE',    'REALMODE',    DEF_REALMODE,    LCL
  LINARG_MA2 'SEGMENTS',    'SEGMENTS',    DEF_SEGMENTS,    LCL
  LINARG_MA2 'STACKSIZE',   'STACKSIZE',   DEF_STACKSIZE,   LCL
  LINARG_MA2 'STUB',        'STUB',        DEF_STUB,        LCL
	ENDSEG_MA2 DEF


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 DEFCHK
  LINARG_MA2 'APPLOADER',   'APPLOADER',   DEF_CHK,         LCL
  LINARG_MA2 'CODE',        'CODE',        DEF_CHK,         LCL
  LINARG_MA2 'DATA',        'DATA',        DEF_CHK,         LCL
  LINARG_MA2 'DESCRIPTION', 'DESCRIPTION', DEF_CHK,         LCL
  LINARG_MA2 'EXETYPE',     'EXETYPE',     DEF_CHK,         LCL
  LINARG_MA2 'EXPORTS',     'EXPORTS',     DEF_CHK,         LCL
  LINARG_MA2 'FUNCTIONS',   'FUNCTIONS',   DEF_CHK,         LCL
  LINARG_MA2 'HEAPSIZE',    'HEAPSIZE',    DEF_CHK,         LCL
  LINARG_MA2 'IMPORTS',     'IMPORTS',     DEF_CHK,         LCL
  LINARG_MA2 'INCLUDE',     'INCLUDE',     DEF_CHK,         LCL
  LINARG_MA2 'LIBRARY',     'LIBRARY',     DEF_CHK,         LCL
  LINARG_MA2 'NAME',        'NAME',        DEF_CHK,         LCL
  LINARG_MA2 'OLD',         'OLD',         DEF_CHK,         LCL
  LINARG_MA2 'PROTMODE',    'PROTMODE',    DEF_CHK,         LCL
  LINARG_MA2 'REALMODE',    'REALMODE',    DEF_CHK,         LCL
  LINARG_MA2 'SEGMENTS',    'SEGMENTS',    DEF_CHK,         LCL
  LINARG_MA2 'STACKSIZE',   'STACKSIZE',   DEF_CHK,         LCL
  LINARG_MA2 'STUB',        'STUB',        DEF_CHK,         LCL
	ENDSEG_MA2 DEFCHK


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 DEFNAME
  LINARG_MA2 'LONGNAMES',       'LONGNAMES',       DEFNAME_NEWFILES, LCL
  LINARG_MA2 'NEWFILES',        'NEWFILES',        DEFNAME_NEWFILES, LCL
  LINARG_MA2 'NOTWINDOWCOMPAT', 'NOTWINDOWCOMPAT', DEFNAME_NOVIO,    LCL
  LINARG_MA2 'WINDOWAPI',       'WINDOWAPI',       DEFNAME_PM,       LCL
  LINARG_MA2 'WINDOWCOMPAT',    'WINDOWCOMPAT',    DEFNAME_VIO,      LCL
	ENDSEG_MA2 DEFNAME


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 DEFLIB
  LINARG_MA2 'PRIVATELIB', 'PRIVATELIB', DEFLIB_PRIVATELIB, LCL
	ENDSEG_MA2 DEFLIB


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 STUB
  LINARG_MA2 'NONE',  'NONE', DEFSTUB_NONE, LCL
	ENDSEG_MA2 STUB


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 EXE
  LINARG_MA2 'DOS',      'DOS',     DEFEXETYPE_DOS,     LCL
  LINARG_MA2 'UNKNOWN',  'UNKNOWN', DEFEXETYPE_UNKNOWN, LCL
  LINARG_MA2 'WINDOWS',  'WINDOWS', DEFEXETYPE_WINDOWS, LCL
	ENDSEG_MA2 EXE


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 CODE
  LINARG_MA2 'DISCARDABLE',     'DISCARDABLE',    DEFCODE_DISCARDABLE,    LCL
  LINARG_MA2 'EXECUTEONLY',     'EXECUTEONLY',    DEFCODE_EXECUTEONLY,    LCL
  LINARG_MA2 'EXECUTEREAD',     'EXECUTEREAD',    DEFCODE_EXECUTEREAD,    LCL
  LINARG_MA2 'FIXED',           'FIXED',          DEFCODE_FIXED,          LCL
  LINARG_MA2 'IMPURE',          'IMPURE',         DEFCODE_NONSHARED,      LCL
  LINARG_MA2 'LOADONCALL',      'LOADONCALL',     DEFCODE_LOADONCALL,     LCL
  LINARG_MA2 'MOVABLE',         'MOVABLE',        DEFCODE_MOVABLE,        LCL
  LINARG_MA2 'MOVEABLE',        'MOVEABLE',       DEFCODE_MOVABLE,        LCL
  LINARG_MA2 'NONDISCARDABLE',  'NONDISCARDABLE', DEFCODE_NONDISCARDABLE, LCL
  LINARG_MA2 'NONSHARED',       'NONSHARED',      DEFCODE_NONSHARED,      LCL
  LINARG_MA2 'PRELOAD',         'PRELOAD',        DEFCODE_PRELOAD,        LCL
  LINARG_MA2 'PURE',            'PURE',           DEFCODE_SHARED,         LCL
  LINARG_MA2 'SHARED',          'SHARED',         DEFCODE_SHARED,         LCL
	ENDSEG_MA2 CODE


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 DATA
  LINARG_MA2 'FIXED',           'FIXED',          DEFDATA_FIXED,          LCL
  LINARG_MA2 'IMPURE',          'IMPURE',         DEFDATA_NONSHARED,      LCL
  LINARG_MA2 'LOADONCALL',      'LOADONCALL',     DEFDATA_LOADONCALL,     LCL
  LINARG_MA2 'MULTIPLE',        'MULTIPLE',       DEFDATA_NONSHARED,      LCL
  LINARG_MA2 'MOVABLE',         'MOVABLE',        DEFDATA_MOVABLE,        LCL
  LINARG_MA2 'MOVEABLE',        'MOVEABLE',       DEFDATA_MOVABLE,        LCL
  LINARG_MA2 'NONE',            'NONE',           DEFDATA_NONE,           LCL
  LINARG_MA2 'NONSHARED',       'NONSHARED',      DEFDATA_NONSHARED,      LCL
  LINARG_MA2 'PRELOAD',         'PRELOAD',        DEFDATA_PRELOAD,        LCL
  LINARG_MA2 'PURE',            'PURE',           DEFDATA_SHARED,         LCL
  LINARG_MA2 'READONLY',        'READONLY',       DEFDATA_READONLY,       LCL
  LINARG_MA2 'READWRITE',       'READWRITE',      DEFDATA_READWRITE,      LCL
  LINARG_MA2 'SHARED',          'SHARED',         DEFDATA_SHARED,         LCL
  LINARG_MA2 'SINGLE',          'SINGLE',         DEFDATA_SHARED,         LCL
	ENDSEG_MA2 DATA


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 SEGS
  LINARG_MA2 'CLASS',           'CLASS',          DEFSEGS_CLASS,          LCL
  LINARG_MA2 'DISCARDABLE',     'DISCARDABLE',    DEFCODE_DISCARDABLE,    LCL
  LINARG_MA2 'EXECUTEONLY',     'EXECUTEONLY',    DEFCODE_EXECUTEONLY,    LCL
  LINARG_MA2 'EXECUTEREAD',     'EXECUTEREAD',    DEFCODE_EXECUTEREAD,    LCL
  LINARG_MA2 'FIXED',           'FIXED',          DEFSEGS_FIXED,          LCL
  LINARG_MA2 'IMPURE',          'IMPURE',         DEFSEGS_NONSHARED,      LCL
  LINARG_MA2 'LOADONCALL',      'LOADONCALL',     DEFSEGS_LOADONCALL,     LCL
  LINARG_MA2 'MOVABLE',         'MOVABLE',        DEFSEGS_MOVABLE,        LCL
  LINARG_MA2 'MOVEABLE',        'MOVEABLE',       DEFSEGS_MOVABLE,        LCL
  LINARG_MA2 'NONDISCARDABLE',  'NONDISCARDABLE', DEFCODE_NONDISCARDABLE, LCL
  LINARG_MA2 'NONSHARED',       'NONSHARED',      DEFSEGS_NONSHARED,      LCL
  LINARG_MA2 'PRELOAD',         'PRELOAD',        DEFSEGS_PRELOAD,        LCL
  LINARG_MA2 'PURE',            'PURE',           DEFSEGS_SHARED,         LCL
  LINARG_MA2 'READONLY',        'READONLY',       DEFDATA_READONLY,       LCL
  LINARG_MA2 'READWRITE',       'READWRITE',      DEFDATA_READWRITE,      LCL
  LINARG_MA2 'SHARED',          'SHARED',         DEFSEGS_SHARED,         LCL
	ENDSEG_MA2 SEGS


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 EXPORD
  LINARG_MA2 'NONAME',          'NONAME',       DEFEXPORD_NONAME,       LCL
  LINARG_MA2 'RESIDENTNAME',    'RESIDENTNAME', DEFEXPORD_RESNAME,      LCL
	ENDSEG_MA2 EXPORD


; All keywords in this table *MUST* be in uppercase

	INISEG_MA2 EXP
  LINARG_MA2 'NODATA',          'NODATA',       DEFEXP_NODATA,          LCL
  LINARG_MA2 'PRIVATE',         'PRIVATE',      DEFEXP_PRIVATE,         LCL
	ENDSEG_MA2 EXP


; All keywords in this table *MUST* be in uppercase

	INISEG_MAC CMD
  LINARG_MAC '/ALIGN',                   '/A',        FCN_ALIGN

  LINARG_MAC '/BATCH',                   '/B',        FCN_BATCH

  LINARG_MAC '/CODEVIEW',                '/CO',       FCN_CODEVIEW
  LINARG_MAC '/CPARMAXALLOC',            '/CP',       FCN_CPARMAXALLOC

  LINARG_MAC '/DEBUG',                   '/DEBUG',    FCN_DEBUG
  LINARG_MAC '/DOSSEG',                  '/DOSS',     FCN_DOSSEG
  LINARG_MAC '/DSALLOCATE',              '/DS',       FCN_DSALLOCATE
  LINARG_MAC '/DYNAMIC',                 '/DY',       FCN_DYNAMIC
  LINARG_MAC '/DUMP',                    '/DUMP',     FCN_DUMP

  LINARG_MAC '/EXEPACK',                 '/E',        FCN_EXEPACK

  LINARG_MAC '/FARCALLTRANSLATION',      '/F',        FCN_FARCALLTRANSLATION

;;LINARG_MAC '/HELP',                    '/HE',       FCN_HELP
  LINARG_MAC '/HIGH',                    '/HI',       FCN_HIGH

  LINARG_MAC '/INFORMATION',             '/I',        FCN_INFORMATION

  LINARG_MAC '/KNOWEAS',                 '/KN',       FCN_KNOWEAS

  LINARG_MAC '/LINENUMBERS',             '/L',        FCN_LINENUMBERS

  LINARG_MAC '/MAP',                     '/M',        FCN_MAP

  LINARG_MAC '/NODEFAULTLIBRARYSEARCH',  '/NOD',      FCN_NODEFAULTLIBRARYSEARCH
  LINARG_MAC '/NOEXTDICTIONARY',         '/NOE',      FCN_NOEXTDICTIONARY
  LINARG_MAC '/NOFARCALLTRANSLATION',    '/NOF',      FCN_NOFARCALLTRANSLATION
;;LINARG_MAC '/NOGROUPASSOCIATION',      '/NOG',      FCN_NOGROUPASSOCIATION
  LINARG_MAC '/NOIGNORECASE',            '/NOI',      FCN_NOIGNORECASE
  LINARG_MAC '/NOLOGO',                  '/NOL',      FCN_NOLOGO
  LINARG_MAC '/NONULLSDOSSEG',           '/NON',      FCN_NONULLSDOSSEG
  LINARG_MAC '/NOPACKCODE',              '/NOPACKC',  FCN_NOPACKCODE
  LINARG_MAC '/NOPACKDATA',              '/NOPACKD',  FCN_NOPACKDATA
  LINARG_MAC '/NOPACKFUNCTIONS',         '/NOPACKF',  FCN_NOPACKFUNCTIONS
  LINARG_MAC '/NOSWAP',                  '/NOS',      FCN_NOSWAP
  LINARG_MAC '/NS',                      '/NS',       FCN_NS

;;LINARG_MAC '/OLDOVERLAY',              '/OL',       FCN_OLDOVERLAY
  LINARG_MAC '/ONERROR',                 '/ON',       FCN_ONERROR
  LINARG_MAC '/OPTHEADER',               '/OP',       FCN_OPTHEADER
;;LINARG_MAC '/OVERLAYINTERRUPT',        '/OV',       FCN_OVERLAYINTERRUPT

  LINARG_MAC '/PACKCODE',                '/PACKC',    FCN_PACKCODE
  LINARG_MAC '/PACKDATA',                '/PACKD',    FCN_PACKDATA
  LINARG_MAC '/PACKFUNCTIONS',           '/PACKF',    FCN_PACKFUNCTIONS
;;LINARG_MAC '/PAUSE',                   '/PAU',      FCN_PAUSE
;;LINARG_MAC '/PCODE',                   '/PC',       FCN_PCODE
  LINARG_MAC '/PMTYPE',                  '/PM',       FCN_PMTYPE

;;LINARG_MAC '/QUICKLIBRARY',            '/Q',        FCN_QUICKLIBRARY

;;LINARG_MAC '/R',                       '/R',        FCN_R

  LINARG_MAC '/SEGMENTS',                '/SE',       FCN_SEGMENTS
  LINARG_MAC '/STACK',                   '/ST',       FCN_STACK

  LINARG_MAC '/TINY',                    '/T',        FCN_TINY

  LINARG_MAC '/WARNFIXUP',               '/W',        FCN_WARNFIXUP

  LINARG_MAC '/?',                       '/?',        FCN_QUICKHELP
	ENDSEG_MAC CMD


NCODE	segment 		; Start NCODE segment
	assume	cs:NGROUP,ds:NGROUP

	extrn	DATASEG:word

	NPPROC	CHECK_ARGS -- Check for Arguments
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for arguments

On exit:

CF	=	0 if all went OK
	=	1 otherwise

|

	pushad			; Save all EGP registers
	REGSAVE <ds,fs> 	; Save segment registers

	mov	ax,es		; Copy DGROUP segment
	mov	fs,ax		; Address it
	assume	fs:DGROUP	; Tell the assembler about it

; Make room for the input buffer

	mov	ax,NEXTSEG	; Get next available segment
	mov	INPBUF_VEC.VSEG,ax ; Save for later use
	mov	ds,ax		; Address it
	assume	ds:nothing	; Tell the assembler about it

	mov	ds:[0].BUFINP_MAX,@BUFSEG_LEN-2 ; Set the length

	add	ax,@BUFSEG_LEN/16 ; Skip over it
	mov	NEXTSEG,ax	; Protect the input buffer

	mov	ds,PSPSEG	; Address the PSP
	assume	ds:PSPGRP	; Tell the assembler about it

	call	PROC_ENV	; Process the environment variable
	jc	near ptr CHECK_ARGS_EXIT ; Jump if error (note CF=1)

	call	PROC_CFG	; Process the .CFG file
	jc	near ptr CHECK_ARGS_EXIT ; Jump if error (note CF=1)

	lea	si,PSP_PARM_STRING ; DS:SI ==> command line
	movzx	bx,PSP_PARM_COUNT ; Get length of ...
	mov	ds:[bx+si].LO,EOF ; Ensure properly terminated

	call	FIND_LIBENV	; Find LIB= environment variable

	call	CHECK_ARGS_SUB	; Handle via subroutine
	jc	near ptr CHECK_ARGS_EXIT ; Jump if error (note CF=1)

	call	CHECK_ARGS_POST ; Argument post processing

	call	FIND_MAIN	; Find the name of the main file
	jnc	short CHECK_ARGS_OKOBJ ; Jump if found

	test	ARG_FLAG,@ARG_BATCH ; Running in batch mode?
	jz	short CHECK_ARGS_PMTOBJ ; Jump if not

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:MSG_OBJ) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	stc			; Mark as in error

	jmp	CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS_PMTOBJ:

; Prompt for .OBJ files

	push	dword ptr (offset DGROUP:PMTOBJ) ; Pass the offset
	call	GET_BUFINP	; Get buffered input

	lds	si,INPBUF_VEC	; DS:SI ==> buffer struc
	assume	ds:nothing	; Tell the assembler about it

	lea	si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	call	DISPOBJ 	; Display .OBJ files from DS:SI

	call	FIND_MAIN	; Find the name of the main file
	jc	short CHECK_ARGS_PMTOBJ ; Jump if not found
CHECK_ARGS_OKOBJ:
	cmp	PFLDS[@FLD_EXE*(type PFLDS)],0 ; Izit filled in?
	jne	short CHECK_ARGS_OKEXE ; Jump if so

	test	LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	jnz	short CHECK_ARGS_DEFEXE ; Use the default value

; Prompt for .EXE file

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTEXE1) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	PFID_LEN	; Pass the length in bytes
	push	PFID_FVEC.FSEL	; Pass segment of message
	push	PFID_FVEC.FOFF	; ...  offset ...
	call	U16_DISP_MSGL	; Display the message

	push	dword ptr (offset DGROUP:PMTEXE2) ; Pass offset of message
	call	GET_BUFINP	; Get buffered input

	lds	si,INPBUF_VEC	; DS:SI ==> buffer struc
	assume	ds:nothing	; Tell the assembler about it

	lea	si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	call	DISPEXE 	; Display .EXE file from DS:SI

	jmp	short CHECK_ARGS_OKEXE ; Join common code


; Use the default name for the .EXE file

CHECK_ARGS_DEFEXE:
	lds	esi,PFID_FVEC	; DS:eSI ==> base filename
	assume	ds:nothing	; Tell the assembler about it

	call	DISPEXE 	; Display .EXE file from DS:SI
CHECK_ARGS_OKEXE:
	cmp	PFLDS[@FLD_MAP*(type PFLDS)],0 ; Izit filled in?
	jne	near ptr CHECK_ARGS_OKMAP ; Jump if so

	test	ARG_FLAG,@ARG_MAP ; Izit present?
	jz	short @F	; Jump if not

	lds	si,PFLDS[@FLD_EXE*(type PFLDS)] ; DS:SI ==> EXE filename
	assume	ds:nothing	; Tell the assembler about it

	call	FIND_FIDBEG	; Find start of FID in DS:SI
				; Return with DS:DX ==> start of FID, CX = length
	call	DISPMAP_ALLOC	; Allocate CX bytes for DS:DX
@@:
	test	LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	jnz	near ptr CHECK_ARGS_OKMAP ; Skip it (we don't require one)

; Prompt for .MAP file

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTMAP1) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	test	ARG_FLAG,@ARG_MAP ; Izit present?
	jnz	short CHECK_ARGS_MAP1 ; Jump if so

	push	PNUL_LEN	; Pass the length in bytes
	push	PNUL_FVEC.FSEL	; Pass segment of message
	push	PNUL_FVEC.FOFF	; ...  offset ...
	call	U16_DISP_MSGL	; Display the message

	mov	PMAP_DEF,offset DGROUP:PNUL_FVEC ; Save as default name

	jmp	short CHECK_ARGS_MAPCOM ; Join common code


CHECK_ARGS_MAP1:
	push	PFID_LEN	; Pass the length in bytes
	push	PFID_FVEC.FSEL	; Pass segment of message
	push	PFID_FVEC.FOFF	; ...  offset ...
	call	U16_DISP_MSGL	; Display the message

	mov	PMAP_DEF,offset DGROUP:PFID_FVEC ; Save as default name
CHECK_ARGS_MAPCOM:
	push	dword ptr (offset DGROUP:PMTMAP2) ; Pass offset of message
	call	GET_BUFINP	; Get buffered input

	lds	si,INPBUF_VEC	; DS:SI ==> buffer struc
	assume	ds:nothing	; Tell the assembler about it

	lea	si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	call	DISPMAP 	; Display .MAP file from DS:SI
CHECK_ARGS_OKMAP:
	cmp	PFLDS[@FLD_LIB*(type PFLDS)],0 ; Izit filled in?
	jne	short CHECK_ARGS_OKLIB ; Jump if so

	test	LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	jnz	short CHECK_ARGS_OKLIB ; Skip it (we don't require one)

; Prompt for .LIB files

	push	dword ptr (offset DGROUP:PMTLIB) ; Pass offset of message
	call	GET_BUFINP	; Get buffered input

	lds	si,INPBUF_VEC	; DS:SI ==> buffer struc
	assume	ds:nothing	; Tell the assembler about it

	lea	si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	call	DISPLIB 	; Display .LIB files from DS:SI
CHECK_ARGS_OKLIB:
	cmp	PFLDS[@FLD_DEF*(type PFLDS)],0 ; Izit filled in?
	jne	short CHECK_ARGS_OKDEF ; Jump if so

	test	LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	jnz	short CHECK_ARGS_OKDEF ; Skip it (we don't require one)

; Prompt for .DEF file

	push	dword ptr (offset DGROUP:PMTDEF) ; Pass offset of message
	call	GET_BUFINP	; Get buffered input

	lds	si,INPBUF_VEC	; DS:SI ==> buffer struc
	assume	ds:nothing	; Tell the assembler about it

	lea	si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	call	DISPDEF 	; Display .DEF file from DS:SI
CHECK_ARGS_OKDEF:

COMMENT|

If /DOSSEG is specified
    If /NONULLSDOSSEG is not specified
       Set NONULLS_OFF to 0010h (one NULL para)
|

	mov	NONULLS_OFF,0	; No NULL para at start of _TEXT segment

	test	ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
	jz	short @F	; Jump if not

	test	ARG_FLAG,@ARG_NONULLS ; Is /NONULLSDOSSEG specified?
	jnz	short @F	; Jump if so

	mov	NONULLS_OFF,0010h ; Insert one para at start of _TEXT segment
@@:

; Parsing of the .DEF file (if present) is left to when we
; have switched to PM and have a symbol table available to us

CHECK_ARGS_CLC:
	clc			; Indicate all went well
CHECK_ARGS_EXIT:
	REGREST <fs,ds> 	; Restore
	assume	ds:DGROUP,fs:nothing ; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	NPPROC	PROC_ENV -- Process The Environment Variable
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Process the environment variable

On exit:

CF	=	 0 if successful
	=	 1 if not

|

	pusha			; Save registers
	REGSAVE <ds,es> 	; ...

	call	FIND_LNKENV	; Find QLINK= environment variable

	cmp	LNKENV_VEC,0	; Izit present?
	je	short PROC_ENV_EXIT ; Jump if not (ntoe CF=0)

	lds	si,LNKENV_VEC	; DS:SI ==> QLINK=, zero-terminated
	assume	ds:nothing	; Tell the assembler about it

	call	STR_UPPER	; Convert the string at DS:SI to upper case
	or	LCL_FLAG,@LCL_ENV ; Mark as processing environment variable
PROC_ENV_NEXT:
	call	U16_SKIP_WHITE	; Skip over white space

	cmp	al,0		; Izit EOF marker?
	je	short PROC_ENV_EXIT ; Jump if so (note CF=0)

	cmp	al,'/'          ; Izit switch marker?
	jne	short PROC_ENV_ERRSW ; Jump if so

	push	1		; Mark as error message allowed
	push	dword ptr (offset DGROUP:TAB_CMD_SW) ; Pass offset of table
	call	CHECK_SWITCHES	; See if it matches our list of switches
	jc	short PROC_ENV_EXIT ; Jump if error (note CF=1)

	jmp	PROC_ENV_NEXT	; Go around again


PROC_ENV_ERRSW:
	push	fs		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_ENVSW) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	stc			; Mark as in error
PROC_ENV_EXIT:
	pushf			; Save flgs (CF in particular)
	and	LCL_FLAG,not @LCL_ENV ; Mark as no longer processing environment variable
	popf			; Restore

	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popa			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_ENV endp			; End PROC_ENV procedure
	NPPROC	FIND_LNKENV -- Find QLINK= Environment Variable
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Find QLINK= environment variable

|

	REGSAVE <ax,cx,si,di,es> ; Save registers

	mov	es,PSPSEG	; Address the PSP
	assume	es:PSPGRP	; Tell the assembler about it

	mov	es,PSP_ENVIR_PTR ; Get segment of our environment
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> start of environment
	mov	cx,8000h	; Maximum size of environment
	mov	al,0		; Terminator value
FIND_LNKENV_NEXT:
	cmp	al,es:[di].LO	; Izit the end of the line?
	je	short FIND_LNKENV_EXIT ; Jump if so

; Search for QLINK=

	REGSAVE <cx,di> 	; Save for a moment

	lea	si,ENVNAME	; Get offset of QLINK=
	mov	cx,ENVNAME_LEN	; Get length of ...
   repe cmps	ENVNAME[si],es:[di].LO ; Izit the same?
	REGREST <di,cx> 	; Restore
	je	short FIND_LNKENV_OK ; Jump if so

;;;;;;; mov	al,0		; Terminator value
  repne scas	es:[di].LO	; Search for it
	jne	short FIND_LNKENV_EXIT ; Jump if not found

	jmp	FIND_LNKENV_NEXT ; Go around again


FIND_LNKENV_OK:
	add	di,ENVNAME_LEN	; Skip over QLINK=
	mov	LNKENV_VEC.VOFF,di ; Save offset
	mov	LNKENV_VEC.VSEG,es ; Save segment
FIND_LNKENV_EXIT:
	REGREST <es,di,si,cx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_LNKENV endp		; End FIND_LNKENV procedure
	NPPROC	PROC_CFG -- Process .CFG File
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Process the .CFG file

On exit:

CF	=	 0 if successful
	=	 1 if not

|

	pusha			; Save registers
	REGSAVE <ds,es> 	; ...

; Look for a QLINK.CFG file first in the current directory and,
; if not found there, in the directory from which QLINK.EXE is loaded.

	mov	ax,fs		; Get DGROUP segment
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	al,@OPEN_R	; Open as read-only
	DOSCALL @OPENF2,CFGNAME ; Attempt to open the CFG file in cur dir
	jnc	short PROC_CFG_OPEN ; Jump if file found

; Try the directory from which QLINK.EXE was loaded

; Construct the filename to open in the next available segment

	mov	ds,PSPSEG	; Address the PSP
	assume	ds:PSPGRP	; Tell the assembler about it

	mov	es,PSP_ENVIR_PTR ; Get segment of our environment
	assume	es:nothing	; Tell the assembler about it

; Search for the end of environment to find the
; strings section (right next to the woodwinds)

	xor	di,di		; Start at offset 0
	mov	cx,8000h	; Maximum size of environment
	mov	al,0		; Search for this terminator (twice)
@@:
   repne scas	es:[di].LO	; Search for it
	jne	near ptr PROC_CFG_DONE ; Jump if not found (just done)

	and	cx,cx		; Is there another byte?
	jz	near ptr PROC_CFG_DONE ; Jump if not found (just done)

	scas	es:[di].LO	; Izit here twice?
	jne	short @B	; Jump if not

; ES:DI  ==>	 end of environment (string count word)

	lea	si,es:[di+2]	; Skip over the string count word

	mov	ax,es		; Get segment of the environment
	mov	ds,ax		; Address it
	assume	ds:nothing	; Tell the assembler about it

; DS:SI  ==>	 'd:\path\QLINK.EXE',0

	mov	es,NEXTSEG	; Get next available segment
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> next available segment

; Copy the string to the next available segment

	xor	cx,cx		; Mark as no path/drive separator
PROC_CFG_NEXTPATH:
	lods	ds:[si].LO	; Get the next byte

	cmp	al,'\'          ; Izit path separator
	jne	short @F	; Jump if not

	lea	cx,es:[di+1]	; Copy address of byte after path/drive sep
@@:
	cmp	al,':'          ; Izit drive separator
	jne	short @F	; Jump if not

	lea	cx,es:[di+1]	; Copy address of byte after path/drive sep
@@:
	cmp	al,0		; Izit the end?
	je	short @F	; Jump if so

	stos	es:[di].LO	; Save in

	jmp	PROC_CFG_NEXTPATH ; Go around again


@@:

; If there was a path/drive separator, strip off the
; filename.ext text after that point

	jcxz	@F		; Jump if no path/drive separator

	mov	di,cx		; Strip off filename.exe text
@@:

; Append the CFGNAME

	mov	ax,es		; Get segment of copied CFG filename
	mov	ds,ax		; Address it
	assume	ds:nothing	; Tell the assembler about it

	lea	si,CFGNAME	; DS:SI ==> .CFG filename
	mov	cx,CFGNAME_LEN	; # bytes in CFGNAME
     rep movs	es:[di].LO,DGROUP:[si].LO ; Copy it, including trailing zero

	push	di		; Pass # bytes used
	call	U16_CALC_HIGHSEG ; Calculate new HIGHSEG value

; Attempt to open it

	mov	al,@OPEN_R	; Open as read-only
	xor	dx,dx		; DS:DX ==> copy of CFG filename
	DOSCALL @OPENF2 	; Attempt to open the CFG file in cur dir
	jc	near ptr PROC_CFG_DONE ; Jump if file not found (just done)
PROC_CFG_OPEN:
	mov	bx,ax		; Copy to handle register

	mov	ax,fs		; Get segment of DGROUP
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ds,NEXTSEG	; Get next available segment
	assume	ds:nothing	; Tell the assembler about it

; Read the .CFG file into memory

	mov	cx,-1		; The whole enchilada
	xor	dx,dx		; Offset into next available segment
	DOSCALL @READF2 	; Read in the file
	jc	short PROC_CFG_READ ; Jump if something went wrong

	mov	si,ax		; Copy size of file
	mov	ds:[si].LO,EOF	; Mark as End-Of-File
	inc	si		; Count in the EOF

	push	si		; Pass # bytes used
	call	U16_CALC_HIGHSEG ; Calculate new HIGHSEG value

	DOSCALL @CLOSF2 	; Close the .CFG file

	xor	si,si		; DS:SI ==> start of command line
	call	STR_UPPER	; Convert the string at DS:SI to upper case
	or	LCL_FLAG,@LCL_CFG ; Mark as processing .CFG file
PROC_CFG_NEXT:
	call	U16_SKIP_WHITE	; Skip over white space

	cmp	al,EOF		; Izit EOF marker?
	je	short PROC_CFG_DONE ; Jump if so (that's all folks)

	cmp	al,'#'          ; Izit comment marker?
	je	short PROC_CFG_COMMENT ; Jump if so (skip ovr the coment)

	cmp	al,';'          ; Izit comment marker?
	je	short PROC_CFG_COMMENT ; Jump if so (skip ovr the coment)

	cmp	al,CR		; Izit EOL marker?
	je	short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	cmp	al,LF		; Izit EOL marker?
	je	short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	cmp	al,'/'          ; Izit switch marker?
	jne	short PROC_CFG_ERRSW ; Jump if so

	push	1		; Mark as error message allowed
	push	dword ptr (offset DGROUP:TAB_CMD_SW) ; Pass offset of table
	call	CHECK_SWITCHES	; See if it matches our list of switches
	jc	short PROC_CFG_ERRCOM ; Jump if error

	jmp	PROC_CFG_NEXT	; Go around again


; Skip over a comment

PROC_CFG_COMMENT:
	lods	ds:[si].LO	; Get next character

	cmp	al,EOF		; Izit EOF marker?
	je	short PROC_CFG_DONE ; Jump if so (that's all folks)

	cmp	al,CR		; Izit EOL marker?
	je	short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	cmp	al,LF		; Izit EOL marker?
	je	short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	jmp	PROC_CFG_COMMENT ; Go around again


; Skip over EOL markers

PROC_CFG_OVEREOL:
	lods	ds:[si].LO	; Get next character

	cmp	al,EOF		; Izit EOF marker?
	je	short PROC_CFG_DONE ; Jump if so (that's all folks)

	cmp	al,CR		; Izit EOL marker?
	je	short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	cmp	al,LF		; Izit EOL marker?
	je	short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	dec	si		; Back off to last valid character

	jmp	PROC_CFG_NEXT	; Go around again


PROC_CFG_DONE:
	clc			; Mark as successful

	jmp	short PROC_CFG_EXIT ; Join common exit code


PROC_CFG_ERRSW:
	push	fs		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_CFGSW) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	jmp	short PROC_CFG_ERRCOM ; Join common error code


PROC_CFG_READ:
	push	fs		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_CFG) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message
PROC_CFG_ERRCOM:
	DOSCALL @CLOSF2 	; Close the .CFG file

	stc			; Mark as in error
PROC_CFG_EXIT:
	pushf			; Save flgs (CF in particular)
	and	LCL_FLAG,not @LCL_CFG ; Mark as no longer processing .CFG file
	popf			; Restore

	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popa			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_CFG endp			; End PROC_CFG procedure
	NPPROC	CHECK_ARGS_SUB -- Subroutine to CHECK_ARGS
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Subroutine to CHECK_ARGS

On entry:

DS:SI	==>	 text to parse

On exit:

CF	=	 0 if successful
	=	 1 otherwise

|

	REGSAVE <eax,si>	; Save registers

	call	STR_UPPER	; Convert the string at DS:SI to upper case
CHECK_ARGS_SUB_SRCH:		; Search for arguments
	call	U16_SKIP_WHITE	; Skip over white space

	cmp	al,EOF		; Check for terminator
	je	near ptr CHECK_ARGS_SUB_EOF ; That's all folks

	cmp	al,';'          ; Check for terminator
	je	near ptr CHECK_ARGS_SUB_ENDFLD ; That's all folks

	cmp	al,','          ; Check for field separator
	je	short CHECK_ARGS_SUB_SEP ; That's all folks

	test	LCL_FLAG,@LCL_ARF ; Are we already ARFing?
	jnz	short @F	; Jump if so

	cmp	al,'@'          ; Check for ARF marker
	je	short CHECK_ARGS_SUB_ARF ; That's all folks
@@:
	cmp	al,'/'          ; Check for switch marker
	jne	near ptr CHECK_ARGS_SUB_XSW ; Jump if not
CHECK_ARGS_SUB_SW:
	push	1		; Mark as error message allowed
	push	dword ptr (offset DGROUP:TAB_CMD_SW) ; Pass offset of table
	call	CHECK_SWITCHES	; See if it matches our list of switches
	jnc	short CHECK_ARGS_SUB_SRCH ; Jump if found

	jmp	CHECK_ARGS_SUB_EXIT ; Jump if not found (note CF=1)


CHECK_ARGS_SUB_ARF:
	inc	si		; Skip over the ARF marker

	call	CHECK_ARF	; Check it out
	jc	near ptr CHECK_ARGS_SUB_EXIT ; Jump if something went wrong (note CF=1)

	jmp	CHECK_ARGS_SUB_SRCH ; Go around again


CHECK_ARGS_SUB_SEP:
	inc	si		; Skip over the field separator
	inc	FIELDNO 	; Skip to the next field

	cmp	FIELDNO,@NFLDS	; Izit too large?
	jb	near ptr CHECK_ARGS_SUB_SRCH ; Jump if not

; If the field is empty, ignore it

	call	U16_SKIP_WHITE	; Skip over white space

	cmp	al,EOF		; Izit EOF marker?
	je	short CHECK_ARGS_SUB_EOF ; Jump if so

	cmp	al,';'          ; Izit comment marker?
	je	short CHECK_ARGS_SUB_ENDFLD ; Jump if so

	cmp	al,','          ; Check for field separator
	je	short CHECK_ARGS_SUB_SEP ; Jump if so

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:MSG_FLD) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	stc			; Mark as in error

	jmp	short CHECK_ARGS_SUB_EXIT ; Join common exit code


CHECK_ARGS_SUB_XSW:
	call	U16_SKIP_WHITE	; Skip over white space

	mov	eax,FIELDNO	; Get the field #

; Display the input with the appropriate prompt

	call	PDISP[eax*(type PDISP)] ; Display the input
				; Return with DS:SI ==> next char after input
	jc	short CHECK_ARGS_SUB_EXIT ; Jump if something went wrong (note CF=1)

	jmp	CHECK_ARGS_SUB_SRCH ; Go around again


; EOF encountered:  if we're ARFing, call it an end field marker

CHECK_ARGS_SUB_EOF:
	test	LCL_FLAG,@LCL_ARF ; Are we ARFing?
	jz	short CHECK_ARGS_SUB_DONE ; Jump if not

; We're done processing arguments

CHECK_ARGS_SUB_ENDFLD:
	or	LCL_FLAG,@LCL_ENDFLD ; Mark as ending field marker present
	or	ARG_FLAG,@ARG_BATCH ; Mark as running in batch mode
CHECK_ARGS_SUB_DONE:
	clc			; Mark as successful
CHECK_ARGS_SUB_EXIT:
	REGREST <si,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS_SUB endp		; End CHECK_ARGS_SUB procedure
	NPPROC	CHECK_SWITCHES -- Check For Switches
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for switches

On entry:

DS:SI	==>	command line to parse

On exit:

CF	=	0 if found
	=	1 if not
DS:SI	==>	next character after switch

|

CSW_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CSW_PTAB dd	?		; Offset in DGROUP of switch table
CSW_FLAG dw	?		; 1 = allow error message; 0 = don't

CSW_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; It's a switch command:  find out which one.

	mov	edx,[bp].CSW_PTAB ; Get offset in DGROUP of table
	xor	ebx,ebx 	; Zero index register
	mov	ecx,DGROUP:[edx].SWTAB_NARGS ; # arguments to check

	push	si		; Save for a moment
	push	@TOK_UC 	; Tell 'em to convert to uppercase
	call	U16_GET_TOKN	; Get the next token into CMD_TOKN
	pop	si		; Restore
	jc	short CHECK_SWITCHES_NOTFOUND ; Jump if error
CHECK_SWITCHES_NEXT:
	REGSAVE <cx,si,ds,es>	; Save for a moment

	mov	ax,es		; Get segment of CMD_TOKN
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	lea	si,CMD_TOKN	; DS:SI ==> token

; Get maximum length

	mov	edi,DGROUP:[edx].SWTAB_MAX ; Get pointer to maximum length
	mov	cx,(type CMDARG_MAX) ptr NGROUP:[edi+ebx*(type CMDARG_MAX)]

; Get location of text

	mov	edi,DGROUP:[edx].SWTAB_TAB ; Get pointer to text table
	les	di,(type CMDARG_TAB) ptr NGROUP:[edi+ebx*(type CMDARG_TAB)]
	assume	es:nothing	; Tell the assembler about it

	push	di		; Save for a moment

   repe cmps	ds:[si].LO,es:[di].LO ; Compare 'em
	je	short @F	; Jump if it matches

	dec	di		; Back off to mismatch
@@:
	mov	ax,di		; Get offset of mismatching char

	pop	di		; Restore

	sub	ax,di		; Subtract to get length

	REGREST <es,ds,si,cx>	; Restore
	assume	ds:nothing,es:DGROUP ; Tell the assembler about it

; Mark as found only if the next character is a valid separator
; and the length is >= the minimum

	mov	edi,DGROUP:[edx].SWTAB_MIN ; Get pointer to minimum length
	mov	di,(type CMDARG_MIN) ptr NGROUP:[edi+ebx*(type CMDARG_MIN)]

	cmp	ax,di		; Izit at or above the minimum length?
	jb	short CHECK_SWITCHES_NEXT1 ; Jump if not

	mov	di,si		; Copy starting offset
	add	di,ax		; Add actual length into starting offset
	mov	al,ds:[di]	; Get the next character

	cmp	al,':'          ; Check for valid separator
	je	short CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,'+'          ; Check for valid separator
	je	short CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,','          ; Check for valid separator
	je	short CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,';'          ; Check for valid separator
	je	short CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,'/'          ; Check for valid separator
	je	short CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,' '          ; Check for blank or below
	jbe	short CHECK_SWITCHES_FOUND ; A match
CHECK_SWITCHES_NEXT1:
	inc	ebx		; Skip to next entry

	loop	CHECK_SWITCHES_NEXT ; Jump if more entries to check

; Keyword not found

CHECK_SWITCHES_NOTFOUND:
	cmp	[bp].CSW_FLAG,0 ; Ignore error message?
	je	short CHECK_SWITCHES_NOTFOUND1 ; Jump if so

	lea	edi,MSG_UNKCFG	; ES:EDI ==> message

	test	LCL_FLAG,@LCL_CFG ; Izit in .CFG file?
	jnz	short @F	; Jump if so

	lea	edi,MSG_DEF	; ES:EDI ==> message

	test	LCL_FLAG,@LCL_DEF ; Izit in .DEF file?
	jnz	short @F	; Jump if so

	lea	edi,MSG_UNKENV	; ES:EDI ==> message

	test	LCL_FLAG,@LCL_ENV ; Izit in environment variable?
	jnz	short @F	; Jump if so

	lea	edi,MSG_UNK	; ES:EDI ==> message
@@:
	call	U16_DISP_UNK	; Display it along with unknown keyword at DS:SI
CHECK_SWITCHES_NOTFOUND1:
	stc			; Indicate an error occurred

	jmp	short CHECK_SWITCHES_EXIT ; Join common exit code


CHECK_SWITCHES_FOUND:
	mov	LASTKEY.ELO,si	; Save starting offset
	mov	si,di		; Skip over the keyword

; Take appropriate action

	mov	edi,DGROUP:[edx].SWTAB_ACT ; Get pointer to action
	call	(type CMDARG_ACT) ptr NGROUP:[edi+ebx*(type CMDARG_ACT)]
				; Return with CF significant
CHECK_SWITCHES_EXIT:
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	pop	bp		; Restore

	ret	4+2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SWITCHES endp		; End CHECK_SWITCHES procedure
	NPPROC	CHECK_ARGS_POST -- Argument Post Processing
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Argument post processing

|

; If /TINY is specified and /NOFARCALL is not specified, use /FARCALL

	test	ARG_FLAG,@ARG_TINY ; Is it specified?
	jz	short @F	; Jump if not

	test	ARG_FLAG,@ARG_XFCT ; Is it specified?
	jnz	short @F	; Jump if so

	or	ARG_FLAG,@ARG_FCT ; Specify /FARCALL
@@:








	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS_POST endp		; End CHECK_ARGS_POST procedure
	NPPROC	GET_BUFINP -- Get Buffered Input
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get buffered input

|

GBI_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
GBI_PMT dd	?		; Offset in DGROUP of prompt

GBI_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,dx,ds>	; Save registers

; Display the leading prompt

	push	es		; Pass the segment
	push	[bp].GBI_PMT	; Pass the offset
	call	U16_DISP_MSG	; Display the message

	lds	dx,INPBUF_VEC	; DS:DX ==> buffer for input
	assume	ds:nothing	; Tell the assembler about it

	DOSCALL @BKEYIN 	; Get buffered keyboard input

	call	U16_NEWLINE	; Goto a new line

	REGREST <ds,dx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_BUFINP endp 		; End GET_BUFINP procedure
	NPPROC	DISPOBJ -- Display .OBJ Files
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .OBJ files

On entry:

DS:SI	==>	 input to parse and display

On exit:

DS:SI	==>	 next character after parsed input

CF	=	 0 if successful
	=	 1 if not

|

	REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it, one file per line

DISPOBJ_AGAIN:
	call	U16_SKIP_WHITE	; Skip over white space

	push	@BIT0		; Allow continuation character ('+')
	call	FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after U16_SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  prompt for it if so

	and	cx,cx		; Izit empty?
	jnz	short DISPOBJ_SPACE ; Jump if not

	cmp	LASTCHAR,'+'    ; Izit continuation char?
	je	short DISPOBJ_AGAIN ; Jump if so (go around again)

; If we already have some .OBJs, use them

	cmp	SEGOBJ_1ST,0	; Izit filled in?
	jne	short DISPOBJ_END ; Jump if so

	test	ARG_FLAG,@ARG_BATCH ; Running in batch mode?
	jnz	short DISPOBJ_ERR ; Jump if so

; Get buffered keyboard input

	push	dword ptr (offset DGROUP:PMTOBJ) ; Pass the offset
	call	GET_BUFINP	; Get buffered input

	lds	si,INPBUF_VEC	; DS:SI ==> buffer for input
	assume	ds:nothing	; Tell the assembler about it

	lea	si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	jmp	DISPOBJ_AGAIN	; Go around again


; Allocate space for the .OBJ filename

DISPOBJ_SPACE:
	call	DISPOBJ_ALLOC	; Allocate CX bytes for DS:DX

	test	LCL_FLAG,@LCL_ARF ; Running from .ARF?
	jz	short DISPOBJ_XDISP ; Jump if not

; Display the .OBJ file with leading prompt

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTOBJ) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	bx		; Save for a moment

	mov	bx,@STD_OUT	; Display to standard output
	DOSCALL @WRITF2 	; Write it out

	pop	bx		; Restore

	cmp	LASTCHAR,'+'    ; Izit a continuation char?
	jne	short @F	; Jump if not

	push	dx		; Save for a moment

	mov	dl,LASTCHAR	; Send to console
	DOSCALL @CHROUT 	; ...

	pop	dx		; Restore
@@:
	call	U16_NEWLINE	; Goto a new line
DISPOBJ_XDISP:
	cmp	LASTCHAR,'+'    ; Are there more FIDs?
	je	near ptr DISPOBJ_AGAIN ; Jump if so
DISPOBJ_END:
	call	FIND_MAIN	; Find the name of the main file
				; Ignore return code
	clc			; Mark as successful

	jmp	short DISPOBJ_EXIT ; Join common exit code


; No .OBJ files and running in batch mode

DISPOBJ_ERR:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:MSG_OBJ) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	stc			; Mark as in error
DISPOBJ_EXIT:
	REGREST <ds,di,cx,dx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPOBJ endp			; End DISPOBJ procedure
	NPPROC	DISPOBJ_ALLOC -- Allocate Space For .OBJ Filename
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .OBJ filename

On entry:

DS:DX	==>	start of FID
CX	=	byte length

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	mov	ax,NEXTSEG	; Get next available segment

	cmp	SEGOBJ_1ST,0	; Izit initialized?
	jne	short @F	; Jump if so

	mov	SEQOBJ,0	; Initialize sequence #
	mov	SEGOBJ_1ST,ax	; Save for later use
	mov	SEGOBJ_LAST,ax	; ...
;;;;;;;
;;;;;;; call	FIND_MAIN	; Find the name of the main file
;;;;;;; 			; Ignore return code
@@:
	push	es		; Save for a moment

	mov	si,ax		; Copy segment of new entry
	xchg	si,SEGOBJ_LAST	; Mark as new last entry
	mov	es,si		; Address the previous last entry
	assume	es:nothing	; Tell the assembler about it

	mov	es:[0].POBJ_NEXT,ax ; Point it to this entry

	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	ax,SEQOBJ	; Get sequence #
	mov	es:[0].POBJ_SEQ,ax ; Save in record
	inc	SEQOBJ		; Skip to next sequence #
	mov	es:[0].POBJ_NEXT,-1 ; Mark as no next entry
	lea	edi,es:[0].POBJ_FID ; ES:EDI ==> start of save area
	mov	si,dx		; DS:SI ==> start of FID

	push	cx		; Save the byte count

    rep movs	es:[di].LO,ds:[si].LO ; Copy to save area

	pop	cx		; Restore

	push	dword ptr (offset DGROUP:EXT_OBJ) ; Pass offset in DGROUP of def ext
	call	CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	mov	es:[0].POBJ_LEN,cl ; Save as byte length (excluding trailing zero)
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Terminate it

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	add	di,16-1 	; Round up to para boundary
	shr	di,4-0		; Convert from bytes to paras
	add	NEXTSEG,di	; Protect it

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPOBJ_ALLOC endp		; End DISPOBJ_ALLOC procedure
	NPPROC	DISPEXE -- Display .EXE File
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .EXE file

On entry:

DS:SI	==>	input to parse and display

On exit:

CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it

DISPEXE_AGAIN:
	call	U16_SKIP_WHITE	; Skip over white space

	push	0		; Disallow continuation character ('+')
	call	FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after U16_SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  use default if so

	and	cx,cx		; Izit empty?
	jnz	short DISPEXE_SPACE ; Jump if not

; Use the default filename (base)

	lds	esi,PFID_FVEC	; DS:SI ==> base filename
	assume	ds:nothing	; Tell the assembler about it

	jmp	DISPEXE_AGAIN	; Go around again


; Allocate space for the .EXE/.COM filename

DISPEXE_SPACE:
	call	DISPEXE_ALLOC	; Allocate CX bytes for DS:DX

	test	LCL_FLAG,@LCL_ARF ; Running from .ARF?
	jz	short DISPEXE_XDISP ; Jump if not

; Display the .EXE/.COM file with leading prompt

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTEXE1) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	PFID_LEN	; Pass the length in bytes
	push	PFID_FVEC.FSEL	; Pass segment of message
	push	PFID_FVEC.FOFF	; ...  offset ...
	call	U16_DISP_MSGL	; Display the message

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTEXE2) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	bx		; Save for a moment

	mov	bx,@STD_OUT	; Display to standard output
	DOSCALL @WRITF2 	; Write it out

	pop	bx		; Restore

	call	U16_NEWLINE	; Goto a new line
DISPEXE_XDISP:
	clc			; Mark as successful

	REGREST <ds,di,cx,dx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPEXE endp			; End DISPEXE procedure
	NPPROC	DISPEXE_ALLOC -- Allocate Space For .EXE Filename
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .EXE filename

On entry:

DS:DX	==>	 start of FID
CX	=	 byte length

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	mov	ax,NEXTSEG	; Get next available segment
	mov	PFLDS[@FLD_EXE*(type PFLDS)].VSEG,ax ; Save for later use

	push	es		; Save for a moment

	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	edi,edi 	; ES:EDI ==> start of save area
	mov	si,dx		; DS:SI ==> start of FID

	push	cx		; Save the byte count

     rep movs	es:[di].LO,ds:[si].LO ; Copy to save area

	pop	cx		; Restore

; Append the default extension if none present

	test	ARG_FLAG,@ARG_TINY ; Izit a .COM file?
	lea	eax,EXT_COM	; Assume so
	jnz	short @F	; Jump if so

	lea	eax,EXT_EXE	; It's .EXE
@@:
	push	eax		; Pass offset in DGROUP of default extension
	call	CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Terminate it

	mov	eax,DEFEXT_VEC	; Get offset where default extension appended
				; in case the command line later specifies /TINY
	mov	EXEFIL_EXTVEC,eax ; Save for later use

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	add	di,16-1 	; Round up to para boundary
	shr	di,4-0		; Convert from bytes to paras
	add	NEXTSEG,di	; Protect it

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPEXE_ALLOC endp		; End DISPEXE_ALLOC procedure
	NPPROC	DISPMAP -- Display .MAP File
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .MAP file

On entry:

DS:SI	==>	input to parse and display

On exit:

CF	=	0 if successful
	=	1 otherwise

|

	REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it

DISPMAP_AGAIN:
	call	U16_SKIP_WHITE	; Skip over white space

	push	0		; Disallow continuation character ('+')
	call	FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after U16_SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  use default if so

	and	cx,cx		; Izit empty?
	jnz	short DISPMAP_SPACE ; Jump if not

; Use the default filename

	mov	esi,PMAP_DEF	; Get offset in DGROUP of ptr to default name
	lds	esi,DGROUP:[esi].EDF ; DS:eSI ==> default filename
	assume	ds:nothing	; Tell the assembler about it

	jmp	DISPMAP_AGAIN	; Go around again


; Allocate space for the .MAP filename

DISPMAP_SPACE:
	call	DISPMAP_ALLOC	; Allocate CX bytes for DS:DX

	test	LCL_FLAG,@LCL_ARF ; Running from .ARF?
	jz	short DISPMAP_XDISP ; Jump if not

; Display the .MAP file with leading prompt

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTMAP1) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	test	ARG_FLAG,@ARG_MAP ; Izit present?
	jnz	short DISPMAP1	; Jump if so

	push	PNUL_LEN	; Pass the length in bytes
	push	PNUL_FVEC.FSEL	; Pass segment of message
	push	PNUL_FVEC.FOFF	; ...  offset ...
	call	U16_DISP_MSGL	; Display the message

	jmp	short DISPMAP_COM ; Join common code


DISPMAP1:
	push	PFID_LEN	; Pass the length in bytes
	push	PFID_FVEC.FSEL	; Pass segment of message
	push	PFID_FVEC.FOFF	; ...  offset ...
	call	U16_DISP_MSGL	; Display the message
DISPMAP_COM:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTMAP2) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	bx		; Save for a moment

	mov	bx,@STD_OUT	; Display to standard output
	DOSCALL @WRITF2 	; Write it out

	pop	bx		; Restore

	call	U16_NEWLINE	; Goto a new line
DISPMAP_XDISP:
	clc			; Mark as successful

	REGREST <ds,di,cx,dx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPMAP endp			; End DISPMAP procedure
	NPPROC	DISPMAP_ALLOC -- Allocate Space For .MAP Filename
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .MAP filename

On entry:

DS:DX	==>	 start of FID
CX	=	 byte length

|

	REGSAVE <ax,cx,si,di>	; Save registers

	mov	ax,NEXTSEG	; Get next available segment
	mov	PFLDS[@FLD_MAP*(type PFLDS)].VSEG,ax ; Save for later use

	push	es		; Save for a moment

	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	edi,edi 	; ES:EDI ==> start of save area
	mov	si,dx		; DS:SI ==> start of FID

	push	cx		; Save the byte count

     rep movs	es:[di].LO,ds:[si].LO ; Copy to save area

	pop	cx		; Restore

	push	dword ptr (offset DGROUP:EXT_MAP) ; Pass offset in DGROUP of def ext
	call	CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Terminate it

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	add	di,16-1 	; Round up to para boundary
	shr	di,4-0		; Convert from bytes to paras
	add	NEXTSEG,di	; Protect it

	REGREST <di,si,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPMAP_ALLOC endp		; End DISPMAP_ALLOC procedure
	NPPROC	DISPLIB -- Display .LIB Files
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .LIB files

On entry:

DS:SI	==>	 input to parse and display

On exit:

CF	=	 0 if successful
	=	 1 otherwise

|

	REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it, one file per line

DISPLIB_AGAIN:
	call	U16_SKIP_WHITE	; Skip over white space

	push	@BIT0		; Allow continuation character ('+')
	call	FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after U16_SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  ignore it if so

	and	cx,cx		; Izit empty?
	jz	short DISPLIB_END ; Jump if so

	cmp	LASTCHAR,'+'    ; Izit continuation char?
	je	short DISPLIB_AGAIN ; Jump if so (go around again)

; Allocate space for the .LIB filename

	call	DISPLIB_ALLOC	; Allocate CX bytes for DS:DX

	test	LCL_FLAG,@LCL_ARF ; Running from .ARF?
	jz	short DISPLIB_XDISP ; Jump if not

; Display the .LIB file with leading prompt

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTLIB) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	bx		; Save for a moment

	mov	bx,@STD_OUT	; Display to standard output
	DOSCALL @WRITF2 	; Write it out

	pop	bx		; Restore

	cmp	LASTCHAR,'+'    ; Izit a continuation char?
	jne	short @F	; Jump if not

	push	dx		; Save for a moment

	mov	dl,LASTCHAR	; Send to console
	DOSCALL @CHROUT 	; ...

	pop	dx		; Restore
@@:
	call	U16_NEWLINE	; Goto a new line
DISPLIB_XDISP:
	cmp	LASTCHAR,'+'    ; Are there more FIDs?
	je	near ptr DISPLIB_AGAIN ; Jump if so
DISPLIB_END:
	clc			; Mark as successful
DISPLIB_EXIT:
	REGREST <ds,di,cx,dx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPLIB endp			; End DISPLIB procedure
	NPPROC	DISPLIB_ALLOC -- Allocate Space For .LIB Filename
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .LIB filename

Remember to update LINK_LIBNAM.

On entry:

DS:DX	==>	 start of FID
CX	=	 byte length

|

	pushad			; Save registers

; Check for directory

	mov	bx,dx		; Copy offset
	add	bx,cx		; Plus length

	cmp	ds:[bx-1].LO,'\' ; Izit path separator?
	jne	short @F	; Jump if not

	mov	al,0		; Get string terminator
	xchg	al,ds:[bx]	; Terminate the string

	push	ds		; Pass ptr to libdir
	push	dx		; ...
	call	AppendLIBDIR	; Append to libdir linked list

	mov	ds:[bx],al	; Restore

	jmp	DISPLIB_ALLOC_EXIT ; Join common exit code


@@:

; *FIXME*
;;;;;;; call	CHECK_LIBNAM	; Check for libname duplicates at DS:ESI
;;;;;;; jc	short LINK_LIBNAM_EXIT ; Jump if it's a duplicate

	movzx	eax,NEXTSEG	; Get next available segment
	mov	PFLDS[@FLD_LIB*(type PFLDS)].VSEG,ax ; Save for later use
	shl	eax,4-0 	; Convert from paras to bytes

	cmp	LaLIB_1ST,0	; Izit initialized?
	jne	short @F	; Jump if so

	mov	LaLIB_1ST,eax	; Save for later use
	mov	LaLIB_LAST,eax	; ...
@@:
	push	es		; Save for a moment

	mov	esi,eax 	; Copy LA of new entry
	xchg	esi,LaLIB_LAST	; Mark as new last entry
	shr	esi,4-0 	; Convert from bytes to paras
	mov	es,si		; Address the previous last entry
	assume	es:nothing	; Tell the assembler about it

	mov	es:[0].PLIB_NEXT,eax ; Point it to this entry

	shr	eax,4-0 	; Convert from bytes to paras
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	es:[0].PLIB_NEXT,-1 ; Mark as no next entry
	mov	es:[0].PLIB_HNDL,-1 ; Mark as unopened
;;;;;;; mov	es:[0].PLIB_LaXDICT,-1 ; Mark as not present
	mov	edi,type PLIB_STR ; ES:EDI ==> start of save area
	shl	eax,4-0 	; Convert from bytes to paras
	add	eax,edi 	; Add to get LA
	mov	es:[0].PLIB_PNAM,eax ; Save LA of FID

	mov	si,dx		; DS:SI ==> start of FID

	push	cx		; Save the byte count

	mov	bx,di		; Save offset of length byte
	inc	di		; Skip over length byte
    rep movs	es:[di].LO,ds:[si].LO ; Copy to save area

	pop	cx		; Restore

	push	dword ptr (offset DGROUP:EXT_LIB) ; Pass offset in DGROUP of def ext
	call	CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	mov	es:[bx].LO,cl	; Precede saved name with length byte

	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Terminate it

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	add	di,16-1 	; Round up to para boundary
	shr	di,4-0		; Convert from bytes to paras
	add	NEXTSEG,di	; Protect it
DISPLIB_ALLOC_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPLIB_ALLOC endp		; End DISPLIB_ALLOC procedure
	NPPROC	FIND_LIBENV -- Find LIB= Environment Variable
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Find LIB= environment variable

|

	REGSAVE <eax,cx,esi,di,es,gs> ; Save registers

	mov	es,PSPSEG	; Address the PSP
	assume	es:PSPGRP	; Tell the assembler about it

	mov	es,PSP_ENVIR_PTR ; Get segment of our environment
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> start of environment
	mov	cx,8000h	; Maximum size of environment
FIND_LIBENV_NEXT:
	cmp	es:[di].LO,0	; Izit the end of the line?
	je	near ptr FIND_LIBENV_EXIT ; Jump if so

; Search for LIB=

	cmp	es:[di].EDD,'=BIL' ; Izit LIB=?
	je	short FIND_LIBENV_OK ; Jump if so

	mov	al,0		; Terminator value
  repne scas	es:[di].LO	; Search for it
	jne	near ptr FIND_LIBENV_EXIT ; Jump if not found

	jmp	FIND_LIBENV_NEXT ; Go around again


FIND_LIBENV_OK:
	add	di,4		; Skip over LIB=

; Copy each path to a separate data struct (LIBDIR_STR)

	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg DGROUP:LaLIBENV ; Get segment of group of LaLIBENV
	mov	gs,ax		; Address it
	assume	gs:nothing	; Tell the assembler about it

	lea	esi,LaLIBENV	; GS:SI ==> last entry
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,esi 	; Add to get LA
	mov	LaLIBENVLast,eax ; Save as ptr to last entry

	call	AppendLIBDIRSub ; Append paths at ES:DI to libdir linked
				; list at GS:SI
FIND_LIBENV_EXIT:
	REGREST <gs,es,di,esi,cx,eax> ; Restore
	assume	es:DGROUP,gs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_LIBENV endp		; End FIND_LIBENV procedure
	NPPROC	AppendLIBDIR -- Append Paths To LIBDIR
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Append paths to LIBDIR

|

ALIBDIR_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
ALIBDIR_VEC dd	?		; Ptr to path

ALIBDIR_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <esi,di,es,gs>	; Save registers

	les	di,[bp].ALIBDIR_VEC ; ES:DI ==> incoming path
	assume	es:nothing	; Tell the assembler about it

	mov	esi,LaLIBENVLast ; Get LA of last entry
	ror	esi,4-0 	; Convert from bytes to paras
	mov	gs,si		; Address it
	assume	gs:nothing	; Tell the assembler about it

	rol	esi,4-0 	; Rotate back
	and	esi,@NIB0	; GS:SI ==> last entry

	call	AppendLIBDIRSub ; Append paths at ES:DI to libdir linked
				; list at GS:SI
	REGREST <gs,es,di,esi>	; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AppendLIBDIR endp		; End AppendLIBDIR procedure
	NPPROC	AppendLIBDIRSub -- Subroutine to Append To LIBDIR
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Subroutine to AppendLIBDIR

On entry:

ES:DI	==>	semicolon-delimited paths
GS:SI	==>	last entry

On exit:

|

	pushad			; Save registers
	REGSAVE <ds>		; ...
AppendLIBDIRSubNext:
	mov	ds,NEXTSEG	; Get next available segment
	assume	ds:nothing	; Tell the assembler about it

	xor	ebx,ebx 	; DS:eBX ==> next save char

; Skip over leading blanks

@@:
	mov	al,es:[di]	; Get next character
	inc	di		; Skip over source

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short @B	; Jump if so

	cmp	al,0		; Izit end of string?
	je	short AppendLIBDIRSubDone ; Jump if so
@@:
	cmp	al,';'          ; Izit end of path?
	je	short @F	; Jump if so

	cmp	al,0		; Izit end of string?
	je	short @F	; Jump if so

	mov	ds:[bx].LIBDIR_DIR,al ; Save in entry
	inc	bx		; Skip over destination

	mov	al,es:[di]	; Get next character
	inc	di		; Skip over source

	jmp	@B		; Go around again


; Delete trailing blanks

@@:
	dec	bx		; Back off to prev char
	js	short @F	; Jump if no more

	mov	al,ds:[bx].LIBDIR_DIR ; Get last char

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short @B	; Jump if so
@@:
	inc	bx		; Skip to next char
	jz	short AppendLIBDIRSubLoop ; Jump if it's empty

; Ensure there's a trailing backslash

	cmp	al,'\'          ; Izit present?
	je	short @F	; Jump if so

	mov	ds:[bx].LIBDIR_DIR,'\' ; Put one there
	inc	bx		; Skip over destination
@@:
	mov	ds:[bx].LIBDIR_DIR,0 ; Terminate it
	inc	bx		; Skip over destination
	mov	ds:[0].LIBDIR_NEXT,-1 ; Mark as last entry

; Check for duplicate LIBDIRs

	call	DupLIBDIR	; Check for duplicate LIBDIR at DS:0
	jc	short AppendLIBDIRSubLoop ; Jump if duplicate

; Save ptr to next segment in last segment

	xor	eax,eax 	; Zero to use as dword
	mov	ax,ds		; Copy current segment
	shl	eax,4-0 	; Convert from paras to bytes
	mov	gs:[si].LIBDIR_NEXT,eax ; Save ptr to next in last segment
	xor	si,si		; Start off in new segment
	mov	LaLIBENVLast,eax ; Save as ptr to last entry

; Copy current segment to last segment

	push	ds		; Copy it
	pop	gs		; ...
	assume	gs:nothing	; Tell the assembler about it

; Skip to next segment

	add	eax,ebx 	; Skip to end of the entry
	add	eax,16-1	; Round up to para boundary
	shr	eax,4-0 	; Convert from bytes to paras
	mov	NEXTSEG,ax	; Save as new NEXTSEG

; Check for EOS

AppendLIBDIRSubLoop:
	cmp	es:[di-1].LO,0	; Izit EOS?
	jne	near ptr AppendLIBDIRSubNext ; Jump if not
AppendLIBDIRSubDone:
	REGREST <ds>		; Restore
	popad			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AppendLIBDIRSub endp		; End AppendLIBDIRSub procedure
	NPPROC	DupLIBDIR -- Check For Duplicate LIBDIR
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check for duplicate LIBDIR

On entry:

DS:0	==>	new LIBDIR

On exit:

CF	=	0 if not duplicated
	=	1 if duplicated

|

	REGSAVE <ax,edi,es>	; Save registers

	mov	edi,LaLIBENV	; Get LA of first entry

	and	edi,edi 	; Izit empty?
	jz	short DupLIBDIRExit ; Jump if so (note CF=0)

	jmp	short @F	; Join common start code


DupLIBDIRStart:
	mov	edi,es:[di].LIBDIR_NEXT ; Get LA of next entry

	cmp	edi,-1		; Izit the last entry?
	je	short DupLIBDIRExit ; Jump if so (note CF=0)
@@:
	ror	edi,4-0 	; Convert from bytes to paras
	mov	es,di		; Address it
	assume	es:nothing	; Tell the assembler about it

	rol	edi,4-0 	; Rotate back
	and	edi,@NIB0	; ES:eDI ==> last entry

	mov	ax,offset LIBDIR_DIR ; Get offset of source string

	push	ds		; Pass source ptr
	push	ax		; ...
	add	ax,di		; Add to get offset of destin string
	push	es		; ...  destin ptr
	push	ax		; ...
	call	U16_StrICmp	; Compare strings, case-insensitive
				; Return with AX = 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short DupLIBDIRStart ; Jump if not

	stc			; Mark as duplicated
DupLIBDIRExit:
	REGREST <es,edi,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DupLIBDIR endp			; End DupLIBDIR procedure
	NPPROC	DISPDEF -- Display .DEF File
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .DEF file

On entry:

DS:SI	==>	 input to parse and display

On exit:

CF	=	 0 if successful
	=	 1 otherwise

|

	REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it

DISPDEF_AGAIN:
	call	U16_SKIP_WHITE	; Skip over white space

	push	0		; Disallow continuation character ('+')
	call	FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after U16_SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  ignore it if so

	and	cx,cx		; Izit empty?
	jz	short DISPDEF_END ; Jump if so

; Allocate space for the .DEF filename

	call	DISPDEF_ALLOC	; Allocate CX bytes for DS:DX

	test	LCL_FLAG,@LCL_ARF ; Running from .ARF?
	jz	short DISPDEF_XDISP ; Jump if not

; Display the .DEF file with leading prompt

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:PMTDEF) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	push	bx		; Save for a moment

	mov	bx,@STD_OUT	; Display to standard output
	DOSCALL @WRITF2 	; Write it out

	pop	bx		; Restore

	call	U16_NEWLINE	; Goto a new line
DISPDEF_XDISP:
DISPDEF_END:
	clc			; Mark as successful

	REGREST <ds,di,cx,dx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPDEF endp			; End DISPDEF procedure
	NPPROC	DISPDEF_ALLOC -- Allocate Space For .DEF Filename
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .DEF filename

On entry:

DS:DX	==>	 start of FID
CX	=	 byte length

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	mov	ax,NEXTSEG	; Get next available segment
	mov	PFLDS[@FLD_DEF*(type PFLDS)].VSEG,ax ; Save for later use

	push	es		; Save for a moment

	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	edi,edi 	; ES:EDI ==> start of save area
	mov	si,dx		; DS:SI ==> start of FID

	push	cx		; Save the byte count
     rep movs	es:[di].LO,ds:[si].LO ; Copy to save area
	pop	cx		; Restore

; Append the default extension if none present

	push	dword ptr (offset DGROUP:EXT_DEF) ; Pass offset in DGROUP of def ext
	call	CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Terminate it

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	add	di,16-1 	; Round up to para boundary
	shr	di,4-0		; Convert from bytes to paras
	add	NEXTSEG,di	; Protect it

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPDEF_ALLOC endp		; End DISPDEF_ALLOC procedure
	NPPROC	CHECK_ARF -- Check Automatic Response File
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check automatic response file

On entry:

DS:SI	==>	filename.ext of ARF

On exit:

DS:SI	==>	next character after ARF
CF	=	0 if successful
	=	1 otherwise

|

	REGSAVE <ax,bx,cx,dx,di,ds> ; Save registers

; Find the end of the FID

	push	0		; Disallow continuation character ('+')
	call	FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after U16_SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  error if so

	jcxz	CHECK_ARF_ERR1	; Jump if empty

; Attempt to open the file

	mov	cl,0		; ASCIIZ terminator
	xchg	cl,ds:[di]	; Terminate it
	mov	al,@OPEN_R	; Read-only access
	DOSCALL @OPENF2 	; Open the file
	xchg	cl,ds:[di]	; Restore
	jc	short CHECK_ARF_ERR1 ; Jump if something went wrong

	mov	bx,ax		; Copy to handle register

; Read it into memory

	xor	dx,dx		; Start of segment
	mov	ds,NEXTSEG	; DS:DX ==> next available segment
	assume	ds:nothing	; Tell the assembler about it

	mov	cx,-1		; Read it all in
	DOSCALL @READF2 	; ...
	jc	short CHECK_ARF_ERR2 ; Jump if something went wrong

	mov	di,dx		; Copy start of ARF contents
	add	di,ax		; Plus its length
	mov	ds:[di].LO,EOF	; Ensure properly terminated
	inc	ax		; Count it in

	add	ax,16-1 	; Round up to para boundary
	rcr	ax,1		; In case of overflow
	shr	ax,3-0		; Convert from bytes to para
	add	NEXTSEG,ax	; Protect the ARF contents

	DOSCALL @CLOSF2 	; Close 'er up

	or	LCL_FLAG,@LCL_ARF ; Mark as ARFing

	push	si		; Save for a moment
	mov	si,dx		; DS:SI ==> text to parse
	call	CONV_ARF	; Convert the .ARF contents to commnd line
	call	CHECK_ARGS_SUB	; Handle via subroutine
	pop	si		; Restore
	jc	short CHECK_ARF_ERRCOM ; Jump if something went wrong

	clc			; Mark as successful

	jmp	short CHECK_ARF_EXIT ; Join common exit code


CHECK_ARF_ERR1:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_ARF1) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	jmp	short CHECK_ARF_ERRCOM ; Join common error code


CHECK_ARF_ERR2:
	DOSCALL @CLOSF2 	; Close 'er up

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_ARF2) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message
CHECK_ARF_ERRCOM:
	and	LCL_FLAG,not @LCL_ARF ; Mark as no longer ARFing

	stc			; Mark as in error
CHECK_ARF_EXIT:
	REGREST <ds,di,dx,cx,bx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARF endp			; End CHECK_ARF procedure
	NPPROC	CONV_ARF -- Convert .ARF Contents
	assume	ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Convert .ARF contents to look like a command line

On entry:

DS:SI	==>	.ARF contents

|

	REGSAVE <ax,ebx,ecx,si,di,es> ; Save registers

	mov	ax,ds		; Copy segment
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	al,0		; Set last character
	mov	di,si		; ES:DI ==> .ARF contents
CONV_ARF_NEXT:
	lods	ds:[si].LO	; Get the next character

	cmp	al,EOF		; Izit EOF?
	je	near ptr CONV_ARF_EOF ; Jump if so

	cmp	al,';'          ; Izit EOF?
	je	near ptr CONV_ARF_EOF ; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short CONV_ARF_LF ; Jump if so

	cmp	al,' '          ; Izit white space?
	je	short CONV_ARF_SPC ; Jump if so (force to white space)

	cmp	al,CR		; Izit EOL?
	je	short CONV_ARF_NEXT ; Jump if so (ignore it)

	cmp	al,TAB		; Izit TAB?
	je	short CONV_ARF_SPC ; Jump if so (force to white space)

	cmp	al,'+'          ; Izit a separator?
	je	short CONV_ARF_SEP ; Jump if so

	cmp	al,','          ; Izit a separator?
	je	short CONV_ARF_SEP ; Jump if so

	jmp	short CONV_ARF_FSA ; Handle via FSA


CONV_ARF_SPC:
	mov	al,' '          ; Convert to a space
CONV_ARF_SEP:
CONV_ARF_LF:
CONV_ARF_FSA:

; The current char must be processed via the FSA

	REGSAVE <edi,es>	; Save for a moment

	mov	cx,fs		; Copy DGROUP segment
	mov	es,cx		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,FSASPEC	; ES:EDI ==> list of special characters
	mov	ecx,FSASPEC_LEN ; ECX = # ...
  repne scas	FSASPEC[edi]	; Search for special characters
	sub	edi,offset es:FSASPEC[type FSASPEC] ; Convert to origin-0

; We now compute the address of the word in FSASTM at row CUR_STATE, column EDI

	imul	ebx,CUR_STATE,FSASPEC_LEN ; Current state times row length

	mov	ebx,FSASTM[ebx+edi*(type FSASTM)] ; New state
	mov	CUR_STATE,ebx	; Save for next time
	mov	ebx,FSATAB[ebx] ; Get next action

	REGREST <es,edi>	; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	ebx		; Take appropriate action


; Save LF, start at initial state

CONV_ARF_INIF:
	mov	al,','          ; Get general field marker
	mov	CUR_STATE,@INI	; Start at initial state

	jmp	short CONV_ARF_SAVE ; Join common save code


; Plus, name or plus, LF, name

CONV_ARF_PNAM:
	mov	es:[di].LO,'+'  ; Save in .ARF file

	jmp	short CONV_ARF_COM ; Join common code


; White space, name

CONV_ARF_WNAM:
	mov	es:[di].LO,' '  ; Save in .ARF file
CONV_ARF_COM:
	inc	di		; Skip over it
	mov	CUR_STATE,@NAM	; Goto name state

;;;;;;; jmp	short CONV_ARF_SAVE ; Join common save code


; Initial state, switch
; White space, switch
; Plus, switch
; Plus, LF, switch
; Name, switch
; Name, white space, switch

CONV_ARF_SAVE:
	stos	es:[di].LO	; Save in .ARF file

	jmp	CONV_ARF_NEXT	; Go around again


CONV_ARF_EOF:
	stos	es:[di].LO	; Save in .ARF file

	REGREST <es,di,si,ecx,ebx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CONV_ARF endp			; End CONV_ARF procedure
	NPPROC	FIND_FIDBEG -- Find The Start of a FID
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the start of a FID

On entry:

DS:SI	==>	 start of text to parse

On exit:

DS:DX	==>	 starting offset
CX	=	 # characters in FID excluding .ext

|

	REGSAVE <ax,si,di>	; Save registers

	mov	dx,si		; Save as starting offset
	mov	di,si		; ...
FIND_FIDBEG_NEXT:
	lods	ds:[si].LO	; Get the next character

	cmp	al,0		; Check for terminator
	je	short FIND_FIDBEG_END ; Jump if so

	cmp	al,';'          ; Check for terminator
	je	short FIND_FIDBEG_END ; Jump if so

	cmp	al,EOF		; Check for terminator
	je	short FIND_FIDBEG_END ; Jump if so

	cmp	al,','          ; Check for field separator
	je	short FIND_FIDBEG_END ; Jump if so

	cmp	al,'/'          ; Check for switch marker
	je	short FIND_FIDBEG_END ; Jump if so

	cmp	al,'+'          ; Check for FID separator
	je	short FIND_FIDBEG_END ; Jump if so

	cmp	al,':'          ; Check for drive separator
	je	short FIND_FIDBEG_SEP ; Jump if so

	cmp	al,'\'          ; Check for path separator
	je	short FIND_FIDBEG_SEP ; Jump if so

	cmp	al,'.'          ; Check for ext separator
	jne	short @F	; Jump if not

	mov	di,si		; Save offset of '.'+1
@@:
	cmp	al,' '          ; Izit end of the name?
	ja	short FIND_FIDBEG_NEXT ; Jump if not
FIND_FIDBEG_END:

; If there's an extension separator after the FID start,
; shorten the length to exclude it

	cmp	di,dx		; Izit after FID start?
	jbe	short @F	; Jump if not

	mov	si,di		; Copy as ending offset
@@:
	mov	cx,si		; Copy offset
	dec	cx		; Back off to last good character
	sub	cx,dx		; Subtract to get length

	jmp	short FIND_FIDBEG_EXIT ; Join common exit code


FIND_FIDBEG_SEP:
	mov	dx,si		; Save as starting offset

	jmp	FIND_FIDBEG_NEXT ; Go around again


FIND_FIDBEG_EXIT:
	REGREST <di,si,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_FIDBEG endp		; End FIND_FIDBEG procedure
	NPPROC	FIND_FIDEND -- Find The End of a FID
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the end of a FID

On entry:

DS:SI	==>	 start of text to parse

On exit:

DS:DX	==>	 starting offset
DS:DI	==>	 next character after FID
DS:SI	==>	 DS:SI after U16_SKIP_WHITE
CX	=	 # characters in FID

|

FINDFID_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
FINDFID_FLAG dw ?		; Flags:  Bit 0 = allow continuation char ('+')

FINDFID_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax>		; Save register

	mov	dx,si		; Save starting offset
FIND_FIDEND_NEXT:
	lods	ds:[si].LO	; Get the next character
	mov	di,si		; Save next offset

	cmp	al,EOF		; Check for terminator
	je	short FIND_FIDEND_END ; Jump if so

	cmp	al,';'          ; Check for terminator
	je	short FIND_FIDEND_END ; Jump if so

	cmp	al,','          ; Check for field separator
	je	short FIND_FIDEND_END ; Jump if so

	cmp	al,'/'          ; Check for switch marker
	je	short FIND_FIDEND_END ; Jump if so

	test	[bp].FINDFID_FLAG,@BIT0 ; Allow continuation char?
	jz	short @F	; Jump if not

	cmp	al,'+'          ; Check for FID separator
	je	short FIND_FIDEND_END ; Jump if so
@@:
	cmp	al,' '          ; Izit end of the name?
	ja	short FIND_FIDEND_NEXT ; Jump if not

	call	U16_SKIP_WHITE	; Skip over white space
	inc	si		; Reverse the next instruction

; Check for empty input:  re-prompt if so

FIND_FIDEND_END:
	dec	si		; Back off to last character
	mov	LASTCHAR,al	; Save as last character

	test	[bp].FINDFID_FLAG,@BIT0 ; Allow continuation char?
	jz	short @F	; Jump if not

	cmp	LASTCHAR,'+'    ; Izit continuation char?
	jne	short @F	; Jump if not

	inc	si		; Skip over it
@@:
	dec	di		; Back off to char after FID
	mov	cx,di		; Get next offset
	sub	cx,dx		; Subtract to get length

	REGREST <ax>		; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_FIDEND endp		; End FIND_FIDEND procedure
	NPPROC	FIND_MAIN -- Find The Main File
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the main file which is the first file in the .OBJ list.

On exit:

CF	=	 0 if found
	=	 1 if not

|

	pushad			; Save all EGP registers
	REGSAVE <ds>		; Save segment register

	cmp	SEGOBJ_1ST,0	; Izit filled in?
	je	near ptr FIND_MAIN_ERR ; Jump if not

	cmp	PFID_LEN,0	; Izit already found?
	jne	near ptr FIND_MAIN_CLC ; Jump if so

	mov	ds,SEGOBJ_1ST	; DS:0 ==> first .OBJ file
	assume	ds:nothing	; Tell the assembler about it

	lea	esi,ds:[0].POBJ_FID ; Copy starting offset
	mov	edx,esi 	; ...
FIND_MAIN_NEXT:
	lods	ds:[si].LO	; Get the next character

	cmp	al,0		; Check for terminator
	je	short FIND_MAIN_END ; Jump if so

	cmp	al,';'          ; Check for terminator
	je	short FIND_MAIN_END ; Jump if so

	cmp	al,EOF		; Check for terminator
	je	short FIND_MAIN_END ; Jump if so

	cmp	al,','          ; Check for terminator
	je	short FIND_MAIN_END ; Jump if so

	cmp	al,'/'          ; Check for terminator
	je	short FIND_MAIN_END ; Jump if so

	cmp	al,'+'          ; Check for terminator
	je	short FIND_MAIN_END ; Jump if so

	cmp	al,':'          ; Izit a drive separator?
	je	short FIND_MAIN_SEP ; Jump if so

	cmp	al,'\'          ; Izit a path separator?
	je	short FIND_MAIN_SEP ; Jump if so

	cmp	al,' '          ; Check for separator
	ja	short FIND_MAIN_NEXT ; Jump if not
FIND_MAIN_END:
	mov	cx,si		; Copy offset
	dec	cx		; Back off to last good character
	sub	cx,dx		; Subtract to get length

	mov	PFID_FVEC.FOFF,edx ; Save for later use
	mov	PFID_FVEC.FSEL,ds ; ...
	mov	PFID_LEN,cx	; Save the length in bytes

; Get the length in bytes of the filename

	mov	si,dx		; Copy starting offset
FIND_MAIN_NEXT2:
	lods	ds:[si].LO	; Get the next character

	cmp	al,'.'          ; Check for separator
	loopne	FIND_MAIN_NEXT2 ; Jump if more chars and != sep
	jne	short FIND_MAIN_END2 ; Jump if no sep

	inc	cx		; Count in the EXT separator
	sub	PFID_LEN,cx	; Subtract to get the length in bytes
FIND_MAIN_END2:

; Copy the FID to local storage

	lds	esi,PFID_FVEC	; DS:ESI ==> main FID
	assume	ds:nothing	; Tell the assembler about it

	mov	cx,PFID_LEN	; Length in bytes
	lea	edi,LCLFID	; ES:EDI ==> local storage

	mov	PFID_FVEC.FOFF,edi ; Save for later use
	mov	PFID_FVEC.FSEL,es ; ...

     rep movs	LCLFID[di],ds:[si].LO ; Copy to local storage
	mov	al,0		; Terminator
	stos	es:[di].LO	; Terminate it
FIND_MAIN_CLC:
	clc			; Mark as found

	jmp	short FIND_MAIN_EXIT ; Join common exit code


FIND_MAIN_SEP:
	mov	edx,esi 	; Save offset of next char

	jmp	FIND_MAIN_NEXT	; Go around again


FIND_MAIN_ERR:
	stc			; Mark as not found
FIND_MAIN_EXIT:
	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_MAIN endp			; End FIND_MAIN procedure
	NPPROC	STR_UPPER -- Convert String to Uppercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert ASCIIZ string at DS:SI to uppercase

|

	REGSAVE <ax,si> 	; Save registers
STR_UPPER_NEXT:
	lods	ds:[si].LO	; Get next character

	and	al,al		; Check for end-of-the-line
	jz	short STR_UPPER_EXIT ; Good guess

	cmp	al,EOF		; Check for end-of-the-file
	je	short STR_UPPER_EXIT ; Good guess

	cmp	al,'a'          ; Check against lower limit
	jb	short STR_UPPER_NEXT ; Jump if too small

	cmp	al,'z'          ; Check against upper limit
	ja	short STR_UPPER_NEXT ; Jump if too large

	add	al,'A'-'a'      ; Convert to uppercase

	mov	ds:[si-1],al	; Save back in text

	jmp	short STR_UPPER_NEXT ; Go around again


STR_UPPER_EXIT:
	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STR_UPPER endp			; End STR_UPPER procedure
	NPPROC	U16_DISP_MSG -- Display Message
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an EOS-terminated message

|

U16_DISP_MSG_STR struc

	dw	?		; Caller's BP
	dw	?		; Caller's return address
U16_DISP_MSG_FVEC df ?		; Seg:Off in DGROUP of message

U16_DISP_MSG_STR ends

	push	bp		; Prepare to address stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,edx,ds>	; Save registers

	lds	edx,[bp].U16_DISP_MSG_FVEC ; DS:EDX ==> message
	assume	ds:nothing	; Tell the assembler about it

	DOSCALL @STROUT 	; Display the message

	REGREST <ds,edx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	6		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_DISP_MSG endp		; End U16_DISP_MSG procedure
	NPPROC	U16_DISP_MSGL -- Display Message by Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an length-specified message.

|

U16_DISP_MSGL_STR struc

	dw	?		; Caller's BP
	dw	?		; Caller's return address
U16_DISP_MSGL_FVEC df ? 	; Seg:Off in DGROUP of message
U16_DISP_MSGL_LEN dw  ? 	; Length in bytes

U16_DISP_MSGL_STR ends

	push	bp		; Prepare to address stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,bx,cx,edx,ds> ; Save registers

	lds	edx,[bp].U16_DISP_MSGL_FVEC ; DS:EDX ==> message
	assume	ds:nothing	; Tell the assembler about it

	mov	cx,[bp].U16_DISP_MSGL_LEN ; CX = length in bytes
	mov	bx,@STD_OUT	; Send to standard output

	DOSCALL @WRITF2 	; Display the message

	REGREST <ds,edx,cx,bx,ax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	6+2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_DISP_MSGL endp		; End U16_DISP_MSGL procedure
	NPPROC	U16_NEWLINE -- Goto A New Line
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Goto a new line

|

	REGSAVE <ax,dx> 	; Save registers

	mov	dl,CR		; Send to console
	DOSCALL @CHROUT 	; ...

	mov	dl,LF		; Send to console
	DOSCALL @CHROUT 	; ...

	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_NEWLINE endp		; End U16_NEWLINE procedure
	NPPROC	U16_CALC_HIGHSEG -- Calculate New HIGHSEG
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate new HIGHSEG

|

U16_CALC_HIGHSEG_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
U16_CALC_HIGHSEG_CNT dw ?	    ; # bytes used in NEXTSEG

U16_CALC_HIGHSEG_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,ds> 	; Save registers

	mov	ds,DATASEG	; Get segment of DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ax,[bp].U16_CALC_HIGHSEG_CNT ; Get # bytes used in NEXTSEG

	add	ax,16-1 	; Round up to para boundary
	shr	ax,4-0		; Convert from bytes to paras
	add	ax,NEXTSEG	; Add in the base segment

	cmp	ax,HIGHSEG	; Izit a new high?
	jb	short @F	; Jump if not

	mov	HIGHSEG,ax	; Save as new high
@@:
	REGREST <ds,ax> 	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_CALC_HIGHSEG endp		; End U16_CALC_HIGHSEG procedure
	NPPROC	CHECK_DEFEXT -- Check On Default Extension
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check on the default extension, VM version

Remember to update PMCHECK_DEFEXT.

On entry:

DS:DX	==>	 FID
ES:DI	==>	 output area
CX	=	 byte count

On exit:

ES:EDI	==>	 next character after extension (default or not)
CX	=	 new length if default extension appended

|

CHECK_DEFEXT_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CHECK_DEFEXT_OFF dd ?		; Offset in DGROUP of the default extension

CHECK_DEFEXT_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,dx,si>	; Save registers

; Search backwards through DS:DX for the extension marker

	mov	si,dx		; Copy to index register
	add	si,cx		; Add to get next address
	mov	dx,cx		; Save original length
	mov	DEFEXT_VEC,0	; Assume no default extension used
CHECK_DEFEXT_NEXT:
	dec	si		; Back off to previous byte
	mov	al,ds:[si]	; Get the next byte

	cmp	al,'.'          ; Izit an extension separator?
	je	short CHECK_DEFEXT_EXIT ; Jump if so (no default extension)

	cmp	al,'\'          ; Izit a path separator?
	je	short CHECK_DEFEXT_COPY ; Jump if so (use default extension)

	loop	CHECK_DEFEXT_NEXT ; Jump if more bytes to check
CHECK_DEFEXT_COPY:
	mov	DEFEXT_VEC.VSEG,es ; Save for later use
	mov	DEFEXT_VEC.VOFF,di ; ...
	mov	si,[bp].CHECK_DEFEXT_OFF.ELO ; Get def ext offset in DGROUP

	mov	cx,4		; Get length of default extension
	add	dx,cx		; Count in the default extension
     rep movs	es:[di].LO,DGROUP:[si].LO ; Copy default extension
CHECK_DEFEXT_EXIT:
	mov	cx,dx		; Return length

	REGREST <si,dx,ax>	; Restore

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEFEXT endp		; End CHECK_DEFEXT procedure
	NPPROC	U16_StrICmp -- String Compare, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, case insensitive

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

StrICmp_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrICmpArg2 dd	?		; Ptr to Arg #2
StrICmpArg1 dd	?		; ...	     #1

StrICmp_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <si,di,ds,es>	; Save registers

	lds	si,[bp].StrICmpArg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].StrICmpArg1 ; Get Arg #1 ptr
	assume	es:nothing	; Tell the assembler about it
StrICmpNext:
	mov	ah,ds:[si]	; Get next Arg #2 char
	mov	al,es:[di]	; ...	       #1 ...
	inc	si		; Skip over it
	inc	di		; ...

	and	ax,ax		; Izit EOS?
	jz	short StrICmpExit ; Jump if so with AX=0

; Check for case-sensitivity

	xchg	al,ah		; Put Arg #2 char in AL for UpperCase
	call	U16_LOWERCASE	; Convert AL to lowercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	U16_LOWERCASE	; Convert AL to lowercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	jz	short StrICmpNext ; Jump if same
StrICmpExit:
	REGREST <es,ds,di,si> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_StrICmp endp		; End U16_StrICmp procedure

DISP_UNK_MAC macro PREF,E

	NPPROC	&PREF&DISP_UNK -- Display Message and Unknown Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display message and unknown keyword.

On entry:

ES:EDI	==>	message to display
DS:eSI	==>	unknown keyword

|

	push	es		; Pass the segment
	push	edi		; Pass address of message
	call	&PREF&DISP_MSG	; Display the message

; Copy unmatched text to local buffer

	REGSAVE <&E&ax,&E&cx,&E&si,&E&di>  ; Save registers

	mov	cx,30		; Maximum message length
@@:
	lods	ds:[&E&si].LO	; Get next character
	stos	es:[&E&di].LO	; Save in local buffer

	cmp	al,' '          ; Check for terminator
	jbe	short @F	; Jump if that's all folks

	loop	@B		; Jump if more characters
@@:
	mov	ax,LF*256+CR	; Line terminators
	stos	es:[&E&di].ELO	; Save in message

	mov	al,EOS		; String terminator
	stos	es:[&E&di].ELO	; Save in message

	REGREST <&E&di,&E&si,&E&cx,&E&ax> ; Restore

	push	es		; Pass the segment
	push	edi		; Pass address of unknown keyword
	call	&PREF&DISP_MSG	; Display the message

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&DISP_UNK endp		; End &PREF&DISP_UNK procedure

	endm			; DISP_UNK_MAC

SKIP_WHITE_MAC macro PREF,E

	NPPROC	&PREF&SKIP_WHITE -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:eSI	==>	ASCII text

On exit:

AL	=	non-white space character
DS:eSI	==>	(updated)

|

@@:
	lods	ds:[&E&si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; izit white space?
	je	short @B	; Jump if so

	dec	&E&si		; Back off to last non-white space

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&SKIP_WHITE endp		; End &PREF&SKIP_WHITE procedure

	endm			SKIP_WHITE_MAC

CHECK_BASE_MAC macro PREF,E

	NPPROC	&PREF&CHECK_BASE -- Check Number Base
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the number base by looking at the string at DS:ESI.
If it looks like a C-constant (0xHHHH), then use base 16;
otherwise use base 10.

On entry:

DS:eSI	==>	string to check

On exit:

ECX	=	number base to use
DS:eSI	==>	(updated)

|

	REGSAVE <eax>		; Save register

	mov	ax,ds:[&E&si]	; Get the next two bytes
	xchg	al,ah		; Swap so that the 'X' is in AL, '0' in AH
	call	&PREF&LOWERCASE ; Convert to lowercase

	mov	ecx,10		; Assume base 10

	cmp	ax,'0x'         ; Izit hex notation?
	jne	short @F	; Jump if not

	mov	ecx,16		; Use base 16
	add	&E&si,2 	; Skip over the '0x'
@@:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&CHECK_BASE endp		; End &PREF&CHECK_BASE procedure

	endm			; CHECK_BASE_MAC

BASE2BIN_MAC macro PREF,E

	NPPROC	&PREF&BASE2BIN -- Convert From Specified Base to Binary
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:eSI in base ECX to binary.
The converted # is returned in EAX.

On entry:

ECX	=	number base
DS:eSI	==>	input save area

On exit:

CF	=	1 if overflow
	=	0 if OK
EAX	=	converted #

|

	REGSAVE <ebx,edx,edi>	; Save registers

	xor	ebx,ebx 	; Zero accumulator
&PREF&BASE2BIN_NEXT:
	lods	ds:[&E&si].LO	; Get next digit
	call	&PREF&LOWERCASE ; Convert to lowercase

	lea	edi,NUMBERS_LO	; Get address of number conversion table
	push	ecx		; Save number base (and table length)
  repne scas	NUMBERS_LO[edi] ; Look for the character
	pop	ecx		; Restore number base
	jne	short &PREF&BASE2BIN_DONE ; Not one of ours

	sub	edi,(type NUMBERS_LO)+offset es:NUMBERS_LO ; Convert to origin 0
	mov	eax,ebx 	; Copy old to multiply by base

	mul	ecx		; Shift over accumulated #
	jc	short &PREF&BASE2BIN_OVF ; Jump if out of range

	mov	ebx,eax 	; Copy back
	add	ebx,edi 	; Add in new #
	jnc	short &PREF&BASE2BIN_NEXT ; Jump if in range
&PREF&BASE2BIN_OVF:
	stc			; Indicate something went wrong

	jmp	short &PREF&BASE2BIN_EXIT ; Join common exit code


&PREF&BASE2BIN_DONE:
	dec	&E&si		; Back off to previous character
	mov	eax,ebx 	; Place result in accumulator

	clc			; Indicate all went well
&PREF&BASE2BIN_EXIT:
	REGREST <edi,edx,ebx>	; Restore registers

	ret			; Return to caller with number in EAX

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&BASE2BIN endp		; End &PREF&BASE2BIN procedure

	endm			; BASE2BIN_MAC

GET_TOKN_MAC macro PREF,WID,NUM,E

	NPPROC	&PREF&GET_TOKN -- Get next Token Into CMD_TOKN
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next token into CMD_TOKN.
Note we're assuming that there's no embedded zero in the text.

On entry:

DS:eSI	==>	next byte on command line

On exit:

DS:eSI	==>	(updated)
CMD_TOKL	filled in
CMD_TOKN	filled in
CF	=	0 if successful
	=	1 if error

|

&PREF&GET_TOKN_STR struc

	&WID	?		; Caller's eBP
	&WID	?		; ...	   eIP
&PREF&GET_TOKN_FLAG &WID ?	; Flags (see @TOK_xx)

&PREF&GET_TOKN_STR ends

	push	&E&bp		; Prepare to address the stack
	mov	&E&bp,&E&sp	; Hello, Mr. Stack

	REGSAVE <&E&ax,&E&bx,&E&dx,&E&di> ; Save registers

	lea	&E&di,CMD_TOKN	; ES:eDI ==> save area for token
	mov	bh,0		; Initialize token length
	mov	bl,0		; Mark as no previous quote
	mov	dl,0		; Mark as not requiring quotes

	test	[&E&bp].&PREF&GET_TOKN_FLAG,@TOK_RQ ; Require quotes?
	jz	short &PREF&GET_TOKN_NEXT ; Jump if not

	lods	ds:[&E&si].LO ; Get next character

	cmp	al,'"'          ; Izit a double quote?
	je	short &PREF&GET_TOKN_QUOTE ; Jump if so

	cmp	al,''''         ; Izit a single quote?
	je	short &PREF&GET_TOKN_QUOTE ; Jump if so

	mov	dl,1		; Mark as requiring quotes, but not present

	jmp	short @F	; Join common code


&PREF&GET_TOKN_NEXT:
	lods	ds:[&E&si].LO ; Get next character

	test	[&E&bp].&PREF&GET_TOKN_FLAG,@TOK_QU or @TOK_RQ ; Process quotes?
	jz	short @F	; Jump if not

	cmp	al,bl		; Duzit match a previous quote marker?
	je	short &PREF&GET_TOKN_UNQUOTE ; Jump if so

	cmp	al,'"'          ; Izit a double quote?
	je	short &PREF&GET_TOKN_QUOTE ; Jump if so

	cmp	al,''''         ; Izit a single quote?
	je	short &PREF&GET_TOKN_QUOTE ; Jump if so
@@:
	cmp	al,EOF		; Izit EOF?
	je	short &PREF&GET_TOKN_EXIT ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short &PREF&GET_TOKN_EXIT ; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short &PREF&GET_TOKN_EXIT ; Jump if so

	cmp	bl,0		; Izit outside a quote?
	jne	short @F	; Jump if not

	cmp	al,' '          ; Izit any terminator?
	jbe	short &PREF&GET_TOKN_EXIT ; Jump if so
@@:
	test	[&E&bp].&PREF&GET_TOKN_FLAG,@TOK_UC ; Convert to uppercase?
	jz	short &PREF&GET_TOKN_SAVE ; Jump if not

	call	&PREF&UPPERCASE ; Convert AL to uppercase
&PREF&GET_TOKN_SAVE:
	add	bh,1		; Count into length
	jc	short &PREF&GET_TOKN_EXIT ; Jump if too many

	stos	CMD_TOKN[&E&di] ; Save in token

	jmp	&PREF&GET_TOKN_NEXT ; Go around again


&PREF&GET_TOKN_QUOTE:
	mov	bl,al		; Save as new quote marker

	jmp	short &PREF&GET_TOKN_NEXT ; Go around again


&PREF&GET_TOKN_UNQUOTE:
	mov	bl,0		; Mark as no previous quote

	cmp	al,ds:[&E&si]	; Duplicate quote markers?
	je	short &PREF&GET_TOKN_SAVE ; Jump if so

	inc	&E&si		; Skip over ending char
&PREF&GET_TOKN_EXIT:
	mov	CMD_TOKL,bh	; Save as length of CMD_TOKN

	mov	ax,0		; Get string terminator (double-zero)
	stos	CMD_TOKN.ELO[&E&di] ; Save in token

	dec	&E&si		; Back off to ending char

; We ended correctly if DL == 0 && BL == 0 && BH != 0

	cmp	dl,1		; Did we require quotes and not find them?
	jae	short @F	; Jump if so (note CF=0)

	cmp	bl,1		; Are we unquoted?
	jae	short @F	; Jump if not (note CF=0)

	cmp	bh,1		; Izit too long or too short?
				; CF=1 ==> error
	cmc			; Convert to CF=0 ==> error
@@:
	cmc			; Convert to CF=1 ==> error

	REGREST <&E&di,&E&dx,&E&bx,&E&ax> ; Restore

	pop	&E&bp		; Restore

	ret	&NUM		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&GET_TOKN endp		; End &PREF&GET_TOKN procedure

	endm			; GET_TOKN_MAC

UPPERCASE_MAC macro PREF

	NPPROC	&PREF&UPPERCASE -- Convert AL To Uppercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to uppercase

On entry:

AL	=	character to convert

On exit:

AL	=	converted character

|

	cmp	al,'a'          ; Izit below lower limit?
	jb	short @F	; Jump if so

	cmp	al,'z'          ; Izit above upper limit?
	ja	short @F	; Jump if so

	add	al,'A'-'a'      ; Convert to uppercase
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&UPPERCASE endp		; End &PREF&UPPERCASE procedure

	endm			; UPPERCASE_MAC

LOWERCASE_MAC macro PREF

	NPPROC	&PREF&LOWERCASE -- Convert AL To Lowercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to lowercase

On entry:

AL	=	 character to convert

On exit:

AL	=	 converted character

|

	cmp	al,'A'          ; Izit below lower limit?
	jb	short @F	; Jump if so

	cmp	al,'Z'          ; Izit above upper limit?
	ja	short @F	; Jump if so

	add	al,'a'-'A'      ; Convert to lowercase
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

&PREF&LOWERCASE endp		; End &PREF&LOWERCASE procedure

	endm			; LOWERCASE_MAC

	DISP_UNK_MAC U16_
	SKIP_WHITE_MAC U16_
	CHECK_BASE_MAC U16_
	BASE2BIN_MAC U16_
	GET_TOKN_MAC U16_,dw,2
	UPPERCASE_MAC U16_
	LOWERCASE_MAC U16_

NCODE	ends			; End NCODE segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	CSEL_DATA:word

	extrn	WRITE_OUT:near
	extrn	IzitSUFCODE:near
	extrn	StrLen:near

	DISP_UNK_MAC U32_,e
	SKIP_WHITE_MAC U32_,e
	CHECK_BASE_MAC U32_,e
	BASE2BIN_MAC U32_,e
	GET_TOKN_MAC U32_,dd,4,e
	UPPERCASE_MAC U32_,e
	LOWERCASE_MAC U32_,e

	NPPROC	U32_DISP_MSG -- Display Message
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an EOS-terminated message

On exit:

CF	=	0 if successful
	=	1 if not (error writing to .MAP or .ERR file)

|

U32_DISP_MSG_STR struc

	dd	?		; Caller's EBP
	dd	?		; Caller's return address
U32_DISP_MSG_FVEC df ?		; Seg:Off of message
	dw	?		; Filler

U32_DISP_MSG_STR ends

	push	ebp		; Prepare to address stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,edx,ds> ; Save registers

	lds	edx,[ebp].U32_DISP_MSG_FVEC ; DS:EDX ==> message
	assume	ds:nothing	; Tell the assembler about it

; Calculate the EOS-terminated string length

	mov	ecx,edx 	; Copy start of message
@@:
	cmp	ds:[ecx].LO,EOS ; Izit End-Of-String?
	je	short @F	; Jump if so

	inc	ecx		; Skip to the next char

	jmp	@B		; Go around again


@@:
	sub	ecx,edx 	; Subtract to get length
	call	WRITE_OUT	; Write DS:EDX for ECX bytes to output file
				; Return with CF significant
	REGREST <ds,edx,ecx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	8		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_DISP_MSG endp		; End U32_DISP_MSG procedure
	NPPROC	U32_DISP_MSGL -- Display Message by Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an length-specified message.

On exit:

CF	=	0 if successful
	=	1 if not (error writing to .MAP or .ERR file)

|

U32_DISP_MSGL_STR struc

	dd	?		; Caller's BP
	dd	?		; Caller's return address
U32_DISP_MSGL_FVEC df ? 	; Seg:Off of message
	dw	?		; Filler
U32_DISP_MSGL_LEN dd  ? 	; Length in bytes

U32_DISP_MSGL_STR ends

	push	ebp		; Prepare to address stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,ds> ; Save registers

	lds	edx,[ebp].U32_DISP_MSGL_FVEC ; DS:EDX ==> message
	assume	ds:nothing	; Tell the assembler about it

	mov	ecx,[ebp].U32_DISP_MSGL_LEN ; ECX = length in bytes
	call	WRITE_OUT	; Write DS:EDX for ECX bytes to output file
				; Return with CF significant
	REGREST <ds,edx,ecx,ebx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	8+4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_DISP_MSGL endp		; End U32_DISP_MSGL procedure
	NPPROC	U32_NEWLINE -- Goto A New Line
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Goto a new line

On exit:

CF	=	0 if successful
	=	1 if not (error writing to .MAP or .ERR file)

|

	push	CSEL_DATA.EDD	; Pass DGROUP segment (as dword)
	push	dword ptr (offset DGROUP:MSG_CRLF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
				; Return with CF significant
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_NEWLINE endp		; End U32_NEWLINE procedure
	NPPROC	U32_CALC_HIGHSEG -- Calculate New HIGHSEG
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Calculate new HIGHSEG

|

U32_CALC_HIGHSEG_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
U32_CALC_HIGHSEG_CNT dd ?	; # bytes used in NEXTSEG

U32_CALC_HIGHSEG_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	mov	eax,[ebp].U32_CALC_HIGHSEG_CNT ; Get # bytes used in NEXTSEG

	add	eax,16-1	; Round up to para boundary
	shr	eax,4-0 	; Convert from bytes to paras
	add	ax,NEXTSEG	; Add in the base segment

	cmp	ax,HIGHSEG	; Izit a new high?
	jb	short @F	; Jump if not

	mov	HIGHSEG,ax	; Save as new high
@@:
	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_CALC_HIGHSEG endp		; End U32_CALC_HIGHSEG procedure
	NPPROC	U32_SKIP_EOL -- Skip Over EOLs and White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over EOLs and white space

On entry:

DS:ESI	==>	ASCII text

On exit:

AL	=	non-white space character

|

@@:
	lods	ds:[esi].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short @B	; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short @B	; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short @B	; Jump if so

	dec	esi		; Back off to last non-white space/EOL

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_SKIP_EOL endp		; End U32_SKIP_EOL procedure
	NPPROC	U32_CHECK_SWITCHES -- Check For Switches
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for switches

On entry:

DS:ESI	==>	command line to parse

On exit:

CF	=	0 if found
	=	1 if not
DS:ESI	==>	next character after switch

|

U32_CSW_STR  struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
U32_CSW_PTAB dd ?		; Offset in DGROUP of switch table
U32_CSW_FLAG dd ?		; 1 = allow error message; 0 = don't

U32_CSW_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; It's a switch command:  find out which one.

	mov	edx,[ebp].U32_CSW_PTAB ; Get offset in DGROUP of table
	xor	ebx,ebx 	; Zero index register
	mov	ecx,DGROUP:[edx].SWTAB_NARGS ; # arguments to check

	push	esi		; Save for a moment
	push	@TOK_UC 	; Tell 'em to convert to uppercase
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	pop	esi		; Restore
	jc	short U32_CHECK_SWITCHES_NOTFOUND ; Jump if error
U32_CHECK_SWITCHES_NEXT:
	REGSAVE <ecx,esi,ds>	; Save for a moment

	mov	ax,es		; Get segment of CMD_TOKN
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	lea	esi,CMD_TOKN	; DS:ESI ==> token

; Get maximum length

	mov	edi,DGROUP:[edx].SWTAB_MAX ; Get pointer to maximum length
	mov	ecx,(type DEFARG_MAX) ptr DGROUP:[edi+ebx*(type DEFARG_MAX)]

; Get location of text

	mov	edi,DGROUP:[edx].SWTAB_TAB ; Get pointer to text table
	mov	edi,(type DEFARG_TAB) ptr DGROUP:[edi+ebx*(type DEFARG_TAB)]

	push	edi		; Save for a moment

   repe cmps	CMD_TOKN[esi],DGROUP:[edi].LO ; Compare 'em
	je	short @F	; Jump if it matches

	dec	edi		; Back off to mismatch
@@:
	mov	eax,edi 	; Get offset of mismatching char

	pop	edi		; Restore

	sub	eax,edi 	; Subtract to get length

	REGREST <ds,esi,ecx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

; Mark as found only if the next character is a valid separator
; and the length is >= the minimum

	mov	edi,DGROUP:[edx].SWTAB_MIN ; Get pointer to minimum length
	mov	edi,(type DEFARG_MIN) ptr DGROUP:[edi+ebx*(type DEFARG_MIN)]

	cmp	eax,edi 	; Izit at or above the minimum length?
	jb	short U32_CHECK_SWITCHES_NEXT1 ; Jump if not

	mov	edi,esi 	; Copy starting offset
	add	edi,eax 	; Add actual length into starting offset
	mov	al,ds:[edi]	; Get the next character

	cmp	al,':'          ; Check for valid separator
	je	short U32_CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,','          ; Check for valid separator
	je	short U32_CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,';'          ; Check for valid separator
	je	short U32_CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,'/'          ; Check for valid separator
	je	short U32_CHECK_SWITCHES_FOUND ; Jump if valid

	cmp	al,' '          ; Check for blank or below
	jbe	short U32_CHECK_SWITCHES_FOUND ; A match
U32_CHECK_SWITCHES_NEXT1:
	inc	ebx		; Skip to next entry

	loop	U32_CHECK_SWITCHES_NEXT ; Jump if more entries to check

; Keyword not found

U32_CHECK_SWITCHES_NOTFOUND:
	cmp	[ebp].U32_CSW_FLAG,0 ; Ignore error message?
	je	short U32_CHECK_SWITCHES_NOTFOUND1 ; Jump if so

	lea	edi,MSG_UNKCFG	; ES:EDI ==> message

	test	LCL_FLAG,@LCL_CFG ; Izit in .CFG file?
	jnz	short @F	; Jump if so

	lea	edi,MSG_DEF	; ES:EDI ==> message

	test	LCL_FLAG,@LCL_DEF ; Izit in .DEF file?
	jnz	short @F	; Jump if so

	lea	edi,MSG_UNKENV	; ES:EDI ==> message

	test	LCL_FLAG,@LCL_ENV ; Izit in environment variable?
	jnz	short @F	; Jump if so

	lea	edi,MSG_UNK	; ES:EDI ==> message
@@:
	call	U32_DISP_UNK	; Display it along with unknown keyword at DS:ESI
U32_CHECK_SWITCHES_NOTFOUND1:
	stc			; Indicate an error occurred

	jmp	short U32_CHECK_SWITCHES_EXIT ; Join common exit code


U32_CHECK_SWITCHES_FOUND:
	mov	LASTKEY,esi	; Save starting offset
	mov	esi,edi 	; Skip over the keyword

; Take appropriate action

	mov	edi,DGROUP:[edx].SWTAB_ACT ; Get pointer to action
	call	(type DEFARG_ACT) ptr DGROUP:[edi+ebx*(type DEFARG_ACT)]
				; Return with CF significant
U32_CHECK_SWITCHES_EXIT:
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_CHECK_SWITCHES endp 	; End U32_CHECK_SWITCHES procedure
	NPPROC	IzitDefSwitch -- Izit .DEF File Main Switch
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Izit a .DEF file main switch?

On entry:

DS:ESI	==>	switch line

On exit:

CF	=	0 if TRUE
	=	1 if not

|

	REGSAVE <esi>		; Save register

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_DEFCHK_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
				; Return with CF = 0 iff TRUE
	REGREST <esi>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IzitDefSwitch endp		; End IzitDefSwitch procedure
	NPPROC	CHECK_DEFFILE -- Check on .DEF File
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check on .DEF file

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	pushad			; Save all EGP registers
	REGSAVE <es>		; Save register

; Parse the .DEF file (if present)

	or	LCL_FLAG,@LCL_DEF ; Mark as processing .DEF file

	mov	ax,fs		; Get DGROUP selector
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	cmp	PFLDS[@FLD_DEF*(type PFLDS)],0 ; Izit empty?
	je	near ptr CHECK_DEFFILE_DONE ; Jump if so

; Open the .DEF file and read it in

	movzx	edx,PFLDS[@FLD_DEF*(type PFLDS)].VSEG ; EDX ==> segment of .DEF filename
	shl	edx,4-0 	; Convert from paras to bytes
	movzx	eax,PFLDS[@FLD_DEF*(type PFLDS)].VOFF ; EAX ==> offset of .DEF filename
	add	edx,eax 	; DS:EDX ==> .DEF filename

	mov	al,@OPEN_R	; Open as read-only
	DOSCALL @OPENF2 	; Attempt to open the DEF file
	jc	near ptr CHECK_DEFFILE_ERROPEN ; Jump if file not found

	mov	bx,ax		; Copy to handle register

; Calculate the length of the file

	xor	cx,cx		; CX:DX = 0:0
	xor	dx,dx		; ...
	mov	al,@MOVFP2_END	; Code to move ptr to EOF
	DOSCALL @MOVFP2 	; Set file pointer
;;;;;;; jc	short ???	; Jump if error
				; Return with DX:AX = file size
	add	ax,16-1+1	; Round up to para boundary + room for EOF
	adc	dx,0		; ...
;;;;;;; jc	short ???	; Jump if error

	mov	ecx,4		; # bits to shift out
@@:
	shr	dx,1		; Shift down one bit from DX
	rcr	ax,1		; ...into AX
	loop	@B		; Jump if more bits

; Allocate memory for it

	movzx	ebp,NEXTSEG	; Get next available segment
	add	NEXTSEG,ax	; Skip over it *FIXME*
	shl	ebp,4-0 	; Convert from paras to bytes

; Move the file pointer back to the start

	xor	cx,cx		; CX:DX = 0:0
	xor	dx,dx		; ...
	mov	al,@MOVFP2_BEG	; Code to move ptr to BOF
	DOSCALL @MOVFP2 	; Set file pointer
;;;;;;; jc	short ???	; Jump if error

; Read in the file

	mov	ecx,-1		; Read it all
	mov	edx,ebp 	; DS:EDX ==> buffer
	DOSCALL @READF2 	; Read it in
	jc	near ptr CHECK_DEFFILE_ERRREAD ; Jump if error

	mov	ds:[edx+eax].LO,EOF ; Mark as EOF

	DOSCALL @CLOSF2 	; Close 'er up
;;;;;;; jc	short ???	; Jump if error

	mov	esi,edx 	; DS:ESI ==> start of .DEF file

; Parse the file

CHECK_DEFFILE_NEXT_LINE:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	near ptr CHECK_DEFFILE_DONE ; Jump if so

	cmp	al,';'          ; Izit a comment?
	je	short CHECK_DEFFILE_SKIPLINE ; Jump if so

	push	1		; Mark as error message allowed
	push	dword ptr (offset DGROUP:TAB_DEF_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short CHECK_DEFFILE_NEXT_LINE ; Jump if found

	jmp	CHECK_DEFFILE_ERRTOKN ; Jump if not found


; A comment has been found -- skip over it

CHECK_DEFFILE_SKIPLINE:
	lods	ds:[esi].LO	; Get next char

	cmp	al,EOF		; Izit EOF?
	je	short CHECK_DEFFILE_DONE ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short CHECK_DEFFILE_NEWLINE ; Jump if so

	cmp	al,LF		; Izit EOL?
	jne	short CHECK_DEFFILE_SKIPLINE ; Jump if not

; An EOL has been found -- skip over it

CHECK_DEFFILE_NEWLINE:
	lods	ds:[esi].LO	; Get next char

	cmp	al,EOF		; Izit EOF?
	je	short CHECK_DEFFILE_DONE ; Jump if so

	cmp	al,';'          ; Izit a comment?
	je	short CHECK_DEFFILE_SKIPLINE ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short CHECK_DEFFILE_NEWLINE ; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short CHECK_DEFFILE_NEWLINE ; Jump if so

	dec	esi		; Back off to last good char

	jmp	CHECK_DEFFILE_NEXT_LINE ; Go around again


DEF_OLD:
DEF_IMPORTS:
DEF_FUNCTIONS:
DEF_INCLUDE:
	stc			; Mark as in error

	ret			; Return to caller

CHECK_DEFFILE_DONE:
	mov	eax,DEF_FLAG	; Get .DEF file flags
	and	eax,@DEF_XTYPE	; Isolate the

	cmp	eax,@DEF_XTYPE_WIN shl $DEF_XTYPE  ; Izit EXETYPE WINDOWS?
	sete	EXE_WIN 	; 1 in Windows, 0 = not

; If there's no description string, use the .EXE name

	test	DEF_FLAG,@DEF_DESC ; Izit specified?
	jnz	short @F	; Jump if so

	movzx	esi,PFLDS[@FLD_EXE*(type PFLDS)].VSEG ; Get the segment
	shl	esi,4-0 	; Convert from paras to bytes
	movzx	eax,PFLDS[@FLD_EXE*(type PFLDS)].VOFF ; Get the offset
	add	esi,eax 	; Add offset to get LA

	push	ds		; Pass ptr to string
	push	esi		; ...
	call	StrLen		; Return with EAX = string length
	mov	ecx,eax 	; Copy to count register

	lea	edi,WIN_DESC	; DGROUP:EDI ==> destin
	stos	WIN_DESC[edi]	; Save the length byte
    rep movs	WIN_DESC[edi],AGROUP:[esi].LO ; Copy the name
@@:
	and	LCL_FLAG,not @LCL_DEF ; Mark as no longer processing .DEF file

	clc			; Mark as successful

	jmp	short CHECK_DEFFILE_EXIT ; Join common exit code


CHECK_DEFFILE_ERROPEN:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short CHECK_DEFFILE_ERRCOM ; Join common erorr code


CHECK_DEFFILE_ERRREAD:
	DOSCALL @CLOSF2 	; Close 'er up

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF2) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short CHECK_DEFFILE_ERRCOM ; Join common erorr code


CHECK_DEFFILE_ERRMEM:
	DOSCALL @CLOSF2 	; Close 'er up

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF3) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short CHECK_DEFFILE_ERRCOM ; Join common erorr code


CHECK_DEFFILE_ERRTOKN:
	DOSCALL @CLOSF2 	; Close 'er up

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF_TOKN) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short CHECK_DEFFILE_ERRCOM ; Join common erorr code


CHECK_DEFFILE_ERRSYNT:
	DOSCALL @CLOSF2 	; Close 'er up

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF_SYNT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

;;;;;;; jmp	short CHECK_DEFFILE_ERRCOM ; Join common erorr code


CHECK_DEFFILE_ERRCOM:
	and	LCL_FLAG,not @LCL_DEF ; Mark as no longer processing .DEF file

	stc			; Mark as in error
CHECK_DEFFILE_EXIT:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEFFILE endp		; End CHECK_DEFFILE procedure
	NPPROC	DEF_CHK -- Check On .DEF File Main Switches
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on .DEF file main switches

On entry:

DS:ESI	==>	switch line

On exit:

CF	=	0

|

	clc			; Mark as successful

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_CHK endp		; End DEF_CHK procedure
	NPPROC	DEF_NAME -- Definitions File NAME Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

NAME keyword

NAME [appname] [apptype] [NEWFILES | LONGNAMES]

where apptype is one of

WINDOWAPI	the default
WINDOWCOMPAT
NOTWINDOWCOMPAT

The arguments can appear in any order.

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	test	DEF_FLAG,@DEF_ETYPE ; Izit already specified?
	jnz	short DEF_NAME_ERRDUP_KWD ; Jump if so

	or	DEF_FLAG,@DEF_ETYPE_NAME shl $DEF_ETYPE ; Mark as NAME specified
DEF_NAME_NEXT:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_NAME_DONE ; Jump if so

	cmp	al,'"'          ; Izit a quote mark?
	je	short @F	; Jump if so

	cmp	al,''''         ; Izit a quote mark?
	jne	short DEF_NAME1 ; Jump if not
@@:
DEF_NAME_APPNAME:
	cmp	WIN_NAME.CC_COUNT,0 ; Izit unused?
	jne	short DEF_NAME_ERRDUP_NAME ; Jump if not

	push	@TOK_QU 	; Tell 'em to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	short DEF_NAME_ERROVF ; Jump if error

; Copy the name to local storage

	REGSAVE <ecx,esi,edi>	; Save for a moment

	movzx	ecx,CMD_TOKL	; Get the string length
	inc	ecx		; Include the length byte
	lea	esi,CMD_TOKL	; ?S:ESI ==> source
	lea	edi,WIN_NAME	; ES:EDI ==> destin
    rep movs	WIN_NAME[edi],CMD_TOKL[esi] ; Copy it

	REGREST <edi,esi,ecx>	; Restore

	jmp	DEF_NAME_NEXT	; Go around again


; Check for other keywords

DEF_NAME1:
	call	IzitDefSwitch	; Izit a main .DEF file switch?
	jnc	short DEF_NAME_DONE ; Jump if so

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_DEFNAME_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short DEF_NAME_NEXT ; Jump if found

	jmp	DEF_NAME_APPNAME ; Treat is as an appname


DEF_NAME_ERRDUP_KWD:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFNAME_DUP_KWD) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_NAME_ERRCOM ; Join common error code


DEF_NAME_ERRDUP_NAME:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFNAME_DUP_NAME) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_NAME_ERRCOM ; Join common error code


DEF_NAME_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFNAME_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_NAME_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_NAME_EXIT ; Join common exit code


DEF_NAME_DONE:

; Handle default case

	mov	eax,DEF_FLAG	; Get definitions flags
	and	eax,@DEF_NTYPE	; Isolate the executable types

	cmp	eax,@DEF_NTYPE_NONE shl $DEF_NTYPE ; Izit unspecified?
	jne	short @F	; Jump if not

	or	DEF_FLAG,@DEF_NTYPE_PM shl $DEF_NTYPE ; Mark as WINDOWAPI
@@:
	clc			; Mark as successful
DEF_NAME_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_NAME endp			; End DEF_NAME procedure
	NPPROC	DEFNAME_PM -- NAME WINDOWAPI
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NAME WINDOWAPI

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	test	DEF_FLAG,@DEF_NTYPE ; Izit already specified?
	stc			; Assume so
	jnz	short @F	; Jump if so

	or	DEF_FLAG,@DEF_NTYPE_PM shl $DEF_NTYPE; Mark as PM (note CF=0)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEFNAME_PM endp 		; End DEFNAME_PM procedure
	NPPROC	DEFNAME_VIO -- NAME WINDOWCOMPAT
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NAME WINDOWCOMPAT

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	test	DEF_FLAG,@DEF_NTYPE ; Izit already specified?
	stc			; Assume so
	jnz	short @F	; Jump if so

	or	DEF_FLAG,@DEF_NTYPE_VIO shl $DEF_NTYPE; Mark as VIO (note CF=0)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEFNAME_VIO endp		; End DEFNAME_VIO procedure
	NPPROC	DEFNAME_NOVIO -- NAME NOTWINDOWCOMPAT
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NAME NOTWINDOWCOMPAT

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	test	DEF_FLAG,@DEF_NTYPE ; Izit already specified?
	stc			; Assume so
	jnz	short @F	; Jump if so

	or	DEF_FLAG,@DEF_NTYPE_NOVIO shl $DEF_NTYPE; Mark as NOVIO (note CF=0)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEFNAME_NOVIO endp		; End DEFNAME_NOVIO procedure
	NPPROC	DEFNAME_NEWFILES -- NAME NEWFILES
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NAME NEWFILES
NAME LONGNAMES

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	DEF_FLAG,@DEF_NEWF ; Mark as NEWFILES (note CF=0)

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEFNAME_NEWFILES endp		; End DEFNAME_NEWFILES procedure
	NPPROC	DEF_LIBRARY -- Definitions File LIBRARY Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

LIBRARY keyword

LIBRARY [libname] [PRIVATELIB]

The arguments can appear in any order.

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	test	DEF_FLAG,@DEF_ETYPE ; Izit already specified?
	jnz	short DEF_LIBRARY_ERRDUP_KWD ; Jump if so

	or	DEF_FLAG,@DEF_ETYPE_LIB shl $DEF_ETYPE ; Mark as LIBRARY specified
	or	SEG_DATA,@NE_SEGTAB_SHARE ; Mark as shared (the default for DLLs)
DEF_LIBRARY_NEXT:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_LIBRARY_DONE ; Jump if so

	cmp	al,'"'          ; Izit a quote mark?
	je	short @F	; Jump if so

	cmp	al,''''         ; Izit a quote mark?
	jne	short DEF_LIBRARY1 ; Jump if not
@@:
DEF_LIBRARY_LIBNAME:
	cmp	WIN_NAME.CC_COUNT,0 ; Izit unused?
	jne	short DEF_LIBRARY_ERRDUP_NAME ; Jump if not

	push	@TOK_QU 	; Tell 'em to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	short DEF_LIBRARY_ERROVF ; Jump if error

; Copy the name to local storage

	REGSAVE <ecx,esi,edi>	; Save for a moment

	movzx	ecx,CMD_TOKL	; Get the string length
	inc	ecx		; Include the length byte
	lea	esi,CMD_TOKL	; ?S:ESI ==> source
	lea	edi,WIN_NAME	; ES:EDI ==> destin
    rep movs	WIN_NAME[edi],CMD_TOKL[esi] ; Copy it

	REGREST <edi,esi,ecx>	; Restore

	jmp	DEF_LIBRARY_NEXT ; Go around again


; Check for other keywords

DEF_LIBRARY1:
	call	IzitDefSwitch	; Izit a main .DEF file switch?
	jnc	short DEF_LIBRARY_DONE ; Jump if so

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_DEFLIB_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short DEF_LIBRARY_NEXT ; Jump if found

	jmp	DEF_LIBRARY_LIBNAME ; Treat is as an libname


DEF_LIBRARY_ERRDUP_KWD:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFLIB_DUP_KWD) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_LIBRARY_ERRCOM ; Join common error code


DEF_LIBRARY_ERRDUP_NAME:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFLIB_DUP_NAME) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_LIBRARY_ERRCOM ; Join common error code


DEF_LIBRARY_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFLIB_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_LIBRARY_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_LIBRARY_EXIT ; Join common exit code


DEF_LIBRARY_DONE:
	clc			; Mark as successful
DEF_LIBRARY_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller



DEFLIB_PRIVATELIB:
	or	DEF_FLAG,@DEF_PLIB ; Mark as PRIVATELIB

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_LIBRARY endp		; End DEF_LIBRARY procedure
	NPPROC	DEF_DESCRIPTION -- Definitions File DESCRIPTION Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

DESCRIPTION keyword

DESCRIPTION 'text'

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	bts	DEF_FLAG,$DEF_DESC ; Mark as DESCRIPTION specified
	jc	short DEF_DESCRIPTION_ERRDUP_KWD ; Jump if already specified

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_DESCRIPTION_ERRNOTEXT ; Jump if so

	push	@TOK_QU 	; Tell 'em to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	short DEF_DESCRIPTION_ERROVF ; Jump if error

; Copy the name to local storage

	REGSAVE <ecx,esi,edi>	; Save for a moment

	movzx	ecx,CMD_TOKL	; Get the length byte
	inc	ecx		; Include the length byte
	lea	esi,CMD_TOKL	; ?S:ESI ==> source
	lea	edi,WIN_DESC	; ES:EDI ==> destin
    rep movs	WIN_DESC[edi],CMD_TOKL[esi] ; Copy it

	REGREST <edi,esi,ecx>	; Restore

	clc			; Mark as successful

	jmp	short DEF_DESCRIPTION_EXIT ; Join common exit code


DEF_DESCRIPTION_ERRDUP_KWD:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFDESC_DUP_KWD) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_DESCRIPTION_ERRCOM ; Join common error code


DEF_DESCRIPTION_ERRNOTEXT:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFDESC_NOTEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_DESCRIPTION_ERRCOM ; Join common error code


DEF_DESCRIPTION_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFDESC_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_DESCRIPTION_ERRCOM:
	stc			; Mark as in error
DEF_DESCRIPTION_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_DESCRIPTION endp		; End DEF_DESCRIPTION procedure
	NPPROC	DEF_STUB -- Definitions File STUB Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

STUB keyword

STUB ['stubname' | NONE]

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	bts	DEF_FLAG,$DEF_STUB ; Izit already specified?
	jc	short DEF_STUB_ERRDUP_KWD ; Jump if so

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_STUB_ERRNOTEXT ; Jump if so

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_STUB_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short DEF_STUB_DONE ; Jump if found

	push	@TOK_RQ 	; Tell 'em to require quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	short DEF_STUB_ERROVF ; Jump if error

; Copy the name to local storage

	REGSAVE <ecx,esi,edi>	; Save for a moment

	movzx	ecx,CMD_TOKL	; Get the string length
	inc	ecx		; Including the trailing zero
	lea	esi,CMD_TOKN	; ?S:ESI ==> source
	lea	edi,WIN_STUB	; ES:EDI ==> destin
    rep movs	WIN_STUB[edi],CMD_TOKN[esi] ; Copy it

	REGREST <edi,esi,ecx>	; Restore

	jmp	DEF_STUB_DONE	; Join common done code


DEF_STUB_ERRDUP_KWD:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSTUB_DUP_KWD) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_STUB_ERRCOM ; Join common error code


DEF_STUB_ERRNOTEXT:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSTUB_NOTEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_STUB_ERRCOM ; Join common error code


DEF_STUB_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSTUB_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_STUB_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_STUB_EXIT ; Join common exit code


DEF_STUB_DONE:
	clc			; Mark as successful
DEF_STUB_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller



DEFSTUB_NONE:
	or	DEF_FLAG,@DEF_NSTUB ; Mark as STUB NONE

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_STUB endp			; End DEF_STUB procedure
	NPPROC	DEF_APPLOADER -- Definitions File APPLOADER Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

APPLOADER keyword

APPLOADER 'text'

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	bts	DEF_FLAG,$DEF_APLOD ; Mark as APPLOADER specified
	jc	short DEF_APPLOADER_ERRDUP_KWD ; Jump if already specified

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_APPLOADER_ERRNOTEXT ; Jump if so

	push	@TOK_QU 	; Tell 'em to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	short DEF_APPLOADER_ERROVF ; Jump if error

; Copy the name to local storage

	REGSAVE <ecx,esi,edi>	; Save for a moment

	movzx	ecx,CMD_TOKL	; Get the string length
	inc	ecx		; Including the trailing zero
	lea	esi,CMD_TOKN	; ?S:ESI ==> source
	lea	edi,WIN_APLOD	; ES:EDI ==> destin
    rep movs	WIN_APLOD[edi],CMD_TOKN[esi] ; Copy it

	REGREST <edi,esi,ecx>	; Restore

	clc			; Mark as successful

	jmp	short DEF_APPLOADER_EXIT ; Join common exit code


DEF_APPLOADER_ERRDUP_KWD:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFAPLOD_DUP_KWD) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_APPLOADER_ERRCOM ; Join common error code


DEF_APPLOADER_ERRNOTEXT:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFAPLOD_NOTEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_APPLOADER_ERRCOM ; Join common error code


DEF_APPLOADER_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFAPLOD_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_APPLOADER_ERRCOM:
	stc			; Mark as in error
DEF_APPLOADER_EXIT:
	REGREST <eax>		 ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_APPLOADER endp		; End DEF_APPLOADER procedure
	NPPROC	DEF_EXETYPE -- Definitions File EXETYPE Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

EXETYPE keyword

EXETYPE [WINDOWS [x.x] | DOS | UNKNOWN]

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	test	DEF_FLAG,@DEF_XTYPE ; Izit already specified?
	jnz	short DEF_EXETYPE_ERRDUP_KWD ; Jump if so

	call	U32_SKIP_WHITE	; Skip over white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_EXETYPE_ERRNOTEXT ; Jump if so

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_EXE_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short DEF_EXETYPE_DONE ; Jump if found

	jmp	short DEF_EXETYPE_ERRCOM ; Join common error code


DEF_EXETYPE_ERRDUP_KWD:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFXTYPE_DUP_KWD) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_EXETYPE_ERRCOM ; Join common error code


DEF_EXETYPE_ERRNOTEXT:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFXTYPE_NOTEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_EXETYPE_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_EXETYPE_EXIT ; Join common exit code


DEF_EXETYPE_DONE:
	clc			; Mark as successful
DEF_EXETYPE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller



DEFEXETYPE_WINDOWS:

; Mark as EXETYPE WINDOWS and PROTMODE

	or	DEF_FLAG,@DEF_XTYPE_WIN shl $DEF_XTYPE or @DEF_PMODE
	and	DEF_FLAG,not @DEF_RMODE ; Mark as not REALMODE

	REGSAVE <eax,ebx,ecx>	; Save for a moment

; Check for version #

	call	U32_SKIP_WHITE	; Skip over white space
				; Return with AL = next char
; Check for decimal digits

	cmp	al,'1'          ; Izit below the lower limit?
	jb	short DEFEXETYPE_WINDOWS1 ; Jump if so

	cmp	al,'9'          ; Izit above upper limit?
	ja	short DEFEXETYPE_WINDOWS1 ; Jump if so

	mov	ecx,10		; Convert as decimal
	call	U32_BASE2BIN	; Convert the number at DS:ESI to binary in EAX

	mov	ebx,eax 	; Save for a moment
	xor	eax,eax 	; Assume no more text

	cmp	ds:[esi].LO,'.' ; Izit decimal point?
	jne	short @F	; Jump if not

	inc	esi		; Skip over it

	mov	ecx,10		; Convert as decimal
	call	U32_BASE2BIN	; Convert the number at DS:ESI to binary in EAX

; Convert 3.1 to 3.10 as that's what they really meant

	cmp	ebx,3		; Izit 3.x?
	jne	short @F	; Jump if not

	cmp	eax,1		; Izit 1?
	jne	short @F	; Jump if not

	mov	eax,10		; What they really meant
@@:
	mov	WINVER.HI,bl	; Save as minimum Windows version #
	mov	WINVER.LO,al	; ...
DEFEXETYPE_WINDOWS1:
	REGREST <ecx,ebx,eax>	; Restore

	clc			; Mark as successful

	ret			; Return to caller

DEFEXETYPE_DOS:
	or	DEF_FLAG,@DEF_XTYPE_DOS shl $DEF_XTYPE	; Mark as EXETYPE DOS

	ret			; Return to caller

DEFEXETYPE_UNKNOWN:
	or	DEF_FLAG,@DEF_XTYPE_UNK shl $DEF_XTYPE ; Mark as EXETYPE UNKNOWN

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_EXETYPE endp		; End DEF_EXETYPE procedure
	NPPROC	DEF_PROTMODE -- Definitions File PROTMODE Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

PROTMODE keyword

Not allowed with EXETYPE DOS

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	mov	eax,DEF_FLAG	; Get current settings
	and	eax,mask $DEF_XTYPE ; Isolate the EXETYPE flags

	cmp	eax,@DEF_XTYPE_DOS shl $DEF_XTYPE ; Izit EXETYPE DOS?
	je	short DEF_PROTMODE_ERR ; Jump if so

	or	DEF_FLAG,@DEF_PMODE ; Mark as PROTMODE
	and	DEF_FLAG,not @DEF_RMODE ; Mark as not REALMODE

	clc			; Mark as successful

	jmp	short DEF_PROTMODE_EXIT ; Join comon exit code


DEF_PROTMODE_ERR:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF_NOXDOS) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	stc			; Mark as in error
DEF_PROTMODE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_PROTMODE endp		; End DEF_PROTMODE procedure
	NPPROC	DEF_REALMODE -- Definitions File REALMODE Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

REALMODE keyword

Not allowed with EXETYPE DOS

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	mov	eax,DEF_FLAG	; Get current settings
	and	eax,mask $DEF_XTYPE ; Isolate the EXETYPE flags

	cmp	eax,@DEF_XTYPE_DOS shl $DEF_XTYPE ; Izit EXETYPE DOS?
	je	short DEF_REALMODE_ERR ; Jump if so

	or	DEF_FLAG,@DEF_RMODE ; Mark as REALMODE
	and	DEF_FLAG,not @DEF_PMODE ; Mark as not PROTMODE

	clc			; Mark as successful

	jmp	short DEF_REALMODE_EXIT ; Join comon exit code


DEF_REALMODE_ERR:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEF_NOXDOS) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	stc			; Mark as in error
DEF_REALMODE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_REALMODE endp		; End DEF_REALMODE procedure
	NPPROC	DEF_STACKSIZE -- Definitions File STACKSIZE Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

STACKSIZE keyword

STACKSIZE number

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_STACKSIZE_ERRNOTEXT ; Jump if so

	push	ecx		; Save for a moment

	call	U32_CHECK_BASE	; Check the number base at DS:ESI
				; Return with ECX = number base, DS:ESI updated
	call	U32_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	pop	ecx		; Restore
	jc	short DEF_STACKSIZE_ERROVF ; Jump if too large

	mov	MINSTACK,eax	; Save as stack size

	jmp	short DEF_STACKSIZE_DONE ; Join common done code


DEF_STACKSIZE_ERRNOTEXT:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSTACKSIZE_NOTEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_STACKSIZE_ERRCOM ; Join common error code


DEF_STACKSIZE_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSTACKSIZE_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_STACKSIZE_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_STACKSIZE_EXIT ; Join common exit code


DEF_STACKSIZE_DONE:
	clc			; Mark as successful
DEF_STACKSIZE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_STACKSIZE endp		; End DEF_STACKSIZE procedure
	NPPROC	DEF_HEAPSIZE -- Definitions File HEAPSIZE Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

HEAPSIZE keyword

HEAPSIZE number

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_HEAPSIZE_ERRNOTEXT ; Jump if so

	push	ecx		; Save for a moment

	call	U32_CHECK_BASE	; Check the number base at DS:ESI
				; Return with ECX = number base, DS:ESI updated
	call	U32_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	pop	ecx		; Restore
	jc	short DEF_HEAPSIZE_ERROVF ; Jump if too large

	mov	MINHEAP,eax	; Save as stack size

	jmp	short DEF_HEAPSIZE_DONE ; Join common done code


DEF_HEAPSIZE_ERRNOTEXT:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFHEAPSIZE_NOTEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_HEAPSIZE_ERRCOM ; Join common error code


DEF_HEAPSIZE_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFHEAPSIZE_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DEF_HEAPSIZE_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_HEAPSIZE_EXIT ; Join common exit code


DEF_HEAPSIZE_DONE:
	clc			; Mark as successful
DEF_HEAPSIZE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_HEAPSIZE endp		; End DEF_HEAPSIZE procedure
	NPPROC	DEF_CODE -- Definitions File CODE Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

CODE keyword

CODE [discard] [execute] [load] [movable] [shared]

where

discard  = [DISCARDABLE | NONDISCARDABLE]
execute  = [EXECUTEONLY | EXECUTEREAD]
load	= [PRELOAD | LOADONCALL]
movable  = [MOVABLE | FIXED]
shared	= [SHARED | NONSHARED]

The arguments can appear in any order.

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	test	DEF_FLAG,@DEF_SEGS ; Is the sequence correct?
	jnz	short DEF_CODE_ERRSEQ ; Jump if not

;;;;;;; bts	DEF_FLAG,$DEF_CODE ; Izit already specified?
;;;;;;; jc	short DEF_CODE_ERRDUP_KWD ; Jump if so
;;;;;;;
	or	DEF_FLAG,@DEF_CODE ; Mark as present
DEF_CODE_NEXT:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_CODE_DONE ; Jump if so

	call	IzitDefSwitch	; Izit a main .DEF file switch?
	jnc	short DEF_CODE_DONE ; Jump if so

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_CODE_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short DEF_CODE_NEXT ; Jump if found

	jmp	short DEF_CODE_DONE ; Join common done code


DEF_CODE_ERRSEQ:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFCODE_SEQ) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	stc			; Mark as in error

	jmp	short DEF_CODE_EXIT ; Join common exit code


;;; DEF_CODE_ERRDUP_KWD:
;;;	    push    es		    ; Pass the segment
;;;	    push    dword ptr (offset DGROUP:ERR_DEFCODE_DUP_KWD) ; Pass offset of message
;;;	    call    U32_DISP_MSG    ; Display the message
;;;
;;;	    stc 		    ; Mark as in error
;;;
;;;	    jmp     short DEF_CODE_EXIT ; Join common exit code
;;;
;;;
DEF_CODE_DONE:
	clc			; Mark as successful
DEF_CODE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller


DEFCODE_DISCARDABLE:
	or	SEG_CODE,@NE_SEGTAB_DISC ; Mark as discardable

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_NONDISCARDABLE:
	and	SEG_CODE,not @NE_SEGTAB_DISC ; Mark as nondiscardable

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_EXECUTEONLY:
	or	SEG_CODE,@NE_SEGTAB_ONLY ; Mark as execute-only

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_EXECUTEREAD:
	and	SEG_CODE,not @NE_SEGTAB_ONLY ; Mark as execute-read

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_PRELOAD:
	or	SEG_CODE,@NE_SEGTAB_PRELOAD ; Mark as preload

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_LOADONCALL:
	and	SEG_CODE,not @NE_SEGTAB_PRELOAD ; Mark as load-on-call

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_MOVABLE:
	or	SEG_CODE,@NE_SEGTAB_MOVABLE ; Mark as movable

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_FIXED:
	and	SEG_CODE,not @NE_SEGTAB_MOVABLE ; Mark as fixed

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_SHARED:
	or	SEG_CODE,@NE_SEGTAB_SHARE ; Mark as shared

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFCODE_NONSHARED:
	and	SEG_CODE,not @NE_SEGTAB_SHARE ; Mark as nonshared

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_CODE endp			; End DEF_CODE procedure
	NPPROC	DEF_DATA -- Definitions File DATA Keyword
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

DATA keyword

DATA [instance] [load] [movable] [readonly] [shared]

where

instance = [NONE | SINGLE | MULTIPLE]
load	= [PRELOAD | LOADONCALL]
movable  = [MOVABLE | FIXED]
readonly = [READONLY | READWRITE]
shared	= [SHARED | NONSHARED]

The arguments can appear in any order.

On entry:

DS:ESI	==>	rest of line

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax>		; Save register

	test	DEF_FLAG,@DEF_SEGS ; Is the sequence correct?
	jnz	short DEF_DATA_ERRSEQ ; Jump if not

;;;;;;; bts	DEF_FLAG,$DEF_DATA ; Izit already specified?
;;;;;;; jc	short DEF_DATA_ERRDUP_KWD ; Jump if so
;;;;;;;
	or	DEF_FLAG,@DEF_DATA ; Mark as present
DEF_DATA_NEXT:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	short DEF_DATA_DONE ; Jump if so

	call	IzitDefSwitch	; Izit a main .DEF file switch?
	jnc	short DEF_DATA_DONE ; Jump if so

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_DATA_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
	jnc	short DEF_DATA_NEXT ; Jump if found

	jmp	short DEF_DATA_DONE ; Join common done code


DEF_DATA_ERRSEQ:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFDATA_SEQ) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	stc			; Mark as in error

	jmp	short DEF_DATA_EXIT ; Join common exit code


;;; DEF_DATA_ERRDUP_KWD:
;;;	    push    es		    ; Pass the segment
;;;	    push    dword ptr (offset DGROUP:ERR_DEFDATA_DUP_KWD) ; Pass offset of message
;;;	    call    U32_DISP_MSG    ; Display the message
;;;
;;;	    stc 		    ; Mark as in error
;;;
;;;	    jmp     short DEF_DATA_EXIT ; Join common exit code
;;;
;;;
DEF_DATA_DONE:
	clc			; Mark as successful
DEF_DATA_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller


DEFDATA_NONE:
	and	DEF_FLAG,not (mask $DEF_INST) ; Clear the INSTANCE values
	or	DEF_FLAG,@DEF_INST_NDGR shl $DEF_INST ; Mark as no DGROUP

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_PRELOAD:
	or	SEG_DATA,@NE_SEGTAB_PRELOAD ; Mark as preload

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_LOADONCALL:
	and	SEG_DATA,not @NE_SEGTAB_PRELOAD ; Mark as load-on-call

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_MOVABLE:
	or	SEG_DATA,@NE_SEGTAB_MOVABLE ; Mark as movable

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_FIXED:
	and	SEG_DATA,not @NE_SEGTAB_MOVABLE ; Mark as fixed

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_READONLY:
	or	SEG_DATA,@NE_SEGTAB_ONLY ; Mark as read-only

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_READWRITE:
	and	SEG_DATA,not @NE_SEGTAB_ONLY ; Mark as read-write

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_SHARED:
	or	SEG_DATA,@NE_SEGTAB_SHARE ; Mark as shared
	and	DEF_FLAG,not (mask $DEF_INST) ; Clear the INSTANCE values
	or	DEF_FLAG,@DEF_INST_SING shl $DEF_INST ; Mark as one DGROUP

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller


DEFDATA_NONSHARED:
	and	SEG_DATA,not @NE_SEGTAB_SHARE ; Mark as nonshared
	and	DEF_FLAG,not (mask $DEF_INST) ; Clear the INSTANCE values
	or	DEF_FLAG,@DEF_INST_MULT shl $DEF_INST ; Mark as many DGROUP

;;;;;;; clc			; Mark as successful (clr by previous instr)

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_DATA endp			; End DEF_DATA procedure
	NPPROC	DEF_SEGMENTS -- Definitions File SEGMENTS Keyword
	assume	ds:AGROUP,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT!

SEGMENTS keyword

This keyword marks the beginning of a section of segment definitions.
Multiple definitions must be separated by one or more spaces, tabs, or
newline characters.  The SEGMENTS keyword must appear once before the
first definition (on the same or preceding line) and can be repeated
before each additional definition.  SEGMENTS statements can appear more
than once in the file.

SEGMENTS
[']segmentname['] [CLASS 'classname'] [attributes]

where

attributes are in TAB_SEGS_SW.

On entry:

DS:ESI	==>	rest of file

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax,ecx,edx,edi> ; Save registers

	or	DEF_FLAG,@DEF_SEGS ; Mark as present

	push	SEG_CODE	; Save default values
	push	SEG_DATA	; ...
DEF_SEGMENTS_NEXT0:
	pop	SEG_DATA	; Initialize to default values
	pop	SEG_CODE	; ...

	push	SEG_CODE	; Save default values
	push	SEG_DATA	; ...
DEF_SEGMENTS_NEXT:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	near ptr DEF_SEGMENTS_DONE ; Jump if so

	call	IzitDefSwitch	; Izit a main .DEF file switch?
	jnc	near ptr DEF_SEGMENTS_DONE ; Jump if so

	push	@TOK_QU 	; Tell 'em to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	near ptr DEF_SEGMENTS_ERROVF ; Jump if error

	REGSAVE <esi,es>	; Save for a moment

	mov	ax,ds		; Get AGROUP selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

; Zero the DEFSEG_STR struc

.errnz (4-1) and (type DEFSEG_STR)
	mov	ecx,(type DEFSEG_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	mov	edi,LMB_DEFSEG.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	edx,edi 	; Save starting offset of DEFSEG_STR
	mov	LAST_DEFSEG,edx ; Save for later use

	UNOVRB	edi,DEFSEG	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	mov	LMB_DEFSEG.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; CMD_TOKN has the <segmentname>

	movzx	ecx,CMD_TOKL	; Get the token length
	add	ecx,type CC_COUNT ; Count in the length byte
	lea	edi,AGROUP:[edx].DEFSEG_SEGNAME ; ES:EDI ==> segment name
	lea	esi,CMD_TOKL	; FS:ESI ==> token length followed by the token
	UNCURB	edi,DEFSEG	; Ensure within current bounds
    rep movs	AGROUP:[edi].LO,CMD_TOKL[esi] ; Copy to DEFSEG_STR

	REGREST <es,esi>	; Restore
	assume	es:DGROUP	; Tell the assembler about it

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
; Check for other switches

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_SEGS_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
;;;;;;; jnc	short ???	; Jump if found

; If no CLASS was specified, use class CODE

;;;;;;; UNCURB	edx,DEFSEG	; Ensure within current bounds
	cmp	AGROUP:[edx].DEFSEG_CLSNAME.CC_COUNT,0 ; Izit empty?
	jne	short @F	; Jump if not

	push	es		; Save for a moment

	mov	ax,ds		; Get AGROUP selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	lea	edi,AGROUP:[edx].DEFSEG_CLSNAME ; AGROUP:EDI ==> destin
	lea	esi,TXT_CODE	; DGROUP:ESI ==> source
	movzx	ecx,TXT_CODE.CC_COUNT ; Get the length byte
	add	ecx,type CC_COUNT ; Count in the length byte
    rep movs	AGROUP:[edi].LO,TXT_CODE[esi].LO ; Copy to DEFSEG_STR

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it
@@:

; If this segment's class ends with 'CODE', it's a code segment;
; otherwise, it's a data segment

;;;;;;; UNCURB	edx,DEFSEG	; Ensure within current bounds
	push	edx		; Pass LA of text (Count, Char[])
	call	IzitSUFCODE	; Duzit end with 'CODE'?
	jc	short @F	; Jump if not

; Save the flags for this code segment

	mov	eax,SEG_CODE	; Get flags
	UNCURB	edx,DEFSEG	; Ensure within current bounds
	mov	AGROUP:[edx].DEFSEG_FLAG,eax ; Save in struc

	jmp	short DEFSEGS_LOOP ; Join common loop code


@@:

; Save the flags for this data segment

	mov	eax,SEG_DATA	; Get flags
	UNCURB	edx,DEFSEG	; Ensure within current bounds
	mov	AGROUP:[edx].DEFSEG_FLAG,eax ; Save in struc
DEFSEGS_LOOP:
	jmp	DEF_SEGMENTS_NEXT0 ; Go around again


DEFSEGS_CLASS:
	push	@TOK_RQ 	; Tell 'em to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	short DEFSEGS_CLASS_ERROVF ; Jump if error

; CMD_TOKN has the <classname>

	REGSAVE <ecx,edx,esi,edi,es> ; Save for a moment

	mov	ax,ds		; Get AGROUP selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	mov	edx,LAST_DEFSEG ; Get LA of last DEFSEG_STR

	movzx	ecx,CMD_TOKL	; Get the token length
	add	ecx,type CC_COUNT ; Count in the length byte
	lea	edi,AGROUP:[edx].DEFSEG_CLSNAME ; ES:EDI ==> class name
	lea	esi,CMD_TOKL	; FS:ESI ==> token length followed by the token
	UNCURB	edi,DEFSEG	; Ensure within current bounds
    rep movs	AGROUP:[edi].LO,CMD_TOKL[esi] ; Copy to DEFSEG_STR

	REGREST <es,edi,esi,edx,ecx> ; Restore
	assume	es:DGROUP	; Tell the assembler about it

	clc			; Mark as successful

	ret			; Return to caller


DEFSEGS_CLASS_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSEGS_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	stc			; Mark as in error

	ret			; Return to caller


DEFSEGS_FIXED:
	call	DEFCODE_FIXED	; Call as if it's a CODE segment
	call	DEFDATA_FIXED	; ...		    DATA ...
				; Return with CF significant
	ret			; Return to caller


DEFSEGS_LOADONCALL:
	call	DEFCODE_LOADONCALL ; Call as if it's a CODE segment
	call	DEFDATA_LOADONCALL ; ...	       DATA ...
				; Return with CF significant
	ret			; Return to caller


DEFSEGS_MOVABLE:
	call	DEFCODE_MOVABLE ; Call as if it's a CODE segment
	call	DEFDATA_MOVABLE ; ...		    DATA ...
				; Return with CF significant
	ret			; Return to caller


DEFSEGS_NONSHARED:
	call	DEFCODE_NONSHARED ; Call as if it's a CODE segment
	call	DEFDATA_NONSHARED ; ... 	      DATA ...
				; Return with CF significant
	ret			; Return to caller


DEFSEGS_PRELOAD:
	call	DEFCODE_PRELOAD ; Call as if it's a CODE segment
	call	DEFDATA_PRELOAD ; ...		    DATA ...
				; Return with CF significant
	ret			; Return to caller


DEFSEGS_SHARED:
	call	DEFCODE_SHARED	; Call as if it's a CODE segment
	call	DEFDATA_SHARED	; ...		    DATA ...
				; Return with CF significant
	ret			; Return to caller


DEF_SEGMENTS_ERROVF:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFSEGS_OVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

;;;;;;; jmp	short DEF_SEGMENTS_ERRCOM ; Join common error code


DEF_SEGMENTS_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_SEGMENTS_EXIT ; Join common exit code


DEF_SEGMENTS_DONE:
	clc			; Mark as successful
DEF_SEGMENTS_EXIT:
	pop	SEG_DATA	; Restore
	pop	SEG_CODE	; ...

	REGREST <edi,edx,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_SEGMENTS endp		; End DEF_SEGMENTS procedure
	NPPROC	DEF_EXPORTS -- Definitions File EXPORTS Keyword
	assume	ds:AGROUP,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT!

EXPORTS keyword

This keyword marks the beginning of a section of export definitions.
Multiple definitions must be separated by one or more spaces, tabs, or
newline characters.  The EXPORTS keyword must appear once before the
first definition (on the same or preceding line) and can be repeated
before each additional definition.  EXPORTS statements can appear more
than once in the file.

EXPORTS
entryname[=internalname] [@ord[nametable]] [NODATA] [PRIVATE]

where

nametable = [RESIDENTNAME | NONAME]

On entry:

DS:ESI	==>	rest of file

On exit:

DS:ESI	==>	(updated)
CF	=	0 if all went well
	=	1 otherwise

!

	REGSAVE <eax,ecx,edx,edi> ; Save registers
DEF_EXPORTS_NEXT:
	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,EOF		; Izit EOF?
	je	near ptr DEF_EXPORTS_DONE ; Jump if so

	call	IzitDefSwitch	; Izit a main .DEF file switch?
	jnc	near ptr DEF_EXPORTS_DONE ; Jump if so

	push	0		; Tell 'em not to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	near ptr DEF_EXPORTS_ERROVF1 ; Jump if error

	REGSAVE <esi,es>	; Save for a moment

	mov	ax,ds		; Get AGROUP selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

; Zero the EXPDEF_STR struc

.errnz (4-1) and (type EXPDEF_STR)
	mov	ecx,(type EXPDEF_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	mov	edi,LMB_EXPDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	edx,edi 	; Save starting offset of EXPDEF_STR
	mov	LAST_EXPDEF,edx ; Save for later use

	UNOVRB	edi,EXPDEF	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	mov	LMB_EXPDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; Fill in the entries

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	mov	AGROUP:[edx].EXPDEF_PPEROBJ,-1 ; Save for later use

; CMD_TOKN has the <entryname>

	movzx	ecx,CMD_TOKL	; Get the token length
	add	ecx,type CC_COUNT ; Count in the length byte
	lea	edi,AGROUP:[edx].EXPDEF_EXPNAME ; ES:EDI ==> exported name
	lea	esi,CMD_TOKL	; FS:ESI ==> token length followed by the token
	UNCURB	edi,EXPDEF	; Ensure within current bounds
    rep movs	AGROUP:[edi].LO,CMD_TOKL[esi] ; Copy to EXPDEF_STR

	REGREST <es,esi>	; Restore
	assume	es:DGROUP	; Tell the assembler about it

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,'='          ; Izit followed by <internalname>?
	jne	short @F	; Jump if not

	inc	esi		; Skip over the separator

	push	0		; Tell 'em not to process quotes
	call	U32_GET_TOKN	; Get the next token into CMD_TOKN
	jc	near ptr DEF_EXPORTS_ERROVF1 ; Jump if error
@@:

; CMD_TOKN has the <internalname>

	REGSAVE <esi,es>	; Save for a moment

	mov	ax,ds		; Get AGROUP selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	movzx	ecx,CMD_TOKL	; Get the token length
	add	ecx,type CC_COUNT ; Count in the length byte
	lea	edi,AGROUP:[edx].EXPDEF_INTNAME ; ES:EDI ==> internal name
	lea	esi,CMD_TOKL	; FS:ESI ==> token length followed by the token
	UNCURB	edi,EXPDEF	; Ensure within current bounds
    rep movs	AGROUP:[edi].LO,CMD_TOKL[esi] ; Copy to EXPDEF_STR

	REGREST <es,esi>	; Restore
	assume	es:DGROUP	; Tell the assembler about it

	call	U32_SKIP_EOL	; Skip over EOLs & white space
				; Return with AL = next char
	cmp	al,'@'          ; Izit followed by <@ordinal>?
	jne	short DEF_EXPORTS_XORD ; Jump if not

	inc	esi		; Skip over the separator

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	or	AGROUP:[edx].EXPDEF_FLAG,@EXPFL_ORD ; Mark as ordinal present

	call	U32_CHECK_BASE	; Check the number base at DS:ESI
				; Return with ECX = number base, DS:ESI updated
	call	U32_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	jc	near ptr DEF_EXPORTS_ERROVF2 ; Jump if too large

	cmp	eax,0FFFFh	; Izit too large?
	ja	near ptr DEF_EXPORTS_ERROVF2 ; Jump if so

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	mov	AGROUP:[edx].EXPDEF_ORDINAL,ax ; Save the ordinal

; Check for ordinal switches

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_EXPORD_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
;;;;;;; jnc	short ???	; Jump if found
DEF_EXPORTS_XORD:

; Check for other switches

	push	0		; Mark as error message not allowed
	push	dword ptr (offset DGROUP:TAB_EXP_SW) ; Pass offset of table
	call	U32_CHECK_SWITCHES ; See if it matches our list of switches
;;;;;;; jnc	short ???	; Jump if found

	jmp	DEF_EXPORTS_NEXT ; Go around again


DEFEXPORD_NONAME:
	push	edx		; Save for a moment

	mov	edx,LAST_EXPDEF ; Get LA of last EXPDEF_STR

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	or	AGROUP:[edx].EXPDEF_FLAG,@EXPFL_NON ; Mark as present

	pop	edx		; Restore

	clc			; Mark as successful

	ret			; Return to caller


DEFEXPORD_RESNAME:
	push	edx		; Save for a moment

	mov	edx,LAST_EXPDEF ; Get LA of last EXPDEF_STR

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	or	AGROUP:[edx].EXPDEF_FLAG,@EXPFL_RES ; Mark as present

	pop	edx		; Restore

	clc			; Mark as successful

	ret			; Return to caller


DEFEXP_NODATA:
	push	edx		; Save for a moment

	mov	edx,LAST_EXPDEF ; Get LA of last EXPDEF_STR

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	or	AGROUP:[edx].EXPDEF_FLAG,@EXPFL_NOD ; Mark as present

	pop	edx		; Restore

	clc			; Mark as successful

	ret			; Return to caller


DEFEXP_PRIVATE:
	push	edx		; Save for a moment

	mov	edx,LAST_EXPDEF ; Get LA of last EXPDEF_STR

	UNCURB	edx,EXPDEF	; Ensure within current bounds
	or	AGROUP:[edx].EXPDEF_FLAG,@EXPFL_PRV ; Mark as present

	pop	edx		; Restore

	clc			; Mark as successful

	ret			; Return to caller


DEF_EXPORTS_ERROVF1:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFEXP_OVF1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DEF_EXPORTS_ERRCOM ; Join common error code


DEF_EXPORTS_ERROVF2:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:ERR_DEFEXP_OVF2) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

;;;;;;; jmp	short DEF_EXPORTS_ERRCOM ; Join common error code


DEF_EXPORTS_ERRCOM:
	stc			; Mark as in error

	jmp	short DEF_EXPORTS_EXIT ; Join common exit code


DEF_EXPORTS_DONE:
	clc			; Mark as successful
DEF_EXPORTS_EXIT:
	REGREST <edi,edx,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEF_EXPORTS endp		; End DEF_EXPORTS procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_ARG module
