;' $Header:   P:/PVCS/MISC/QLINK/QLNK_OMF.ASV   1.3   07 Aug 1998 16:00:12   BOB  $
	title	QLNK_OMF -- QLINK OMF Functions
	page	58,122
	name	QLNK_OMF

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, August, 1994.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include DPMI.INC
	include ASCII.INC
	include EXE.INC
	include BITFLAGS.INC
	include OMF.INC
	include DOSCALL.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
	include QLNK_TYP.INC
.list

DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	IWF_FLAG:dword
	extrn	IW2_FLAG:dword
	extrn	IW3_FLAG:dword
	include QLNK_IWF.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	LaDATA:dword
	extrn	ERRCNT:dword

	extrn	LMB_TXTSTR:tbyte
	extrn	LMB_PEROBJ:tbyte
	extrn	LMB_PERSEG:tbyte
	extrn	LMB_PERGRP:tbyte
	extrn	LMB_LINNUM:tbyte
	extrn	LMB_LNAMES:tbyte
	extrn	LMB_SYMBOL:tbyte
	extrn	LMB_SEGDEF:tbyte
	extrn	LMB_GRPDEF:tbyte
	extrn	LMB_EXTDEF:tbyte
	extrn	LMB_PUBDEF:tbyte
	extrn	LMB_COMDEF:tbyte
	extrn	LMB_COMDAT:tbyte
	extrn	LMB_FIXUPP:tbyte
	extrn	LMB_SEGOBJ:tbyte
	extrn	LMB_BAKPAT:tbyte

	extrn	DEF32:byte
	extrn	OMFTYP:byte
	extrn	EXE_HDR:tbyte
	extrn	IWFCNT:dword

	extrn	THISOBJ_STR:dword
	extrn	THISOBJ_CSUM:dword
	extrn	MSG_RQEND:byte
	extrn	TXT_NONE:byte

	extrn	MSG_CRLF:byte
	extrn	SYMCASE_END:dword
	
	extrn	SS_SYMBOLS:byte

	public	LAST_COMDAT
LAST_COMDAT dd	-1		; Ptr to last valid COMDAT entry (-1=none)

	public	NS_HEAD
NS_HEAD dd	-1		; Ptr to head of NameSub linked list (-1 = end)

	public	LAST_DATREC,LAST_DATSEG,LAST_DATOFF,LAST_DATTYP
LAST_DATREC dd	?		; Linear address of last data record
				; record (0=none)
LAST_DATSEG dd	?		; Linear address of PERSEG_STR of last data record
LAST_DATOFF dd	?		; Offset of last data record
LAST_DATTYP db	?		; Last data record OMF type

	public	CDFLAG,CDFLAG,CDATTR,CDALIN,CDOFF,CDPBGRP,CDPBSEG,CDPNI
	public	CDLEN,CDCSUM
CDFLAG	db	?		; COMDAT flag value
CDATTR	db	?		; ...	 attributes
CDALIN	db	?		; ...	 alignment type
CDOFF	dd	?		; ...	 data offset
CDPBGRP dd	?		; ...	 public base group   (-1=none)
CDPBSEG dd	?		; ...	 public base segment (-1=none)
CDPNI	dd	?		; ...	 public name index
CDLEN	dd	?		; ...	 data length
CDCSUM	dd	?		; ...	 checksum

	align	4

	public	BASE_GRP,BASE_SEG,BASE_OLDLEN
BASE_GRP dd	?		; LA of base group struc (PERGRP_STR, 0=none)
BASE_SEG dd	?		; ...	     segment ... (PERSEG_STR, 0=none)
BASE_OLDLEN dd	?		; Length of old segment

	public	SEGDEF_FRM,SEGDEF_LEN,SEGDEF_CLS
SEGDEF_FRM dd	?		; Save area for frame in bytes (abs segs only)
SEGDEF_LEN dd	?		; ...		length
SEGDEF_CLS dd	?		; ...		class name symbol (SYM_STR)
				; (0=none, -1=absolute)
	public	STACK_PPERSEG
STACK_PPERSEG dd 0		; LA of stack combine type PERSEG_STR

	public	ALINTYP
ALINTYP dd	offset DGROUP:TXT_ABS	     ; 0:  Absolute
	dd	offset DGROUP:TXT_BYTE	     ; 1:  Byte-aligned
	dd	offset DGROUP:TXT_WORD	     ; 2:  Word-aligned
	dd	offset DGROUP:TXT_PARA	     ; 3:  Para-aligned
	dd	offset DGROUP:TXT_256B	     ; 4:  256-byte-aligned
	dd	offset DGROUP:TXT_DWORD      ; 5:  Dword-aligned
	dd	offset DGROUP:TXT_4KB	     ; 6:  4KB-aligned
;;;;;;; dd	offset DGROUP:TXT_INVALID    ; 7:  (Invalid, already ruled out)

	public	ALINWID
ALINWID dd	0			     ; 0:  Absolute (can't be the wider)
	dd	1			     ; 1:  Byte-aligned
	dd	2			     ; 2:  Word-aligned
	dd	16			     ; 3:  Para-aligned
	dd	256			     ; 4:  256-byte-aligned
	dd	4			     ; 5:  Dword-aligned
	dd	@CON4KB 		     ; 6:  4KB-aligned
;;;;;;; dd	?			     ; 7:  (Invalid, already ruled out)

	public	NONULLS_OFF
NONULLS_OFF dd	0		; NULL para offset for _TEXT segment with
				; /DOSSEG but not /NONULLSDOSSEG specified
	public	LOCAT,FIXDAT
LOCAT	dw	?		; Temporary save area for LOCAT word
FIXDAT	db	?		; ...			  FIXDAT byte

	public	T_THREAD,F_THREAD
T_THREAD THRED_STR 4 dup (<>)	; Target thread #1-4
F_THREAD THRED_STR 4 dup (<>)	; Frame  ...	#1-4

	public	WORKAREA_SYM,WORKAREA
WORKAREA_SYM	SYM_STR <>	; Leading symbol data
WORKAREA db	@SYMBOL_MAXLEN dup (?) ; Work area with room for
				; SEG (255+1), CLASS (255+1), Combine (1)

	CCMAC	'$$MODEND', MODEND_NAME, ; Form (Count, Char[])
	CCMAC	'$$MODEND', MODEND_CLASS ; ...

	public	SEGDEF_C_XLAT
;		 0   1	 2   3	 4   5	 6   7
SEGDEF_C_XLAT db 0, -1,  2, -1,  2,  5,  6,  2

	public	ACBP
ACBP	db	?		; ACBP byte

	public	LOCAT_LOC
;		0   1	2   3	4   5	6   7	8   9  10  11  12  13  14  15
LOCAT_LOC db	0,  1,	2,  3, -1,  1, -1, -1, -1,  9, -1, 11, -1,  9, -1, -1

	public	FIXDAT_FRM
;		0   1	2   3	4   5	6   7
FIXDAT_FRM db	0,  1,	2, -1,	4,  5, -1, -1 ; Validate FRM fields

	public	FIXMETH_TAB
	align	4
FIXMETH_TAB dd	offset PGROUP:OMF_FIXUPP_M0 ; SEGDEF method
	dd	offset PGROUP:OMF_FIXUPP_M1 ; GRPDEF ...
	dd	offset PGROUP:OMF_FIXUPP_M2 ; EXTDEF ...
	dd	?			    ; (Invalid, already ruled out)
	dd	offset PGROUP:OMF_FIXUPP_M4 ; Frame from LAST_DATSEG
	dd	offset PGROUP:OMF_FIXUPP_M5 ; Frame from target's index
;;;;;;; dd	?			    ; (Invalid, already ruled out)
;;;;;;; dd	?			    ; (Invalid, already ruled out)

	CCMAC	'DGROUP',  TXT_DGROUP   ; Form (Count, Char[])
	CCMAC	'FLAT',    TXT_FLAT     ; ...
	CCMAC	'CODE',    TXT_CODE     ; ...
	CCMAC	'BEGDATA', TXT_BEGDATA  ; ...
	CCMAC	'BSS',     TXT_BSS      ; ...
	CCMAC	'STACK',   TXT_STACK    ; ...
	CCMAC	'_TEXT',   TXT__TEXT    ; ...

	CCMAC	'absolute',       TXT_ABS
	CCMAC	'byte',           TXT_BYTE
	CCMAC	'word',           TXT_WORD
	CCMAC	'para',           TXT_PARA
	CCMAC	'256 byte',       TXT_256B
	CCMAC	'dword',          TXT_DWORD
	CCMAC	'4KB',            TXT_4KB
;;;;;;; CCMAC	'** invalid **',  TXT_INVALID

	CCMAC	'COMDAT_CODE16_SEG1', TXT_COMDAT_CODE16
	CCMAC	'COMDAT_CODE32_SEG1', TXT_COMDAT_CODE32
	CCMAC	'COMDAT_DATA16_SEG1', TXT_COMDAT_DATA16
	CCMAC	'COMDAT_DATA32_SEG1', TXT_COMDAT_DATA32

	align	4

	public	COMDAT_SEGNAM
COMDAT_SEGNAM label dword
	dd	offset DGROUP:TXT_COMDAT_CODE16
	dd	offset DGROUP:TXT_COMDAT_CODE32
	dd	offset DGROUP:TXT_COMDAT_DATA16
	dd	offset DGROUP:TXT_COMDAT_DATA32

	public	COMDAT_SEGACBP
COMDAT_SEGACBP label byte
	db	0*@ACBP_P or @ACBP_C_PRIVATE
	db	1*@ACBP_P or @ACBP_C_PRIVATE
	db	0*@ACBP_P or @ACBP_C_PRIVATE
	db	1*@ACBP_P or @ACBP_C_PRIVATE

	public	COMDAT_SEGTAB
COMDAT_SEGTAB dd 4 dup (0)	; LA of PERSEG_STR for COMDAT segments

	public	COMDAT_SELTAB
COMDAT_SELTAB label dword
	dd	offset PGROUP:OMF_COMDAT_SEL_NONE
	dd	offset PGROUP:OMF_COMDAT_SEL_ANY
	dd	offset PGROUP:OMF_COMDAT_SEL_SIZE
	dd	offset PGROUP:OMF_COMDAT_SEL_CSUM

;-------------------------------------------------------------------------------

; The following error messages terminate QLINK without user control

MSG_OBJLMB  db	'様> FAIL:  Unable to allocate Linear Memory Block for record',CR,LF
	    db	@I,'at offset '
MSG_OBJLMB1 db	'________ in file ',EOS

MSG_OBJAPPND db '様> FAIL:  Insufficient symbol table size from record',CR,LF
	    db	@I,'at offset '
MSG_OBJAPPND1 db '________ in file ',EOS

MSG_PUBDUP  db	'様> FAIL:  Symbol ',@LQ,EOS
MSG_PUBDUP1 db	@RQ,' is also public',CR,LF,@I,'in file ',EOS
MSG_PUBDUP2 db	CR,LF,@I,'reference PUBDEF record at offset '
MSG_PUBDUP3 db	'________',CR,LF,@I,'in file ',EOS

MSG_COMDUP  db	'様> FAIL:  Symbol ',@LQ,EOS
MSG_COMDUP1 db	@RQ,' is also public',CR,LF,@I,'in file ',EOS
MSG_COMDUP2 db	CR,LF,@I,'reference COMDEF record at offset '
MSG_COMDUP3 db	'________',CR,LF,@I,'in file ',EOS

MSG_COMDIF  db	'様> FAIL:  Symbol ',@LQ,EOS
MSG_COMDIF1 db	@RQ,' has different distance (near vs. far) in file ',EOS

MSG_SEGINV  db	'様> FAIL:  Invalid segment index in LEDATA/LIDATA record',CR,LF
	    db	@I,'at offset '
MSG_SEGINV1 db	'________ in file ',EOS

MSG_GRPNDX  db	'様> FAIL:  Invalid group name index in GPRDEF record',CR,LF
	    db	@I,'at offset '
MSG_GRPNDX1 db	'________ in file ',EOS

MSG_SEGNDX  db	'様> FAIL:  Invalid segment name index in GPRDEF record',CR,LF
	    db	@I,'at offset '
MSG_SEGNDX1 db	'________ in file ',EOS

MSG_LSTINV  db	'様> FAIL:  No LEDATA/LIDATA/COMDAT record precedes the first FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_LSTINV1 db	'________ in file ',EOS

MSG_LOCINV  db	'様> FAIL:  Invalid LOCAT.LOC field in FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_LOCINV1 db	'________ in file ',EOS

MSG_THRDINV db	'様> FAIL:  Thread reference precedes set in FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_THRDINV1 db '________ in file ',EOS

MSG_FNDXINV db	'様> FAIL:  Invalid Frame Datum index in FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_FNDXINV1 db '________ in file ',EOS

MSG_TNDXINV db	'様> FAIL:  Invalid Target Datum index in FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_TNDXINV1 db '________ in file ',EOS

MSG_FRMINV  db	'様> FAIL:  Invalid FIXDAT.FRM field in FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_FRMINV1 db	'________ in file ',EOS

MSG_TGTINV  db	'様> FAIL:  Invalid FIXDAT.TGT field in FIXUPP record',CR,LF
	    db	@I,'at offset '
MSG_TGTINV1 db	'________ in file ',EOS

MSG_TYPINV  db	'様> FAIL:  Invalid data type in COMDEF record',CR,LF
	    db	@I,'at offset '
MSG_TYPINV1 db	'________ in file ',EOS

MSG_VLENINV db	'様> FAIL:  Invalid data type length in COMDEF record',CR,LF
	    db	@I,'at offset '
MSG_VLENINV1 db '________ in file ',EOS

MSG_CD_FLAG db	'様> FAIL:  Invalid flag byte in COMDAT record',CR,LF
	    db	@I,'at offset '
MSG_CD_FLAG1 db '________ in file ',EOS

MSG_CD_SEL  db	'様> FAIL:  Invalid selection criteria in attribute byte in COMDAT record',CR,LF
	    db	@I,'at offset '
MSG_CD_SEL1 db	'________ in file ',EOS

MSG_CD_TYP  db	'様> FAIL:  Invalid allocation type in attribute byte in COMDAT record',CR,LF
	    db	@I,'at offset '
MSG_CD_TYP1 db	'________ in file ',EOS

MSG_CD_ALIN db	'様> FAIL:  Invalid alignment byte in COMDAT record',CR,LF
	    db	@I,'at offset '
MSG_CD_ALIN1 db '________ in file ',EOS

MSG_CD_CONT1 db '様> FAIL:  A COMDAT continuation record is not preceded by COMDAT record',CR,LF
	     db @I,'at offset '
MSG_CD_CONT11 db '________ in file ',EOS

MSG_CD_CONT2 db "様> FAIL:  A COMDAT continuation record does not match the previous record's",CR,LF
	     db @I,"Flags, Attributes, Alignment, Public Base, and/or Public Name Index",CR,LF
	     db @I,'at offset '
MSG_CD_CONT21 db '________ in file ',EOS

	public	MSG_CD_CSUM
MSG_CD_CSUM db	'様> FAIL:  A COMDAT record requiring all instances to have an exact match failed',CR,LF
	    db	@I,'at offset '
MSG_CD_CSUM1 db '________ in file ',EOS

	public	MSG_CD_LEN
MSG_CD_LEN  db	'様> FAIL:  A COMDAT record requiring all instances to have the same length failed',CR,LF
	    db	@I,'at offset '
MSG_CD_LEN1 db	'________ in file ',EOS

	public	MSG_CD_UNIQ
MSG_CD_UNIQ db	'様> FAIL:  A COMDAT record requiring only one instance failed',CR,LF
	    db	@I,'at offset '
MSG_CD_UNIQ1 db '________ in file ',EOS

	public	MSG_CD_EXPL
MSG_CD_EXPL db	'様> FAIL:  A COMDAT record with Explicit Allocation did not specify a Segment',CR,LF
	    db	@I,'at offset '
MSG_CD_EXPL1 db '________ in file ',EOS

;-------------------------------------------------------------------------------

; The following error messages can be ignored/warned/failed on user control

	public	MSG_OMFUNK
MSG_OMFUNK  db	'(OMFUNK) Unknown OMF type',CR,LF
	    db	@I,'at offset '
MSG_OMFUNK1 db	'________ in file ',EOS

	public	MSG_OMFIGN
MSG_OMFIGN  db	'(OMFIGN) Unsupported OMF record',CR,LF
	    db	@I,'at offset '
MSG_OMFIGN1 db	'________ in file ',EOS

	public	MSG_BLKDEF
MSG_BLKDEF  db	'(BLKDEF) Block definition record',CR,LF
	    db	@I,'at offset '
MSG_BLKDEF1 db	'________ in file ',EOS

	public	MSG_BLKEND
MSG_BLKEND  db	'(BLKEND) Block end record',CR,LF
	    db	@I,'at offset '
MSG_BLKEND1 db	'________ in file ',EOS

	public	MSG_TYPDEF
MSG_TYPDEF  db	'(TYPDEF) Type definition record',CR,LF
	    db	@I,'at offset '
MSG_TYPDEF1 db	'________ in file ',EOS

	public	MSG_CTYPINV
MSG_CTYPINV db	'(CTYPINV) Invalid combine type in SEGDEF record',CR,LF
	    db	@I,'at offset '
MSG_CTYPINV1 db '________ in file ',EOS

	public	MSG_ALININV
MSG_ALININV db	'(ALININV) Invalid alignment type in SEGDEF record',CR,LF
	    db	@I,'at offset '
MSG_ALININV1 db '________ in file ',EOS

	public	MSG_ALINDIF
MSG_ALINDIF db	'(ALINDIF) Segment ',@LQ,EOS
MSG_ALINDIF1 db @RQ,CR,LF,@I,'has ',EOS
MSG_ALINDIF2 db ' alignment in file ',EOS
MSG_ALINDIF3 db CR,LF,@I,'and ',EOS
MSG_ALINDIF4 db ' alignment in file ',EOS
MSG_ALINDIF5 db CR,LF,@I,'reference SEGDEF record at offset '
MSG_ALINDIF6 db '________',CR,LF,@I,'in file ',EOS

	public	MSG_USEDIF
MSG_USEDIF db	'(USEDIF) Differing USE16 and USE32 attributes',CR,LF
	   db	@I,'for segment ',@LQ,EOS
MSG_USEDIF1 db	@RQ,', class ',@LQ,EOS
MSG_USEDIF2 db	@RQ,' in SEGDEF record',CR,LF
	    db	@I,'at offset '
MSG_USEDIF3 db	'________ in file ',EOS

	public	MSG_GRPINV
MSG_GRPINV  db	'(GRPINV) Invalid group component descriptor in GPRDEF record',CR,LF
	    db	@I,'at offset '
MSG_GRPINV1 db	'________ in file ',EOS

	public	MSG_GRPDIF
MSG_GRPDIF  db	'(GRPDIF) Segment ',@LQ,EOS
MSG_GRPDIF1 db	@RQ,' owned by group ',@LQ,EOS
MSG_GRPDIF3 db	@RQ,' and',CR,LF
	    db	@I,'by group ',@LQ,EOS
MSG_GRPDIF4 db	@RQ,' which last grouped this segment',CR,LF
	    db	@I,'in file ',EOS
MSG_GRPDIF5 db	@RQ,CR,LF,@I,'reference GRPDEF record at offset '
MSG_GRPDIF6 db	'________',CR,LF,@I,'in file ',EOS

	public	MSG_TYPDIF
MSG_TYPDIF  db	'(TYPDIF) Type indices differ for symbol ',@LQ,EOS
MSG_TYPDIF1 db	@I,'Last occurrence ('
MSG_TYPDIF1A db '____) declared in file ',EOS
MSG_TYPDIF2 db	@I,'This occurrence ('
MSG_TYPDIF2A db '____) declared in file ',EOS
MSG_TYPDIF3 db	@I,'at offset '
MSG_TYPDIF4 db	'________ in file ',EOS

	public	MSG_PUBDIF
MSG_PUBDIF  db	'(PUBDIF) For the symbol ',@LQ,EOS
MSG_PUBDIF1 db	@RQ,',',CR,LF
	    db	@I,'the specified segment ',@LQ,EOS
MSG_PUBDIF2 db	@RQ,' is not contained in',CR,LF
	    db	@I,'the specified group ',@LQ,EOS
MSG_PUBDIF3 db	@RQ,' for PUBDEF record',CR,LF,@I,'at offset '
MSG_PUBDIF4 db	'________ in file ',EOS

	public	MSG_LINDIF
MSG_LINDIF  db	'(LINDIF) The segment ',@LQ,EOS
MSG_LINDIF1 db	@RQ,' is not contained in the group ',@LQ,EOS
MSG_LINDIF2 db	@RQ,CR,LF,@I,'for LINNUM record at offset '
MSG_LINDIF3 db	'________ in file ',EOS

	public	MSG_ALIAS
MSG_ALIAS   db	'(ALIAS) The symbol ',@LQ,EOS
MSG_ALIAS1  db	@RQ,' is already aliased.',CR,LF,EOS

	public	MSG_THRINV
MSG_THRINV  db	'(THRINV) The Target Method field of a Thread FIXUPP record is > 3',CR,LF
	    db	@I,'at offset '
MSG_THRINV1 db	'________ in file ',EOS

	public	MSG_BAKPAT
MSG_BAKPAT  db	'(BAKPAT) The location type field in BAKPAT field is invalid (> 2)',CR,LF
	    db	@I,'at offset '
MSG_BAKPAT1 db	'________ in file ',EOS

	public	DBGMSG_ALIAS,DBGMSG_PUB,DBGMSG_SEP,DBGMSG_WEAK
DBGMSG_ALIAS db @DBG,"Aliased symbols:      ",EOS
DBGMSG_PUB   db @DBG,"Public symbol:        ",EOS
DBGMSG_SEP   db " - ",EOS
DBGMSG_WEAK  db @DBG,"Weak extrns:          ",EOS

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	CHECK_CNT:near
	extrn	GET_INDEX:near
	extrn	COPY_CNTCHR:near
	extrn	DISP_ERRDD:near
	extrn	LOOKUP_SYM:near
	extrn	SYMSRCH:near
	extrn	SYMAPPND:near
	extrn	CHECK_ALIGN:near
	extrn	GET_OFF32:near
	extrn	U32_DISP_MSG:near
	extrn	U32_NEWLINE:near
	extrn	DISP_CNTCHR:near
	extrn	DISP_THEADR:near
	extrn	DUMPIT:near
	extrn	IWF_TEST:near
	extrn	DW2HEX:near
	extrn	LINK_LIBNAM:near
	extrn	StrNICmp:near

	NPPROC	OMF_UNK -- Unknown OMF Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display unknown OMF record.

On entry:

DS:EDI	==>	POBJ_STR
DS:ESI	==>	.OBJ record
DS:EDX	==>	start of .OBJ file

On exit:

CF	=	1 to signal an error

|

	push	dword ptr (offset PGROUP:IWF_OMFUNK) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_OMFUNK	; Pass offset of bit mask
	call	IWF_TEST	; Test for unknown OMF record
				; Return with CF=1 if it's fatal
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_UNK endp			; End OMF_UNK procedure
	NPPROC	IWF_OMFUNK -- OMF Unknown Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF unknown record

|

	push	dword ptr (offset DGROUP:MSG_OMFUNK) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OMFUNK1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_OMFUNK endp 		; End IWF_OMFUNK procedure
	NPPROC	OMF_IGN -- Ignore This OMF Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display an ignorable OMF record.

On entry:

DS:EDI	==>	POBJ_STR
DS:ESI	==>	.OBJ record
DS:EDX	==>	start of .OBJ file

On exit:

CF	 =	 1 if this event is fatal

|

	push	dword ptr (offset PGROUP:IWF_OMFIGN) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_OMFIGN	; Pass offset of bit mask
	call	IWF_TEST	; Test for ignorable OMF record
				; Return with CF=1 if it's fatal
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_IGN endp			; End OMF_IGN procedure
	NPPROC	IWF_OMFIGN -- OMF Ignorable Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF ignorable record.

|

	push	dword ptr (offset DGROUP:MSG_OMFIGN) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OMFIGN1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_OMFIGN endp 		; End IWF_OMFIGN procedure
	NPPROC	OMF_BLKDEF -- Block Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Block definition record (7Ah).

On entry:

DS:EDI	==>	POBJ_STR
DS:ESI	==>	.OBJ record
DS:EDX	==>	start of .OBJ file

On exit:

CF	=	1 to signal an error

|

	push	dword ptr (offset PGROUP:IWF_BLKDEF) ; Pass offset of action routine
	push	IW3_FLAG	; Pass value of flags
	push	$IW3_BLKDEF	; Pass offset of bit mask
	call	IWF_TEST	; Test for unknown OMF record
				; Return with CF=1 if it's fatal
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_BLKDEF endp 		; End OMF_BLKDEF procedure
	NPPROC	IWF_BLKDEF -- Block Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Block definition record

|

	push	dword ptr (offset DGROUP:MSG_BLKDEF) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_BLKDEF1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_BLKDEF endp 		; End IWF_BLKDEF procedure
	NPPROC	OMF_BLKEND -- Block End Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Block end record (7Ch).

On entry:

DS:EDI	==>	POBJ_STR
DS:ESI	==>	.OBJ record
DS:EDX	==>	start of .OBJ file

On exit:

CF	=	1 to signal an error

|

	push	dword ptr (offset PGROUP:IWF_BLKEND) ; Pass offset of action routine
	push	IW3_FLAG	; Pass value of flags
	push	$IW3_BLKEND	; Pass offset of bit mask
	call	IWF_TEST	; Test for unknown OMF record
				; Return with CF=1 if it's fatal
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_BLKEND endp 		; End OMF_BLKEND procedure
	NPPROC	IWF_BLKEND -- Block End Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Block end record

|

	push	dword ptr (offset DGROUP:MSG_BLKEND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_BLKEND1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_BLKEND endp 		; End IWF_BLKEND procedure
	NPPROC	OMF_THEADR -- Translator Header Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Translator header record (80h).

On entry:

DS:ESI	==>	OMF_THEADR_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

OMF_THEADR_STR struc

	db	(size OBJHDR_STR) dup () ; .OBJ header
OMF_THEADR_LEN db ?		; Length in bytes of OMF_THEADR_FID
OMF_THEADR_FID db ?		; Module filename

OMF_THEADR_STR ends

	REGSAVE <ecx,edx,esi,edi> ; Save registers

; Copy the module name

	movzx	ecx,ds:[esi].OMF_THEADR_LEN ; Get the byte length
	inc	ecx		; Count in the length byte

	mov	edi,LMB_TXTSTR.LMB_CURB.BOUND_NXT ; Get LA of next entry

; Save LA of THEADR text in PEROBJ data

	mov	edx,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	edx,type PEROBJ_STR ; Back off to previous entry
	UNCURB	edx,PEROBJ	; Ensure within current bounds
	mov	AGROUP:[edx].PEROBJ_PTHEADR,edi ; Save for later use

	lea	esi,ds:[esi].OMF_THEADR_LEN ; Copy from length byte

	UNOVRB	edi,TXTSTR	; Ensure within overall bounds
    rep movs	AGROUP:[edi].LO,ds:[esi].LO ; Copy as small text string

	mov	LMB_TXTSTR.LMB_CURB.BOUND_NXT,edi ; Save as LA of next entry

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	REGREST <edi,esi,edx,ecx> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_THEADR endp 		; End OMF_THEADR procedure
	NPPROC	OMF_COMENT -- Comment Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Comment record (88h)

On entry:

DS:ESI	==>	OBJHDR_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

NXT_COMENT_STR struc

NXT_COMENT_TYP db ?		; Comment type (ignored)
NXT_COMENT_CLASS db ?		; ...	  class

NXT_COMENT_STR ends

	pushad			; Save registers

	add	esi,type OBJHDR_STR ; Skip over the header

	lods	(type NXT_COMENT_TYP) ptr ds:[esi] ; Get comment type (ignored)
	lods	(type NXT_COMENT_CLASS) ptr ds:[esi] ; Get comment class

	cmp	al,0A2h 	; Izit LINK Pass marker?
	jne	short OMF_COMENT1 ; Jump if not

	lods	ds:[esi].LO	; Get subtype

	cmp	al,1		; Izit pass one or two?
	jbe	near ptr OMF_COMENT_IGN ; Jump if so (ignore the rest of the record)

	jmp	OMF_COMENT_ERR	; Join common error code


; If it's the translator name,        ignore the rest of the record
; If it's Intel copyright,            ...
; If it's MSDOS version number,       ...
; If it's LIBMOD comment,             ...
; If it's unknown Borland record #1,  ...
; If it's unknown Borland record #2,  ...
; If it's unknown Borland record #3,  ...
; If it's unknown Borland record #4,  ...
; If it's unknown Borland record #5,  ...
; If it's unknown Borland record #6,  ...
; If it's unknown Borland record #7,  ...
; If it's unknown Borland record #8,  ...
; If it's Borland dependency files,   ...
; If it's unknown Borland record #9,  ...
; If it's unknown Borland record #10, ...
; If it's unknown Borland record #11, ...

OMF_COMENT1:
	cmp	al,@OMF_COMENT_TNAME ; Izit translator name (00)?
	je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)

	cmp	al,@OMF_COMENT_ICOPY ; Izit Intel copyright (01)?
	je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)

	cmp	al,@OMF_COMENT_MSDOSVER ; Izit MSDOS version number (9C)?
	je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)

	cmp	al,@OMF_COMENT_LIBMOD ; Izit LIBMOD comment (A3)?
	je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)

;;;;;;; cmp	al,0E0h 	; Izit unknown Borland record #1?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E1h 	; Izit unknown Borland record #2?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E2h 	; Izit unknown Borland record #3?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E3h 	; Izit unknown Borland record #4?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E5h 	; Izit unknown Borland record #5?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E6h 	; Izit unknown Borland record #6?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E7h 	; Izit unknown Borland record #7?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0E8h 	; Izit unknown Borland record #8?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
	cmp	al,@OMF_COMENT_BORDEP ; Izit Borland dependency files (E9)?
	je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)

;;;;;;; cmp	al,0EAh 	; Izit unknown Borland record #9?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0EEh 	; Izit unknown Borland record #10?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; cmp	al,0F8h 	; Izit unknown Borland record #11?
;;;;;;; je	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)
;;;;;;;
; If it's memory model marker, mark it as such

	cmp	al,@OMF_COMENT_MEMMODEL ; Izit memory model marker (9D)?
	jne	short @F	; Jump if not

	or	LCL_FLAG,@LCL_MEMMOD ; Mark as present *FIXME*

	jmp	OMF_COMENT_IGN	; Join common ignore code

@@:

; If it's DOSSEG switch, set it

	cmp	al,@OMF_COMENT_DOSSEG ; Izit DOSSEG switch (9E)?
	jne	short OMF_COMENT2 ; Jump if not

	or	ARG_FLAG,@ARG_DOSSEG ; Mark as using DOSSEGs

COMMENT|

If /DOSSEG is specified
    If /NONULLSDOSSEG is not specified
       Set NONULLS_OFF to 0010h (one NULL para)
|

	mov	NONULLS_OFF,0	; No NULL para at start of _TEXT segment

;;;;;;; test	ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	ARG_FLAG,@ARG_NONULLS ; Is /NONULLSDOSSEG specified?
	jnz	short @F	; Jump if so

	mov	NONULLS_OFF,0010h ; Insert one para at start of _TEXT segment
@@:
	jmp	OMF_COMENT_IGN	; Join common ignore code

OMF_COMENT2:

; If it's a default library search name and /NOD has been specified,
; skip the record.

	cmp	al,@OMF_COMENT_LIBSPEC ; Izit Def Lib Search (81)?
	je	short @F	; Jump if so

	cmp	al,@OMF_COMENT_DEFLIB ; Izit Def Lib Search (9F)?
	jne	short OMF_COMENT3 ; Jump if not
@@:
	test	ARG_FLAG,@ARG_NODLS ; Izit No Def Lib Search?
	jnz	near ptr OMF_COMENT_EXIT ; Jump if so (note CF=0)

	mov	ecx,THISOBJ_CSUM ; Get ending address
	sub	ecx,esi 	; Less current address to get length
	call	LINK_LIBNAM	; Link in .LIB name at DS:ESI of length ECX
				; Return DS:ESI ==> next char after libname
	jmp	OMF_COMENT_DONE ; Join common done code



; If it's "New OMF" extension switch, set it

OMF_COMENT3:
	cmp	al,@OMF_COMENT_NOMFEXT ; Izit "New OMF" extension switch (A1)?
	jne	short OMF_COMENT4 ; Jump if not

	or	ARG_FLAG,@ARG_NEWOMF ; Mark as using "new OMFs" *FIXME*

	jmp	OMF_COMENT_EXIT ; Join common exit code


; If it's weak extrns, handle them

OMF_COMENT4:
	cmp	al,@OMF_COMENT_WEAKEXT ; Izit weak extrns (A8)?
	jne	near ptr OMF_COMENT5 ; Jump if not
OMF_COMENT4_NEXT:
	cmp	esi,THISOBJ_CSUM ; Are we at the end of the record?
	je	near ptr OMF_COMENT_DONE ; Jump if so

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1) *FIXME*

	imul	eax,type EXTDEF_STR ; Convert to index for SEGDEF_STRs
	add	eax,LMB_EXTDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	call	MARK_MATCHED	; Mark the EXTDEF at EAX as matched
	mov	ebx,AGROUP:[eax].EXTDEF_PSYM ; Get LA of symbol (SYM_STR)
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_WEAK ; Mark as weak

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1) *FIXME*

	imul	eax,type EXTDEF_STR ; Convert to index for SEGDEF_STRs
	add	eax,LMB_EXTDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	call	MARK_MATCHED	; Mark the EXTDEF at EAX as matched
	mov	eax,AGROUP:[eax].EXTDEF_PSYM ; Get LA of symbol (SYM_STR)

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	UNCURB	eax,SYMBOL	; ...
	mov	AGROUP:[ebx].SYM_PERITEM,eax ; Point 1st symbol to resolver

; If we're in a debuggin' mood, display the weak extrn symbols

	test	ARG_FLAG,@ARG_DBGMSG ; Displaying debugging messages?
	jz	short OMF_COMENT4_XDBG ; Jump if not

; EBX = La of SYM_STR of 1st symbol
; EAX = La of SYM_STR of 2nd symbol

	pushad			; Save for a moment

	push	eax		; Save for a moment

	lea	edx,DBGMSG_WEAK ; Get line start
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	mov	edx,AGROUP:[ebx].SYM_PNAM ; Get LA of 1st symbol (Count, Char[])
	movzx	ecx,ds:[edx].LO ; Get the count
	inc	edx		; Skip over it
	mov	bx,@STD_OUT	; Send to standard output
	DOSCALL @WRITF2 	; Write it out

	lea	edx,DBGMSG_SEP	; Get separator
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	pop	eax		; Restore

	mov	edx,AGROUP:[eax].SYM_PNAM ; Get LA of 2nd symbol (Count, Char[])
	movzx	ecx,ds:[edx].LO ; Get the count
	inc	edx		; Skip over it
	mov	bx,@STD_OUT	; Send to standard output
	DOSCALL @WRITF2 	; Write it out

	lea	edx,MSG_CRLF	; Get line ending
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	popad			; Restore
OMF_COMENT4_XDBG:
	jmp	OMF_COMENT4_NEXT ; Go around again


OMF_COMENT5:


OMF_COMENT_ERR:
	stc			; Mark as in error

	jmp	short OMF_COMENT_EXIT ; Join common exit code

OMF_COMENT_IGN:
	clc			; Mark as successful

	jmp	short OMF_COMENT_EXIT ; Join common exit code

OMF_COMENT_DONE:
	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
OMF_COMENT_EXIT:
	popad			; Restore
	jc	near ptr OMF_IGN ; If it's in error, ignore it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_COMENT endp 		; End OMF_COMENT procedure
	NPPROC	OMF_MODEND -- Module End Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Module end record (8Ah/8Bh)

On entry:

DS:ESI	==>	OMF_MODEND_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

OMF_MODEND_STR struc

	db	(size OBJHDR_STR) dup () ; .OBJ header
OMF_MODEND_TYP db ?		; Module type (see MODTYP_REC)
OMF_MODEND_ENDDAT db ?		; End data byte

OMF_MODEND_STR ends


MODTYP_REC record \
$MODTYP_M:1,	\
$MODTYP_S:1,	\
$MODTYP_RSV1:5, \
$MODTYP_X:1

@MODTYP_M equ	(mask $MODTYP_M) ; Module is main
@MODTYP_S equ	(mask $MODTYP_S) ; Module has starting address
@MODTYP_X equ	(mask $MODTYP_X) ; Address needs fixup

	pushad			; Save registers

	add	esi,type OBJHDR_STR ; Skip over the header

	lods	(type OMF_MODEND_TYP) ptr ds:[esi] ; Get module type byte

;;;;;;; test	al,@MODTYP_M	; Izit a main module?
;;;;;;; jz	short ???	; Jump if not *FIXME*
;;;;;;;
	test	al,@MODTYP_S	; Is there a starting address?
	jz	near ptr OMF_MODEND_DONE ; Jump if not

	or	LCL_FLAG,@LCL_START ; Mark as present

	lods	(type OMF_MODEND_ENDDAT) ptr ds:[esi] ; Get ENDDAT byte
	mov	FIXDAT,al	; Save ENDDAT byte (just like FIXDAT byte)

; Zero the FIXUPP struc

	mov	edi,LMB_FIXUPP.LMB_CURB.BOUND_NXT ; Get LA of next entry

	push	edi		; Save starting address

.errnz (4-1) and (type FIXUPP_STR)
	mov	ecx,(type FIXUPP_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	UNOVRB	edi,FIXUPP	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc

	mov	LMB_FIXUPP.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	pop	edi		; Restore

	cmp	DEF32,1 	; Izit a 32-bit record?
	sete	al		; AL = 1 iff 32-bit record
	shl	al,@FIXFL_32	; Shift into position
	or	al,@FIXFL_MOD	; Include MODEND flag
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	AGROUP:[edi].FIXUPP_FLAG,al ; Save fixup flags

; Construct and write out a LOCAT word

; Mark as FIXUP, Segment-relative, Ptr16:16

	mov	eax,@LOCAT_FIX or @LOCAT_M or (@LOCAT_LOC_VEC shl $LOCAT_LOC) ; Mark it
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	AGROUP:[edi].FIXUPP_LOCAT,ax ; Save LOCAT word

; Create a new segment to contain the fixup location
; We only need a dword, but we'll allocate a whole segment anyway

	push	1		; Mark as MODEND special segment
	call	SETUP_NEWSEG	; Setup a new segment
	jc	near ptr OMF_MODEND_EXIT ; Jump if something went wrong (note CF=1)

; Create a pseudo-segment name

	push	edi		; Save for a moment

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

; Copy the pseudo-segment name

	lea	eax,MODEND_NAME ; Get offset in DGROUP of pseudo-segment name
	add	eax,LaDATA	; Plus LA of DGROUP
	push	eax		; Pass LA of text
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated
; Copy the pseudo-class name

	lea	eax,MODEND_CLASS ; Get offset in DGROUP of pseudo-class name
	add	eax,LaDATA	; Plus LA of DGROUP
	push	eax		; Pass LA of text
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated
; Save a pseudo-ACBP byte (Absolute, Private, Small, USE16)

	mov	al,(@ACBP_A_ABS     shl $ACBP_A) or \
		   (@ACBP_C_PRIVATE shl $ACBP_C) or \
		   (0		    shl $ACBP_B) or \
		   (0		    shl $ACBP_P)
	mov	ACBP,al 	; Save for later use
	stos	es:[edi].LO	; Save in the work area

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	movzx	eax,ACBP	; Get the incoming ACBP byte
	or	eax,@SYMFL_END	; Mark as a MODEND-segment
	mov	WORKAREA_SYM.SYM_FLAG,eax ; Save as flags

	pop	edi		; Restore

	push	esi		; Save for a moment
	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
	pop	esi		; Restore
	jc	short OMF_MODEND_APPND ; Jump if something went wrong

	mov	eax,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PERSEG_STR ; Back off to previous struc

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,eax ; Save in symbol table

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	AGROUP:[eax].PERSEG_SEGSYM,ebx ; Save as ptr to SYM_STR

;;;;;;; UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	AGROUP:[eax].PERSEG_CLSSYM,-1 ; Mark as to be skipped in PROC_SEGS

; Save the LA of the corresponding PERSEG_STR in FIXUPP_STR

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	AGROUP:[edi].FIXUPP_PPERSEG,eax ; Save LA of seg of DRO (PERSEG_STR)

; Save the segment length before appending to this segment

;;;;;;; UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].PERSEG_OLDLEN ; Get length before appending
				; this segment
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	AGROUP:[edi].FIXUPP_OLDLEN,ecx ; Save length before appending
				; this segment
; Write out a FIXUPP_DRO_CUR value which corresponds to the start
; of the segment we just created

;;;;;;; UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].PERSEG_LMB.LMB_CURB.BOUND_BEG ; Get start of segment
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	AGROUP:[edi].FIXUPP_DRO_CUR,ecx ; Save LA of fixup current
;;;;;;; UNCURB	eax,PERSEG	; Ensure within current bounds
	add	AGROUP:[eax].PERSEG_LMB.LMB_CURB.BOUND_NXT,4 ; Skip over it
	UNCURB	ecx,PERSEG,eax	; Ensure within current bounds
	mov	AGROUP:[ecx].EDD,0 ; Initialize the entry

	call	FIXUPP_COM	; Call routine to accumulate fixup
	jc	short OMF_MODEND_ERR ; Jump if something went wrong




OMF_MODEND_DONE:
	or	LCL_FLAG,@LCL_MODEND ; Mark as MODEND record

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	jmp	short OMF_MODEND_EXIT ; Join common exit code


OMF_MODEND_APPND:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	call	DUMPIT		; Dump all the tables
OMF_MODEND_ERR:
	stc			; Mark as in error
OMF_MODEND_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_MODEND endp 		; End OMF_MODEND procedure
	NPPROC	OMF_EXTDEF -- External Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

External definition names record (8Ch)
Local external definition names record (B4h/B5h)

On entry:

DS:ESI	==>	OMF_EXTDEF_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

NXT_EXTDEF_STR struc

NXT_EXTDEF_LEN db ?		; Length in bytes of NXT_EXTDEF_FID
NXT_EXTDEF_FID db ?		; Module filename

NXT_EXTDEF_STR ends

	pushad			; Save registers

; Setup loop variables to copy the names to the work area
; and save an entry for it in the EXTDEF table

	add	esi,type OBJHDR_STR ; Skip over the header
	mov	edi,LMB_EXTDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
OMF_EXTDEF_NEXT:

; Zero the EXTDEF struc

.errnz (4-1) and (type EXTDEF_STR)
	mov	ecx,(type EXTDEF_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
;;;;;;; mov	edi,LMB_EXTDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	edx,edi 	; Save starting offset of EXTDEF_STR

	UNOVRB	edi,EXTDEF	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	mov	LMB_EXTDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	push	edi		; Save for a moment

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

	movzx	ecx,ds:[esi].NXT_EXTDEF_LEN ; Get the byte length
	inc	ecx		; Count in the length byte

; Copy the (Count, Char[]) pair to the work area

	call	CopyCountChar	; Copy it

; In case this is a local EXTDEF, we append to the name the
; LA of the current PEROBJ_STR

	mov	cl,OMFTYP	; Get the OMF type
	and	cl,not @BIT0	; Clear the 32-bit bit

	cmp	cl,@OMF_LEXTDEF ; Izit LEXTDEF record?
	jne	short @F	; Jump if not

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	stos	AGROUP:[edi].EDD ; Save in work area
@@:

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	mov	WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SYM ; Mark as symbol class

; If this is a local EXTDEF, mark it as such so we don't
; display it in the .MAP file

	cmp	cl,@OMF_LEXTDEF ; Izit LEXTDEF record?
	jne	short @F	; Jump if not

	or	WORKAREA_SYM.SYM_FLAG,@SYMFL_LOCAL ; Mark as local symbol
@@:
	pop	edi		; Restore

; See if this entry already exists in the symbol table

	 REGSAVE <esi>		; Save for a moment

	 lea	 esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	 add	 esi,LaDATA	; Plus LA of DGROUP
	 call	 SYMSRCH	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	 jnc	 short OMF_EXTDEF_OLD ; Jump if already in the table (note CF=0)

; Append the entry to the symbol table

;;;;;;;; lea	 esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;;; add	 esi,LaDATA	; Plus LA of DGROUP
	 call	 SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
OMF_EXTDEF_OLD:
	 REGREST <esi>		; Restore
	 jc	 near ptr OMF_EXTDEF_APPND ; Jump if something went wrong

	 UNCURB  edx,EXTDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].EXTDEF_PSYM,ebx ; Save as pointer to SYM_STR
	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 or	 AGROUP:[ebx].SYM_FLAG,@SYMFL_EXT ; Mark as external symbol

; Get and check the type index field

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 short @F	; Jump if no index (EAX=-1)

	 call	 CHECK_TYPE	; Check type indices of EAX and [EBX].SYM_TYPE
	 jc	 near ptr OMF_EXTDEF_EXIT ; Jump if it's fatal (note CF=1)

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_TYPE,eax ; Save as type index
@@:

; If this symbol is not already marked as public, save the PEROBJ_STR
; of this module in SYM_PERITEM so we can reference a module name in
; case the external symbol is never matched by a public one.
; Note that we wait until we've checked the type indices before storing
; this value as that code depends upon seeing the old name in
; the SYM_PERITEM field.

;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[ebx].SYM_FLAG,@SYMFL_PUB ; Izit already marked public?
	 jnz	 short @F	; Jump if so

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_PERITEM,eax ; Save for later use
@@:
	 cmp	 esi,THISOBJ_CSUM ; Are we at the end of the record?
	 jb	 near ptr OMF_EXTDEF_NEXT ; Jump if more names to check

	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	 jmp	 short OMF_EXTDEF_EXIT ; Join common exit code


OMF_EXTDEF_APPND:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 call	 DUMPIT 	; Dump all the tables

	 stc			; Mark as in error
OMF_EXTDEF_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_EXTDEF endp 		; End OMF_EXTDEF procedure
	 NPPROC  CHECK_TYPE -- Check Type Indices
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check type indices

On entry:

EAX	 =	 current type index
EBX	 =	 LA of symbol (SYM_STR)

On exit:

CF	 =	 0 if all went OK
	 =	 1 if not

|

	 pushad 		; Save registers

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 ecx,AGROUP:[ebx].SYM_TYPE ; Get previous type index

	 and	 ecx,ecx	; Izit unspecified?
	 jz	 short CHECK_TYPE_EXIT ; Jump if so (note CF=0)

	 cmp	 eax,ecx	; Duzit match?
	 je	 short CHECK_TYPE_EXIT ; Jump if so (note CF=0)

	 push	 dword ptr (offset PGROUP:IWF_TYPDIF) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_TYPDIF	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for differing type indices
				; Return with CF significant
CHECK_TYPE_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TYPE endp 		; End CHECK_TYPE procedure
	 NPPROC  IWF_TYPDIF -- Ignore/Warn/Fail About Differing Types
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about differing types

On entry:

EAX	 =	 current type index
EBX	 =	 LA of symbol (SYM_STR)

|

	 pushad 		; Save registers

	 lea	 edi,MSG_TYPDIF2A ; Get offset in DGROUP
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 call	 DW2HEX 	; Convert AX to hex at ES:EDI

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].SYM_TYPE ; Get the last type
	 lea	 edi,MSG_TYPDIF1A ; Get offset in DGROUP
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 call	 DW2HEX 	; Convert AX to hex at ES:EDI

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_TYPDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the symbol name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display last occurrence filename from SYM_STR

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_TYPDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].SYM_PERITEM ; Get PUBDEF_STR or PEROBJ_STR

;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[ebx].SYM_FLAG,@SYMFL_PUB ; Izit public?
	 jz	 short IWF_TYPDIF1 ; Jump if not

	 UNCURB  eax,PUBDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PUBDEF_PPEROBJ ; Get LA of PEROBJ_STR
IWF_TYPDIF1:
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 call	 U32_NEWLINE	; Goto a new line

; Display current filename

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_TYPDIF2) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 call	 U32_NEWLINE	; Goto a new line

; Display the record information

	 push	 dword ptr (offset DGROUP:MSG_TYPDIF3) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_TYPDIF4) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_TYPDIF endp 		; End IWF_TYPDIF procedure
	NPPROC	OMF_TYPDEF -- Type Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Type definiton record (8Eh).

On entry:

DS:EDI	==>	POBJ_STR
DS:ESI	==>	.OBJ record
DS:EDX	==>	start of .OBJ file

On exit:

CF	=	1 to signal an error

|

	push	dword ptr (offset PGROUP:IWF_TYPDEF) ; Pass offset of action routine
	push	IW3_FLAG	; Pass value of flags
	push	$IW3_TYPDEF	; Pass offset of bit mask
	call	IWF_TEST	; Test for unknown OMF record
				; Return with CF=1 if it's fatal
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_TYPDEF endp 		; End OMF_TYPDEF procedure
	NPPROC	IWF_TYPDEF -- Type Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Type definition record

|

	push	dword ptr (offset DGROUP:MSG_TYPDEF) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_TYPDEF1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_TYPDEF endp 		; End IWF_TYPDEF procedure
	 NPPROC  OMF_PUBDEF -- Public Definition Record
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Public definition names record (90h/91h).

The PUBDEF_ADDR field consists of three parts (assuming the symbol is
not absolute):

1.  The offset of this symbol in this segment in this module.  This
    value comes from the Public Offset field in the current .OBJ
    record.

2.  The offset of this segment in this module in the entire segment.
    This value comes from PERSEG_OLDLEN.

3.  The base address of this segment.  This value is determined after
    all components of this segment have been processed.  It is stored
    in PUBDEF_BASE.

On entry:

DS:ESI	 ==>	 OMF_PUBDEF_STR

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

NXT_PUBDEF_STR struc

NXT_PUBDEF_LEN db ?		; Length in bytes of NXT_PUBDEF_FID
NXT_PUBDEF_FID db ?		; Module filename

NXT_PUBDEF_STR ends

	 pushad 		; Save registers

; Setup loop variables to copy the names to the work area
; and save an entry for it in the PUBDEF table

	 add	 esi,type OBJHDR_STR ; Skip over the header

	 push	 0		; Mark as PUBDEF
	 push	 dword ptr (offset PGROUP:IWF_PUBDIF) ; Pass offset of action routine
	 push	 IW2_FLAG	; Pass value of flags
	 push	 $IW2_PUBDIF	; Pass offset of bit mask
	 call	 SETUP_BASE	; Setup base group and segs for PUBDEF/LINNUM
	 jc	 near ptr OMF_PUBDEF_EXIT ; Jump if something went wrong
OMF_PUBDEF_NEXT:
	 lea	 edi,WORKAREA	; Get offset in DGROUP of work area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 mov	 ebx,edi	; Save starting address

; If we're in a debuggin' mood, display the public symbol

	test	ARG_FLAG,@ARG_DBGMSG ; Displaying debugging messages?
	jz	short OMF_PUBDEF_XDBG ; Jump if not

	pushad			; Save for a moment

	lea	edx,DBGMSG_PUB	; Get line start
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	lea	edx,ds:[esi].NXT_PUBDEF_LEN ; Get LA of symbol (Count, Char[])
	movzx	ecx,ds:[edx].LO ; Get the count
	inc	edx		; Skip over it
	mov	bx,@STD_OUT	; Send to standard output
	DOSCALL @WRITF2 	; Write it out

	lea	edx,MSG_CRLF	; Get line ending
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	popad			; Restore
OMF_PUBDEF_XDBG:
	movzx	ecx,ds:[esi].NXT_PUBDEF_LEN ; Get the byte length
	inc	ecx		; Count in the length byte

; Copy the (Count, Char[]) pair to the work area

	call	CopyCountChar	; Copy it

; In case this is a local PUBDEF, we append to the name the
; LA of the current PEROBJ_STR

	mov	cl,OMFTYP	; Get the OMF type
	and	cl,not @BIT0	; Clear the 32-bit bit

	cmp	cl,@OMF_LPUBDEF ; Izit LPUBDEF record?
	jne	short @F	; Jump if not

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	stos	AGROUP:[edi].EDD ; Save in work area
@@:

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	mov	WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SYM ; Mark as symbol class

; If this is a local PUBDEF, mark it as such so we don't
; display it in the .MAP file

	cmp	cl,@OMF_LPUBDEF ; Izit LPUBDEF record?
	jne	short @F	; Jump if not

	or	WORKAREA_SYM.SYM_FLAG,@SYMFL_LOCAL ; Mark as local symbol
@@:

; See if this entry already exists in the symbol table

	REGSAVE <esi>		; Save for a moment

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	jnc	short OMF_PUBDEF_OLD ; Jump if already in the table (note CF=0)

; Append the entry to the symbol table

;;;;;;; lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;; add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
OMF_PUBDEF_OLD:
	 REGREST <esi>		; Restore
	 jc	 near ptr OMF_PUBDEF_APPND ; Jump if something went wrong

; If this symbol is temp, use the existing PUBDEF_STR

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 edx,AGROUP:[ebx].SYM_PERITEM ; Get PUBDEF_STR if temp

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 btr	 AGROUP:[ebx].SYM_FLAG,$SYMFL_TEMP ; Izit temp?
	 jc	 short OMF_PUBDEF_TEMP ; Jump if so

; Zero the PUBDEF struc

.errnz (4-1) and (type PUBDEF_STR)
	 mov	 ecx,(type PUBDEF_STR)/4 ; # dwords to zero
	 xor	 eax,eax	; Set to this
	 mov	 edi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 mov	 edx,edi	; Save starting offset of PUBDEF_STR

	 UNOVRB  edi,PUBDEF	; Ensure within overall bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the struc
	 mov	 LMB_PUBDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	 jmp	 short OMF_PUBDEF_TEMPCOM ; Join common code


; We've matched a temp symbol:  if the base group and segment don't
; agree, call it a duplicate symbol

OMF_PUBDEF_TEMP:
	 mov	 eax,BASE_GRP	; Get LA of base group (PERGRP_STR)
	 UNCURB  edx,PUBDEF	; Ensure within current bounds
	 cmp	 eax,AGROUP:[edx].PUBDEF_PPERGRP ; Izit the same?
	 jne	 near ptr OMF_PUBDEF_PUBDUP ; Jump if it's already public
				; With EBX and EDX used in error display
	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 cmp	 eax,AGROUP:[edx].PUBDEF_PPERSEG ; Izit the same?
	 jne	 near ptr OMF_PUBDEF_PUBDUP ; Jump if it's already public
				; With EBX and EDX used in error display
OMF_PUBDEF_TEMPCOM:
	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPEROBJ,eax ; Save for later use

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_PPEROBJ,eax ; Save for later use

	 mov	 eax,BASE_GRP	; Get LA of base group (PERGRP_STR)
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPERGRP,eax ; Save for later use

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPERSEG,eax ; Save for later use

	 mov	 eax,BASE_OLDLEN ; Get old segment length
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 add	 AGROUP:[edx].PUBDEF_ADDR,eax ; Add in the old segment length
				; part of the entire address
; Mark this as a 32-bit symbol if appropriate

	 mov	 ecx,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	 jecxz	 OMF_PUBDEF1	; Jump if it's invalid

	 UNCURB  ecx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[ecx].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[eax].SYM_FLAG,@SYMFL_P ; Izit USE32?
	 jz	 short OMF_PUBDEF1 ; Jump if not

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 or	 AGROUP:[ebx].SYM_FLAG,@SYMFL_P ; Mark as USE32
OMF_PUBDEF1:

; Mark this as an absolute constant if appropriate

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	 or	 eax,BASE_GRP	; Include LA of base group (PERGRP_STR)
	 jnz	 short @F	; Jump if base frame not present

;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 or	 AGROUP:[ebx].SYM_FLAG,@SYMFL_ABSCON ; Mark as absolute constant
@@:
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PSYM,ebx ; Save as pointer to SYM_STR

; Get and save the offset

	 call	 GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	 UNCURB  edx,PUBDEF	; Ensure within current bounds
	 add	 AGROUP:[edx].PUBDEF_ADDR,eax ; Add in the public offset
				; part of the entire address

; If the symbol is an absolute constant => 64KB, mark it as USE32

;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[ebx].SYM_FLAG,@SYMFL_ABSCON ; Izit an absolute constant
	 jz	 short @F	; Jump if not

	 cmp	 eax,@CON64KB	; Izit bigger than a breadbox?
	 jb	 short @F	; Jump if not

;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 or	 AGROUP:[ebx].SYM_FLAG,@SYMFL_P ; Mark as USE32
	 or	 LCL_FLAG,@LCL_CON32 ; Note for later use
@@:

; Get and check the type index field

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 short @F	; Jump if no index (EAX=-1)

	 call	 CHECK_TYPE	; Check type indices of EAX and [EBX].SYM_TYPE
	 jc	 near ptr OMF_PUBDEF_EXIT ; Jump if it's fatal (note CF=1)

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_TYPE,eax ; Save as type index
@@:

; Ensure there's no duplicate public symbols
; Note that we wait until we've checked the type indices before storing
; this value as that code depends upon seeing the old name in
; the SYM_PERITEM field.

	UNCURB	ebx,SYMBOL     ; Ensure within current bounds
	bts	AGROUP:[ebx].SYM_FLAG,$SYMFL_PUB ; Mark as public
	jc	short OMF_PUBDEF_PUBDUP ; Jump if it's already public
				; With EBX and EDX used in error display

; Remove any alias or substitute flags

;;;;;;; UNCURB	ebx,SYMBOL     ; Ensure within current bounds
	and	AGROUP:[ebx].SYM_FLAG,not (@SYMFL_ALIAS or @SYMFL_SUBST) ; Remove 'em

; Handle back pointer

;;;;;;; UNCURB	ebx,SYMBOL     ; Ensure within current bounds
	btr	AGROUP:[ebx].SYM_FLAG,$SYMFL_BKPTR ; Izit back ptr?
	jnc	short @F	; Jump if not

;;;;;;; UNCURB	ebx,SYMBOL     ; Ensure within current bounds
	mov	ecx,AGROUP:[ebx].SYM_PERITEM ; Get back pointer
	UNCURB	ecx,SYMBOL     ; Ensure within current bounds
	mov	AGROUP:[ecx].SYM_PERITEM,edx ; Save LA of public (PUBDEF_STR)
@@:
;;;
;;; ; Clear the symbol substitute flag
;;;
;;;;;;; UNCURB	ebx,SYMBOL     ; Ensure within current bounds
;;;;;;; btr	AGROUP:[ebx].SYM_FLAG,$SYMFL_SUBST ; Izit substituted?
;;;	jnc	short @F	; Jump if not
;;;
;;; ; If this symbol is a substitute, transfer the flags to the resolver symbol
;;;
;;; ;;;;;;; UNCURB  ebx,SYMBOL	    ; Ensure within current bounds
;;;	    mov     eax,AGROUP:[ebx].SYM_FLAG ; Get the current flags
;;;	    and     eax,not @SYMFL_SUBST ; Less the substitute flag
;;; ;;;;;;; UNCURB  ebx,SYMBOL	    ; Ensure within current bounds
;;;	    mov     edi,AGROUP:[ebx].SYM_PERITEM ; Get the matching SYM_STR
;;;	    UNCURB  edi,SYMBOL	    ; Ensure within current bounds
;;;	    or	    AGROUP:[edi].SYM_FLAG,eax ; Include the flags
;;;@@:
;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_PERITEM,edx ; Save LA of public (PUBDEF_STR)

	 cmp	 esi,THISOBJ_CSUM ; Are we at the end of the record?
	 jb	 near ptr OMF_PUBDEF_NEXT ; Jump if more names to check

	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	 jmp	 OMF_PUBDEF_EXIT ; Join common exit code


COMMENT|

Duplicate public symbols

EBX	 =	 LA of SYM_STR of existing PUBDEF
EDX	 =	 LA of PUBDEF_STR of incoming PUBDEF

|

OMF_PUBDEF_PUBDUP:
	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_PUBDUP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the symbol name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_PUBDUP1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display filename #1

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PUBDEF_STR
	 UNCURB  eax,PUBDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PUBDEF_PPEROBJ ; Get LA of PEROBJ_STR
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

; Display the record offset, etc.

	 push	 dword ptr (offset DGROUP:MSG_PUBDUP2) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_PUBDUP3) ; ...

	 jmp	 short OMF_PUBDEF_ERRCOM ; Join common error code

OMF_PUBDEF_APPND:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...

	 inc	 ERRCNT 	; Mark as writing to error file

;;;;;;;; jmp	 short OMF_PUBDEF_ERRCOM ; Join common error code

OMF_PUBDEF_ERRCOM:
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 call	 DUMPIT 	; Dump all the tables

	 stc			; Mark as in error
OMF_PUBDEF_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_PUBDEF endp 		; End OMF_PUBDEF procedure
	 NPPROC  SETUP_BASE -- Setup Base Group And Segments
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Setup base group and segments for PUBDEF & LINNUM records.

On entry:

ESI	 =	 LA of input stream

On exit:

ESI	 =	 next byte after last byte read from input stream

CF	 =	 0 if successful
	 =	 1 if not

|

SETUP_BASE_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
SETUP_BASE_$IWF dd ?		; Value for $IW?_xxxx variable
SETUP_BASE_IWF_FLAG dd ?	; Value of IW?_FLAG
SETUP_BASE_IWF_ACT dd ? 	; Offset in PGROUP of action routine
SETUP_BASE_FLAG dd ?		; Flag:  0 = PUBDEF, 1 = LINNUM

SETUP_BASE_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax>		; Save registers

; Get and save the base group index

	 mov	 BASE_GRP,0	; Assume no index

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 short SETUP_BASE_XGRP ; Jump if no index (EAX=-1)

	 imul	 eax,type GRPDEF_STR ; Convert to index for GRPDEF_STRs
	 add	 eax,LMB_GRPDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	 UNCURB  eax,GRPDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].GRPDEF_PPERGRP ; Get LA of PERGRP_STR
	 mov	 BASE_GRP,eax	; Save for later use
SETUP_BASE_XGRP:

; Get and save the base segment index and the old segment length

	 mov	 BASE_OLDLEN,0	; Clear it in case no segment (i.e., abs symbol)
	 mov	 BASE_SEG,0	; Assume no index

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 short SETUP_BASE_XSEG ; Jump if no index (EAX=-1)

	 imul	 eax,type SEGDEF_STR ; Convert to index for SEGDEF_STRs
	 add	 eax,LMB_SEGDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	 UNCURB  eax,SEGDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].SEGDEF_PPERSEG ; Get LA of PERSEG_STR
	 mov	 BASE_SEG,eax	; Save for later use

	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_OLDLEN ; Get old length before adding
				; in the length of this segment to get current offset
	 mov	 BASE_OLDLEN,eax ; Save for later use
SETUP_BASE_XSEG:
	 cmp	 [ebp].SETUP_BASE_FLAG,0 ; Izit PUBDEF?
	 jne	 short @F	; Jump if not (no base frame to skip over)

; If the group and segment indices are both missing, there's no base frame

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	 or	 eax,BASE_GRP	; Include LA of base group (PERGRP_STR)
	 jnz	 short @F	; Jump if base frame not present

	 add	 esi,2		; Ignore and skip over the base frame
@@:

; If the base group and segment are both present, ensure that the
; segment is contained in the group

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	 and	 eax,BASE_GRP	; Include LA of base group (PERGRP_STR)
	 jz	 short SETUP_BASE_XPRES ; Jump if not both present

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group symbol (SYM_STR)

	 and	 eax,eax	; Izit in a group?
	 jz	 short @F	; Jump if not

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].SYM_PERITEM ; Get LA of group (PERGRP_STR)

	 cmp	 eax,BASE_GRP	; Izit the same?
	 je	 short SETUP_BASE_XPRES ; Jump if so
@@:

; If this group is FLAT (and we're creating a VxD *FIXME*), ignore test

	 mov	 eax,BASE_GRP	; Get LA of base group (PERGRP_STR)
	 UNCURB  eax,PERGRP	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of symbol (SYM_STR)

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[eax].SYM_FLAG,@SYMFL_FLAT ; Izit FLAT?
	 jnz	 short SETUP_BASE_XPRES ; Jump if so

	 push	 [ebp].SETUP_BASE_IWF_ACT ; Pass offset of action routine
	 push	 [ebp].SETUP_BASE_IWF_FLAG ; Pass value of flags
	 push	 [ebp].SETUP_BASE_$IWF ; Pass offset of bit mask
	 call	 IWF_TEST	; Test for differing group names
	 jc	 near ptr SETUP_BASE_EXIT ; Jump if it's fatal (note CF=1)
SETUP_BASE_XPRES:

; If the group is not present, but the segment is contained in a group
; use that group.

	 cmp	 BASE_GRP,0	; Izit present?
	 jne	 short SETUP_BASE_GRPOK ; Jump if so

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)

	 cmp	 eax,0		; Izit present?
	 je	 short SETUP_BASE_GRPOK ; Jump if not

	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group symbol (SYM_STR)

	 cmp	 eax,0		; Izit in a group?
	 je	 short SETUP_BASE_GRPOK ; Jump if not

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].SYM_PERITEM ; Get LA of group (PERGRP_STR)

	 mov	 BASE_GRP,eax	; Save for later use
SETUP_BASE_GRPOK:
	 clc			; Mark as successful
SETUP_BASE_EXIT:
	 REGREST <eax>		; Restore

	 pop	 ebp		; Restore

	 ret	 4*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_BASE endp 		; End SETUP_BASE procedure
	 NPPROC  IWF_PUBDIF -- Ignore/Warn/Fail About PUBDEF Segment Not In Group
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about PUBDEF segment not contained in group.

On entry:

BASE_SEG =	 LA of base segment (PERSEG_STR)
BASE_GRP =	 ...	    group   (PERGRP_STR)
ESI	 =	 LA of NXT_PUBDEF_STR

On exit:

|

	 pushad 		; Save registers

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_PUBDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the symbol name

	 push	 esi		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_PUBDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the segment name

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_PUBDIF2) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the group name

	 mov	 eax,BASE_GRP	; Get LA of base group (PERGRP_STR)
	 UNCURB  eax,PERGRP	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of group symbol (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 dword ptr (offset DGROUP:MSG_PUBDIF3) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_PUBDIF4) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_PUBDIF endp 		; End IWF_PUBDIF procedure
	 NPPROC  OMF_LINNUM -- Line Numbers Record
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Line numbers record (94h/95h).

On entry:

DS:ESI	 ==>	 OBJHDR_STR

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

; Setup loop variables to copy the Line #s and offsets to the work area
; and save an entry for it in the LINNUM table

	 add	 esi,type OBJHDR_STR ; Skip over the header

	 push	 1		; Mark as LINNUM
	 push	 dword ptr (offset PGROUP:IWF_LINDIF) ; Pass offset of action routine
	 push	 IW2_FLAG	; Pass value of flags
	 push	 $IW2_LINDIF	; Pass offset of bit mask
	 call	 SETUP_BASE	; Setup base group and segs for PUBDEF/LINNUM
	 jc	 near ptr OMF_LINNUM_EXIT ; Jump if something went wrong

	 mov	 edi,LMB_LINNUM.LMB_CURB.BOUND_NXT ; Get LA of next entry
OMF_LINNUM_NEXT:

; Zero the LINNUM struc

.errnz (4-1) and (type LINNUM_STR)
	 mov	 ecx,(type LINNUM_STR)/4 ; # dwords to zero
	 xor	 eax,eax	; Set to this
;;;;;;;; mov	 edi,LMB_LINNUM.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 mov	 edx,edi	; Save starting offset of LINNUM_STR

	 UNOVRB  edi,LINNUM	; Ensure within overall bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the struc
	 mov	 LMB_LINNUM.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 UNCURB  edx,LINNUM	; Ensure within current bounds
	 mov	 AGROUP:[edx].LINNUM_PPEROBJ,eax ; Save for later use

	 mov	 eax,BASE_GRP	; Get LA of base group (PERGRP_STR)
;;;;;;;; UNCURB  edx,LINNUM	; Ensure within current bounds
	 mov	 AGROUP:[edx].LINNUM_PPERGRP,eax ; Save for later use

	 mov	 eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
;;;;;;;; UNCURB  edx,LINNUM	; Ensure within current bounds
	 mov	 AGROUP:[edx].LINNUM_PPERSEG,eax ; Save for later use

; Get the line number

	 xor	 eax,eax	; Zero to use as dword
	 lods	 ds:[esi].ELO	; Get next word

	 UNCURB  edx,LINNUM	; Ensure within current bounds
	 mov	 AGROUP:[edx].LINNUM_LINNUM,eax ; Save as line #

; Get and save the offset

	 call	 GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	 add	 eax,BASE_OLDLEN ; Plus old segment length
	 UNCURB  edx,LINNUM	; Ensure within current bounds
	 mov	 AGROUP:[edx].LINNUM_NUMOFF,eax ; Save as line # offset

	 cmp	 esi,THISOBJ_CSUM ; Are we at the end of the record?
	 jb	 near ptr OMF_LINNUM_NEXT ; Jump if more names to check

	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
OMF_LINNUM_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_LINNUM endp 		; End OMF_LINNUM procedure
	NPPROC	IWF_LINDIF -- Ignore/Warn/Fail About LINNUM Segment Not In Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about LINNUM segment not contained in group.

On entry:

BASE_SEG =	 LA of base segment (PERSEG_STR)
BASE_GRP =	 ...	    group   (PERGRP_STR)

On exit:

|

	pushad			; Save registers

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_LINDIF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the segment name

	mov	eax,BASE_SEG	; Get LA of base segment (PERSEG_STR)
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_LINDIF1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the group name

	mov	eax,BASE_GRP	; Get LA of base group (PERGRP_STR)
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of group symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	dword ptr (offset DGROUP:MSG_LINDIF2) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_LINDIF3) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_LINDIF endp 		; End IWF_LINDIF procedure
	NPPROC	OMF_LNAMES -- List Of Names Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

List of names record (96h).
Local logical names definition record (CAh).

On entry:

DS:ESI	==>	OBJHDR_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

NXT_LNAMES_STR struc

NXT_LNAMES_LEN db ?		; Length in bytes of NXT_LNAMES_FID
NXT_LNAMES_FID db ?		; Module filename

NXT_LNAMES_STR ends

	pushad			; Save registers

; Setup loop variables to copy the names to the small text strings area
; and save an entry for it in the LNAMES table

	add	esi,type OBJHDR_STR ; Skip over the header

	mov	edi,LMB_TXTSTR.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	ebx,LMB_LNAMES.LMB_CURB.BOUND_NXT ; ...
OMF_LNAMES_NEXT:

; Zero the LNAMES struc

	mov	edx,ebx 	; Save starting offset of LNAMES_STR
	xchg	ebx,edi 	; Swap for STOS
.errnz (4-1) and (type LNAMES_STR)
	mov	ecx,(type LNAMES_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	UNOVRB	edi,LNAMES	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	xchg	ebx,edi 	; Swap back

; Fill in non-zero items in LNAMES_STR

	UNOVRB	edx,LNAMES	; Ensure within overall bounds
	mov	AGROUP:[edx].LNAMES_PTXT,edi ; Save as pointer to text

	cmp	OMFTYP,@OMF_LNAMES ; Izit logical names record?
	sete	al		; Mark as global (=1), local (=0) name
	stos	AGROUP:[edi].LO ; Save in small text string

; Copy the (Count, Char[]) pair as small text string

	movzx	ecx,ds:[esi].NXT_LNAMES_LEN ; Get the byte length
	inc	ecx		; Count in the length byte
	 
	UNOVRB	edi,TXTSTR	; Ensure within overall bounds
	call	CopyCountChar	; Copy it

	cmp	esi,THISOBJ_CSUM ; Are we at the end of the record?
	jb	short OMF_LNAMES_NEXT ; Jump if more names to check

	mov	LMB_LNAMES.LMB_CURB.BOUND_NXT,ebx ; Save LA of next entry
	mov	LMB_TXTSTR.LMB_CURB.BOUND_NXT,edi ; ...

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_LNAMES endp 		; End OMF_LNAMES procedure
	NPPROC	OMF_SEGDEF -- Segment Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Segment definition record (98h/99h).

On entry:

DS:ESI	==>	OMF_SEGDEF_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

OMF_SEGDEF_STR struc

	db	(size OBJHDR_STR) dup () ; .OBJ header
OMF_SEGDEF_ACBP db ?		; ACBP byte
OMF_SEGDEF_NXT db ?		; Next entries depend upon the ACBP byte

OMF_SEGDEF_STR ends


OMF_SEGDEF_A0_STR struc

OMF_SEGDEF_A0_FRM dw ?		; Frame #
OMF_SEGDEF_A0_OFF db ?		; Offset

OMF_SEGDEF_A0_STR ends

	pushad			; Save registers

	add	esi,type OBJHDR_STR ; Skip over the header

	lods	(type OMF_SEGDEF_ACBP) ptr ds:[esi] ; Get ACBP byte
	mov	ACBP,al 	; Save for later use

; Translate Combine types to canonical values

;;;;;;; mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_C	; Isolate combine types
	shr	al,$ACBP_C	; Shift to low-order

	lea	ebx,SEGDEF_C_XLAT ; Get offset of translate table
	xlat	SEGDEF_C_XLAT[ebx] ; Translate the byte

	cmp	al,-1		; Izit invalid?
	jne	short @F	; Jump if not

	push	dword ptr (offset PGROUP:IWF_CTYPINV) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_CTYPINV	; Pass offset of bit mask
	call	IWF_TEST	; Test for invalid combine types
	jc	near ptr OMF_SEGDEF_EXIT ; Jump if it's fatal (note CF=1)

	mov	al,@ACBP_C_PRIVATE ; Mark as private
@@:
	shl	al,$ACBP_C	; Shift to normal place
	and	ACBP,not @ACBP_C ; Zero existing entries
	or	ACBP,al 	; Include translated entries

; Check for invalid alignments

	mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_A	; Isolate alignment types

	cmp	al,@ACBP_A	; Check for all 1s
	jne	short @F	; Jump if it's valid

	push	dword ptr (offset PGROUP:IWF_ALININV) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_ALININV	; Pass offset of bit mask
	call	IWF_TEST	; Test for invalid alignment types
	jc	near ptr OMF_SEGDEF_EXIT ; Jump if it's fatal (note CF=1)

	and	ACBP,not @ACBP_A ; Clear the alignment bits
	or	ACBP,@ACBP_A_BYTE shl $ACBP_A ; Mark as relocatable byte-aligned
@@:

; If the alignment type is Absolute, save the frame # and offset fields

	mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_A	; Isolate alignment types

	cmp	al,@ACBP_A_ABS	; Izit absolute?
	jne	short @F	; Jump if not

	xor	eax,eax 	; Zero to use as dword
	lods	(type OMF_SEGDEF_A0_FRM) ptr ds:[esi] ; Get the frame #
	shl	eax,4-0 	; Convert from paras to bytes
	mov	SEGDEF_FRM,eax	; Save as frame # (in bytes)

	xor	eax,eax 	; Zero to use as dword
	lods	(type OMF_SEGDEF_A0_OFF) ptr ds:[esi] ; Get the offset
	add	SEGDEF_FRM,eax	; Add into frame # (in bytes)
@@:

; Get the segment length

	call	GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	test	ACBP,@ACBP_B	; Izit a Big segment?
	jz	short @F	; Jump if not

	mov	eax,@CON64KB	; Use size of 64KB (USE32 caught below)

	cmp	DEF32,1 	; Izit a 32-bit record?
	jne	short @F	; Jump if not

	xor	eax,eax 	; Mark as 4GB record *FIXME*
@@:
	mov	SEGDEF_LEN,eax	; Save for later use

; Form a single name with Segment-Class-CombineType for table lookup

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

; DS:ESI ==> segment name index
; ES:EDI ==> work area

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	jc	short @F	; Jump if no index

; Lookup the name in LMB_LNAMES

	imul	eax,type LNAMES_STR ; Convert to index for LNAMES_STRs
	add	eax,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Plus starting address

	UNCURB	eax,LNAMES	; Ensure within current bounds
	mov	eax,AGROUP:[eax].LNAMES_PTXT ; Get LA of (type, text)
	inc	eax		; Skip over the type (global/local) byte
				; to text (Count, Char[])
	push	eax		; Pass LA of text (Count, Char[])
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated
@@:

; DS:ESI ==> class name index
; ES:EDI ==> work area

	mov	SEGDEF_CLS,0	; Assume no class name

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	jc	short @F	; Jump if no index

; Lookup the name in LMB_LNAMES

	imul	eax,type LNAMES_STR ; Convert to index for LNAMES_STRs
	add	eax,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Plus starting address
	mov	SEGDEF_CLS,eax	; Save LA of LNAMES_STR for class name

	UNCURB	eax,LNAMES	; Ensure within current bounds
	mov	eax,AGROUP:[eax].LNAMES_PTXT ; Get LA of (type, text)
	inc	eax		; Skip over the type (global/local) byte
				; to text (Count, Char[])
	push	eax		; Pass LA of text (Count, Char[])
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated
@@:
	mov	SYMCASE_END,edi  ; Save as offset of last name

; If the alignment is absolute, zap the class

	mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_A	; Isolate alignment types

	cmp	al,@ACBP_A_ABS	; Izit absolute?
	jne	short @F	; Jump if not

	mov	SEGDEF_CLS,-1	; Zap it so PROC_SEGS is simpler
@@:

; ES:EDI ==> work area

	mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_C	; Isolate the combine types
	stos	es:[edi].LO	; Save in the work area

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	movzx	eax,ACBP	; Get the incoming ACBP byte
	or	eax,@SYMFL_CL_SEG or @SYMFL_SEG ; Mark as segment class
	mov	WORKAREA_SYM.SYM_FLAG,eax ; Save as flags

; Lookup this Segment-Class-CombineType in the symbol table

	mov	al,ACBP 	; Get the icoming ACBP byte
	and	al,@ACBP_A	; Isolate the alignment bits
	shr	al,$ACBP_A	; Shift to low-order

	cmp	al,@ACBP_A_ABS	; If alignment type is absolute, ignore combine type
	je	short @F	; Jump if so

	mov	al,ACBP 	; Get the icoming ACBP byte
	and	al,@ACBP_C	; Isolate the alignment bits
	shr	al,$ACBP_C	; Shift to low-order

	cmp	al,@ACBP_C_PRIVATE ; If combine type is private, append it
	je	near ptr OMF_SEGDEF_NEW ; Jump if it's private
@@:

; See if this entry already exists in the symbol table

	push	esi		; Save for a moment
	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	pop	esi		; Restore
	jc	near ptr OMF_SEGDEF_NEW ; Jump if not already in the table

; Check the existing entry at AGROUP:EBX

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edx,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG_STR in case temp

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	btr	AGROUP:[ebx].SYM_FLAG,$SYMFL_TEMP ; Wuzit temp?
	jc	near ptr OMF_SEGDEF_SORTANEW ; Jump if so (call it sorta new)

; Ensure we don't mix USE16 and USE32 segments

	mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_P	; Isolate the USExx type
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	ah,AGROUP:[ebx].SYM_FLAG.LO ; Get the existing ACBP byte
	and	ah,@ACBP_P	; Isolate the USExx type

	cmp	al,ah		; Izit the same?
	je	short @F	; Jump if so

	push	dword ptr (offset PGROUP:IWF_USEDIF) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_USEDIF	; Pass offset of bit mask
	call	IWF_TEST	; Test for differing USExx attrs
	jc	near ptr OMF_SEGDEF_EXIT ; Jump if it's fatal (note CF=1)

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_P ; Mark as USE32
@@:

; Ensure the alignments are the same

	mov	al,ACBP 	; Get the incoming ACBP byte
	and	al,@ACBP_A	; Isolate the alignment type
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	ah,AGROUP:[ebx].SYM_FLAG.LO ; Get the existing ACBP byte
	and	ah,@SYMFL_A	; Isolate the alignment type

	cmp	al,ah		; Izit the same?
	je	short OMF_SEGDEF_ALINDONE ; Jump if so

	push	dword ptr (offset PGROUP:IWF_ALINDIF) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_ALINDIF	; Pass offset of bit mask
	call	IWF_TEST	; Test for differing segment alignments
	jc	near ptr OMF_SEGDEF_EXIT ; Jump if it's fatal (note CF=1)
;;;
;;; ; Use the wider segment alignment type
;;;
;;;	    movzx   ecx,al	    ; Get incoming alignment
;;;	    shr     ecx,$ACBP_A     ; Shift to low-order
;;;	    mov     ecx,ALINWID[ecx*(type ALINWID)] ; Get the width
;;;
;;;	    movzx   edx,ah	    ; Get existing alignment
;;;	    shr     edx,$ACBP_A     ; Shift to low-order
;;;	    mov     edx,ALINWID[edx*(type ALINWID)] ; Get the width
;;;
;;;	    cmp     ecx,edx	    ; Use the wider
;;;	    jbe     short OMF_SEGDEF_ALINDONE ; Jump if existing is no smaller
;;;
;;; ;;;;;;; UNCURB  ebx,SYMBOL	    ; Ensure within current bounds
;;;	    and     AGROUP:[ebx].SYM_FLAG.LO,not @SYMFL_A ; Zero alignment
;;;	    or	    AGROUP:[ebx].SYM_FLAG.LO,al ; Use incoming alignment
OMF_SEGDEF_ALINDONE:

; Add in the incoming segment length unless it's Common in which
; case use the larger of the two.

	mov	eax,SEGDEF_LEN	; Get the incoming segment length
;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edx,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG strucs

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	cl,AGROUP:[ebx].SYM_FLAG.LO ; Get the existing ACBP byte
	and	cl,@SYMFL_C	; Isolate the combine type
	shr	cl,$SYMFL_C	; Shift to low-order

	cmp	cl,@ACBP_C_COMMON ; Izit Common combine type?
	je	short OMF_SEGDEF_COMTYP ; Jump if so

; If this segment is Absolute, don't accumulate lengths

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	cl,AGROUP:[ebx].SYM_FLAG.LO ; Get the existing ACBP byte
	and	cl,@SYMFL_A	; Isolate the alignment type
	shr	cl,$SYMFL_A	; Shift to low-order

	cmp	cl,@ACBP_A_ABS	; Izit Absolute alignment?
	je	short OMF_SEGDEF_COMTYP ; Jump if so

COMMENT|

The test below was originally put in to avoid rounding up the last
non-empty segment in a group to that group's alignment, in favor of
using the alignment of the first segment in the next group.  I took it
out because I'm not sure it's a good idea anymore.  At least SWAT
links differently with this test left in.

|

;;;;;;; mov	eax,SEGDEF_LEN	; Get the incoming segment length
;;;;;;;
;;;;;;; cmp	eax,0		; Izit empty?
;;;;;;; je	short @F	; Jump if so (skip alignment checks)

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
;;;;;;; push	AGROUP:[ebx].SYM_FLAG ; Pass the fags w/ACBP byte in low-order
	push	ACBP.EDD	; Pass the ACBP byte in low-order
	UNCURB	edx,PERSEG	; Ensure within current bounds
	push	AGROUP:[edx].PERSEG_NEWLEN ; Pass the current size
	call	CHECK_ALIGN	; Check alignment
				; Return ECX = new current size
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_OLDLEN,ecx ; Save as old length
	add	eax,ecx 	; Add in the incoming length
	mov	AGROUP:[edx].PERSEG_NEWLEN,eax ; Save as new length
@@:
	jmp	OMF_SEGDEF_COM	; Join common code

OMF_SEGDEF_COMTYP:
	mov	eax,SEGDEF_LEN	; Get the incoming segment length

	UNCURB	edx,PERSEG	; Ensure within current bounds
	cmp	eax,AGROUP:[edx].PERSEG_NEWLEN ; Is the incoming segment larger?
	jb	short @F	; Jump if not

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_NEWLEN,eax ; Use the incoming segment size
@@:
	jmp	OMF_SEGDEF_COM	; Join common code

OMF_SEGDEF_NEW:
	push	esi		; Save for a moment
	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
	pop	esi		; Restore
	jc	near ptr OMF_SEGDEF_APPND ; Jump if something went wrong

	push	0		; Mark as normal segment
	call	SETUP_NEWSEG	; Setup a new segment
	jc	near ptr OMF_SEGDEF_EXIT ; Jump if something went wrong (note CF=1)

	mov	edx,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	edx,type PERSEG_STR ; Back off to previous struc

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_FLAG,@PERSEG_OTHGRP ; Assume not in DGROUP
OMF_SEGDEF_SORTANEW:
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,edx ; Save in symbol table

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_SEGSYM,ebx ; Save as ptr to SYM_STR

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_PPEROBJ,eax ; Save LA of this .OBJ file

	call	FC_SEGDEF	; Search/append this class to symbol table
				; using EDX as PERSEG_STR and SEGDEF_CLS as
				; LNAMES_STR
; If this segment has stack combine type, save its PERSEG_STR for later use
; unless there is already a segment with stack combine type

	mov	al,ACBP 	; Get the icoming ACBP byte
	and	al,@ACBP_C	; Isolate the alignment bits
	shr	al,$ACBP_C	; Shift to low-order

	cmp	al,@ACBP_C_STACK ; Izit combine type stack?
	jne	short @F	; Jump if not

	cmp	STACK_PPERSEG,0 ; Izit still undefined?
	jne	short @F	; Jump if not

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG strucs
	mov	STACK_PPERSEG,eax ; Save for later use
@@:
OMF_SEGDEF_COM:

; Save LA of PERSEG table in SEGDEF table

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG strucs
	mov	edi,LMB_SEGDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	UNOVRB	edi,SEGDEF	; Ensure within overall bounds
	stos	(type SEGDEF_PPERSEG) ptr AGROUP:[edi] ; Save in SEGDEF table
	mov	LMB_SEGDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; If this is a 32-bit segment, note that for later use (.MAP file display)

	test	ACBP,@ACBP_P	; Izit a 32-bit segment?
	jz	short @F	; Jump if not

	or	LCL_FLAG,@LCL_SEG32 ; Mark it as such
@@:

; If this segment is absolute, save its frame #

;;;;;;; UNCURB	ebx,SYMBOL     ; Ensure within current bounds
	mov	cl,AGROUP:[ebx].SYM_FLAG.LO ; Get the existing ACBP byte
	and	cl,@SYMFL_A	; Isolate the alignment type
	shr	cl,$SYMFL_A	; Shift to low-order

	cmp	cl,@ACBP_A_ABS	; Izit Absolute alignment?
	jne	short @F	; Jump if not

	mov	eax,SEGDEF_FRM	; Get the frame #
;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_ADRB.BOUND_BEG,eax ; Save as starting address
	dec	eax		; Less one to get limit
	mov	AGROUP:[edx].PERSEG_ADRB.BOUND_NXT,eax ; ...	 ending   ...
@@:

; DS:ESI ==> overlay name index
; Skip over Overlay Name Index

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Ignore if no index (EAX=-1) -- *FIXME*

; If the user has specified /MAP:FULL, save info about this segment
; piece in LMB_SEGOBJ

	push	edx		; Pass LA of segment (PERSEG_STR)
	call	LINK_SEGOBJ	; Link in this segment

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	jmp	short OMF_SEGDEF_EXIT ; Join common exit code


OMF_SEGDEF_APPND:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	call	DUMPIT		; Dump all the tables

	stc			; Mark as in error
OMF_SEGDEF_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_SEGDEF endp 		; End OMF_SEGDEF procedure
	NPPROC	LINK_SEGOBJ -- Link Into SEGOBJ Chain
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

If the user has specified /MAP:FULL, save info about this segment
piece in LMB_SEGOBJ

On entry:

EDX	=	LA of segment (PERSEG_STR)

|

LINK_SEGOBJ_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
LINK_SEGOBJ_PPERSEG dd ?	; LA of segment (PERSEG_STR)

LINK_SEGOBJ_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushad 		; Save registers

	 test	 ARG_FLAG,@ARG_MAPFULL ; Izit /MAP:FULL?
	 jz	 short LINK_SEGOBJ_EXIT ; Jump if not

	 mov	 edx,[ebp].LINK_SEGOBJ_PPERSEG ; Get LA of segment (PERSEG_STR)

	 mov	 ebx,LMB_SEGOBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 add	 LMB_SEGOBJ.LMB_CURB.BOUND_NXT,type SEGOBJ_STR ; Skip to next entry

	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 cmp	 AGROUP:[edx].PERSEG_SEGLST,0 ; Izit uninitialized?
	 jne	 short @F	; Jump if not

;;;;;;;; UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edx].PERSEG_SEG1ST,ebx ; Mark as 1st entry
	 mov	 AGROUP:[edx].PERSEG_SEGLST,ebx ; ...	  last ...
@@:

; Link this entry into the chain

	 mov	 ecx,ebx	; Copy current LA
;;;;;;;; UNCURB  edx,PERSEG	; Ensure within current bounds
	 xchg	 ecx,AGROUP:[edx].PERSEG_SEGLST ; Swap with previous link

	 mov	 eax,ebx	; Copy current LA
	 UNCURB  ecx,SEGOBJ	; Ensure within current bounds
	 xchg	 eax,AGROUP:[ecx].SEGOBJ_NXT ; Save as ptr to next link
	 UNCURB  ebx,SEGOBJ	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SEGOBJ_NXT,-1 ; Mark as last in the chain

;;;;;;;; UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[edx].PERSEG_OLDLEN ; Get length before appending
				; this segment
	 UNCURB  ebx,SEGOBJ	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SEGOBJ_OFF,eax ; Save as offset of this piece

	 mov	 eax,SEGDEF_LEN ; Get the incoming segment length
;;;;;;;; UNCURB  ebx,SEGOBJ	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SEGOBJ_SIZ,eax ; Save as size of this piece

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous struc
	 mov	 AGROUP:[ebx].SEGOBJ_PPEROBJ,eax ; Save as LA of .OBJ (PEROBJ_STR)
LINK_SEGOBJ_EXIT:
	 popad			; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINK_SEGOBJ endp		 ; End LINK_SEGOBJ procedure
	 NPPROC  FC_SEGDEF -- Find Class Name Symbol In OMF_SEGDEF
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find a class name symbol

On entry:

EDX	 =	 LA of segment (PERSEG_STR)
SEGDEF_CLS =	 LA of LNAMES_STR with class name (0=none, -1=absolute)

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ebx,ecx>	; Save registers

	 mov	 ebx,SEGDEF_CLS ; Get LA of LNAMES_STR for class name

	 cmp	 ebx,0		; Izit invalid?
	 je	 short FC_SEGDEF_DONE ; Jump if so

	 cmp	 ebx,-1 	; Izit invalid?
	 je	 short FC_SEGDEF_DONE ; Jump if so

	 mov	 eax,ebx	; Copy for later use
	 UNCURB  eax,LNAMES	; Ensure within current bounds
	 mov	 ebx,AGROUP:[eax].LNAMES_PSYM ; Get LA of symbol (SYM_STR)

	 and	 ebx,ebx	; Is there already a valid symbol?
	 jnz	 short FC_SEGDEF_DONE ; Jump if so

; If this segment has no class, don't look for it as later on we depend
; upon finding a zero in PERSEG_CLSSYM for unclassed segments

;;;;;;;; UNCURB  eax,LNAMES	; Ensure within current bounds
	 mov	 ecx,AGROUP:[eax].LNAMES_PTXT ; Get LA of (type, text)
	 inc	 ecx		; Skip over type (global/local) byte
				; to text (Count, Char[])
	 cmp	 AGROUP:[ecx].LO,0 ; Izit empty?
	 je	 short FC_SEGDEF_DONE ; Jump if so

	 push	 ecx		; Pass LA of text (Count, Char[])
	 call	 FIND_CLASS	; Find class name symbol
				; Return AGROUP:EBX = new entry (SYM_STR)
	 jc	 short FC_SEGDEF_EXIT ; Jump if we failed???

	 UNCURB  eax,LNAMES	; Ensure within current bounds
	 mov	 AGROUP:[eax].LNAMES_PSYM,ebx ; Save LA of symbol (SYM_STR)
FC_SEGDEF_DONE:
	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edx].PERSEG_CLSSYM,ebx ; Save LA of class symbol (SYM_STR)
				; (0=none, -1=skip)
; Set flags (PERSEG_FLAG) for the class and segment name

	 push	 edx		; Pass LA of segment (PERSEG_STR)
	 push	 ebx		; Pass LA of class symbol (SYM_STR)
	 call	 FLAG_CLASS	; Set flags for class and segment name

	 clc			; Mark as successful
FC_SEGDEF_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FC_SEGDEF endp			; End FC_SEGDEF procedure
	 NPPROC  FIND_CLASS -- Find Class Name Symbol
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find a class name symbol

On exit:

EBX	 =	 LA of class name symbol (SYM_STR) (0=none)
CF	 =	 0 if successful
	 =	 1 if not

|

FIND_CLASS_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
FIND_CLASS_PTXT dd ?		; LA of text (Count, Char[])

FIND_CLASS_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 @LOOKUP_APP	; Append if not found
	 push	 [ebp].FIND_CLASS_PTXT ; Pass LA of text (Count, Char[])
	 push	 @SYMFL_CL_CLS or @SYMFL_CLS ; Mark as class class
	 call	 LOOKUP_SYM	; Lookup the symbol
				; Return EBX = LA of matching entry (SYM_STR)
	 jnc	 short FIND_CLASS_EXIT ; Jump if it's in the table (note CF=0)

	 mov	 ebx,0		; This name has no class (note CF=1)
FIND_CLASS_EXIT:
	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_CLASS endp 		; End FIND_CLASS procedure
	NPPROC	FLAG_CLASS -- Set Flags For Class And Segment Name
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Set flags for a class and segment name

|

FLAG_CLASS_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FLAG_CLASS_PSYM dd ?		; LA of class symbol (SYM_STR)
				; (0=none, -1=skip)
FLAG_CLASS_PPERSEG dd ? 	; LA of segment (PERSEG_STR)

FLAG_CLASS_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers

	mov	ebx,[ebp].FLAG_CLASS_PSYM ; Get LA of symbol (SYM_STR)
	mov	edx,[ebp].FLAG_CLASS_PPERSEG ; Get LA of segment (PERSEG_STR)

	cmp	ebx,0		; Izit invalid?
	je	near ptr FLAG_CLASS_EXIT ; Jump if so

	cmp	ebx,-1		; Izit invalid?
	je	near ptr FLAG_CLASS_EXIT ; Jump if so

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PNAM ; Get LA of text (Count, Char[])
	UNCURB	edi,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[edi].LO ; Get length in bytes
	inc	ecx		; Count in the length byte

; See if it ends in 'CODE'

	REGSAVE <ecx,edi>	; Save for a moment

	cmp	ecx,1+4 	; Izit at or above minimum length?
	jb	short @F	; Jump if not

	add	edi,ecx 	; Skip to next char
	mov	ecx,4		; Get length of 'CODE'
	sub	edi,ecx 	; Back up to 'CODE' if it's there

	lea	esi,TXT_CODE[1] ; Get offset in DGROUP of 'CODE',
				; skipping the length byte
	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT_CODE[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

	UNCURB	edx,PERSEG	; Ensure within current bounds
	or	AGROUP:[edx].PERSEG_FLAG,@PERSEG_SUFCODE ; Mark as present
@@:
	REGREST <edi,ecx>	; Restore

; See if it's class 'BEGDATA'

;;;;;;; REGSAVE <ecx,edi>	; Save for a moment
;;;;;;;
	lea	esi,TXT_BEGDATA ; Get offset in DGROUP of 'BEGDATA'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT_BEGDATA[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

	UNCURB	edx,PERSEG	; Ensure within current bounds
	or	AGROUP:[edx].PERSEG_FLAG,@PERSEG_BEGDATA ; Mark as present
@@:
;;;;;;; REGREST <edi,ecx>	; Restore

; See if it's class 'BSS'

;;;;;;; REGSAVE <ecx,edi>	; Save for a moment
;;;;;;;
	lea	esi,TXT_BSS	; Get offset in DGROUP of 'BSS'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT_BSS[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

	UNCURB	edx,PERSEG	; Ensure within current bounds
	or	AGROUP:[edx].PERSEG_FLAG,@PERSEG_BSS ; Mark as present
@@:
;;;;;;; REGREST <edi,ecx>	; Restore

; See if it's class 'STACK'

;;;;;;; REGSAVE <ecx,edi>	; Save for a moment
;;;;;;;
	lea	esi,TXT_STACK	; Get offset in DGROUP of 'STACK'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT_STACK[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

	UNCURB	edx,PERSEG	; Ensure within current bounds
	or	AGROUP:[edx].PERSEG_FLAG,@PERSEG_STACK ; Mark as present
@@:
;;;;;;; REGREST <edi,ecx>	; Restore

; Set "other class" flag if none of the above

	UNCURB	edx,PERSEG	; Ensure within current bounds
	test	AGROUP:[edx].PERSEG_FLAG,@PERSEG_ALLCLS ; Izit classed?
	jnz	short @F	; Jump if so

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	or	AGROUP:[edx].PERSEG_FLAG,@PERSEG_OTHCLS ; Mark as present
@@:

; See if it's segment '_TEXT'

	REGSAVE <ecx,edi>	; Save for a moment

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[edx].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[edi].SYM_PNAM ; Get LA of text (Count, Char[])
	UNCURB	edi,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[edi].LO ; Get length in bytes
	inc	ecx		; Count in the length byte

	lea	esi,TXT__TEXT	; Get offset in DGROUP of '_TEXT'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT__TEXT[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	bts	AGROUP:[edx].PERSEG_FLAG,$PERSEG__TEXT ; Mark as present
	jc	short @F	; Jump if not the first time

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	eax,NONULLS_OFF ; Get NONULLS offset
	add	AGROUP:[edx].PERSEG_NEWLEN,eax ; Skip over NULL para
	add	AGROUP:[edx].PERSEG_OLDLEN,eax ; ...
@@:
	REGREST <edi,ecx>	; Restore

; See if it's segment '$$SYMBOLS'

	REGSAVE <ecx,edi>	; Save for a moment

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[edx].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[edi].SYM_PNAM ; Get LA of text (Count, Char[])
	UNCURB	edi,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[edi].LO ; Get length in bytes
	inc	ecx		; Count in the length byte

	lea	esi,SS_SYMBOLS	; Get offset in DGROUP of '$$SYMBOLS'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	SS_SYMBOLS[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	or	AGROUP:[edx].PERSEG_FLAG,@PERSEG_SYMBOLS ; Mark as present
@@:
	REGREST <edi,ecx>	; Restore
FLAG_CLASS_EXIT:
	popad			; Restore

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLAG_CLASS endp 		; End FLAG_CLASS procedure
	NPPROC	SETUP_NEWSEG -- Setup A New Segment
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Setup a new segment

On entry:

SEGDEF_LEN =	length of segment

On exit:

CF	=	0 if successful
	=	1 if not

|

NEWSEG_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
NEWSEG_FLAG dd	?		; Flag:  0 = normal, 1 = MODEND special

NEWSEG_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers

; Zero the fields

.errnz (4-1) and (type PERSEG_STR)
	mov	ecx,(type PERSEG_STR)/4 ; # dwords in struc
	xor	eax,eax 	; Fill with this
	mov	edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Get LA of next entry

	UNOVRB	edi,PERSEG	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the fields

	xchg	edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Save LA of next entry

	mov	eax,@LMB_NEWSEG_LEN ; Get length of normal segment

	cmp	[ebp].NEWSEG_FLAG,0 ; Izit a normal segment?
	je	short @F	; Jump if so

	mov	eax,4		; Get length of MODEND special segment
@@:
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_LEN,eax ; Save new length
	mov	AGROUP:[edi].PERSEG_SEGSEQ,-1 ; Mark as last in sequence

; Allocate an LMB

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[edi].PERSEG_LMB.LMB_LEN ; Allocate this many bytes

	cmp	[ebp].NEWSEG_FLAG,0 ; Izit a normal segment?
	jne	short SETUP_NEWSEG_MODEND ; Jump if not

	xor	ebx,ebx 	; Starting linear address unspecified
	xor	edx,edx 	; Flags:  uncommitted pages
	DPMICALL @DPMI_GETLMB	; Return EBX = linear address
				;	 ESI = handle for memory block
	jc	short SETUP_NEWSEG_ERR ; Join common error code

; Fill in non-zero fields

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_HNDL,esi ; Save for later use
	mov	AGROUP:[edi].PERSEG_LMB.LMB_CURB.BOUND_BEG,ebx ; ...
	mov	AGROUP:[edi].PERSEG_LMB.LMB_CURB.BOUND_NXT,ebx ; ...

; Note that we don't allow the last page of a Linear Memory Block
; to be committed so as to reduce overwriting into the next LMB.

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_OVRB.BOUND_BEG,ebx ; ...
	add	ebx,ecx 	; Plus length of the array
	sub	ebx,@CON4KB+1	; Less 4KB+1 to get ending address
;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_OVRB.BOUND_NXT,ebx ; Save for later use

	mov	eax,SEGDEF_LEN	; Get the incoming segment length
;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_NEWLEN,eax ; Save as new length

	clc			; Mark as successful

	jmp	short SETUP_NEWSEG_EXIT ; Join common exit code

SETUP_NEWSEG_MODEND:

; Fill in non-zero fields

	lea	ebx,EXE_HDR.EXE_IP ; Get offset in DGROUP of fixup location
	add	ebx,LaDATA	; Plus LA of DGROUP

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_HNDL,-1 ; Mark as no handle
	mov	AGROUP:[edi].PERSEG_LMB.LMB_CURB.BOUND_BEG,ebx ; ...
	mov	AGROUP:[edi].PERSEG_LMB.LMB_CURB.BOUND_NXT,ebx ; ...

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_OVRB.BOUND_BEG,ebx ; ...
	add	ebx,ecx 	; Plus length of the array
	dec	ebx		; Less 1 to get ending address
;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_LMB.LMB_OVRB.BOUND_NXT,ebx ; Save for later use

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_NEWLEN,ecx ; Save as new length

	clc			; Mark as successful

	jmp	short SETUP_NEWSEG_EXIT ; Join common exit code


SETUP_NEWSEG_ERR:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJLMB) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJLMB1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	call	DUMPIT		; Dump all the tables

	stc			; Mark as in error
SETUP_NEWSEG_EXIT:
	popad			; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_NEWSEG endp		; End SETUP_NEWSEG procedure
	 NPPROC  SETUP_NEWGRP -- Setup A New Group
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Setup a new group

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

; Zero the fields

.errnz (4-1) and (type PERGRP_STR)
	 mov	 ecx,(type PERGRP_STR)/4 ; # dwords in struc
	 xor	 eax,eax	; Fill with this
	 mov	 edi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Get LA of next entry

	 UNOVRB  edi,PERGRP	; Ensure within overall bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the fields

	 mov	 LMB_PERGRP.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	 clc			; Mark as successful

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_NEWGRP endp		; End SETUP_NEWGRP procedure
	 NPPROC  IWF_GRPINV -- Ignore/Warn/Fail About Invalid Group Component
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about invalid group component.

|

	 push	 dword ptr (offset DGROUP:MSG_GRPINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_GRPINV1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_GRPINV endp 		; End IWF_GRPINV procedure
	 NPPROC  IWF_GRPDIF -- Ignore/Warn/Fail About Differing Group Owners
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about differing group owners.

On entry:

EBX	 =	 LA of group #1 (SYM_STR)
EDX	 =	 LA of segment	(PERSEG_STR)

|

	 pushad 		; Save registers

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the segment name

	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[edx].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display group #1 name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPDIF3) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display group #2 name

	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[edx].PERSEG_GRPSYM ; Get LA of group name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPDIF4) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display group #2's .OBJ filename

	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[edx].PERSEG_GRPOBJ ; Get LA of last .OBJ file
				; which grouped this segment
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 push	 dword ptr (offset DGROUP:MSG_GRPDIF5) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_GRPDIF6) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_GRPDIF endp 		; End IWF_GRPDIF procedure
	 NPPROC  IWF_CTYPINV -- Ignore/Warn/Fail About Differing Combine Types
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about differing combine types.

|

	 push	 dword ptr (offset DGROUP:MSG_CTYPINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_CTYPINV1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_CTYPINV endp		; End IWF_CTYPINV procedure
	 NPPROC  IWF_USEDIF -- Ignore/Warn/Fail About Differing Segment USE Attributes
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about differing segment USE attributes.

On entry:

AL	 =	 incoming segment USE attr
AH	 =	 existing ...
EBX	 =	 LA of segment name (SYM_STR)
SEGDEF_CLS =	 LA of LNAMES_STR with class name (0=none, -1=absolute)

|

	 pushad 		; Save registers

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_USEDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the segment name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_USEDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the class name

	 lea	 eax,TXT_NONE	; Get offset in DGROUP of '<none>'
	 add	 eax,LaDATA	; Plus LA of DGROUP

	 mov	 ebx,SEGDEF_CLS ; Get LA of LNAMES_STR (-1=absolute)

	 cmp	 ebx,-1 	; Izit absolute alignment?
	 je	 short @F	; Jump if so

	 UNCURB  ebx,LNAMES	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].LNAMES_PTXT ; Pass LA of (type, text)
	 inc	 eax		; Skip over type (global/local) byte
				; to text (Count, Char[])
@@:
	 push	 eax		; Pass LA of text (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 dword ptr (offset DGROUP:MSG_USEDIF2) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_USEDIF3) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_USEDIF endp 		; End IWF_USEDIF procedure
	 NPPROC  IWF_ALININV -- Ignore/Warn/Fail About Invalid Segment Alignment
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about invalid segment alignment.

|

	 push	 dword ptr (offset DGROUP:MSG_ALININV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_ALININV1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_ALININV endp		; End IWF_ALININV procedure
	 NPPROC  IWF_ALINDIF -- Ignore/Warn/Fail About Differing Segment Alignments
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about differing segment alignments.

On entry:

AL	 =	 incoming segment alignment
AH	 =	 existing ...
EBX	 =	 LA of segment name (SYM_STR)

|

	 pushad 		; Save registers

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ALINDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the segment name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ALINDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the incoming segment align type

	 movzx	 ecx,al 	; Get incoming alignment
	 shr	 ecx,$ACBP_A	; Shift to low-order bits
	 mov	 ecx,ALINTYP[ecx*(type ALINTYP)] ; Get offset in DGROUP of text
				; in (Count, Char[]) format
	 add	 ecx,LaDATA	; Plus LA of DGROUP
	 push	 ecx		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ALINDIF2) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display incoming .OBJ filename

	 mov	 ecx,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 ecx,type PEROBJ_STR ; Back off to previous entry
	 UNCURB  ecx,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[ecx].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 ecx		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ALINDIF3) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the existing segment align type

	 movzx	 ecx,ah 	; Get existing alignment
	 shr	 ecx,$ACBP_A	; Shift to low-order bits
	 mov	 ecx,ALINTYP[ecx*(type ALINTYP)] ; Get offset in DGROUP of text
				; in (Count, Char[]) format
	 add	 ecx,LaDATA	; Plus LA of DGROUP
	 push	 ecx		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ALINDIF4) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display existing .OBJ filename

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 ecx,AGROUP:[ebx].SYM_PERITEM ; Get LA of segment (PERSEG_STR)
	 UNCURB  ecx,PERSEG	; Ensure within current bounds
	 mov	 ecx,AGROUP:[ecx].PERSEG_PPEROBJ ; Get LA of last .OBJ file
				; which defined this segment
	 UNCURB  ecx,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[ecx].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 ecx		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 push	 dword ptr (offset DGROUP:MSG_ALINDIF5) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_ALINDIF6) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_ALINDIF endp		; End IWF_ALINDIF procedure
	 NPPROC  OMF_GRPDEF -- Group Definition Record
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Group definition record (9Ah).

On entry:

DS:ESI	 ==>	 OBJHDR_STR

1    2	      1 or 2	1    1 or 2
------------------------------------
9A   Reclen   GrpName	FF   SegName
			<-repeated->

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 add	 esi,type OBJHDR_STR ; Skip over the header

; DS:ESI ==> group name index

; Get the group name index

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 near ptr OMF_GRPDEF_GRPNDX ; Jump if it's invalid

; Lookup the name in LMB_LNAMES

	 imul	 eax,type LNAMES_STR ; Convert to index for LNAMES_STRs
	 add	 eax,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Plus starting address

	 push	 0		; Do nothing
	 UNCURB  eax,LNAMES	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].LNAMES_PTXT ; Get LA of (type, text)
	 inc	 eax		; Skip over the type (global/local) byte
				; to text (Count, Char[])
	 push	 eax		; Pass LA of text (Count, Char[])
	 push	 @SYMFL_CL_GRP or @SYMFL_GRP ; Mark as group class
	 call	 LOOKUP_SYM	; Lookup the symbol
				; Return EBX = LA of matching entry (SYM_STR)
				;	 ESI = advanced past text
	 jnc	 short OMF_GRPDEF_COM ; Jump if already in the table

	 push	 esi		; Save for a moment

	 lea	 esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	 add	 esi,LaDATA	; Plus LA of DGROUP
	 call	 SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
	 pop	 esi		; Restore
	 jc	 near ptr OMF_GRPDEF_APPND ; Jump if something went wrong

	 call	 SETUP_NEWGRP	; Setup a new group

	 mov	 eax,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PERGRP_STR ; Back off to previous struc
	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_PERITEM,eax ; Save in symbol table
	 UNCURB  eax,PERGRP	; Ensure within current bounds
	 mov	 AGROUP:[eax].PERGRP_GRPSYM,ebx ; Save as ptr to SYM_STR
OMF_GRPDEF_COM:

; Save LA of PERGRP table in GRPDEF table

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG strucs
	 mov	 edi,LMB_GRPDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 UNOVRB  edi,GRPDEF	; Ensure within overall bounds
	 stos	 (type GRPDEF_PPERGRP) ptr AGROUP:[edi] ; Save in GRPDEF table
	 mov	 LMB_GRPDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; For /DOSSEG purposes, determine whether or not this group is named DGROUP

	REGSAVE <esi,edi>	; Save for a moment

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PNAM ; Get LA of symbol (Count, Char[])
	UNCURB	edi,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[edi].LO ; Get length in bytes
	inc	ecx		; Count in the length byte

	lea	esi,TXT_DGROUP	; Get offset in DGROUP of 'DGROUP'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT_DGROUP[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_DGROUP ; Mark as such
@@:
	REGREST <edi,esi>	; Restore

; For VxD purposes, determine whether or not this group is named FLAT

	REGSAVE <esi,edi>	; Save for a moment

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PNAM ; Get LA of symbol (Count, Char[])
	UNCURB	edi,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[edi].LO ; Get length in bytes
	inc	ecx		; Count in the length byte

	lea	esi,TXT_FLAT	; Get offset in DGROUP of 'FLAT'

	push	es		; Pass ptr #2
	push	edi		; ...
	push	fs		; Pass ptr #1
	push	esi		; ...
	push	ecx		; Pass maximum compare length
	call	StrNICmp	; String compare, length-sensitive, case-insensitive
				; Return with AX == 0 if equal
	and	ax,ax		; Are they equal?
	jnz	short @F	; Jump if not

;; repe cmps	TXT_FLAT[esi],AGROUP:[edi].LO ; Izit the same?
;;;;;;; jne	short @F	; Jump if not

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_FLAT ; Mark as such
@@:
	REGREST <edi,esi>	; Restore

COMMENT|

Trundle through pairs of group component descriptors (0FFh)
and segment definitions.

EBX	 =	 LA of SYM_STR for group name
ESI	 =	 LA of group component descriptor

|

OMF_GRPDEF_NEXT:
	 cmp	 esi,THISOBJ_CSUM ; Are we at the end of the record?
	 jae	 near ptr OMF_GRPDEF_END ; Jump if so

	 lods	 ds:[esi].LO	; Get the FF index

	 cmp	 al,0FFh	; Izit as required?
	 je	 short @F	; Jump if so

	 push	 dword ptr (offset PGROUP:IWF_GRPINV) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_GRPINV	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for invalid group component
	 jc	 near ptr OMF_GRPDEF_EXIT ; Jump if it's fatal (note CF=1)
@@:

; Get the segment name index

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 near ptr OMF_GRPDEF_SEGNDX ; Jump if it's invalid

; Lookup the name in LMB_SEGDEF

	 imul	 eax,type SEGDEF_STR ; Convert to index for SEGDEF_STRs
	 add	 eax,LMB_SEGDEF.LMB_CURB.BOUND_BEG ; Plus starting address

	 UNCURB  eax,SEGDEF	; Ensure within current bounds
	 mov	 edx,AGROUP:[eax].SEGDEF_PPERSEG ; Get LA of PERSEG_STR entry

; EDX	 =	 LA of PERSEG_STR

	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 cmp	 AGROUP:[edx].PERSEG_GRPSYM,0 ; Izit already in a group?
	 jne	 near ptr OMF_GRPDEF_SEGLINKED ; Jump if it is

;;;;;;;; UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edx].PERSEG_GRPSYM,ebx ; Save LA of group name

; Link this new segment into the group chain

	 mov	 ecx,LMB_GRPDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 ecx,type GRPDEF_STR ; Back off to previous entry

	 UNCURB  ecx,GRPDEF	; Ensure within current bounds
	 mov	 ecx,AGROUP:[ecx].GRPDEF_PPERGRP ; Get LA of PERGRP_STR

	 push	 ecx		; Pass LA of group (PERGRP_STR)
	 push	 edx		; ...	     segment (PERSEG_STR)
	 call	 LINK_GRP	; Link it into the group chain

	 jmp	 short OMF_GRPDEF_DGRCHK ; Check on DGROUP state


OMF_GRPDEF_SEGLINKED:

; Ensure it's the same group

	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 cmp	 ebx,AGROUP:[edx].PERSEG_GRPSYM ; Izit the same group?
	 je	 short @F	; Jump if it is

	 push	 dword ptr (offset PGROUP:IWF_GRPDIF) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_GRPDIF	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for differing group names
	 jc	 near ptr OMF_GRPDEF_EXIT ; Jump if it's fatal (note CF=1)
@@:

; If this is DGROUP, transfer that bit to PERSEG_FLAG

OMF_GRPDEF_DGRCHK:
	 push	 ebx		; Pass LA of group symbol (SYM_STR)
	 push	 edx		; ...	     segment (PERSEG_STR)
	 call	 CHECK_DGROUP	; Check it out

; Save the LA of this .OBJ as the last one which grouped this segment

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edx].PERSEG_GRPOBJ,eax ; Save LA of .OBJ file (PEROBJ_STR)

	 jmp	 OMF_GRPDEF_NEXT ; Go around again


OMF_GRPDEF_END:
	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	 jmp	 short OMF_GRPDEF_EXIT ; Join common exit code

OMF_GRPDEF_GRPNDX:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_GRPNDX) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_GRPNDX1) ; ...

	 jmp	 short OMF_GRPDEF_ERRCOM ; Join common error code

OMF_GRPDEF_SEGNDX:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_SEGNDX) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_SEGNDX1) ; ...

	 jmp	 short OMF_GRPDEF_ERRCOM ; Join common error code

OMF_GRPDEF_APPND:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...

;;;;;;;; jmp	 short OMF_GRPDEF_ERRCOM ; Join common error code

OMF_GRPDEF_ERRCOM:
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 call	 DUMPIT 	; Dump all the tables

	 stc			; Mark as in error
OMF_GRPDEF_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_GRPDEF endp 		; End OMF_GRPDEF procedure
	 NPPROC  CHECK_DGROUP -- Check On DGROUP Status
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check on DGROUP status

|

CHECK_DGROUP_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
CHECK_DGROUP_PPERSEG dd ?	; LA of segment (PERSEG_STR)
CHECK_DGROUP_PSYM dd ?		; LA of group symbol (SYM_STR) (0=none)

CHECK_DGROUP_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,edx>	; Save registers

	 mov	 ebx,[ebp].CHECK_DGROUP_PSYM ; Get LA of group symbol (SYM_STR)
	 mov	 edx,[ebp].CHECK_DGROUP_PPERSEG ; ...	 segment (PERSEG_STR)

	 mov	 eax,@PERSEG_OTHGRP ; Assume it's not DGROUP

	 cmp	 ebx,0		; Izit ungrouped?
	 je	 short @F	; Jump if so

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[ebx].SYM_FLAG,@SYMFL_DGROUP ; Izit DGROUP?
	 jz	 short @F	; Jump if not

	 mov	 eax,@PERSEG_DGROUP ; It's DGROUP
@@:
	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 and	 AGROUP:[edx].PERSEG_FLAG,not @PERSEG_OTHGRP ; Clear other group flag
	 or	 AGROUP:[edx].PERSEG_FLAG,eax ; Mark as DGROUP or not

	 REGREST <edx,ebx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DGROUP endp		; End CHECK_DGROUP procedure
	 NPPROC  LINK_GRP -- Link Segment Into Group Chain
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Link this segment into the group chain

|

LINK_GRP_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
LINK_GRP_PPERSEG dd ?		; LA of segment (PERSEG_STR)
LINK_GRP_PPERGRP dd ?		; LA of group (PERGRP_STR)

LINK_GRP_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx>	; Save registers

	 mov	 ecx,[ebp].LINK_GRP_PPERGRP ; Get LA of group (PERGRP_STR)
	 mov	 edx,[ebp].LINK_GRP_PPERSEG ; ...	segment (PERSEG_STR)

; ECX	 =	 LA of PERGRP_STR
; EDX	 =	 LA of PERSEG_STR

; Note that this linking must be in increasing order of occurrence
; as some aspects of group processing requires this (such as the base
; address of an absolute segment)

	 UNCURB  ecx,PERGRP	; Ensure within current bounds
	 mov	 eax,AGROUP:[ecx].PERGRP_GRPLNK ; Get next link

	 and	 eax,eax	; Izit the last?
	 jz	 short OMF_GRPDEF3 ; Jump if so

	 mov	 ecx,eax	; Get next PERSEG_STR
OMF_GRPDEF1:
	 UNCURB  ecx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[ecx].PERSEG_GRPLNK ; Get next link

	 and	 eax,eax	; Izit the last?
	 jz	 short OMF_GRPDEF2 ; Jump if so

	 mov	 ecx,eax	; Get next PERSEG_STR

	 jmp	 short OMF_GRPDEF1 ; Go around again

OMF_GRPDEF2:
	 UNCURB  ecx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[ecx].PERSEG_GRPLNK,edx ; Save ptr to next link

	 jmp	 short OMF_GRPDEF4 ; Join common code

OMF_GRPDEF3:
	 UNCURB  ecx,PERGRP	; Ensure within current bounds
	 mov	 AGROUP:[ecx].PERGRP_GRPLNK,edx ; Save ptr to next link
OMF_GRPDEF4:
	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edx].PERSEG_GRPLNK,0 ; Mark as last link

	 REGREST <edx,ecx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINK_GRP endp			; End LINK_GRP procedure
	 NPPROC  OMF_FIXUPP -- Fixup Record
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup record (9Ch/9Dh).

1    2	      From RecLen
------------------------------
9C   RecLen   THREAD or FIXUPP
	      <----repeat---->

THREAD subrecord:

<----one byte--->   0-2
1   1	1   3	2
-------------------------
0   D	0   M	T   Index

D:	0 for Target thread, 1 for Frame thread
M:	Method for Frame or Target
	   T0:	SEGDEF index w/displacement
	   T1:	GRPDEF ...   ...
	   T2:	EXTDEF ...   ...
	   T3:	Not supported
	   T4:	SEGDEF index w/o displacement
	   T5:	GRPDEF ...   ...
	   T6:	EXTDEF ...   ...
	   T7:	Invalid

	   F0:	SEGDEF index
	   F1:	GRPDEF ...
	   F2:	EXTDEF ...
	   F3:	Invalid
	   F4:	SEGDEF index of previous LIDATA/LEDATA record
	   F5:	Same as Target's SEGDEF/GRPDEF/EXTDEF
	   F6:	Invalid
	   F7:	Invalid
T:	Thread #
Index:	Present iff Method < 3

FIXUPP subrecord:

2	1	  0-2	  0-2	   0, 2, or 4
-----------------------------------------------
Locat	FixData   Frame   Target   Target
		  Datum   Datum    Displacement

Locat field:
<---two bytes--->
1   1	4     10
-----------------
1   M	Loc   DRO

M:    Mode - 0 for self-relative, 1 for segment-relative fixups
Loc:  Location
	 0:  Low-order byte
	 1:  16-bit offset
	 2:  16-bit base segment/group
	 3:  Ptr16:16
	 4:  High-order byte (not supported)
	 5:  Same as 1
	 6:  Invalid
	 7:  Invalid
	 8:  Invalid
	 9:  32-bit offset
	10:  Invalid
	11:  Ptr16:32
	12:  Invalid
	13:  Same as 9
	14:  Invalid
	15:  Invalid
DRO:  Data Record Offset - position in previous LEDATA/LIDATA of fixup

FixData field:

<-----one byte------>
1   3	  1   1   2
---------------------
F   Frm   T   P   Tgt

F:    1 if using Frame Thread, in Frm field (mod 4)
      0 ...	       Method, ...
Frm:  interpreted according to F-bit
T:    1 if using Target Thread, in Tgt field
      0 ...		Method, ...
P:    0 if Target Displacement field if present, 1 if not
Tgt:  interpreted according to T-bit

On entry:

DS:ESI	 ==>	 OBJHDR_STR

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 add	 esi,type OBJHDR_STR ; Skip over the header

	 mov	 edi,LMB_FIXUPP.LMB_CURB.BOUND_NXT ; Get LA of next entry

; Parse the FIXUPP record copying the appropriate parts to LMB_FIXUPP

OMF_FIXUPP_NEXT:
	 cmp	 esi,THISOBJ_CSUM ; Are we at the end?
	 jae	 near ptr OMF_FIXUPP_END ; Jump if so

	 test	 ds:[esi].LO,@BIT7 ; Izit a Frame (1) or Thread (0)?
	 jz	 near ptr OMF_FIXUPP_THREAD ; Jump if it's a thread

; This is a Fixup subrecord

	 lods	 ds:[esi].ELO	; Get the LOCAT word
	 xchg	 al,ah		; Swap to normal byte order
	 mov	 LOCAT,ax	; Save for later use

; Validate the LOC field

;;;;;;;; movzx	 eax,LOCAT	; Copy LOCAT word
	 and	 eax,@LOCAT_LOC ; Isolate LOC field
	 shr	 eax,$LOCAT_LOC ; Shift to low-order
	 movzx	 eax,LOCAT_LOC[eax*(type LOCAT_LOC)] ; Translate to canonical value

	 cmp	 al,-1		; Izit invalid?
	 je	 near ptr OMF_FIXUPP_LOCINV ; Jump if so

	 shl	 eax,$LOCAT_LOC ; Shift to original-order
	 and	 LOCAT,not @LOCAT_LOC ; Clear the original bits
	 or	 LOCAT,ax	; Set to canonical value

; Write out the DRO value

	 cmp	 LAST_DATREC,0	; Is the last record offset valid?
	 je	 near ptr OMF_FIXUPP_LSTINV ; Jump if not

	 mov	 ax,LOCAT	; Copy LOCAT word
	 and	 eax,@LOCAT_DRO ; Isolate the Data Record Offset
	 shr	 eax,$LOCAT_DRO ; Shift to low-order
	 add	 eax,LAST_DATREC ; Add to LA of last Data Record

	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_DRO_CUR,eax ; Save LA of fixup current

	 mov	 eax,LAST_DATREC ; Get start of last Data Record
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_DRO_BEG,eax ; Save LA of fixup start

	 mov	 eax,LAST_DATOFF ; Get offset of last Data Record
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_OFF,eax ; Save as offset of fixup

; Write out the PEROBJ_STR entry

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_PPEROBJ,eax ; Save LA of PEROBJ_STR

; Write out the LOCAT word

	 mov	 ax,LOCAT	; Copy LOCAT word
	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_LOCAT,ax ; Save LOCAT word

; Write out the FIXDAT byte and flag

	 lods	 ds:[esi].LO	; Get the FIXDAT byte
	 mov	 FIXDAT,al	; Save locally

	 mov	 al,LAST_DATTYP ; Get last data record OMF type
	 btr	 al,$BIT0	; Clear the 32-bit bit
	 setc	 ah		; AH = 1 iff 32-bit LEDATA/LIDATA record
	 shl	 ah,$FIXFL_32	; Shift into place
	 cmp	 al,@OMF_LIDATA ; Izit an LIDATA record?
	 sete	 al		; AL = 1 iff LIDATA record
	 shl	 al,$FIXFL_LID	; Shift into place
	 or	 al,ah		; Marge the bits
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_FLAG,al ; Save fixup flags

	 mov	 eax,LAST_DATSEG ; Get LA of PERSEG_STR of LAST_DATREC.
	 UNCURB  eax,PERSEG	; Ensure within current bounds
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_PPERSEG,eax ; Save LA of seg of DRO (PERSEG_STR)

	 call	 FIXUPP_COM	; Call routine to accumulate fixup
	 jc	 near ptr OMF_FIXUPP_ERR ; Jump if something went wrong

; Save the segment length before appending to this segment

	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_OLDLEN ; Get length before appending
				; this segment
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_OLDLEN,eax ; Save length before appending
				; this segment
	 add	 edi,type FIXUPP_STR ; Skip to next entry

	 jmp	 OMF_FIXUPP_NEXT ; Go around again


; This is a Thread subrecord

OMF_FIXUPP_THREAD:
	 xor	 eax,eax	; Zero to use as dword
	 lods	 ds:[esi].LO	; Get the THREAD data field

	 mov	 ebx,eax	; Copy data value

; Validate the method field

	 and	 eax,@THRED_M	; Isolate the method field
	 shr	 eax,$THRED_M	; Shift to low-order

; For Target threads, reduce the method field mod 4 as there's
; no primary/secondary bit

	 test	 ebx,@THRED_D	; Izit a Target(0) thread?
	 jnz	 short OMF_FIXUPP_FRMTHR ; Jump if not

	 btr	 eax,$BIT2	; Reduce method field mod 4
	 jnc	 short OMF_FIXUPP_THRCOM ; Jump if OK

	 push	 dword ptr (offset PGROUP:IWF_THRINV) ; Pass offset of action routine
	 push	 IW2_FLAG	; Pass value of flags
	 push	 $IW2_THRINV	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for invalid target method in thread
				; Return with CF=1 if it's fatal
	 jnc	 short OMF_FIXUPP_THRCOM ; Jump if not failed

	 jmp	 OMF_FIXUPP_ERR ; Join common error code

OMF_FIXUPP_FRMTHR:

; For Frame threads, validate the method field

	 cmp	 FIXDAT_FRM[eax*(type FIXDAT_FRM)],-1 ; Izit invalid?
	 je	 near ptr OMF_FIXUPP_FRMINV ; Jump if so
OMF_FIXUPP_THRCOM:

; Calculate a 3-bit Thread index using the type field (D) and the Thread # (T)

	 mov	 bh,bl		; Copy TRDDAT
	 and	 bh,@THRED_D	; Isolate type field
	 shr	 bh,$THRED_D	; Shift to low order
	 and	 bl,@THRED_T	; Isolate thread #
	 shl	 bl,8-$THRED_M	; Shift to high-order just below type field
	 shr	 ebx,8-$THRED_M ; Shift both fields to low-order
	 imul	 ebx,type THRED_STR ; Convert to index THRED_STRs
	 mov	 T_THREAD[ebx].THRED_M,al ; Save the method

; If the method is > 3, there's no index field

	 cmp	 eax,3		; Is there an index field?
	 ja	 short @F	; Jump if not

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 short @F	; Jump if no index
@@:
	 mov	 T_THREAD[ebx].THRED_NDX,ax ; Save index

	 jmp	 OMF_FIXUPP_NEXT ; Go around again


OMF_FIXUPP_END:
	 mov	 LMB_FIXUPP.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	 jmp	 short OMF_FIXUPP_EXIT ; Join common exit code

OMF_FIXUPP_LSTINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_LSTINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_LSTINV1) ; ...

	 jmp	 short OMF_FIXUPP_ERRCOM ; Join common error code

OMF_FIXUPP_LOCINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_LOCINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_LOCINV1) ; ...

	 jmp	 short OMF_FIXUPP_ERRCOM ; Join common error code

OMF_FIXUPP_FRMINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_FRMINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_FRMINV1) ; ...

	 jmp	 short OMF_FIXUPP_ERRCOM ; Join common error code

OMF_FIXUPP_TGTINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_TGTINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_TGTINV1) ; ...

;;;;;;;; jmp	 short OMF_FIXUPP_ERRCOM ; Join common error code

OMF_FIXUPP_ERRCOM:
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 call	 DUMPIT 	; Dump all the tables
OMF_FIXUPP_ERR:
	 stc			; Mark as in error
OMF_FIXUPP_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_FIXUPP endp 		; End OMF_FIXUPP procedure
	 NPPROC  IWF_THRINV -- Ignore/Warn/Fail About Invalid Thread Method
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about invalid thread method.

|

	 push	 dword ptr (offset DGROUP:MSG_THRINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_THRINV1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_THRINV endp 		; End IWF_THRINV procedure
	 NPPROC  FIXUPP_COM -- Common Routine To Accumulate A Fixup
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Common routine (to OMF_FIXUPP and OMF_MODEND) to accumulate a fixup.

On entry:

DS:ESI	 ==>	 fixup record
EDI	 =	 LA of FIXUPP_STR

On exit:

DS:ESI	 ==>	 (updated)
CF	 =	 0 if successful
	 =1	 1 if not

|

	 REGSAVE <eax,ebx,ecx>	; Save registers

; Process the frame field

	 movzx	 ecx,FIXDAT	; Copy FIXDAT byte
	 and	 ecx,@FIXDAT_FRM ; Isolate the FRM field
	 shr	 ecx,$FIXDAT_FRM ; Shift to low-order

; If F=1, this is a thread reference, and there's no Frame Datum

	 btr	 FIXDAT,$FIXDAT_F ; Is this a thread reference?
	 jc	 short FIXUPP_COM_FRMTHRED ; Jump if so

; Validate the frame field in the FIXDAT byte

	 cmp	 FIXDAT_FRM[ecx*(type FIXDAT_FRM)],-1 ; Izit invalid?
	 je	 near ptr FIXUPP_COM_FRMINV ; Jump if so

; If FRM > 3, there's no Frame Datum

	 cmp	 ecx,3		; Izit > 3?
	 ja	 short FIXUPP_COM_FRMCOM ; Jump if so

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 near ptr FIXUPP_COM_FNDXINV ; Jump if no frame datum index

	 jmp	 short FIXUPP_COM_FRMCOM ; Join common code

FIXUPP_COM_FRMTHRED:
	 imul	 ecx,type THRED_STR ; Convert to index THRED_STRs
	 movzx	 eax,F_THREAD[ecx].THRED_NDX ; Get the Frame index
	 movzx	 ecx,F_THREAD[ecx].THRED_M   ; ...	     method

; Validate the method #

	 cmp	 cl,-1		; Izit invalid?
	 je	 near ptr FIXUPP_COM_THRDINV ; Jump if so

	 and	 FIXDAT,not @FIXDAT_FRM ; Clear the Frame field
	 mov	 ebx,ecx	; Copy the method #
	 shl	 ebx,$FIXDAT_FRM ; Shift into position
	 or	 FIXDAT,bl	; Include new Frame method
FIXUPP_COM_FRMCOM:
	 call	 FIXMETH_TAB[ecx*(type FIXMETH_TAB)] ; Call to frame action
				; Return with EAX = LA of appropriate xxxDEF_STR entry
	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_FRM,eax ; Save Frame Datum field

; Process the target field

	 movzx	 ecx,FIXDAT	; Copy FIXDAT byte
	 and	 ecx,@FIXDAT_TGT ; Isolate the TGT field
	 shr	 ecx,$FIXDAT_TGT ; Shift to low-order

; If T=1, this is a thread reference, and there's no Target Datum

	 btr	 FIXDAT,$FIXDAT_T ; Is this a thread reference?
	 jc	 short FIXUPP_COM_TGTTHRED ; Jump if so

; Validate the target field in the FIXDAT byte

	 cmp	 ecx,3		; Izit invalid?
	 je	 near ptr FIXUPP_COM_TGTINV ; Jump if so

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 near ptr FIXUPP_COM_TNDXINV ; Jump if no target datum index

	 jmp	 short FIXUPP_COM_TGTCOM ; Join common code

FIXUPP_COM_TGTTHRED:
	 imul	 ecx,type THRED_STR ; Convert to index THRED_STRs
	 movzx	 eax,T_THREAD[ecx].THRED_NDX ; Get the Target index
	 movzx	 ecx,T_THREAD[ecx].THRED_M   ; ...	      method

; Validate the method #

	 cmp	 cl,-1		; Izit invalid?
	 je	 near ptr FIXUPP_COM_THRDINV ; Jump if so

	 and	 FIXDAT,not @FIXDAT_TGT ; Clear the Target field
	 mov	 ebx,ecx	; Copy the method #
	 shl	 ebx,$FIXDAT_TGT ; Shift into position
	 or	 FIXDAT,bl	; Include new Frame method
FIXUPP_COM_TGTCOM:
	 call	 FIXMETH_TAB[ecx*(type FIXMETH_TAB)] ; Call to target action
				; Return with EAX = LA of appropriate xxxDEF_STR entry
	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_TGT,eax ; Save Target Datum field

; Save the (perhaps modified) FIXDAT byte

	 mov	 al,FIXDAT	; Copy FIXDAT byte
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_FIXDAT,al ; Save FIXDAT byte

; Process Target Displacement field (if present)

	 xor	 eax,eax	; Assume no Target Displacement
	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 AGROUP:[edi].FIXUPP_DSP,eax ; Save Target Displacement

; If this is a Target SEGDEF fixup (and not a 16-bit base segment/group)
; add into the Target Displacement field the size so far of the SEGDEF.

	 cmp	 ecx,@FIXDAT_FT_SEG ; Izit SEGDEF target?
	 jne	 short FIXUPP_COM_TGTCOM1 ; Jump if not

	 movzx	 eax,AGROUP:[edi].FIXUPP_LOCAT ; Get the LOCAT word
	 and	 eax,@LOCAT_LOC ; Isolate the location bits
;;;;;;;; shr	 eax,$LOCAT_LOC ; Shift to low-order

; Note that for 16-bit base segment/group fixups, the target displacement
; applies to the segment which is taken care of in FIXLOC2, so we skip it
; here.  For Ptr16:16 and Ptr16:32 fixups, the target displacement applies
; to the offset, so we don't skip them here.

	 cmp	 eax,@LOCAT_LOC_SEG shl $LOCAT_LOC ; Izit 16-bit base segment/group
	 je	 short FIXUPP_COM_TGTCOM1 ; Jump if so

	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 eax,AGROUP:[edi].FIXUPP_TGT ; Get Target Datum field
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_OLDLEN ; Get old length before adding
				; in the length of this segment to get current offset
;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 add	 AGROUP:[edi].FIXUPP_DSP,eax ; Add to Target Displacement
FIXUPP_COM_TGTCOM1:

; If P=1, there's no Target Displacement

	 test	 FIXDAT,@FIXDAT_P ; Is there a Target Displacement?
	 jnz	 short @F	; Jump if not

	 call	 GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 add	 AGROUP:[edi].FIXUPP_DSP,eax ; Add to Target Displacement
@@:

; If this is a self-relative fixup, mark the fixup segment as code

	 UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 test	 AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	 jnz	 short @F	; Jump if so

;;;;;;;; UNOVRB  edi,FIXUPP	; Ensure within overall bounds
	 mov	 eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of seg of DRO (PERSEG_STR)
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 or	 AGROUP:[eax].SYM_FLAG,@SYMFL_CODE ; Mark as code
@@:
	 clc			; Mark as successful

	 jmp	 short FIXUPP_COM_EXIT ; Join common exit code


FIXUPP_COM_THRDINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_THRDINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_THRDINV1) ; ...

	 jmp	 short FIXUPP_COM_ERRCOM ; Join common error code

FIXUPP_COM_FNDXINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_FNDXINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_FNDXINV1) ; ...

	 jmp	 short FIXUPP_COM_ERRCOM ; Join common error code

FIXUPP_COM_TNDXINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_TNDXINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_TNDXINV1) ; ...

	 jmp	 short FIXUPP_COM_ERRCOM ; Join common error code

FIXUPP_COM_FRMINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_FRMINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_FRMINV1) ; ...

	 jmp	 short FIXUPP_COM_ERRCOM ; Join common error code

FIXUPP_COM_TGTINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_TGTINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_TGTINV1) ; ...

;;;;;;;; jmp	 short FIXUPP_COM_ERRCOM ; Join common error code

FIXUPP_COM_ERRCOM:
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 call	 DUMPIT 	; Dump all the tables

	 stc			; Mark as in error
FIXUPP_COM_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXUPP_COM endp 		; End FIXUPP_COM procedure
	 NPPROC  OMF_FIXUPP_M0 -- OMF Fixup Method #0
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF Fixup, method #0 (SEGDEF).

On entry:

EAX	 =	 Frame/Target datum

On exit:

EAX	 =	 LA of PERSEG_STR

|

; The Frame/Target Datum indexes SEGDEF

	 imul	 eax,type SEGDEF_STR ; Convert to index for SEGDEF_STRs
	 add	 eax,LMB_SEGDEF.LMB_CURB.BOUND_BEG ; Plus starting address

	 UNCURB  eax,SEGDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].SEGDEF_PPERSEG ; Get LA of PERSEG_STR entry

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_FIXUPP_M0 endp		; End OMF_FIXUPP_M0 procedure
	 NPPROC  OMF_FIXUPP_M1 -- OMF Fixup Method #1
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF Fixup, method #1 (GRPDEF).

On entry:

EAX	 =	 Frame/Target datum

On exit:

EAX	 =	 LA of GRPSEG_STR

|

; The Frame/Target Datum indexes GRPDEF

	 imul	 eax,type GRPDEF_STR ; Convert to index for GRPDEF_STRs
	 add	 eax,LMB_GRPDEF.LMB_CURB.BOUND_BEG ; Plus starting address

	 UNCURB  eax,GRPDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].GRPDEF_PPERGRP ; Get LA of GRPSEG_STR entry

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_FIXUPP_M1 endp		; End OMF_FIXUPP_M1 procedure
	 NPPROC  OMF_FIXUPP_M2 -- OMF Fixup Method #2
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF Fixup, method #2 (EXTDEF).

On entry:

EAX	 =	 Frame/Target datum

On exit:

EAX	 =	 LA of SYM_STR for symbol

|

; The Frame/Target Datum indexes EXTDEF

	 imul	 eax,type EXTDEF_STR ; Convert to index for EXTDEF_STRs
	 add	 eax,LMB_EXTDEF.LMB_CURB.BOUND_BEG ; Plus starting address

	call	MARK_MATCHED	; Mark the EXTDEF at EAX as matched
	 mov	 eax,AGROUP:[eax].EXTDEF_PSYM ; Get LA of SYM_STR entry

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_FIXUPP_M2 endp		; End OMF_FIXUPP_M2 procedure
	 NPPROC  OMF_FIXUPP_M4 -- OMF Fixup Method #4
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF Fixup, method #4 (LAST_DATSEG).

On exit:

EAX	 =	 LA of PERSEG_STR

|

	 mov	 eax,LAST_DATSEG ; Get LA of PERSEG_STR of LAST_DATREC.

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_FIXUPP_M4 endp		; End OMF_FIXUPP_M4 procedure
	 NPPROC  OMF_FIXUPP_M5 -- OMF Fixup Method #5
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

OMF Fixup, method #5 (Target).

Nothing to do until we process the fixups.

|

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_FIXUPP_M5 endp		; End OMF_FIXUPP_M5 procedure
	NPPROC	OMF_LEDATA -- Logical Enumerated/Iterated Data Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Logical enumerated data record (A0h/A1h).
Logical iterated data record (A2h/A3h).

On entry:

DS:ESI	==>	OBJHDR_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	add	esi,type OBJHDR_STR ; Skip over the header

; Get the segment index

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	jc	short OMF_LEDATA_ERR ; Jump if it's invalid

; Lookup this segment in the SEGDEF table

	imul	eax,type SEGDEF_STR ; Get offset into SEGDEF_STR
	add	eax,LMB_SEGDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	eax,SEGDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].SEGDEF_PPERSEG ; Get LA of PERSEG_STR

	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].PERSEG_LMB.LMB_CURB.BOUND_NXT ; Get LA of next entry

; Get the OMF record type and save it in the data record

	mov	al,OMFTYP	; Get the type
	mov	LAST_DATTYP,al	; Save for later use
	UNOVRB	edi,PERSEG,ebx	; Ensure within overall bounds
	stos	(type DATREC_TYP) ptr AGROUP:[edi] ; Save the type

; Get the enumerated data offset

	call	GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	mov	LAST_DATOFF,eax ; Save as offset of last data record
;;;;;;; UNCURB	ebx,PERSEG	; Ensure within current bounds
	add	eax,AGROUP:[ebx].PERSEG_OLDLEN ; Plus old length before adding
				; in the length of this segment to get current offset

;;;;;;; UNOVRB	edi,PERSEG,ebx	; Ensure within overall bounds
	stos	(type DATREC_OFF) ptr AGROUP:[edi] ; Save the data offset

; Copy the data to the segment data

	mov	ecx,THISOBJ_CSUM ; Get the offset of the checksum
	sub	ecx,esi 	; Less the current offset to get remaining length
	mov	eax,ecx 	; Copy the byte length
;;;;;;; UNOVRB	edi,PERSEG,ebx	; Ensure within overall bounds
	stos	(type DATREC_LEN) ptr AGROUP:[edi] ; Save the data length
	mov	LAST_DATREC,edi ; Save as LA of last data record
	mov	LAST_DATSEG,ebx ; Save as LA of PERSEG_STR of last data record

	UNOVRB	edi,PERSEG,ebx	; Ensure within overall bounds
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy as segment data

	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[ebx].PERSEG_LMB.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	jmp	short OMF_LEDATA_EXIT ; Join common exit code


; Missing segment index

OMF_LEDATA_ERR:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_SEGINV) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_SEGINV1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	call	DUMPIT		; Dump all the tables

	stc			; Mark as in error
OMF_LEDATA_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_LEDATA endp 		; End OMF_LEDATA procedure
	 NPPROC  OMF_COMDEF -- Communal Names Definition Record
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Communal names definition names record (B0h).
Local communal names definition names record (B8h).

On entry:

DS:ESI	 ==>	 OBJHDR_STR

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 add	 esi,type OBJHDR_STR ; Skip over the header
OMF_COMDEF_NEXT:

; Zero the EXTDEF struc

.errnz (4-1) and (type EXTDEF_STR)
	 mov	 ecx,(type EXTDEF_STR)/4 ; # dwords to zero
	 xor	 eax,eax	; Set to this
	 mov	 edi,LMB_EXTDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 mov	 edx,edi	; Save starting offset of EXTDEF_STR

	 UNOVRB  edi,EXTDEF	; Ensure within overall bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the struc
	 mov	 LMB_EXTDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; EDX	 =	 LA of EXTDEF_STR

	 lea	 edi,WORKAREA	; Get offset in DGROUP of work area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 mov	 ebx,edi	; Save starting address

	 movzx	 ecx,ds:[esi].LO ; Get the byte length
	 inc	 ecx		; Count in the length byte

; Copy the (Count, Char[]) pair to the work area

	call	CopyCountChar	; Copy it

; In case this is a local COMDEF, we append to the name the
; LA of the current PEROBJ_STR

	 mov	 cl,OMFTYP	; Get the OMF type
	 and	 cl,not @BIT0	; Clear the 32-bit bit

	 cmp	 cl,@OMF_LCOMDEF ; Izit LCOMDEF record?
	 jne	 short @F	; Jump if not

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 stos	 AGROUP:[edi].EDD ; Save in work area
@@:

; Fill in the work area fields

	 sub	 edi,ebx	; Subtract to get length
	 mov	 WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	 mov	 WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;;; mov	 WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	 mov	 WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SYM ; Mark as symbol class

; If this is a local COMDEF, mark it as such so we don't
; display it in the .MAP file

	 cmp	 cl,@OMF_LCOMDEF ; Izit LCOMDEF record?
	 jne	 short @F	; Jump if not

	 or	 WORKAREA_SYM.SYM_FLAG,@SYMFL_LOCAL ; Mark as local symbol
@@:

; See if this entry already exists in the symbol table

	 REGSAVE <esi>		; Save for a moment

	 lea	 esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	 add	 esi,LaDATA	; Plus LA of DGROUP
	 call	 SYMSRCH	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	 jnc	 short OMF_COMDEF_OLD ; Jump if already in the table (note CF=0)

; Append the entry to the symbol table

;;;;;;;; lea	 esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;;; add	 esi,LaDATA	; Plus LA of DGROUP
	 call	 SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
OMF_COMDEF_OLD:
	 REGREST <esi>		; Restore
	 jc	 near ptr OMF_COMDEF_APPND ; Jump if something went wrong

	 UNCURB  edx,EXTDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].EXTDEF_PSYM,ebx ; Save as pointer to SYM_STR

; Ensure there's no duplicate public non-communal symbols

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 bts	 AGROUP:[ebx].SYM_FLAG,$SYMFL_COM ; Izit already common?
	 jnc	 short @F	; Jump if not

;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 edi,AGROUP:[ebx].SYM_PERITEM ; Get LA of previous PUBDEF_STR

	 jmp	 OMF_COMDEF_COM1 ; Join common code

@@:

; Zero the PUBDEF struc

.errnz (4-1) and (type PUBDEF_STR)
	 mov	 ecx,(type PUBDEF_STR)/4 ; # dwords to zero
	 xor	 eax,eax	; Set to this
	 mov	 edi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry

	 UNOVRB  edi,PUBDEF	; Ensure within overall bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the struc
	 xchg	 LMB_PUBDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; EDI	 =	 LA of PUBDEF_STR

	 UNCURB  edi,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edi].PUBDEF_PSYM,ebx ; Save as pointer to SYM_STR

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 bts	 AGROUP:[ebx].SYM_FLAG,$SYMFL_PUB ; Mark as public
	 jc	 near ptr OMF_COMDEF_COMDUP ; Jump if it's already public
				; With EBX and EDI used in error display
;;;;;;;; UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_PERITEM,edi ; Save as PERITEM ptr

	 UNCURB  edi,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edi].PUBDEF_PSYM,ebx ; Save as pointer to SYM_STR

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry
	 UNCURB  edi,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edi].PUBDEF_PPEROBJ,eax ; Save as LA of PEROBJ_STR

; Zero the COMDEF struc

.errnz (4-1) and (type COMDEF_STR)
	 mov	 ecx,(type COMDEF_STR)/4 ; # dwords to zero
	 xor	 eax,eax	; Set to this
	 mov	 edx,edi	; Copy LA of PUBDEF_STR
	 mov	 edi,LMB_COMDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry

	 UNOVRB  edi,COMDEF	; Ensure within overall bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the struc
	 xchg	 LMB_COMDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	 UNCURB  edi,COMDEF	; Ensure within current bounds
	 mov	 AGROUP:[edi].COMDEF_PPUBDEF,edx ; Save LA of public (PUBDEF_STR)
	 mov	 edi,edx	; Restore LA of public (PUBDEF_STR)
OMF_COMDEF_COM1:

; EDI	 =	 LA of PUBDEF_STR

; Get and check the type index field

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	 jc	 short @F	; Jump if no index (EAX=-1)

	 call	 CHECK_TYPE	; Check type indices of EAX and [EBX].SYM_TYPE
	 jc	 near ptr OMF_COMDEF_EXIT ; Jump if it's fatal (note CF=1)

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 AGROUP:[ebx].SYM_TYPE,eax ; Save as type index
@@:

; Get the data type field

	 lods	 ds:[esi].LO	; Get the data type (61h or 62h)

	 cmp	 al,61h 	; Izit Far Data?
	 je	 short OMF_COMDEF_FAR ; Jump if so

	 cmp	 al,62h 	; Izit Near Data?
	 jne	 near ptr OMF_COMDEF_TYPINV ; Jump if so
;;;_COMDEF_NEAR:
	 mov	 eax,-1 	; Get near data marker
	 UNCURB  edi,PUBDEF	; Ensure within current bounds
	 xchg	 eax,AGROUP:[edi].PUBDEF_NELM ; Mark as near data

	 cmp	 eax,0		; Izit previously unspecified?
	 je	 short @F	; Jump if so

	 cmp	 eax,-1 	; Izit previously near
	 jne	 short OMF_COMDEF_COMDIF ; Jump if not
				; With EBX and EDX used in error display
@@:
	 mov	 ecx,1		; Get # elements

	 jmp	 short OMF_COMDEF_FARCOM ; Join common code

OMF_COMDEF_FAR:
	 call	 GET_VLEN	; Get communal length value into EAX
	 jc	 near ptr OMF_COMDEF_VLENINV ; Jump if invalid length

	 UNCURB  edi,PUBDEF	; Ensure within current bounds
	 add	 AGROUP:[edi].PUBDEF_NELM,eax ; Add in # elements
	 mov	 ecx,eax	; Copy # elements
OMF_COMDEF_FARCOM:
	 call	 GET_VLEN	; Get communal length value into EAX
	 jc	 near ptr OMF_COMDEF_VLENINV ; Jump if invalid length

	 imul	 eax,ecx	; Times # elements to get size
	 UNCURB  edi,PUBDEF	; Ensure within current bounds
	 add	 AGROUP:[edi].PUBDEF_SIZ,eax ; Add in size of data

; We're finished with this portion of this record -- check for repeats

	 cmp	 esi,THISOBJ_CSUM ; Are we at the end of the record?
	 jb	 near ptr OMF_COMDEF_NEXT ; Jump if more names to check

	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	 jmp	 OMF_COMDEF_EXIT ; Join common exit code


COMMENT|

Different distance (near vs. far)

EBX	 =	 LA of SYM_STR of existing PUBDEF

|

OMF_COMDEF_COMDIF:
	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_COMDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the existing symbol name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_COMDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 jmp	 short OMF_COMDEF_COMDUP_COM ; Join common code

COMMENT|

Duplicate public symbols:  one in common, one not

EBX	 =	 LA of SYM_STR of existing PUBDEF

|

OMF_COMDEF_COMDUP:
	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_COMDUP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the existing symbol name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_COMDUP1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display filename #1

OMF_COMDEF_COMDUP_COM:
	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PUBDEF_STR
	 UNCURB  eax,PUBDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PUBDEF_PPEROBJ ; Get LA of PEROBJ_STR
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Point to symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

; Display the record offset, etc.

	 push	 dword ptr (offset DGROUP:MSG_COMDUP2) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_COMDUP3) ; ...

	 jmp	 short OMF_COMDEF_ERRCOM ; Join common error code

OMF_COMDEF_TYPINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_TYPINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_TYPINV1) ; ...

	 inc	 ERRCNT 	; Mark as writing to error file

	 jmp	 short OMF_COMDEF_ERRCOM ; Join common error code

OMF_COMDEF_VLENINV:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_VLENINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_VLENINV1) ; ...

	 inc	 ERRCNT 	; Mark as writing to error file

	 jmp	 short OMF_COMDEF_ERRCOM ; Join common error code

OMF_COMDEF_APPND:
	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...

	 inc	 ERRCNT 	; Mark as writing to error file

;;;;;;;; jmp	 short OMF_COMDEF_ERRCOM ; Join common error code

OMF_COMDEF_ERRCOM:
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 call	 DUMPIT 	; Dump all the tables

	 stc			; Mark as in error
OMF_COMDEF_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_COMDEF endp 		; End OMF_COMDEF procedure
	 NPPROC  GET_VLEN -- Get Variable Length Data
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get variable length data from COMDEF record.

On entry:

DS:ESI	 ==>	 data record

On exit:

EAX	 =	 data value
DS:ESI	 ==>	 (updated)
CF	 =	 0 if successful
	 =	 1 if not

|

	 xor	 eax,eax	; Zero to use as dword
	 lods	 ds:[esi].LO	; Get the type value

	 cmp	 al,80h 	; Izit a byte?
	 jbe	 short GET_VLEN_DONE ; Jump if so

	 cmp	 al,81h 	; Izit a word?
	 je	 short GET_VLEN_WORD ; Jump if so

	 cmp	 al,84h 	; Izit 3 bytes?
	 je	 short GET_VLEN_3BYTE ; Jump if so

	 cmp	 al,88h 	; Izit a dword?
	 je	 short GET_VLEN_DWORD ; Jump if so

	 stc			; Mark as in error

	 jmp	 short GET_VLEN_EXIT ; Join common exit code

GET_VLEN_DWORD:
	 lods	 ds:[esi].LO	; Get the next byte
	 shl	 eax,3*8	; Shift into position
GET_VLEN_3BYTE:
	 rol	 eax,16 	; Swap high- and low-order words
	 lods	 ds:[esi].LO	; Get the next byte
	 ror	 eax,16 	; Swap high- and low-order words
GET_VLEN_WORD:
	 lods	 ds:[esi].ELO	; Get the word
GET_VLEN_DONE:
	 clc			; Mark as successful
GET_VLEN_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_VLEN endp			; End GET_VLEN procedure
	 NPPROC  OMF_BAKPAT -- BackPatch Record
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

BackPatch record (B2h/B3h).

1-2	  1	      2-4	2-4
--------------------------------------
Segment   Location    Offset	Value
Index	  Type
		     <----repeat---->

On entry:

DS:ESI	 ==>	 OBJHDR_STR

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 add	 esi,type OBJHDR_STR ; Skip over the header

	 mov	 edi,LMB_BAKPAT.LMB_CURB.BOUND_NXT ; Get LA of next entry

; Parse the BAKPAT record copying the appropriate parts to LMB_BAKPAT

	 call	 GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;;; jc	 short ???	; Jump if no index (EAX=-1)

	 imul	 eax,type SEGDEF_STR ; Convert to index for SEGDEF_STRs
	 add	 eax,LMB_SEGDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	 UNCURB  eax,SEGDEF	; Ensure within current bounds
	 mov	 ebx,AGROUP:[eax].SEGDEF_PPERSEG ; Get LA of PERSEG_STR

; Get location type byte

	 xor	 eax,eax	; Zero to use as dword
	 lods	 ds:[esi].LO	; Get location type byte

	 cmp	 al,2		; Izit within bounds?
	 jbe	 short @F	; Jump if so

	 push	 dword ptr (offset PGROUP:IWF_BAKPAT) ; Pass offset of action routine
	 push	 IW2_FLAG	; Pass value of flags
	 push	 $IW2_BAKPAT	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for invalid location type
				; Return with CF=1 if it's fatal
	 jc	 short OMF_BAKPAT_EXIT ; Jump if it's fatal (note CF=1)

	 mov	 al,0		; Use byte width
@@:
	 mov	 edx,eax	; Save for later use
OMF_BAKPAT_NEXT:
	 cmp	 esi,THISOBJ_CSUM ; Are we at the end?
	 jae	 short OMF_BAKPAT_END ; Jump if so

	 mov	 eax,edi	; Copy this index
	 UNCURB  ebx,PERSEG	; Ensure within current bounds
	 xchg	 eax,AGROUP:[ebx].PERSEG_BAKPAT_LNK ; Swap with the last one
	 stos	 (type BAKPAT_LNK) ptr AGROUP:[edi] ; Save in BAKPAT table

; Save the location type

	 mov	 eax,edx	; Copy the location type
	 stos	 (type BAKPAT_TYPE) ptr AGROUP:[edi] ; Save in BAKPAT table

; Get the offset

	 call	 GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX

; Add in the segment length which precedes this location

	 UNCURB  ebx,PERSEG	; Ensure within current bounds
	 add	 eax,AGROUP:[ebx].PERSEG_OLDLEN ; Get length before appending
				; this segment
	 stos	 (type BAKPAT_OFF) ptr AGROUP:[edi] ; Save in BAKPAT table

; Get the value

	 call	 GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	 stos	 (type BAKPAT_VAL) ptr AGROUP:[edi] ; Save in BAKPAT table

	 jmp	 OMF_BAKPAT_NEXT ; Go around again


OMF_BAKPAT_END:
	 mov	 LMB_BAKPAT.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	 call	 CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
OMF_BAKPAT_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_BAKPAT endp 		; End OMF_BAKPAT procedure
	NPPROC	IWF_BAKPAT -- BAKPAT Invalid Location Type
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Invalid location type in BAKTAP record

|

	push	dword ptr (offset DGROUP:MSG_BAKPAT) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_BAKPAT1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_BAKPAT endp 		; End IWF_BAKPAT procedure
	NPPROC	OMF_CEXTDEF -- COMDAT External Names Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

COMDAT external definition names record (BCh)

On entry:

DS:ESI	==>	OBJHDR_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

; Setup loop variables to copy the names to the work area
; and save an entry for it in the EXTDEF table

	add	esi,type OBJHDR_STR ; Skip over the header
	mov	edi,LMB_EXTDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
OMF_CEXTDEF_NEXT:

; Zero the EXTDEF struc

.errnz (4-1) and (type EXTDEF_STR)
	mov	ecx,(type EXTDEF_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
;;;;;;; mov	edi,LMB_EXTDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	edx,edi 	; Save starting offset of EXTDEF_STR

	UNOVRB	edi,EXTDEF	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	mov	LMB_EXTDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	push	edi		; Save for a moment

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

; DS:ESI ==> CEXTDEF name index
; ES:EDI ==> work area

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index

; Lookup the name in LMB_LNAMES

	imul	eax,type LNAMES_STR ; Convert to index for LNAMES_STRs
	add	eax,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Plus starting address

	UNCURB	eax,LNAMES	; Ensure within current bounds
	mov	eax,AGROUP:[eax].LNAMES_PTXT ; Get LA of (type, text)
	mov	cl,AGROUP:[eax] ; Get type (global/local) byte
	inc	eax		; Skip over the type (global/local) byte
				; to text (Count, Char[])
	push	eax		; Pass LA of text (Count, Char[])
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated

; In case this is a local EXTDEF, we append to the name the
; LA of the current PEROBJ_STR

	cmp	cl,0		; Izit local?
	jne	short @F	; Jump if not

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	stos	AGROUP:[edi].EDD ; Save in work area
@@:

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	mov	WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SYM ; Mark as symbol class

; If this is a local EXTDEF, mark it as such so we don't
; display it in the .MAP file

	cmp	cl,0		; Izit local?
	jne	short @F	; Jump if not

	or	WORKAREA_SYM.SYM_FLAG,@SYMFL_LOCAL ; Mark as local symbol
@@:
	pop	edi		; Restore

; See if this entry already exists in the symbol table

	REGSAVE <esi>		; Save for a moment

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	jnc	short OMF_CEXTDEF_OLD ; Jump if already in the table (note CF=0)

; Append the entry to the symbol table

;;;;;;; lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;; add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
OMF_CEXTDEF_OLD:
	REGREST <esi>		; Restore
	jc	near ptr OMF_CEXTDEF_APPND ; Jump if something went wrong

	UNCURB	edx,EXTDEF	; Ensure within current bounds
	mov	AGROUP:[edx].EXTDEF_PSYM,ebx ; Save as pointer to SYM_STR
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_EXT ; Mark as external symbol

; Get and check the type index field

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
	jc	short @F	; Jump if no index (EAX=-1)

	call	CHECK_TYPE	; Check type indices of EAX and [EBX].SYM_TYPE
	jc	near ptr OMF_CEXTDEF_EXIT ; Jump if it's fatal (note CF=1)

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_TYPE,eax ; Save as type index
@@:

; If this symbol is not already marked as public, save the PEROBJ_STR
; of this module in SYM_PERITEM so we can reference a module name in
; case the external symbol is never matched by a public one.
; Note that we wait until we've checked the type indices before storing
; this value as that code depends upon seeing the old name in
; the SYM_PERITEM field.

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[ebx].SYM_FLAG,@SYMFL_PUB ; Izit already marked public?
	jnz	short @F	; Jump if so

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,eax ; Save for later use
@@:
	cmp	esi,THISOBJ_CSUM ; Are we at the end of the record?
	jb	near ptr OMF_CEXTDEF_NEXT ; Jump if more names to check

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	jmp	short OMF_CEXTDEF_EXIT ; Join common exit code


OMF_CEXTDEF_APPND:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	call	DUMPIT		; Dump all the tables

	stc			; Mark as in error
OMF_CEXTDEF_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_CEXTDEF endp		; End OMF_CEXTDEF procedure
	NPPROC	OMF_COMDAT -- Initialized Communal Data Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Initialized communal data record (C2h/C3h).

A COMDAT record is a combination of a PUBDEF on the symbol,
but one which allows and ignores duplicates (if Selection
Criteria allows a match), followed by a LEDATA/LIDATA in a
special segment (as determined by the Allocation Type).

On entry:

DS:ESI	==>	OMF_COMDAT_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

OMF_COMDAT_STR struc

	db	(size OBJHDR_STR) dup () ; .OBJ header
OMF_COMDAT_FLAG db ?		; Flags:  see CDFL_REC below
OMF_COMDAT_ATTR db ?		; Attrs:  see CDAT_REC below
OMF_COMDAT_ALIN db ?		; Align:  see @CDAL_xxx below
OMF_COMDAT_NXT	db ?		; The rest of the record

OMF_COMDAT_STR ends

	int	01h		; *FIXME* -- verify correctness

	pushad			; Save all EGP registers

; Get and test the flag byte

	mov	al,ds:[esi].OMF_COMDAT_FLAG ; Get the flag
	mov	CDFLAG,al	; Save for later use

	test	al,not @CDFL_ALL ; Any undefined bits set?
	jnz	near ptr OMF_COMDAT_ERRFLAG ; Jump if so

; Get and test the attr byte

	mov	al,ds:[esi].OMF_COMDAT_ATTR ; Get the attributes
	mov	CDATTR,al	; Save for later use

	mov	ah,al		; Copy for destructive testing
	and	ah,@CDAT_SEL	; Isolate the selection criteria

	cmp	ah,@CDATSEL_MAX shl $CDAT_SEL ; Izit too big?
	ja	near ptr OMF_COMDAT_ERRSEL ; Jump if so

	mov	ah,al		; Copy for destructive testing
	and	ah,@CDAT_TYP	; Isolate the allocation type

	cmp	ah,@CDATTYP_MAX shl $CDAT_TYP ; Izit too big?
	ja	near ptr OMF_COMDAT_ERRTYP ; Jump if so

; Get and test the alignment byte

	mov	al,ds:[esi].OMF_COMDAT_ALIN ; Get the alignment byte
	mov	CDALIN,al	; Save for later use

	cmp	al,@CDAL_MAX	; Izit too big?
	ja	near ptr OMF_COMDAT_ERRALIN ; Jump if so

; Create an ACBP byte from the Allocation Type and Alignment fields

	xor	eax,eax 	; Zero to use as dword
	mov	al,CDATTR	; Get the attribute byte
	and	al,@CDAT_TYP	; Isolate the allocation type
	shr	al,$CDAT_TYP	; Shift to low-order
	dec	eax		; Convert to origin-0
	js	short @F	; Jump if explicit Allocation Type

	mov	bl,CDALIN	; Get the alignment bits
	shl	bl,$ACBP_A	; Shift into place
	or	bl,COMDAT_SEGACBP[eax*(type COMDAT_SEGACBP)] ; Get the ACBP byte
	mov	ACBP,bl 	; Save for later use
@@:

; Get the enumerated data offset

	lea	esi,ds:[esi].OMF_COMDAT_NXT ; DS:ESI ==> rest of the record

	call	GET_OFF32	; Get d/word from DS:ESI depending upon DEF32
				; returning offset in EAX
	mov	CDOFF,eax	; Save for later use
	mov	LAST_DATOFF,eax ; Save as offset of last data record

; Get and ignore the type index field

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1)

; There are Public Base Group, Segment, and Frame fields
; iff the allocation type is explicit

	mov	CDPBGRP,-1	; Mark as not present
	mov	CDPBSEG,-1	; ...
	mov	al,CDATTR	; Get the attribute byte
	and	al,@CDAT_TYP	; Isolate the type field

	cmp	al,@CDATTYP_EXPL shl $CDAT_TYP ; Izit explicit?
	jne	short @F	; Jump if not

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1)

	mov	CDPBGRP,eax	; Save for later use

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1)

	mov	CDPBSEG,eax	; Save for later use
	
	and	eax,CDPBGRP	; Is there a Public Base Frame?
	inc	eax		; ...
	jnz	short @F	; Jump if not
	
	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1)

	int	03h		; Call our debugger -- this should never occur
@@:

; Form the name

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

; DS:ESI ==> public name index
; ES:EDI ==> work area

; Get the public name index

	call	GET_INDEX	; Get index from DS:ESI into EAX, updating ESI
;;;;;;; jc	short ???	; Jump if no index (EAX=-1)
	mov	CDPNI,eax	; Save for later use

; Now that we've touched all of the static fields, check for
; continuations

	test	CDFLAG,@CDFL_CONT ; Izit a continuation?
	jnz	near ptr OMF_COMDAT_CONT ; Jump if so

; Lookup the name in LMB_LNAMES

;;;;;;; mov	eax,CDPNI	; Get the Public Name Index
	imul	eax,type LNAMES_STR ; Convert to index for LNAMES_STRs
	add	eax,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Plus starting address

	UNCURB	eax,LNAMES	; Ensure within current bounds
	mov	eax,AGROUP:[eax].LNAMES_PTXT ; Get LA of (type, text)
	inc	eax		; Skip over the type (global/local) byte
				; to text (Count, Char[])
	push	eax		; Pass LA of text (Count, Char[])
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated

; In case this is a local PUBDEF, we append to the name the
; LA of the current PEROBJ_STR

	test	CDFLAG,@CDFL_LCL ; Izit local name?
	jz	short @F	; Jump if not

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	stos	AGROUP:[edi].EDD ; Save in work area
@@:

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	mov	WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SYM ; Mark as symbol class

; If this is a local PUBDEF, mark it as such so we don't
; display it in the .MAP file

	test	CDFLAG,@CDFL_LCL ; Izit local name?
	jz	short @F	; Jump if not

	or	WORKAREA_SYM.SYM_FLAG,@SYMFL_LOCAL ; Mark as local symbol
@@:

; See if this entry already exists in the symbol table

	REGSAVE <esi>		; Save for a moment

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	jnc	short OMF_COMDAT_OLD ; Jump if already in the table (note CF=0)

; Append the entry to the symbol table

;;;;;;; lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;; add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
OMF_COMDAT_OLD:
	REGREST <esi>		; Restore
	jc	near ptr OMF_COMDAT_APPND ; Jump if something went wrong

; Calculate the data length and checksum 

	mov	ecx,THISOBJ_CSUM ; Get the offset of the checksum
	sub	ecx,esi 	; Less the current offset to get remaining length
	mov	CDLEN,ecx	; Save for later use

	call	CalcChecksum	; Calculate the checksum of DS:ESI,
				; length ECX bytes, return in EAX
	mov	CDCSUM,eax	; Save for later use

COMMENT|

EBX	=	LA of SYM_STR for the COMDAT symbol

Check for Selection Criteria
If No Match, error if SYM_PERITEM != 0.
If Pick Any, use existing if SYM_PERITEM != 0.
If Same Size, error if SYM_PERITEM != 0 && size different
If Exact Match, error if SYM_PERITEM != 0 && checksum different

|

	xor	eax,eax 	; Zero to use as dword
	mov	al,CDATTR	; Get the attribute byte
	and	al,@CDAT_SEL	; Isolate the Selection Criteria
	shr	al,$CDAT_SEL	; Shift to low-order

	jmp	COMDAT_SELTAB[eax*(type COMDAT_SELTAB)] ; Take appropriate action


; Only one instance of this COMDAT allowed.

OMF_COMDAT_SEL_NONE:
	call	COMDAT_SYMBOL	; Check for valid COMDAT symbol
	je	near ptr OMF_COMDAT_SELCOM ; Jump if so

	jmp	OMF_COMDAT_ERRUNIQ ; Jump if not


; Pick any instance of this COMDAT.

OMF_COMDAT_SEL_ANY:
	call	COMDAT_SYMBOL	; Check for valid COMDAT symbol
	je	near ptr OMF_COMDAT_SELCOM ; Jump if so

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PERITEM ; Get the existing PUBDEF_STR

	jmp	OMF_COMDAT_SELCOM1 ; Join common code


; Pick any instance, but all instances must have the same length.

OMF_COMDAT_SEL_SIZE:
	call	COMDAT_SYMBOL	; Check for valid COMDAT symbol
	je	short OMF_COMDAT_SELCOM ; Jump if so

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PERITEM ; Get the existing PUBDEF_STR

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PUBDEF_COMDAT ; Get LA of COMDAT_STR

	UNCURB	eax,COMDAT	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].COMDAT_LEN ; Get the data length

	cmp	ecx,CDLEN	; Izit the same length?
	jne	near ptr OMF_COMDAT_ERRLEN ; Jump if not

	int	03h		; Do we ignore this record *FIXME*
				; as well as any following FIXUPPs?
	jmp	OMF_COMDAT_SELCOM1 ; Join common code


; Pick any instance, but all instances must have the same checksum.

OMF_COMDAT_SEL_CSUM:
	call	COMDAT_SYMBOL	; Check for valid COMDAT symbol
	je	short OMF_COMDAT_SELCOM ; Jump if so

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PERITEM ; Get the existing PUBDEF_STR

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PUBDEF_COMDAT ; Get LA of COMDAT_STR

	UNCURB	eax,COMDAT	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].COMDAT_LEN ; Get the data length

	cmp	ecx,CDLEN	; Izit the same length?
	jne	near ptr OMF_COMDAT_ERRLEN ; Jump if not

	UNCURB	eax,COMDAT	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].COMDAT_CSUM ; Get the checksum

	cmp	ecx,CDCSUM	; Izit the same checksum?
	jne	near ptr OMF_COMDAT_ERRCSUM ; Jump if not

	int	03h		; Do we ignore this record *FIXME*
				; as well as any following FIXUPPs?
	jmp	OMF_COMDAT_SELCOM1 ; Jump if so


OMF_COMDAT_SELCOM:

; Zero the PUBDEF struc

.errnz (4-1) and (type PUBDEF_STR)
	mov	ecx,(type PUBDEF_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	mov	edi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry

	UNOVRB	edi,PUBDEF	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	xchg	LMB_PUBDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; Fill in the PUBDEF struc
; EDI	=	LA of PUBDEF_STR
; EBX	=	LA of SYM_STR for the COMDAT symbol

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	mov	AGROUP:[edi].PUBDEF_PPEROBJ,eax ; Save in PUBDEF_STR

; *FIXME* -- what to do about the PUBDEF_ADDR field?

	int	01h		; Call our debugger
	mov	AGROUP:[edi].PUBDEF_ADDR,-1 ; *FIXME*

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PSYM,ebx ; Save in PUBDEF_STR

; Get or create a segment for this COMDAT as one of CODE16/32 or DATA16/32
; or the Public Base Segment field (if present)

	call	GetCOMDAT_SEG	; Return with EAX ==> PERSEG_STR for CDATTR
	jc	near ptr OMF_COMDAT_ERR ; Jump if something went wrong
	
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PPERSEG,eax ; Save in PUBDEF_STR

; If there's a Public Base Group field, save the matching PERGRP_STR
; in the PUBDEF_STR

	mov	eax,CDPBGRP	; Get Public base Group (-1=none)
	
	cmp	eax,-1		; Izit absent?
	je	short @F	; Jump if so
	
	imul	eax,type GRPDEF_STR ; Convert to index for GRPDEF_STRs
	add	eax,LMB_GRPDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	eax,GRPDEF     ; Ensure within current bounds
	mov	eax,AGROUP:[eax].GRPDEF_PPERGRP ; Get LA of PERGRP_STR
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PPERGRP,eax ; Save in PUBDEF_STR
@@:

; Save the COMDAT data into LMB_COMDAT

	mov	eax,LMB_COMDAT.LMB_CURB.BOUND_NXT ; Get LA of next entry
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_COMDAT,eax ; Save in PUBDEF_STR
OMF_COMDAT_SELCOM1:
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	bts	AGROUP:[ebx].SYM_FLAG,$SYMFL_PUB ; Mark as public symbol
	jc	short @F	; Jump if already set

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,edi ; Save ptr to PUBDEF_STR
@@:
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PUBDEF_PPERSEG ; Get LA of PPERSEG_STR
	mov	LAST_DATSEG,eax ; Save as LA of PERSEG_STR of last data record

	mov	edi,LMB_COMDAT.LMB_CURB.BOUND_NXT ; Get LA of next entry

; Get the OMF record type and save it in the data record

	mov	al,OMFTYP	; Get the type
	mov	LAST_DATTYP,al	; Save for later use
	stos	(type COMDAT_TYP) ptr AGROUP:[edi] ; Save in data struc

	mov	al,CDFLAG	; Get the flag byte
	stos	(type COMDAT_FLAG) ptr AGROUP:[edi] ; Save in data struc

	mov	al,CDATTR	; Get the attribute byte
	stos	(type COMDAT_ATTR) ptr AGROUP:[edi] ; Save in data struc

	mov	al,CDALIN	; Get the alignment byte
	stos	(type COMDAT_ALIN) ptr AGROUP:[edi] ; Save in data struc

	mov	eax,CDOFF	; Get EDO
	stos	(type COMDAT_OFF) ptr AGROUP:[edi] ; Save in data struc

	mov	eax,CDPBGRP	; Get public base group
	stos	(type COMDAT_PBGRP) ptr AGROUP:[edi] ; Save in data struc

	mov	eax,CDPBSEG	; Get public base segment
	stos	(type COMDAT_PBSEG) ptr AGROUP:[edi] ; Save in data struc

	mov	eax,CDPNI	; Get public name index
	stos	(type COMDAT_PNI) ptr AGROUP:[edi] ; Save in data struc

; Next is the data of the COMDAT record

	mov	eax,CDLEN	; Get the data length
	stos	(type COMDAT_LEN) ptr AGROUP:[edi] ; Save in data struc

	mov	eax,CDCSUM	; Get the checksum
	stos	(type COMDAT_CSUM) ptr AGROUP:[edi] ; Save in data struc

	mov	eax,-1		; Mark as last entry
	stos	(type COMDAT_NEXT) ptr AGROUP:[edi] ; Save in data struc

	mov	LAST_DATREC,edi ; Save as LA of last data record

	mov	ecx,CDLEN	; Get the data length
	UNOVRB	edi,COMDAT	; Ensure within overall bounds
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy as segment data

	xchg	edi,LMB_COMDAT.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	eax,edi 	; Save LA of this entry
	xchg	LAST_COMDAT,edi ; Save for next time

	cmp	edi,-1		; Izit this the first one?
	je	short @F	; Jump if so

	UNCURB	edi,COMDAT	; Ensure within current bounds
	mov	AGROUP:[edi].COMDAT_NEXT,eax ; Save ptr to next entry
@@:	
OMF_COMDAT_DONE:
	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	jmp	OMF_COMDAT_EXIT ; Join common exit code


COMMENT|

This is a continuation record.
Check for valid and matching previous record.

On entry:

DS:ESI	==>	data

|

OMF_COMDAT_CONT:
	mov	edi,LAST_COMDAT ; Get ptr to last COMDAT entry

	cmp	edi,-1		; Izit invalid?
	je	near ptr OMF_COMDAT_ERRCONT1 ; Jump if so

; Make sure the continuation record has the same Flags, Attributes,
; Alignment, Public Base Group/Segment, and Public Name Index
; as the previous record.
; Note that the offset (CDOFF) might be different.

	mov	al,CDFLAG	; Get the flag byte
	and	al,not @CDFL_CONT ; Clear the continuation bit

	UNCURB	edi,COMDAT	; Ensure within current bounds
	cmp	al,AGROUP:[edi].COMDAT_FLAG ; Izit the same?
	jne	near ptr OMF_COMDAT_ERRCONT2 ; Jump if not
	
	mov	al,CDATTR	; Get the attribute byte

;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	cmp	al,AGROUP:[edi].COMDAT_ATTR ; Izit the same?
	jne	near ptr OMF_COMDAT_ERRCONT2 ; Jump if not

	mov	al,CDALIN	; Get the alignment byte

;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	cmp	al,AGROUP:[edi].COMDAT_ALIN ; Izit the same?
	jne	near ptr OMF_COMDAT_ERRCONT2 ; Jump if not

	mov	eax,CDPBGRP	; Get the public base group

;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].COMDAT_PBGRP ; Izit the same?
	jne	near ptr OMF_COMDAT_ERRCONT2 ; Jump if not

	mov	eax,CDPBSEG	; Get the public base segment

;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].COMDAT_PBSEG ; Izit the same?
	jne	near ptr OMF_COMDAT_ERRCONT2 ; Jump if not

	mov	eax,CDPNI	; Get the public name index

;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].COMDAT_PNI ; Izit the same?
	jne	near ptr OMF_COMDAT_ERRCONT2 ; Jump if not

; All checks out:  add in the new length, append the new data
; recalculate the checksum

	mov	ecx,THISOBJ_CSUM ; Get the offset of the checksum
	sub	ecx,esi 	; Less the current offset to get remaining length
;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	mov	eax,AGROUP:[edi].COMDAT_LEN ; Get the old length
;;;;;;; UNCURB	edi,COMDAT	; Ensure within current bounds
	add	AGROUP:[edi].COMDAT_LEN,ecx ; Add in the new length
	mov	ebx,AGROUP:[edi].COMDAT_LEN ; Save new length
	
	add	edi,type COMDAT_STR ; Skip over the header
	mov	edx,edi 	; Save as start of checksum area
	add	edi,eax 	; Skip to the end of the data
	
	cmp	edi,LMB_COMDAT.LMB_CURB.BOUND_NXT ; Get LA of next entry
	je	short @F	; Jump if so

	int	03h		; Hard stop -- this should never occur
@@:
	UNCURB	edi,COMDAT	; Ensure within current bounds
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy as segment data
	xchg	LMB_COMDAT.LMB_CURB.BOUND_NXT,edi ; Save as LA of next entry

	xchg	edx,esi 	; Swap ptrs
	mov	ecx,ebx 	; Get the new length
	call	CalcChecksum	; Calculate the checksum of DS:ESI,
				; length ECX bytes, return in EAX
	xchg	esi,edx 	; Restore
	mov	edi,LAST_COMDAT ; Get ptr to last COMDAT entry
	mov	AGROUP:[edi].COMDAT_CSUM,eax ; Save as new checksum
	
	jmp	OMF_COMDAT_DONE ; Join common ending code


OMF_COMDAT_ERRCSUM:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_CSUM) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_CSUM1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	OMF_COMDAT_ERRCOM ; Join common error code


OMF_COMDAT_ERRLEN:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_LEN) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_LEN1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	OMF_COMDAT_ERRCOM ; Join common error code


OMF_COMDAT_ERRUNIQ:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_UNIQ) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_UNIQ1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	OMF_COMDAT_ERRCOM ; Join common error code


OMF_COMDAT_ERRCONT1:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_CONT1) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_CONT11) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	OMF_COMDAT_ERRCOM ; Join common error code


OMF_COMDAT_ERRCONT2:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure
	
	push	dword ptr (offset DGROUP:MSG_CD_CONT2) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_CONT21) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	OMF_COMDAT_ERRCOM ; Join common error code
	

OMF_COMDAT_ERRFLAG:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_FLAG) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_FLAG1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	short OMF_COMDAT_ERRCOM ; Join common error code

OMF_COMDAT_ERRSEL:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_SEL) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_SEL1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	short OMF_COMDAT_ERRCOM ; Join common error code

OMF_COMDAT_ERRTYP:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_TYP) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_TYP1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	short OMF_COMDAT_ERRCOM ; Join common error code

OMF_COMDAT_ERRALIN:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_ALIN) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_ALIN1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	short OMF_COMDAT_ERRCOM ; Join common error code

OMF_COMDAT_APPND:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...

	inc	ERRCNT		; Mark as writing to error file

;;;;;;; jmp	short OMF_COMDAT_ERRCOM ; Join common error code


OMF_COMDAT_ERRCOM:
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	dec	ERRCNT		; Mark as no longer writing to error file
OMF_COMDAT_ERR:
	call	DUMPIT		; Dump all the tables

	stc			; Mark as in error
OMF_COMDAT_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_COMDAT endp 		; End OMF_COMDAT procedure
	NPPROC	COMDAT_SYMBOL -- Check For Valid COMDAT Symbol
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check for valid COMDAT symbol

On entry:

AGROUP:EBX ==>	SYM_STR

On exit:

ZF	=	1 if OK
	=	0 it not

|

	REGSAVE <eax>		; Save register

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	cmp	AGROUP:[ebx].SYM_PERITEM,0 ; Izit undefined?
	je	short COMDAT_SYMBOL_EXIT ; Jump if so (note ZF=1)

; Check for CEXTDEF, EXTDEF, or new symbol entry in which case we
; replace it with a PUBDEF record

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_FLAG ; Get the flags
	and	eax,@SYMFL_CL_SYM or @SYMFL_EXT or @SYMFL_PUB ; Isolate
				; symbol/public/external
	cmp	eax,@SYMFL_CL_SYM or @SYMFL_EXT ; Izit EXTDEF/CEXTDEF
				; symbol and not public?
	je	short COMDAT_SYMBOL_EXIT ; Jump if so (note ZF=1)

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	cmp	AGROUP:[ebx].SYM_PERITEM,-1 ; Izit new?
				; Fall through with ZF significant
COMDAT_SYMBOL_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMDAT_SYMBOL endp		; End COMDAT_SYMBOL procedure
	NPPROC	GetCOMDAT_SEG -- Get COMDAT Segment
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get or create a COMDAT segment to match the attributes in CDATTR.
If the length of this entry plus the length of the existing
16-bit segment exceeds 64KB, create a new 16-bit segment.

On exit:

EAX	=	LA of PERSEG_STR

CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ebx,ecx,edx,esi,edi> ; Save registers

	xor	ecx,ecx 	; Zero to use as dword
	mov	cl,CDATTR	; Get the attribute byte
	and	cl,@CDAT_TYP	; Isolate the allocation type
	shr	cl,$CDAT_TYP	; Shift to low-order
	dec	ecx		; Convert to origin-0
	js	near ptr GetCOMDAT_SEGExplicit ; Jump if explicit segment

	cmp	COMDAT_SEGTAB[ecx*(type COMDAT_SEGTAB)],0 ; Izit undefined?
	je	short GetCOMDAT_SEG1 ; Jump if so

	test	COMDAT_SEGACBP[ecx*(type COMDAT_SEGACBP)],@ACBP_P ; Izit USE32?
	jnz	near ptr GetCOMDAT_SEGDone1 ; Jump if so (no 64KB limit)

; Check the total length

	mov	eax,COMDAT_SEGTAB[ecx*(type COMDAT_SEGTAB)] ; Get LA or PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_NEWLEN ; Get the length so far
	add	eax,CDLEN	; Plus the length of this portion

	cmp	eax,@CON64KB	; Izit too large?
	jb	near ptr GetCOMDAT_SEGDone1 ; Jump if not

; Bump the segment name suffix
; Note that the technique we've chosen works
; for nine 64KB segments only.	*FIXME*

	mov	eax,COMDAT_SEGNAM[ecx*(type COMDAT_SEGNAM)] ; Get offset of
				; name in (Count, Char[]) format
	movzx	ebx,DGROUP:[eax].LO ; Get the name length
	inc	DGROUP:[eax+ebx].LO ; Increment the last byte

; Define a new segment

GetCOMDAT_SEG1:
	mov	SEGDEF_LEN,0	; Mark as zero-length segment so far
	
	push	0		; Mark as normal segment
	call	SETUP_NEWSEG	; Setup a new segment
	jc	near ptr GetCOMDAT_SEGExit ; Jump if something went wrong (note CF=1)

	mov	edx,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	edx,type PERSEG_STR ; Back off to previous struc

	mov	COMDAT_SEGTAB[ecx*(type COMDAT_SEGTAB)],edx ; Save for next time

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_FLAG,@PERSEG_OTHGRP ; It's not in DGROUP

; Add the segment name symbol to the symbol table

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

; ES:EDI ==> work area

; Save the segment name

	mov	eax,COMDAT_SEGNAM[ecx*(type COMDAT_SEGNAM)] ; Get offset of
				; name in (Count, Char[]) format
	add	eax,LaDATA	; Plus LA of DGROUP to get LA of text
	push	eax		; Pass LA of text (Count, Char[])
	call	COPY_CNTCHR	; Copy (Count, Char[]) to ES:EDI
				; Return EDI ==> updated
; Save the class name (none)

	mov	al,0		; Marker for empty class name
	stos	AGROUP:[edi].LO ; Save in the work area

; Save the segment combine type

	mov	al,ACBP 	; Get the ACBP byte
	and	al,@ACBP_C	; Isolate the combine types
	stos	AGROUP:[edi].LO ; Save in the work area

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	mov	WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SEG or @SYMFL_SEG ; Mark as segment class

; Lookup this Segment-Class-CombineType in the symbol table

; See if this entry already exists in the symbol table

	REGSAVE <esi>		; Save for a moment

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	jnc	short @F	; Jump if already in the table (note CF=0)

; Do we need to validate this symbol as we do in OMF_SEGDEF???
; *FIXME*








; Append the entry to the symbol table

;;;;;;; lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;; add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
@@:
	REGREST <esi>		; Restore
	jc	near ptr GetCOMDAT_SEG_APPND ; Jump if something went wrong

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,edx ; Save in symbol table

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_SEGSYM,ebx ; Save as ptr to SYM_STR

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edx].PERSEG_PPEROBJ,eax ; Save LA of this .OBJ file

; Save LA of PERSEG table in SEGDEF table

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG strucs
	mov	edi,LMB_SEGDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry
	UNOVRB	edi,SEGDEF	; Ensure within overall bounds
	stos	(type SEGDEF_PPERSEG) ptr AGROUP:[edi] ; Save in SEGDEF table
	mov	LMB_SEGDEF.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

; If this is a 32-bit segment, note that for later use (.MAP file display)

	test	ACBP,@ACBP_P	; Izit a 32-bit segment?
	jz	short @F	; Jump if not

	or	LCL_FLAG,@LCL_SEG32 ; Mark it as such
@@:

; If the user has specified /MAP:FULL, save info about this segment
; piece in LMB_SEGOBJ

	push	edx		; Pass LA of segment (PERSEG_STR)
	call	LINK_SEGOBJ	; Link in this segment

	jmp	short GetCOMDAT_SEGDone ; Join common done code


; The segment allocation is explicit as specified
; in the Public Base Group and Segment Fields

GetCOMDAT_SEGExplicit:
	mov	eax,CDPBSEG	; Get the Public Base Segment (-1=none)
	
	cmp	eax,-1		; Izit absent?
	je	short GetCOMDAT_SEG_ERRExpl ; Jump if so
	
	imul	eax,type SEGDEF_STR ; Convert to index for SEGDEF_STRs
	add	eax,LMB_SEGDEF.LMB_CURB.BOUND_BEG ; Plus starting address
	UNCURB	eax,SEGDEF	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SEGDEF_PPERSEG ; Get LA of PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds

	jmp	short GetCOMDAT_SEGDone2 ; Join common done code


GetCOMDAT_SEGDone:
	xor	ecx,ecx 	; Zero to use as dword
	mov	cl,CDATTR	; Get the attribute byte
	and	cl,@CDAT_TYP	; Isolate the allocation type
	shr	cl,$CDAT_TYP	; Shift to low-order
	dec	ecx		; Convert to origin-0
GetCOMDAT_SEGDone1:
	mov	eax,COMDAT_SEGTAB[ecx*(type COMDAT_SEGTAB)] ; Get LA or PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
GetCOMDAT_SEGDone2:
	clc			; Mark as successful
	
	jmp	short GetCOMDAT_SEGExit ; Join common exit code
	
	
GetCOMDAT_SEG_ERRExpl:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_CD_EXPL) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_CD_EXPL1) ; ...

	inc	ERRCNT		; Mark as writing to error file

	jmp	short GetCOMDAT_SEG_ERRCOM ; Join common error code
	

GetCOMDAT_SEG_APPND:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...

	inc	ERRCNT		; Mark as writing to error file

;;;;;;; jmp	short GetCOMDAT_SEG_ERRCOM ; Join common error code

GetCOMDAT_SEG_ERRCOM:
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	dec	ERRCNT		; Mark as no longer writing to error file

	stc			; Mark as in error
GetCOMDAT_SEGExit:
	REGREST <edi,esi,edx,ecx,ebx> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetCOMDAT_SEG endp		; End GetCOMDAT_SEG procedure
	NPPROC	CalcChecksum -- Calculate Checksum
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate a checksum

On entry:

DS:ESI	==>	data
ECX	=	length of ...

On exit:

EAX	=	checksum

|

	REGSAVE <ebx,ecx,esi>	; Save registers

	xor	ebx,ebx 	; Get default checksum
	jecxz	CalcChecksumExit ; Jump if empty
	xor	eax,eax 	; Zero to use as dword
@@:
	lods	ds:[esi].LO	; Get next byte

	add	ebx,eax 	; Add to get new checksum

	loop	@B		; Jump if more bytes
CalcChecksumExit:
	mov	eax,ebx 	; Copy to return register

	REGREST <esi,ecx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CalcChecksum endp		; End CalcChecksum procedure
	NPPROC	OMF_ALIAS -- Alias Definition Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Alias definition names record (C6h).

On entry:

DS:ESI	==>	OBJHDR_STR

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	add	esi,type OBJHDR_STR ; Skip over the header
OMF_ALIAS_NEXT:

; Lookup the alias symbol

	push	@LOOKUP_APP or @LOOKUP_ESI ; Append if not found, advance ESI
	push	esi		; Pass LA of text (Count, Char[])
	push	@SYMFL_CL_SYM	; Mark as symbol class
	call	LOOKUP_SYM	; Lookup the symbol
				; Return EBX = LA of matching entry (SYM_STR)
				;	 ESI = advanced past text
	jc	near ptr OMF_ALIAS_APPND ; Jump if something went wrong

; If this symbol is already public, ignore this alias record
; *FIXME* Should we be concerned about this?

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[ebx].SYM_FLAG,@SYMFL_PUB ; Izit already public?
	jz	short @F	; Jump if not

; Skip over the substitute symbol

	xor	eax,eax 	; Zero to use as dword
	lods	ds:[esi].LO	; Get the length byte
	add	esi,eax 	; Skip over the text

	jmp	OMF_ALIAS_LOOP	; Join common loop code

@@:

; Ensure there's no duplicate alias symbols

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	bts	AGROUP:[ebx].SYM_FLAG,$SYMFL_ALIAS ; Izit already aliased?
	jnc	short OMF_ALIAS1 ; Jump if not

; Complain (if /INFO specified) and use the new substitute

	test	ARG_FLAG,@ARG_INFO ; Is /INFO specified?
	jz	short OMF_ALIAS1 ; Jump if not
;;; *FIXME* What else does /INFO display???
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_ALIAS) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the symbol name

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	push	AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_ALIAS1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
OMF_ALIAS1:

; Lookup the substitute symbol

	mov	edx,ebx 	; Copy alias symbol (SYM_STR)

	push	@LOOKUP_APP or @LOOKUP_ESI ; Append if not found, advance ESI
	push	esi		; Pass LA of text (Count, Char[])
	push	@SYMFL_CL_SYM	; Mark as symbol class
	call	LOOKUP_SYM	; Lookup the symbol
				; Return EBX = LA of matching entry (SYM_STR)
				;	 ESI = advanced past text
	jc	near ptr OMF_ALIAS_APPND ; Jump if something went wrong

	xchg	ebx,edx        ; Swap so EBX is first symbol, EDX second

; EBX	=	LA of alias symbol (SYM_STR)
; EDX	=	LA of substitute symbol (SYM_STR)

	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_SUBST ; Mark as substitutable
	mov	AGROUP:[ebx].SYM_SUBST,edx ; Save ptr to subst symbol (SYM_STR)

; If the subst symbol is already public, no need to save a back ptr

	test	AGROUP:[edx].SYM_FLAG,@SYMFL_PUB ; Izit already public?
	jnz	short OMF_ALIAS2 ; Jump if so

	or	AGROUP:[edx].SYM_FLAG,@SYMFL_BKPTR ; Mark as back ptr present
				; in subst (SYM_STR)
	mov	AGROUP:[edx].SYM_PERITEM,ebx ; Save as back ptr

	jmp	short OMF_ALIAS3 ; Join common code

OMF_ALIAS2:
	mov	eax,AGROUP:[edx].SYM_PERITEM ; Get subst PUBDEF_STR
	mov	AGROUP:[ebx].SYM_PERITEM,eax ; Save in alias
	or	AGROUP:[ebx].SYM_FLAG,@SYMFL_PUB ; Mark alias as public
OMF_ALIAS3:

; If we're in a debuggin' mood, display the alias symbols

	test	ARG_FLAG,@ARG_DBGMSG ; Displaying debugging messages?
	jz	short OMF_ALIAS_XDBG ; Jump if not

	pushad			; Save for a moment

	push	edx		; Save for a moment

	lea	edx,DBGMSG_ALIAS ; Get line start
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	mov	edx,AGROUP:[ebx].SYM_PNAM ; Get LA of 1st symbol (Count, Char[])
	movzx	ecx,ds:[edx].LO ; Get the count
	inc	edx		; Skip over it
	mov	bx,@STD_OUT	; Send to standard output
	DOSCALL @WRITF2 	; Write it out

	lea	edx,DBGMSG_SEP	; Get separator
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	pop	edx		; Restore

	mov	edx,AGROUP:[edx].SYM_PNAM ; Get LA of 2nd symbol (Count, Char[])
	movzx	ecx,ds:[edx].LO ; Get the count
	inc	edx		; Skip over it
	mov	bx,@STD_OUT	; Send to standard output
	DOSCALL @WRITF2 	; Write it out

	lea	edx,MSG_CRLF	; Get line ending
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	popad			; Restore
OMF_ALIAS_XDBG:
	jmp	short OMF_ALIAS_LOOP ; Join common loop code

;;;; ; Copy data from substitute symbol to alias' SYM_STR
;;;;
;;;;	      UNCURB  edx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     eax,AGROUP:[edx].SYM_PERITEM ; Get LA of subst per-item
;;;; ;;;;;;;; UNCURB  ebx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     AGROUP:[ebx].SYM_PERITEM,eax ; Save as original symbol's per-item
;;;;
;;;; ; If the substituted symbol is public, save the alias symbol (SYM_STR) there
;;;;
;;;; ;;;;;;;; UNCURB  edx,SYMBOL     ; Ensure within current bounds
;;;;	      test    AGROUP:[edx].SYM_FLAG,@SYMFL_PUB ; Izit public?
;;;;	      jz      short @F	     ; Jump if not
;;;;
;;;; ;;;;;;;; UNCURB  edx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     eax,AGROUP:[edx].SYM_PERITEM ; Get LA of substitute per-item
;;;;	      UNCURB  eax,PUBDEF     ; Ensure within current bounds
;;;;	      mov     AGROUP:[eax].PUBDEF_PSYM,ebx ; Save as new symbol (SYM_STR)
;;;; @@:
;;;;;;;;;;;; UNCURB  edx,SYMBOL     ; Ensure within current bounds
;;;;	     mov     eax,AGROUP:[edx].SYM_FLAG ; Get resolver's flags
;;;;;;;;;;;; UNCURB  ebx,SYMBOL     ; Ensure within current bounds
;;;;	     and     AGROUP:[ebx].SYM_FLAG,not @SYMFL_ALIAS ; Clear alias bit
;;;;	     or      AGROUP:[ebx].SYM_FLAG,eax ; Include with original symbol's flags
;;;;
;;;; ; In order to handle aliased symbols, we mark the old symbol location
;;;; ; as substituted with a pointer to the new symbol, because the old symbol location
;;;; ; still gets referenced by the hash algorithm.
;;;;
;;;;	      bts     eax,$SYMFL_SUBST ; Mark as substituted
;;;;	      mov     AGROUP:[edx].SYM_FLAG,eax ; Save in substitute location
;;;;	      mov     AGROUP:[edx].SYM_PERITEM,ebx ; Save ptr to real symbol (SYM_STR)
;;;;
;;;; ;;;;;;;; UNCURB  edx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     eax,AGROUP:[edx].SYM_PNAM ; Get LA of symbol
;;;; ;;;;;;;; UNCURB  ebx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     AGROUP:[ebx].SYM_PNAM,eax ; Save as original symbol's name
;;;; ;;;;;;;; UNCURB  edx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     eax,AGROUP:[edx].SYM_NAMLEN ; Get length of name
;;;; ;;;;;;;; UNCURB  ebx,SYMBOL     ; Ensure within current bounds
;;;;	      mov     AGROUP:[ebx].SYM_NAMLEN,eax ; Save as original symbol's length
;;;; ;;;
;;;; ;;;	  UNCURB  ebx,SYMBOL	 ; Ensure within current bounds
;;;; ;;;	  mov	  AGROUP:[ebx].SYM_PERITEM,edx ; Save LA of substitute (SYM_STR)
;;;; ;;;				 ; in alias (SYM_STR)
;;;; ;;; ;;;;;;;; UNCURB  ebx,SYMBOL	 ; Ensure within current bounds
;;;; ;;;	  or	  AGROUP:[ebx].SYM_FLAG,@SYMFL_ALIAS ; Mark as aliased
;;;; ;;;				 ; in alias (SYM_STR)
;;;;
;;;; ; In case there's a fixup pointing to the substituted symbol,
;;;; ; change that reference to the alias symbol
;;;;
;;;;	      mov     eax,LMB_FIXUPP.LMB_CURB.BOUND_BEG ; Get starting address
;;;; OMF_ALIAS_FIXNEXT:
;;;;	      cmp     eax,LMB_FIXUPP.LMB_CURB.BOUND_NXT; Are we at the end?
;;;;	      je      short OMF_ALIAS_FIXEND ; Jump if so
;;;;
;;;;	      UNCURB  eax,FIXUPP     ; Ensure within current bounds
;;;;	      cmp     edx,AGROUP:[eax].FIXUPP_FRM ; Duzit match the frame?
;;;;	      jne     short @F	     ; Jump if not
;;;;
;;;; ;;;;;;;; UNCURB  eax,FIXUPP     ; Ensure within current bounds
;;;;	      mov     AGROUP:[eax].FIXUPP_FRM,ebx ; Save as alias SYM_STR
;;;; @@:
;;;; ;;;;;;;; UNCURB  eax,FIXUPP     ; Ensure within current bounds
;;;;	      cmp     edx,AGROUP:[eax].FIXUPP_TGT ; Duzit match the target?
;;;;	      jne     short @F	     ; Jump if not
;;;;
;;;; ;;;;;;;; UNCURB  eax,FIXUPP     ; Ensure within current bounds
;;;;	      mov     AGROUP:[eax].FIXUPP_TGT,ebx ; Save as alias SYM_STR
;;;; @@:
;;;;	      add     eax,type FIXUPP_STR ; Skip to next entry
;;;;
;;;;	      jmp     OMF_ALIAS_FIXNEXT ; Go around again
;;;;
;;;; OMF_ALIAS_FIXEND:
OMF_ALIAS_LOOP:

; We're finished with this portion of this record -- check for repeats

	cmp	esi,THISOBJ_CSUM ; Are we at the end of the record?
	jb	near ptr OMF_ALIAS_NEXT ; Jump if more names to check

	call	CHECK_CNT	; Ensure the record count comes out even
				; Return with CF significant
	jmp	OMF_ALIAS_EXIT	; Join common exit code


OMF_ALIAS_APPND:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	push	dword ptr (offset DGROUP:MSG_OBJAPPND) ; Pass offset of message
	push	dword ptr (offset DGROUP:MSG_OBJAPPND1) ; ...

	inc	ERRCNT		; Mark as writing to error file

;;;;;;; jmp	short OMF_ALIAS_ERRCOM ; Join common error code

OMF_ALIAS_ERRCOM:
	call	DISP_ERRDD	; Format and fill in a DD and display error msg

	dec	ERRCNT		; Mark as no longer writing to error file

	call	DUMPIT		; Dump all the tables

	stc			; Mark as in error
OMF_ALIAS_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OMF_ALIAS endp			; End OMF_ALIAS procedure
	NPPROC	MARK_MATCHED -- Mark EXTDEF As Matched
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Mark an EXTDEF as matched

On entry:

AGROUP:EAX ==>	EXTDEF_STR

|

	UNCURB	eax,EXTDEF	; Ensure within current bounds
	or	AGROUP:[eax].EXTDEF_FLAG,@EXTDEF_MAT ; Mark as matched

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARK_MATCHED endp		; End MARK_MATCHED procedure
	NPPROC	CheckNameSub -- Check Name Substitutions
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check for Name Substitutions

On entry:

DS:ESI	==>	(Cnt,Chr[]) of incoming name
ECX	=	length of ... including length byte

On exit:

DS:ESI	==>	(Cnt,Chr[]) of outgoing name
ECX	=	length of ... including length byte

|

	REGSAVE <eax,ebx,edx>	; Save registers

; Loop through the linked list of names

	mov	edx,NS_HEAD	; AGROUP:EDX ==> head of linked list
	dec	ecx		; Less length byte
	inc	esi		; Skip over ...
CheckNameSubNext:
	cmp	edx,-1		; Izit invalid?
	je	near ptr CheckNameSubExit ; Jump if so

	mov	eax,THISOBJ_STR ; DS:EBX ==> current POBJ_STR
	mov	ax,AGROUP:[eax].POBJ_SEQ ; Get the sequence #

	cmp	ax,AGROUP:[edx].NS_OBJSEQ ; Izit in range?
	jb	short CheckNameSubLoop ; Jump if not

; Check for stop substitution for this symbol

	test	AGROUP:[edx].NS_FLAG,@NS_STOP ; Izit to be stopped?
	jz	short CheckNameSubNext1 ; Jump if not

; Loop through records from the beginning looking for this symbol

	mov	ebx,NS_HEAD	; AGROUP:EBX ==> head of linked list
CheckNameSub1:
	cmp	ebx,edx 	; Are we back where we started?
	je	short CheckNameSubDelete ; Jump if so

	cmp	AGROUP:[ebx].NS_OBJSEQ,-1 ; Izit deleted?
	je	short @F	; Jump if so

	cmp	cl,AGROUP:[ebx].NS_LEN1 ; Izit same langth?
	jne	short @F	; Jump if not

	push	ds		; Pass incoming segment
	push	esi		; ...		offset
	push	ds		; ...  substituting segment
	lea	eax,AGROUP:[ebx].NS_NAME1 ; Get ptr to Name1
	push	eax		; ...  substituting offset
	push	ecx		; ...  length
	call	StrNICmp	; Compare the two strings

	and	ax,ax		; Izit equal?
	jnz	short @F	; Jump if not

	mov	AGROUP:[ebx].NS_OBJSEQ,-1 ; Mark as deleted
@@:
	mov	ebx,AGROUP:[ebx].NS_NEXT ; Get ptr to next entry

	jmp	CheckNameSub1	; Go around again


; Check for halt to all substitutions

CheckNameSubNext1:
	test	AGROUP:[edx].NS_FLAG,@NS_HALT ; Izit to be halted?
	jz	short CheckNameSubNext2 ; Jump if not

; Set new head

	mov	eax,AGROUP:[edx].NS_NEXT ; Get next entry
	mov	NS_HEAD,eax	; Save as new head

	jmp	short CheckNameSubLoop ; Join common loop code


; Check for a match

CheckNameSubNext2:
	cmp	cl,AGROUP:[edx].NS_LEN1 ; Izit same langth?
	jne	short CheckNameSubLoop ; Jump if not

	push	ds		; Pass incoming segment
	push	esi		; ...		offset
	push	ds		; ...  substituting segment
	lea	eax,AGROUP:[edx].NS_NAME1 ; Get ptr to Name1
	push	eax		; ...  substituting offset
	push	ecx		; ...  length
	call	StrNICmp	; Compare the two strings

	and	ax,ax		; Izit equal?
	jnz	short CheckNameSubLoop ; Jump if not

	lea	esi,AGROUP:[edx].NS_LEN1 ; Get ptr to Name1
	movzx	ecx,AGROUP:[esi].LO ; Get its length
	inc	esi		; Skip over it
	add	esi,ecx 	; Skip over Name1 to Name2
	movzx	ecx,AGROUP:[esi].LO ; Get its length
	inc	esi		; Skip over it

	jmp	short CheckNameSubExit ; Join common exit code


CheckNameSubDelete:
	mov	AGROUP:[ebx].NS_OBJSEQ,-1 ; Mark as deleted
CheckNameSubLoop:
	mov	edx,AGROUP:[edx].NS_NEXT ; Get ptr to next entry
	
	jmp	CheckNameSubNext ; Go around again
	

CheckNameSubExit:
	dec	esi		; Back off to length byte
	inc	ecx		; Plus length byte
	
	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckNameSub	endp		; End CheckNameSub procedure
	NPPROC	CopyCountChar -- Copy (Count, Char[]) 
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Copy a (Count, Char[]) pair to a destinaton
and check for Name Substitution

On entry:

AGROUP:EDI ==>	Work area
AGROUP:ESI ==>	(Count, Char[])
ECX	=	Count from above

On exit:

ESI	=	(updated)
EDI	=	(updated)

|

; Check for Name Substitution	      

	REGSAVE <ecx,esi>	; Save original values
	
	call   CheckNameSub	; Check for substitutions for name at
				; DS:ESI of length ECX
				; Return AGROUP:ESI ==> name
				; ...	 ECX = length
    rep movs	AGROUP:[edi].LO,ds:[esi].LO ; Copy to the work area

	REGREST <esi,ecx>	; Restore
	
	add	esi,ecx 	; Skip over name in original record
	xor	ecx,ecx 	; Zero as per rep movs

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CopyCountChar endp		; End CopyCountChar procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_OMF module
