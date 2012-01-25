;' $Header:   P:/PVCS/MISC/QLINK/QLNK_DMP.ASV   1.1   17 Jul 1997 12:36:44   BOB  $
	title	QLNK_DMP -- QLINK Dump Routines
	page	58,122
	name	QLNK_DMP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2002 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, August, 1994.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include PTR.INC
	include DOSCALL.INC
	include ASCII.INC
	include ALLMEM.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DISP_MAC macro	TTL,NAM,VAL,NAM2
	local	TYP,REG,FN

ifnb <VAL>
TYP	equ	type &TTL&_&VAL
else
TYP	equ	type &TTL&_&NAM
endif

if TYP eq 1
REG	equ	<al>
FN	equ	<DB2HEX>
elseif TYP eq 2
REG	equ	<ax>
FN	equ	<DW2HEX>
else
REG	equ	<eax>
FN	equ	<DD2HEX>
endif

ifnb <VAL>
	mov	REG,AGROUP:[esi].&TTL&_&VAL ; Get offset
else
	mov	REG,AGROUP:[esi].&TTL&_&NAM ; Get offset
endif
ifnb <NAM2>
	lea	edi,TXT_&TTL&_&NAM2&1 ; ES:EDI ==> format area
else
	lea	edi,TXT_&TTL&_&NAM&1 ; ES:EDI ==> format area
endif
%	call	FN		; Convert REG to hex at ES:EDI

	push	eax		; Save for a moment
ifnb <NAM2>
	DOSCALL @STROUT,TXT_&TTL&_&NAM2 ; Display header message
else
	DOSCALL @STROUT,TXT_&TTL&_&NAM ; Display header message
endif
	pop	eax		; Restore

	endm			; DISP_MAC

DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	DMP_FLAG:dword
	include QLNK_DMP.INC

	extrn	EXE_WIN:byte

	extrn	LMB_TXTSTR:tbyte
	extrn	LMB_PERMOD:tbyte
	extrn	LMB_PERLSEG:tbyte
	extrn	LMB_PERCLS:tbyte
	extrn	LMB_PERGRP:tbyte
	extrn	LMB_PERSEG:tbyte
	extrn	LMB_PEROBJ:tbyte
	extrn	LMB_LNAMES:tbyte
;;;;;;; extrn	LMB_LINNUM:tbyte
	extrn	LMB_SYMBOL:tbyte
;;;;;;; extrn	LMB_SYMHSH:tbyte
;;;;;;; extrn	LMB_SEGDEF:tbyte
;;;;;;; extrn	LMB_GRPDEF:tbyte
;;;;;;; extrn	LMB_EXTDEF:tbyte
	extrn	LMB_PUBDEF:tbyte
;;;;;;; extrn	LMB_COMDEF:tbyte
	extrn	LMB_FIXUPP:tbyte
;;;;;;; extrn	LMB_SEGOBJ:tbyte
;;;;;;; extrn	LMB_BAKPAT:tbyte
	extrn	LMB_IMPDEF:tbyte
;;;;;;; extrn	LMB_EXPDEF:tbyte
;;;;;;; extrn	LMB_COMDAT:tbyte
;;;;;;; extrn	LMB_DEFSEG:tbyte

	public	DumpCount
DumpCount dd	?		; Dump counter

	public	HDR_PEROBJ
HDR_PEROBJ	    db '様> PEROBJ Header Record at '
HDR_PEROBJ1	    db '________',CR,LF,EOS
TXT_PEROBJ_PFID     db '    PFID    = '
TXT_PEROBJ_PFID1    db '________ - ',EOS
TXT_PEROBJ_PTHEADR  db '    PTHEADR = '
TXT_PEROBJ_PTHEADR1 db '________ - ',EOS

	public	HDR_LNAMES
HDR_LNAMES	    db '様> LNAMES Header Record at '
HDR_LNAMES1	    db '________',CR,LF,EOS
TXT_LNAMES_PTXT     db '    PTXT    = '
TXT_LNAMES_PTXT1    db '________ - ',EOS

	public	HDR_PERSEG
HDR_PERSEG	    db '様> PERSEG Header Record at %08X (%u entries)',CR,LF,0
TXT_PERSEG_SEGSYM   db '%.2u: SEGSYM  = %08X - %F.*s',CR,LF,0
TXT_PERSEG_GRPSYM   db '    GRPSYM  = '
TXT_PERSEG_GRPSYM1  db '________ - ',EOS
TXT_PERSEG_CLS	    db '    CLS     = '
TXT_PERSEG_CLS1     db '________ - ',EOS
TXT_PERSEG_LSEG     db ' - LSEG = '
TXT_PERSEG_LSEG1    db '____',EOS
TXT_PERSEG_FLAG     db '    FLAG    = '
TXT_PERSEG_FLAG1    db '________',EOS
TXT_PERSEG_WFLAG    db '    WFLAG   = '
TXT_PERSEG_WFLAG1   db '________',CR,LF,EOS
TXT_PERSEG_GRPLNK   db '    GRPLNK  = '
TXT_PERSEG_GRPLNK1  db '________',EOS
TXT_PERSEG_LEN	    db '    LMB_LEN = '
TXT_PERSEG_LEN1     db '________',EOS
TXT_PERSEG_HNDL     db '    LMB_HNDL= '
TXT_PERSEG_HNDL1    db '________',EOS
TXT_PERSEG_BEG	    db '    LMB_BEG = '
TXT_PERSEG_BEG1     db '________',EOS
TXT_PERSEG_NXT	    db '    LMB_NXT = '
TXT_PERSEG_NXT1     db '________',EOS
TXT_PERSEG_END	    db '    LMB_END = '
TXT_PERSEG_END1     db '________',EOS
TXT_PERSEG_ADRBEG   db '    ADR_BEG = '
TXT_PERSEG_ADRBEG1  db '________',EOS
TXT_PERSEG_ADREND   db '    ADR_END = '
TXT_PERSEG_ADREND1  db '________',EOS
TXT_PERSEG_NEWLEN   db '    NEWLEN  = '
TXT_PERSEG_NEWLEN1  db '________',EOS
TXT_PERSEG_OLDLEN   db '    OLDLEN  = '
TXT_PERSEG_OLDLEN1  db '________',EOS


PSF_STR struc

PSF_VAL dd	?		; Flag value
PSF_TXT dd	?		; Offset in DGROUP of flag text

PSF_STR ends


PSF_MAC macro	NAM,TXT
	local	L1

TEXT	segment 		; Start TEXT segment
	assume	ds:DGROUP

L1	db	TXT,EOS

TEXT	ends			; End TEXT segment


	PSF_STR <NAM, offset DGROUP:L1>

	endm			; PSF_MAC


	public	PSF_TAB
PSF_TAB label tbyte
	PSF_MAC @PERSEG_FIXUP,	<' - Fixup present'>
	PSF_MAC @PERSEG_WFLAG,	<' - WFLAG valid'>
;;;;;;; PSF_MAC @PERSEG_SEQ,	<' - Seg is sequenced'>
	PSF_MAC @PERSEG_TYPES,	<' - Seg is TYPES'>
	PSF_MAC @PERSEG_SYMBOLS,<' - Seg is SYMBOLS'>
	PSF_MAC @PERSEG_SUFCODE,<' - Class suffix CODE'>
	PSF_MAC @PERSEG_BEGDATA,<' - Class is BEGDATA'>
	PSF_MAC @PERSEG_BSS,	<' - Class is BSS'>
	PSF_MAC @PERSEG_STACK,	<' - Class is STACK'>
	PSF_MAC @PERSEG_OTHCLS, <' - Other class'>
	PSF_MAC @PERSEG_DGROUP, <' - Seg in DGROUP'>
	PSF_MAC @PERSEG_OTHGRP, <' - Seg not in DGROUP'>
	PSF_MAC @PERSEG__TEXT,	<' - Seg is _TEXT'>
	PSF_MAC @PERSEG_SKIP,	<' - Seg is skippable'>
@NPSF	equ	($-PSF_TAB)/(type PSF_STR) ; # entries


	public	HDR_PERGRP
HDR_PERGRP	    db '様> PERGRP Header Record at %08X (%u entries)',CR,LF,0
TXT_PERGRP_GRPSYM   db '    GRPSYM  = '
TXT_PERGRP_GRPSYM1  db '________ - ',EOS
TXT_PERGRP_BEG	    db '    START   = '
TXT_PERGRP_BEG1     db '________',EOS
TXT_PERGRP_NXT	    db '    NEXT    = '
TXT_PERGRP_NXT1     db '________',EOS
TXT_PERGRP_GRPLNK   db '    GRPLNK  = '
TXT_PERGRP_GRPLNK1  db '________',EOS

	public	HDR_PERCLS
HDR_PERCLS	    db '様> PERCLS Header Record at %08X (%u entries)',CR,LF,0
TXT_PERCLS_PSYM     db '%.2u:    PSYM = %08X - %F.*s',CR,LF,0
TXT_PERCLS_PERSEG1ST  db '    PERSEG1 = '
TXT_PERCLS_PERSEG1ST1 db '________',CR,LF,EOS
TXT_PERCLS_PERLSEG  db '    PERLSEG = '
TXT_PERCLS_PERLSEG1 db '________',CR,LF,EOS

	public	HDR_PERLSEG
HDR_PERLSEG	    db '様> PERLSEG Header Record at %08X (%u entries)',CR,LF,0
TXT_PERLSEG_LSEG    db '%.2u:    LSEG = %08X',CR,LF,0
TXT_PERLSEG_FLAG    db '    FLAG    = '
TXT_PERLSEG_FLAG1   db '________',CR,LF,EOS
TXT_PERLSEG_LEN     db '    LEN     = '
TXT_PERLSEG_LEN1    db '________',CR,LF,EOS

	public	HDR_PUBDEF
HDR_PUBDEF	    db '様> PUBDEF Header Record at %08X (%u entries)',CR,LF,0
TXT_PUBDEF_PSYM     db '%.2u:    PSYM = %08X - %F.*s',CR,LF,0
TXT_PUBDEF_BEG	    db '    LMB_BEG = '
TXT_PUBDEF_BEG1     db '________',CR,LF,EOS
TXT_PUBDEF_NXT	    db '    LMB_NXT = '
TXT_PUBDEF_NXT1     db '________',CR,LF,EOS
TXT_PUBDEF_BASE     db '       BASE = '
TXT_PUBDEF_BASE1    db '________',CR,LF,EOS
TXT_PUBDEF_PPERGRP  db '    PPERGRP = '
TXT_PUBDEF_PPERGRP1 db '________ - ',EOS
TXT_PUBDEF_PPERSEG  db '    PPERSEG = '
TXT_PUBDEF_PPERSEG1 db '________ - ',EOS
TXT_PUBDEF_PPEROBJ  db '    PPEROBJ = '
TXT_PUBDEF_PPEROBJ1 db '________ - ',EOS

	public	HDR_PUBDEF
HDR_IMPDEF	    db '様> IMPDEF Header Record at %08X (%u entries)',CR,LF,0
TXT_IMPDEF_PPEROBJ  db '%.2u: PPEROBJ = %08X - %F.*s',CR,LF,0
TXT_IMPDEF_ORDINAL  db '    ORDINAL = '
TXT_IMPDEF_ORDINAL1 db '____',CR,LF,EOS
TXT_IMPDEF_FLAG     db '       FLAG = '
TXT_IMPDEF_FLAG1    db '____',CR,LF,EOS
TXT_IMPDEF_PPERMOD  db '    PPERMOD = '
TXT_IMPDEF_PPERMOD1 db '________ - ',EOS
TXT_IMPDEF_INTNAME  db '    INTNAME = '
TXT_IMPDEF_INTNAME1 db '________ - ',EOS
TXT_IMPDEF_EXPNAME  db '    EXPNAME = '
TXT_IMPDEF_EXPNAME1 db '________ - ',EOS
TXT_IMPDEF_ENTRY    db '      ENTRY = '
TXT_IMPDEF_ENTRY1   db '________ - ',EOS

	public	HDR_FIXUPP
HDR_FIXUPP	    db '様> FIXUPP Header Record at %08X (%u entries)',CR,LF,0
TXT_FIXUPP_DRO_BEG  db '%.2u: DRO_BEG = %08X - %F.*s',CR,LF,0
TXT_FIXUPP_DRO_CUR  db '    DRO_CUR = '
TXT_FIXUPP_DRO_CUR1 db '________',CR,LF,EOS
TXT_FIXUPP_OFF	    db '        OFF = '
TXT_FIXUPP_OFF1     db '________',CR,LF,EOS
TXT_FIXUPP_LOCAT    db '      LOCAT = '
TXT_FIXUPP_LOCAT1   db '____',CR,LF,EOS
TXT_FIXUPP_FIXDAT   db '     FIXDAT = '
TXT_FIXUPP_FIXDAT1  db '__',CR,LF,EOS
TXT_FIXUPP_FLAG     db '       FLAG = '
TXT_FIXUPP_FLAG1    db '__',CR,LF,EOS
TXT_FIXUPP_FRM	    db '        FRM = '
TXT_FIXUPP_FRM1     db '________',EOS
TXT_FIXUPP_TGT	    db '        TGT = '
TXT_FIXUPP_TGT1     db '________',EOS
TXT_FIXUPP_DSP	    db '        DSP = '
TXT_FIXUPP_DSP1     db '________',CR,LF,EOS
TXT_FIXUPP_PPERSEG  db '    PPERSEG = '
TXT_FIXUPP_PPERSEG1 db '________ - ',EOS
TXT_FIXUPP_PPEROBJ  db '    PPEROBJ = '
TXT_FIXUPP_PPEROBJ1 db '________ - ',EOS
TXT_FIXUPP_OLDLEN   db '     OLDLEN = '
TXT_FIXUPP_OLDLEN1  db '________',CR,LF,EOS

	public	TXT_FIXUPP_SEG,TXT_FIXUPP_GRP,TXT_FIXUPP_EXT
TXT_FIXUPP_SEG db ' - Segment',EOS
TXT_FIXUPP_GRP db ' - Group',EOS
TXT_FIXUPP_EXT db ' - External',EOS

	public	HDR_PERMOD
HDR_PERMOD	    db '様> PERMOD Header Record at %08X (%u entries)',CR,LF,0
TXT_PERMOD_MODSYM   db '%.2u:  MODSYM = %08X - %F.*s',CR,LF,0
TXT_PERMOD_FLAG     db '       FLAG = '
TXT_PERMOD_FLAG1    db '________',CR,LF,EOS

	public	TXT_CRLF,TXT_SEP
TXT_CRLF db	CR,LF,EOS
TXT_SEP db	' - ',EOS

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	CSEL_4GB:word
	extrn	CSEL_DATA:word

	extrn	DB2HEX:near
	extrn	DW2HEX:near
	extrn	DD2HEX:near
	extrn	DISP_CNTCHR:near
	extrn	PRINTF32:near

	NPPROC	DUMPIT -- Dump All The Tables
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Dump all the tables.

|

	pushad			; Save registers
	REGSAVE <ds,es,fs,gs>	; ...

	mov	ds,CSEL_DATA	; Get DGROUP data selector
	assume	ds:DGROUP	; Tell the assembler about it

	mov	es,CSEL_DATA	; Get DGROUP data selector
	assume	es:DGROUP	; Tell the assembler about it

	mov	fs,CSEL_DATA	; Get DGROUP data selector
	assume	fs:DGROUP	; Tell the assembler about it

	mov	gs,CSEL_4GB	; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

;;;;;;; call	DUMP_TXTSTR	; Dump the small text strings table
	call	DUMP_PERMOD	; ...	   per imported module name table
	call	DUMP_PERLSEG	; ...	   per logical segment table
	call	DUMP_PERCLS	; ...	   per class table
	call	DUMP_PERGRP	; ...	   per group table
	call	DUMP_PERSEG	; ...	   per segment table
	call	DUMP_PEROBJ	; ...	   per .OBJ file table
;;;;;;; call	DUMP_LNAMES	; ...	   list of Names table
;;;;;;; call	DUMP_LINNUM	; ...	   line numbers
;;;;;;; call	DUMP_SYMBOL	; ...	   symbol table
;;;;;;; call	DUMP_SYMHSH	; ...	   symbol name hash table
;;;;;;; call	DUMP_SEGDEF	; ...	   segment definitions table
;;;;;;; call	DUMP_GRPDEF	; ...	   group ...
;;;;;;; call	DUMP_EXTDEF	; ...	   external ...
	call	DUMP_PUBDEF	; ...	   public ...
;;;;;;; call	DUMP_COMDEF	; ...	   communal ...
	call	DUMP_FIXUPP	; ...	   fixup table
;;;;;;; call	DUMP_SEGOBJ	; ...	   segment per .OBJ data
;;;;;;; call	DUMP_BAKPAT	; ...	   backpatch records
	call	DUMP_IMPDEF	; ...	   imported names
;;;;;;; call	DUMP_EXPDEF	; ...	   exported names
;;;;;;; call	DUMP_COMDAT	; ...	   communal data
;;;;;;; call	DUMP_DEFSEG	; ...	   definitions file SEGMENTS data
DUMPIT_EXIT:
	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it
	popad			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMPIT	endp			; End DUMPIT procedure
	NPPROC	DUMP_TXTSTR -- Dump Small Text Strings Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump small text strings table

On exit:

All EGP registers except ESP may be clobbered.

|





	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_TXTSTR endp		; End DUMP_TXTSTR procedure
	NPPROC	DUMP_PEROBJ -- Dump Per .OBJ File Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per .OBJ file table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PEROBJ ; Are we a dumpin'?
	jz	near ptr DUMP_PEROBJ_EXIT ; Jump if not

	mov	esi,LMB_PEROBJ.LMB_CURB.BOUND_BEG ; Get starting address
DUMP_PEROBJ_NEXT:
	cmp	esi,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PEROBJ_EXIT ; Jump if so

	mov	eax,esi 	; Copy offset
	lea	edi,HDR_PEROBJ1 ; ES:EDI ==> format area
	call	DD2HEX		; Convert EAX to hex at ES:EDI

	DOSCALL @STROUT,HDR_PEROBJ ; Display header message

	DISP_MAC PEROBJ,PFID
	push	eax		; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display the FID
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PEROBJ,PTHEADR
	push	eax		; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display the FID
	DOSCALL @STROUT,TXT_CRLF

	add	esi,type PEROBJ_STR ; Skip to next entry

	jmp	DUMP_PEROBJ_NEXT ; Go around again


DUMP_PEROBJ_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PEROBJ endp		; End DUMP_PEROBJ procedure
	NPPROC	DUMP_PERSEG -- Dump Per Segment Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per segment table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PERSEG ; Are we a dumpin'?
	jz	near ptr DUMP_PERSEG_EXIT ; Jump if not

	mov	esi,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_PERSEG_EXIT ; Jump if not

	cmp	esi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERSEG_EXIT ; Jump if so

	mov	eax,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type PERSEG_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_PERSEG ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_PERSEG_NEXT:
	cmp	esi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERSEG_EXIT ; Jump if so

	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERSEG_SEGSYM ; Get value
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	inc	eax		; Skip over it

	push	gs		; Pass ptr to string
	push	eax		; ...
	push	ecx		; ...  length of ...
;;;;;;; UNCURB	esi,PERSEG	; Ensure within current bounds
	push	AGROUP:[esi].PERSEG_SEGSYM ; ...  offset
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_PERSEG_SEGSYM ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*7 	; Strip from stack

	DISP_MAC PERSEG,GRPSYM

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,CLS

	mov	ebx,eax 	; Copy for later use
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PSYM ; Get LA of symbol (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short @F	; Jump if not

	UNCURB	ebx,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERCLS_PERSEG1ST ; Get LA of 1st segment (PERSEG_STR)

	and	eax,eax 	; Izit invalid?
	jz	short @F	; Jump if so

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_CLS ; Get LA of class (PERCLS_STR)

	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)

	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #

	lea	edi,TXT_PERSEG_LSEG1 ; ES:EDI ==> format area
	call	DW2HEX		; Convert AX to hex at ES:EDI

	DOSCALL @STROUT,TXT_PERSEG_LSEG ; Display it
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,FLAG
	call	DispPERSEGFlag	; Display the PERSEG flags at
				; AGROUP:[esi].PERSEG_FLAG
	DISP_MAC PERSEG,WFLAG

	DISP_MAC PERSEG,GRPLNK
;;;;;;; call	DUMP_GRPLNK	; Dump the GRPLNK chain by segment name
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,LMB,LMB.LMB_LEN ,LEN
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,LMB,LMB.LMB_HNDL,HNDL
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,LMB,LMB.LMB_CURB.BOUND_BEG,BEG
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,LMB,LMB.LMB_CURB.BOUND_NXT,NXT
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,LMB,LMB.LMB_OVRB.BOUND_NXT,END
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,ADRB,ADRB.BOUND_BEG,ADRBEG
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,ADRB,ADRB.BOUND_NXT,ADREND
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,NEWLEN
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERSEG,OLDLEN
	DOSCALL @STROUT,TXT_CRLF

	inc	DumpCount	; Count in another entry
	add	esi,type PERSEG_STR ; Skip to next entry

	jmp	DUMP_PERSEG_NEXT ; Go around again


DUMP_PERSEG_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERSEG endp		; End DUMP_PERSEG procedure
	NPPROC	DispPERSEGFlag -- Display PERSEG Flags
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display PERSEG flags

On entry:

AGROUP:ESI ==>	segment (PERSEG_STR)

|

	pushad			; Save registers

	mov	ecx,@NPSF	; Get # flags
	xor	ebx,ebx 	; Initialize index into PERSEG_FLAGTAB
DispPERSEGFlagNext:
	mov	eax,PSF_TAB[ebx*(type PSF_STR)].PSF_VAL ; Get flag value

	test	eax,AGROUP:[esi].PERSEG_FLAG ; Duzit match?
	jz	short DispPERSEGFlagLoop ; Jump if not

	mov	edx,PSF_TAB[ebx*(type PSF_STR)].PSF_TXT ; DS:EDX ==> flag text
	DOSCALL @STROUT 	; Display it
DispPERSEGFlagLoop:
	inc	ebx		; Skip to next flag value

	loop	DispPERSEGFlagNext ; Jump if more flags to test

	DOSCALL @STROUT,TXT_CRLF

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispPERSEGFlag endp		; End DispPERSEGFlag procedure
	NPPROC	DUMP_PERGRP -- Dump Per Group Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per group table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PERGRP ; Are we a dumpin'?
	jz	near ptr DUMP_PERGRP_EXIT ; Jump if not

	mov	esi,LMB_PERGRP.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_PERGRP_EXIT ; Jump if not

	cmp	esi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERGRP_EXIT ; Jump if so

	mov	eax,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type PERGRP_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_PERGRP ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_PERGRP_NEXT:
	cmp	esi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERGRP_EXIT ; Jump if so

	DISP_MAC PERGRP,GRPSYM

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERGRP,GRPLNK
	call	DUMP_GRPLNK	; Dump the GRPLNK chain by segment name
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERGRP,ADRB,ADRB.BOUND_BEG,BEG
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PERGRP,ADRB,ADRB.BOUND_NXT,NXT
	DOSCALL @STROUT,TXT_CRLF

	inc	DumpCount	; Count in another entry
	add	esi,type PERGRP_STR ; Skip to next entry

	jmp	DUMP_PERGRP_NEXT ; Go around again


DUMP_PERGRP_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERGRP endp		; End DUMP_PERGRP procedure
	NPPROC	DUMP_PERCLS -- Dump Per Class Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per class table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PERCLS ; Are we a dumpin'?
	jz	near ptr DUMP_PERCLS_EXIT ; Jump if not

	mov	esi,LMB_PERCLS.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_PERCLS_EXIT ; Jump if not

	cmp	esi,LMB_PERCLS.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERCLS_EXIT ; Jump if so

	mov	eax,LMB_PERCLS.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type PERCLS_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_PERCLS ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_PERCLS_NEXT:
	cmp	esi,LMB_PERCLS.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERCLS_EXIT ; Jump if so

	UNCURB	esi,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERCLS_PSYM ; Get value
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	inc	eax		; Skip over it

	push	gs		; Pass ptr to string
	push	eax		; ...
	push	ecx		; ...  length of ...
;;;;;;; UNCURB	esi,PERCLS	; Ensure within current bounds
	push	AGROUP:[esi].PERCLS_PSYM ; ...	offset
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_PERCLS_PSYM ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*7 	; Strip from stack

	DISP_MAC PERCLS,PERSEG1ST
	DISP_MAC PERCLS,PERLSEG

	inc	DumpCount	; Count in another entry
	add	esi,type PERCLS_STR ; Skip to next entry

	jmp	DUMP_PERCLS_NEXT ; Go around again


DUMP_PERCLS_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERCLS endp		; End DUMP_PERCLS procedure
	NPPROC	DUMP_PERLSEG -- Dump Per Logical Segment Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per logical segment table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PERLSEG ; Are we a dumpin'?
	jz	near ptr DUMP_PERLSEG_EXIT ; Jump if not

	mov	esi,LMB_PERLSEG.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_PERLSEG_EXIT ; Jump if not

	cmp	esi,LMB_PERLSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERLSEG_EXIT ; Jump if so

	mov	eax,LMB_PERLSEG.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type PERLSEG_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_PERLSEG ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_PERLSEG_NEXT:
	cmp	esi,LMB_PERLSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERLSEG_EXIT ; Jump if so

	UNCURB	esi,PERLSEG	; Ensure within current bounds
	push	AGROUP:[esi].PERLSEG_LSEG ; Pass logical segment #
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_PERLSEG_LSEG ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	DISP_MAC PERLSEG,FLAG
	DISP_MAC PERLSEG,LEN

	inc	DumpCount	; Count in another entry
	add	esi,type PERLSEG_STR ; Skip to next entry

	jmp	DUMP_PERLSEG_NEXT ; Go around again


DUMP_PERLSEG_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERLSEG endp		; End DUMP_PERLSEG procedure
	NPPROC	DUMP_LNAMES -- Dump List of Names Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump list of names table

On exit:

All EGP registers except ESP may be clobbered.

|

	mov	esi,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	short DUMP_LNAMES_EXIT ; Jump if not

	cmp	esi,LMB_LNAMES.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	short DUMP_LNAMES_EXIT ; Jump if so

	mov	eax,esi 	; Copy offset
	lea	edi,HDR_LNAMES1 ; ES:EDI ==> format area
	call	DD2HEX		; Convert EAX to hex at ES:EDI

	DOSCALL @STROUT,HDR_LNAMES ; Display header message
DUMP_LNAMES_NEXT:
	cmp	esi,LMB_LNAMES.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	short DUMP_LNAMES_EXIT ; Jump if so

	DISP_MAC LNAMES,PTXT
	push	eax		; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display the FID
	DOSCALL @STROUT,TXT_CRLF

	add	esi,type LNAMES_STR ; Skip to next entry

	jmp	DUMP_LNAMES_NEXT ; Go around again


DUMP_LNAMES_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_LNAMES endp		; End DUMP_LNAMES procedure
	NPPROC	DUMP_SYMBOL -- Dump Symbol Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump symbol table

On exit:

All EGP registers except ESP may be clobbered.

|





	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_SYMBOL endp		; End DUMP_SYMBOL procedure
	NPPROC	DUMP_SYMHSH -- Dump Symbol Name Hash Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump symbol name hash table

On exit:

All EGP registers except ESP may be clobbered.

|





	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_SYMHSH endp		; End DUMP_SYMHSH procedure
	NPPROC	DUMP_EXTDEF -- Dump External Definitions Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump external definitions table

On exit:

All EGP registers except ESP may be clobbered.

|





	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_EXTDEF endp		; End DUMP_EXTDEF procedure
	NPPROC	DUMP_PUBDEF -- Dump Public Definitions Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the public definitions table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PUBDEF ; Are we a dumpin'?
	jz	near ptr DUMP_PUBDEF_EXIT ; Jump if not

	mov	esi,LMB_PUBDEF.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_PUBDEF_EXIT ; Jump if not

	cmp	esi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PUBDEF_EXIT ; Jump if so

	mov	eax,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type PUBDEF_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_PUBDEF ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_PUBDEF_NEXT:
	cmp	esi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PUBDEF_EXIT ; Jump if so

	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_PSYM ; Get value
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	inc	eax		; Skip over it

	push	gs		; Pass ptr to string
	push	eax		; ...
	push	ecx		; ...  length of ...
;;;;;;; UNCURB	esi,PUBDEF	; Ensure within current bounds
	push	AGROUP:[esi].PUBDEF_PSYM ; ...	offset
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_PUBDEF_PSYM ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*7 	; Strip from stack

	DISP_MAC PUBDEF,BASE

	DISP_MAC PUBDEF,ADDR,ADDR.BOUND_BEG,BEG

	DISP_MAC PUBDEF,ADDR,ADDR.BOUND_NXT,NXT

	DISP_MAC PUBDEF,PPERGRP

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PUBDEF,PPERSEG

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC PUBDEF,PPEROBJ

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

;;;;;;; DISP_MAC PUBDEF,SIZ
;;;;;;; DOSCALL @STROUT,TXT_CRLF
;;;;;;;
;;;;;;; DISP_MAC PUBDEF,NELM
;;;;;;; DOSCALL @STROUT,TXT_CRLF
;;;;;;;
;;;;;;; DISP_MAC PUBDEF,SRT
;;;;;;; DOSCALL @STROUT,TXT_CRLF
;;;;;;;
;;;;;;; DISP_MAC PUBDEF,COMDAT
;;;;;;; DOSCALL @STROUT,TXT_CRLF
;;;;;;;
;;;;;;; DISP_MAC PUBDEF,IMPDEF
;;;;;;; DOSCALL @STROUT,TXT_CRLF
;;;;;;;
	inc	DumpCount	; Count in another entry
	add	esi,type PUBDEF_STR ; Skip to next entry

	jmp	DUMP_PUBDEF_NEXT ; Go around again


DUMP_PUBDEF_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PUBDEF endp		; End DUMP_PUBDEF procedure
	NPPROC	DUMP_IMPDEF -- Dump Imported Definitions Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the imported definitions table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_IMPDEF ; Are we a dumpin'?
	jz	near ptr DUMP_IMPDEF_EXIT ; Jump if not

	mov	esi,LMB_IMPDEF.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_IMPDEF_EXIT ; Jump if not

	cmp	esi,LMB_IMPDEF.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_IMPDEF_EXIT ; Jump if so

	mov	eax,LMB_IMPDEF.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type IMPDEF_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_IMPDEF ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_IMPDEF_NEXT:
	cmp	esi,LMB_IMPDEF.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_IMPDEF_EXIT ; Jump if so

	UNCURB	esi,IMPDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].IMPDEF_PPEROBJ ; Get value
	UNCURB	eax,PEROBJ	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PEROBJ_PFID ; Get LA of symbol (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	inc	eax		; Skip over it

	push	gs		; Pass ptr to string
	push	eax		; ...
	push	ecx		; ...  length of ...
;;;;;;; UNCURB	esi,IMPDEF	; Ensure within current bounds
	push	AGROUP:[esi].IMPDEF_PPEROBJ ; ...  offset
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_IMPDEF_PPEROBJ ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*7 	; Strip from stack

	DISP_MAC IMPDEF,ORDINAL
	DISP_MAC IMPDEF,FLAG
	DISP_MAC IMPDEF,PPERMOD

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,PERMOD	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERMOD_MODSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC IMPDEF,INTNAME

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,IMPDEF	; Ensure within current bounds
	push	eax		; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC IMPDEF,EXPNAME

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,IMPDEF	; Ensure within current bounds
	push	eax		; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC IMPDEF,ENTRY

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,IMPDEF	; Ensure within current bounds
	push	eax		; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	inc	DumpCount	; Count in another entry
	add	esi,type IMPDEF_STR ; Skip to next entry

	jmp	DUMP_IMPDEF_NEXT ; Go around again


DUMP_IMPDEF_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_IMPDEF endp		; End DUMP_IMPDEF procedure
	NPPROC	DUMP_PERMOD -- Dump Per Imported Module Name Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the per inmported module table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_PERMOD ; Are we a dumpin'?
	jz	near ptr DUMP_PERMOD_EXIT ; Jump if not

	mov	esi,LMB_PERMOD.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_PERMOD_EXIT ; Jump if not

	cmp	esi,LMB_PERMOD.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERMOD_EXIT ; Jump if so

	mov	eax,LMB_PERMOD.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type PERMOD_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_PERMOD ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_PERMOD_NEXT:
	cmp	esi,LMB_PERMOD.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_PERMOD_EXIT ; Jump if so

	UNCURB	esi,PERMOD	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERMOD_MODSYM ; Get value
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PNAM ; Get LA of symbol (CC_STR)
	UNCURB	eax,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[eax].CC_COUNT ; Get the count
	inc	eax		; Skip over it

	push	gs		; Pass ptr to string
	push	eax		; ...
	push	ecx		; ...  length of ...
;;;;;;; UNCURB	esi,PERMOD	; Ensure within current bounds
	push	AGROUP:[esi].PERMOD_MODSYM ; ...  offset
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_PERMOD_MODSYM ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*7 	; Strip from stack

	DISP_MAC PERMOD,FLAG

	inc	DumpCount	; Count in another entry
	add	esi,type PERMOD_STR ; Skip to next entry

	jmp	DUMP_PERMOD_NEXT ; Go around again


DUMP_PERMOD_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERMOD endp		; End DUMP_PERMOD procedure
	NPPROC	DUMP_FIXUPP -- Dump Fixup Table
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the fixup table

On exit:

All EGP registers except ESP may be clobbered.

|

	test	DMP_FLAG,@DMP_FIXUPP ; Are we a dumpin'?
	jz	near ptr DUMP_FIXUPP_EXIT ; Jump if not

	mov	esi,LMB_FIXUPP.LMB_CURB.BOUND_BEG ; Get starting address

	cmp	esi,0		; Izit initialized?
	je	near ptr DUMP_FIXUPP_EXIT ; Jump if not

	cmp	esi,LMB_FIXUPP.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_FIXUPP_EXIT ; Jump if so

	mov	eax,LMB_FIXUPP.LMB_CURB.BOUND_NXT ; Get next available offset
	sub	eax,esi 	; Less starting offset
	mov	ecx,type FIXUPP_STR ; Get size of each entry
	xor	edx,edx 	; Zero to use as qword
	div	ecx		; Return with EAX = quotient
				; ...	      EDX = remainder
	push	eax		; Pass # entries
	push	esi		; ...  offset
	push	ds		; ...  ptr to format string
	push	offset ds:HDR_FIXUPP ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	mov	DumpCount,0	; Initialize counter
DUMP_FIXUPP_NEXT:
	cmp	esi,LMB_FIXUPP.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	near ptr DUMP_FIXUPP_EXIT ; Jump if so

	UNCURB	esi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[esi].FIXUPP_DRO_BEG ; ...  DRO start
	push	DumpCount	; ...  counter
	push	ds		; ...  ptr to format string
	push	offset ds:TXT_FIXUPP_DRO_BEG ; ...
	call	PRINTF32	; Printf it, return with EAX = # chars printed
	add	esp,4*4 	; Strip from stack

	DISP_MAC FIXUPP,DRO_CUR
	DISP_MAC FIXUPP,OFF
	DISP_MAC FIXUPP,LOCAT
	DISP_MAC FIXUPP,FIXDAT
	DISP_MAC FIXUPP,FLAG
	DISP_MAC FIXUPP,FRM

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	movzx	ebx,AGROUP:[esi].FIXUPP_FIXDAT ; Get the FIXDAT byte
	and	ebx,@FIXDAT_FRM ; Isolate the target method
	shr	ebx,$FIXDAT_FRM ; Shift to low-order
	call	DispFrmTgt	; Display the FRM from AGROUP:ESI in EBX
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC FIXUPP,TGT

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	movzx	ebx,AGROUP:[esi].FIXUPP_FIXDAT ; Get the FIXDAT byte
	and	ebx,@FIXDAT_TGT ; Isolate the target method
	shr	ebx,$FIXDAT_TGT ; Shift to low-order
	call	DispFrmTgt	; Display the TGT from AGROUP:ESI in EBX
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC FIXUPP,DSP
	DISP_MAC FIXUPP,PPERSEG

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC FIXUPP,PPEROBJ

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID
@@:
	DOSCALL @STROUT,TXT_CRLF

	DISP_MAC FIXUPP,OLDLEN

	inc	DumpCount	; Count in another entry
	add	esi,type FIXUPP_STR ; Skip to next entry

	jmp	DUMP_FIXUPP_NEXT ; Go around again


DUMP_FIXUPP_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_FIXUPP endp		; End DUMP_FIXUPP procedure
	NPPROC	DUMP_GRPLNK -- Dump The GRPLNK Chain
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the GRPLNK chain by segment name.

On entry:

EAX	=	LA of PERSEG_STR

|

	pushad			; Save registers
DUMP_GRPLNK_NEXT:
	and	eax,eax 	; Izit valid?
	jz	short DUMP_GRPLNK_EXIT ; Jump if not

	push	eax		; Save for a moment
	DOSCALL @STROUT,TXT_SEP ; Display a separator
	pop	eax		; Restore

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of SYM_STR
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	push	AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (CC_STR)
	call	DISP_CNTCHR	; Display the FID

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_GRPLNK ; Get LA of next PERSEG_STR

	jmp	DUMP_GRPLNK_NEXT ; Go around again


DUMP_GRPLNK_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_GRPLNK endp		; End DUMP_GRPLNK procedure
	NPPROC	DispFrmTgt -- Display Frame/Target Data
	assume	ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

On entry:

EAX	=	FRM or TGT base
EBX	=	@FIXDAT_FT_xxx
AGROUP:ESI ==>	FIXUPP_STR

|

	REGSAVE <eax,edx>	; Save registers

	cmp	ebx,@FIXDAT_FT_SEG ; Izit a PERSEG_STR?
	je	short DispFrmTgtSeg ; Jump if so

	cmp	ebx,@FIXDAT_FT_GRP ; Izit a PERGRP_STR?
	je	short DispFrmTgtGrp ; Jump if so

	cmp	ebx,@FIXDAT_FT_EXT ; Izit a SYM_STR?
	je	short DispFrmTgtExt ; Jump if so

	jmp	short DispFrmTgtExit ; Join common exit code


DispFrmTgtSeg:
	DOSCALL @STROUT,TXT_FIXUPP_SEG ; Display a message






	jmp	short DispFrmTgtExit ; Join common exit code


DispFrmTgtGrp:
	DOSCALL @STROUT,TXT_FIXUPP_GRP ; Display a message








	jmp	short DispFrmTgtExit ; Join common exit code


DispFrmTgtExt:
	DOSCALL @STROUT,TXT_FIXUPP_EXT ; Display a message





;;;;;;; jmp	short DispFrmTgtExit ; Join common exit code


DispFrmTgtExit:
	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispFrmTgt endp 		; End DispFrmTgt procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_DMP module
