;' $Header:   P:/PVCS/MISC/QLINK/QLNK_PUB.ASV   1.2   24 Jul 1997 16:30:22   BOB  $
	title	QLNK_PUB -- QLINK Public/Extrn Processor
	page	58,122
	name	QLNK_PUB

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
	include ALLMEM.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	LMB_PERGRP:dword
	extrn	LMB_PERSEG:dword
	extrn	LMB_PUBDEF:dword
	extrn	LMB_SYMBOL:dword

	extrn	MINSIZE:dword
	extrn	EXEFIL_SIZE:dword

	extrn	SP_EDATA:tbyte

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	CB_TERM:near

	NPPROC	PROC_PUBS -- Calculate Base Address Of All Publics
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Calculate the base address of all publics.

|

	pushad			; Save registers

	mov	edi,LMB_SYMBOL.LMB_CURB.BOUND_BEG ; Get starting address
PROC_PUBS_NEXT:
	cmp	edi,LMB_SYMBOL.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr PROC_PUBS_DONE ; Jump if so

	btr	LCL_FLAG,$LCL_BRK ; Izit break time?
	jc	near ptr CB_TERM ; Jump if so

	UNCURB	edi,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edi].SYM_FLAG,@SYMFL_PUB ; Izit a public symbol?
	jz	short PROC_PUBS_LOOP ; Jump if not

;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edi].SYM_FLAG,@SYMFL_IMP ; Izit an imported symbol?
	jnz	short PROC_PUBS_LOOP ; Jump if so

; For each public symbol, save the base address
; (segment or group, as appropriate)

;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].SYM_PERITEM ; Get LA of PERITEM struc (PUBDEF_STR)

; If this symbol is substituted, use the substituted symbol address

;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edi].SYM_FLAG,@SYMFL_SUBST ; Izit substituted?
	jz	short @F	; Jump if not

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].PUBDEF_PSYM ; Get LA of substituted symbol (SYM_STR)
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERITEM struc (PUBDEF_STR)
@@:

; If there's an associated segment, use its base as the symbol's base

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	ecx,AGROUP:[ebx].PUBDEF_PPERSEG ; Get LA of PERSEG_STR
	jecxz	PROC_PUBS_LOOP	; Jump if no associated segment

	UNCURB	ecx,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[ecx].PERSEG_ADRB.BOUND_BEG ; Get starting address

;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[ebx].PUBDEF_BASE,ecx ; Save as base address (segment)
	add	AGROUP:[ebx].PUBDEF_ADDR,ecx ; Add into offset to get entire address

; If there's an associated group, use its base as the symbol's base

;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	ecx,AGROUP:[ebx].PUBDEF_PPERGRP ; Get LA of PERGRP_STR
	jecxz	PROC_PUBS_LOOP	; Jump if no associated group

	UNCURB	ecx,PERGRP	; Ensure within current bounds
	mov	ecx,AGROUP:[ecx].PERGRP_ADRB.BOUND_BEG ; Get starting address

;;;;;;; UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[ebx].PUBDEF_BASE,ecx ; Save as base address (group)
PROC_PUBS_LOOP:
	add	edi,type SYM_STR ; Skip to next entry

	jmp	PROC_PUBS_NEXT	; Go around again


PROC_PUBS_DONE:
COMMENT|

If /DOSSEG is specified (yes, again another exception), then we need
to set the size of the .EXE to the location of the variable '_edata'
as everything after that is allocated at startup.  Correspondingly,
the difference between the calculated .EXE file size and the location
of '_edata' is added into the minimum # paras needed to start the
program.

|

	test	ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
	jz	short PROC_PUBS_EXIT ; Jump if not

; Get location of '_edata'

	mov	eax,SP_EDATA.SPSYM_PSYMBOL ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of public (PUBDEF_STR)
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PUBDEF_ADDR ; Get base + offset
	mov	ebx,EXEFIL_SIZE ; Get calculated file size
	mov	EXEFIL_SIZE,eax ; Save as new file size
	sub	ebx,eax 	; Subtract to get excess
	add	MINSIZE,ebx	; Add into minimum size
PROC_PUBS_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_PUBS endp			; End PROC_PUBS procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_PUB module
