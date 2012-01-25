;' $Header:   P:/PVCS/MISC/QLINK/QLNK_EXT.ASV   1.3   07 Aug 1998 16:00:08   BOB  $
	title	QLNK_EXT -- QLINK Public/Extrn Processor
	page	58,122
	name	QLNK_EXT

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
	include ASCII.INC
	include ALLMEM.INC

	include QLNK_COM.INC
	include QLNK_IWF.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	LMB_PERCLS:dword
	extrn	LMB_PEROBJ:dword
	extrn	LMB_PERSEG:dword
	extrn	LMB_PUBDEF:dword
	extrn	LMB_SYMBOL:dword

	extrn	WORKAREA:byte
	extrn	WORKAREA_SYM:tbyte
	extrn	LaDATA:dword
	extrn	STACK_PPERSEG:dword

	extrn	ERRCNT:dword
	extrn	IWFCNT:dword

	public	LaSYMFIND,LaNULOBJ
LaSYMFIND dd	?		; LA of symbol to find (SYM_STR)
LaNULOBJ dd	0		; LA of NUL PEROBJ_STR entry (0=none)

	public	SPSYM_GRP,SPSYM_GRPSYM,SPSYM_CLS,SPSYM_SEG,SPSYM_SEGSYM
SPSYM_GRP dd	?		; Special symbol group (PERGRP_STR
SPSYM_GRPSYM dd ?		; ...		 group symbol (SYM_STR)
SPSYM_CLS dd	?		; ...		 class (SYM_STR)
SPSYM_SEG dd	?		; ...		 segment (PERSEG_STR)
SPSYM_SEGSYM dd ?		; ...		 segment symbol (SYM_STR)

	public	MSG_PUBEXT
MSG_PUBEXT  db	'ออ> FAIL:  Unresolved external reference ',@LQ,EOS
MSG_PUBEXT1 db	@RQ,CR,LF,@I,'in file ',EOS

	public	TXT_NULOBJ
TXT_NULOBJ label byte
	CCMAC	'<none>',TXT_NONE

	public	SPSYM_END_GRP
SPSYM_END_GRP label byte
	CCMAC	'DGROUP'        ; Group name
SPSYM_END_SCT label byte
	CCMAC	'STACK'         ; Segment ...
SPSYM_END_CLS label byte
	CCMAC	'STACK'         ; Class ...
	db	@ACBP_C_STACK shl $ACBP_C ; CombineType only
SPSYM_END_LEN equ $-SPSYM_END_SCT ; Length of ...
	db	(@ACBP_A_PARA  shl $ACBP_A) or \
		(@ACBP_C_STACK shl $ACBP_C) or \
		(0	       shl $ACBP_B) or \
		(0	       shl $ACBP_P) ; ACBP byte for SYM_FLAG.LO
	dd	@PERSEG_SKIP	; PERSEG_FLAG value

	public	SPSYM_EDATA_GRP
SPSYM_EDATA_GRP label byte
	CCMAC	'DGROUP'        ; Group name
SPSYM_EDATA_SCT label byte
	CCMAC	'_BSS'          ; Segment ...
SPSYM_EDATA_CLS label byte
	CCMAC	'BSS'           ; Class ...
	db	@ACBP_C_PUBLIC shl $ACBP_C ; CombineType only
SPSYM_EDATA_LEN equ $-SPSYM_EDATA_SCT ; Length of ...
	db	(@ACBP_A_WORD	shl $ACBP_A) or \
		(@ACBP_C_PUBLIC shl $ACBP_C) or \
		(0	      shl $ACBP_B) or \
		(0	      shl $ACBP_P) ; ACBP byte for SYM_FLAG.LO
	dd	@PERSEG_SKIP	; PERSEG_FLAG value

	public	MSG_SPSYM
MSG_SPSYM db	'ออ> FAIL:  Unresolved /DOSSEG symbol: ',@LQ,EOS
MSG_SPSYM1 db	@RQ,CR,LF
	   db	   @I,'Group: ',@LQ,EOS
MSG_SPSYM2 db	@RQ,', Segment: ',@LQ,EOS
MSG_SPSYM3 db	@RQ,', Class: ',@LQ,EOS
;;;_SPSYM4 db	@RQ,', Combine Type: ',EOS
MSG_SPSYM5 db	@RQ,CR,LF,EOS

DATA	ends			; End DATA segment


SPSYM_MAC macro SYM,NAM,LBL
	local	L1,L2

TEXT	segment 		; Start TEXT segment
	assume	ds:DGROUP

L1	db	L2,SYM		; The count & text (CC_STR)
L2	equ	$-L1-(type CC_COUNT) ; Length of ...

TEXT	ends			; End TEXT segment


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

ifnb <LBL>
	public	LBL
LBL	label	tbyte
endif				; IFNB <LBL>
	SPSYM_STR <offset DGROUP:L1,		  \
		   offset DGROUP:SPSYM_&NAM&_GRP, \
		   offset DGROUP:SPSYM_&NAM&_CLS, \
		   offset DGROUP:SPSYM_&NAM&_SCT, \
		   SPSYM_&NAM&_LEN>

DATA	ends			; End DATA segment

	endm			; SPSYM_MAC


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	public	SPECSYM
SPECSYM label	tbyte

DATA	ends			; End DATA segment

;		  Symbol    Name   Label
	SPSYM_MAC '_end',   END,   SP_END
	SPSYM_MAC '__end',  END
	SPSYM_MAC '_edata', EDATA, SP_EDATA
	SPSYM_MAC '__edata',EDATA


DATA	segment 		'data' ; Start DATA segment
	assume	ds:DGROUP

NSPECSYM equ	($-SPECSYM)/(type SPSYM_STR) ; # special symbols

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	DISP_CNTCHR:near
	extrn	DISP_THEADR:near
	extrn	U32_DISP_MSG:near
	extrn	U32_NEWLINE:near
	extrn	CB_TERM:near
	extrn	PROC_LIBS:near
	extrn	LOOKUP_SYM:near
	extrn	SYMSRCH:near
	extrn	SYMAPPND:near
	extrn	SETUP_NEWSEG:near
	extrn	FIND_CLASS:near
	extrn	FLAG_CLASS:near
	extrn	LINK_SEGOBJ:near
	extrn	LINK_GRP:near
	extrn	CHECK_DGROUP:near

	NPPROC	PROC_EXTS -- Check Externals For Matching Publics
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ensure all externals are matched with publics.

On exit:

CF	=	0 if all matches
	=	1 if not

|

	pushad			; Save registers

; Define special symbols at the beginning
; Note that /DOSSEG might not be set at this point (a library routine
; can do it), so we need to define some symbols which a library routine
; might reference.

	call	PROC_SPEC_BEG	; Process special symbols at beginning
;;;;;;; jc	short ???	; Ignore error return

	mov	edi,LMB_SYMBOL.LMB_CURB.BOUND_BEG ; Get starting address
PROC_EXTS_NEXT:
	cmp	edi,LMB_SYMBOL.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	short PROC_EXTS_DONE ; Jump if so

	btr	LCL_FLAG,$LCL_BRK ; Izit break time?
	jc	near ptr CB_TERM ; Jump if so

	call	GET_SYMFLAGS	; Get the symbol flags for EDI = SYM_STR
				; Return with EAX = symbol flags
	and	eax,@SYMFL_PUB or @SYMFL_EXT ; Isolate public/external bits
	jz	short PROC_EXTS_LOOP ; Jump if neither

	cmp	eax,@SYMFL_EXT	; Izit external w/o public?
	je	short PROC_EXTS_ERR ; Jump if so
PROC_EXTS_LOOP:
	add	edi,type SYM_STR ; Skip to next symbol

	jmp	PROC_EXTS_NEXT	; Go around again

PROC_EXTS_DONE:
	cmp	IWFCNT[@IWF_FAL*(type IWFCNT)],1 ; Are there any errors?
	cmc			; Complement so CF = 1 iff errors
	jc	near ptr PROC_EXTS_EXIT ; Jump if so (note CF=1)

; Define special symbols at the end

	call	PROC_SPEC_END	; Process special symbols at end
				; Return with CF significant
	jmp	PROC_EXTS_EXIT	; Join common exit code


; The external symbol is not public

PROC_EXTS_ERR:

; If this is a weak extrn, use the resolver symbol

	UNCURB	edi,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edi].SYM_FLAG,@SYMFL_WEAK ; Izit weak?
	jz	short PROC_EXTS_ERR1 ; Jump if not

;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].SYM_PERITEM ; Get LA of resolver symbol (SYM_STR)

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of resolver per-item
;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[edi].SYM_PERITEM,eax ; Save as original symbol's per-item

; If the resolver symbol is public, save the new symbol (SYM_STR) there

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	test	AGROUP:[ebx].SYM_FLAG,@SYMFL_PUB ; Izit public?
	jz	short @F	; Jump if not

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of resolver per-item
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[eax].PUBDEF_PSYM,edi ; Save as new symbol (SYM_STR)
@@:
;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_FLAG ; Get resolver's flags
;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	and	AGROUP:[edi].SYM_FLAG,not @SYMFL_WEAK ; Clear weak bit
	and	eax,not @SYMFL_SUBST ; Don't transfer substitute flag
;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	or	AGROUP:[edi].SYM_FLAG,eax ; Include with original symbol's flags

; In order to handle weak symbols, we mark the old symbol location
; as substituted with a pointer to the new symbol, because the old symbol location
; still gets referenced by the hash algorithm.

	or	eax,@SYMFL_SUBST ; Mark as substituted
;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_FLAG,eax ; Save in old location
	mov	AGROUP:[ebx].SYM_SUBST,edi ; Save ptr to real symbol (SYM_STR)

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PNAM ; Get LA of symbol
;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[edi].SYM_PNAM,eax ; Save as original symbol's name

;;;;;;; UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_NAMLEN ; Get length of name
;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[edi].SYM_NAMLEN,eax ; Save as original symbol's length

	jmp	PROC_EXTS_NEXT	; Go around again


; The external symbol is not public, and not weak

PROC_EXTS_ERR1:
	mov	LaSYMFIND,edi	; Save LA of symbol to find

	call	PROC_LIBS	; Check the .LIB files for the symbol at LaSYMFIND
	jc	short PROC_EXTS_ERR3 ; Jump if not found

	cmp	IWFCNT[@IWF_FAL*(type IWFCNT)],0 ; Any preceding unmatched extrns?
	ja	near ptr PROC_EXTS_LOOP ; Jump if so (skipping this symbol)

; If this is a substitute symbol and it's still external w/o public,
; search for the substitute symbol.

	call	GET_SYMFLAGS	; Get the symbol flags for EDI = SYM_STR
				; Return with EAX = symbol flags
	test	eax,@SYMFL_SUBST ; Izit substitute?
	jz	short PROC_EXTS_ERR2 ; Jump if not

	and	eax,@SYMFL_PUB or @SYMFL_EXT ; Isolate public/external bits
	jz	near ptr PROC_EXTS_LOOP ; Jump if neither

	cmp	eax,@SYMFL_EXT	; Izit external w/o public?
	jne	short PROC_EXTS_ERR2 ; Jump if not

; Search for the substitute symbol

;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[edi].SYM_SUBST ; Get LA of SYM_STR
	mov	LaSYMFIND,eax	; Save LA of symbol to find

	call	PROC_LIBS	; Check the .LIB files for the symbol at LaSYMFIND
	jc	short PROC_EXTS_ERR3 ; Jump if not found

	cmp	IWFCNT[@IWF_FAL*(type IWFCNT)],0 ; Any preceding unmatched extrns?
	ja	near ptr PROC_EXTS_LOOP ; Jump if so (skipping this symbol)
PROC_EXTS_ERR2:
	jmp	PROC_EXTS_NEXT	; Jump to test this symbol again

PROC_EXTS_ERR3:

; If we encountered an error processing the .OBJ file, there's
; already a message displayed.	Moreover, the symbol's PERITEM
; field might have changed from PEROBJ to PUBDEF and the code
; in PROC_EXTERR expects the latter.

	btr	LCL_FLAG,$LCL_ERROBJ ; Izit an error processing .OBJ file/
	jc	short PROC_EXTS_EXIT ; Jump if so (note CF=1)

	call	PROC_EXTERR	; Display an error message

	jmp	PROC_EXTS_LOOP	; Go around again looking for more trouble

PROC_EXTS_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_EXTS endp			; End PROC_EXTS procedure
	NPPROC	PROC_EXTERR -- Process An EXTEDF W/O PUBDEF
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process an EXTDEF (and possibly a weak one) w/o PUBDEF.

On entry:

EDI	=	LA of SYM_STR

|

	REGSAVE <eax>		; Save register

	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_PUBEXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the symbol name

	UNCURB	edi,SYMBOL	; Ensure within current bounds
	push	AGROUP:[edi].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_PUBEXT1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the .OBJ file name in which it's marked as external

	UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[edi].SYM_PERITEM ; Get LA of PEROBJ_STR
				; (SYM_STR if weak)
;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	test	AGROUP:[edi].SYM_FLAG,@SYMFL_WEAK ; Izit a weak extrn?
	jz	short @F	; Jump if not

;;;;;;; UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of PEROBJ_STR
@@:
	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Point to symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	push	1		; Display leading blank
	push	eax		; Pass LA of PEROBJ_STR as argument
	call	DISP_THEADR	; Display the THEADR if present

	call	U32_NEWLINE	; Goto a new line

	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in another mismatch

	dec	ERRCNT		; Mark as no longer writing to error file

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_EXTERR endp		; End PROC_EXTERR procedure
	NPPROC	PROC_SPEC_BEG -- Process Special Symbols At Beginning
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process special symbols at beginning

Note that /DOSSEG might not be set at this point (a library routine
can do it), so we need to define some symbols which a library routine
might reference.

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	xor	edx,edx 	; Initialize index into SPECSYM
	mov	ecx,NSPECSYM	; Get # special symbols
PROC_SPEC_BEG_NEXT:

; Append the symbol to the symbol table

	mov	eax,SPECSYM[edx].SPSYM_PTXT ; Get offset in DGROUP of text
	add	eax,LaDATA	; Plus LA of DGROUP

	push	@LOOKUP_APP	; Append if not found
	push	eax		; Pass LA of text (Count, Char[])
	push	@SYMFL_CL_SYM or @SYMFL_TEMP ; Mark as temp symbol class
	call	LOOKUP_SYM	; Lookup the symbol
				; Return EBX = LA of matching entry (SYM_STR)
	jc	short PROC_SPEC_BEG_EXIT ; Jump if not successful (note CF=1)

; If this symbol isn't already public, define a PUBDEF record for it

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	bts	AGROUP:[ebx].SYM_FLAG,$SYMFL_PUB ; Mark as public
	jc	short PROC_SPEC_BEG_LOOP ; Jump if already public

; Define a new PUBDEF record
; Zero the PUBDEF struc

	push	ecx		; Save for a moment

.errnz (4-1) and (type PUBDEF_STR)
	mov	ecx,(type PUBDEF_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	mov	edi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Get LA of next entry

	UNOVRB	edi,PUBDEF	; Ensure within overall bounds
    rep stos	AGROUP:[edi].EDD ; Zero the struc
	xchg	edi,LMB_PUBDEF.LMB_CURB.BOUND_NXT ; Save LA of next entry

	pop	ecx		; Restore

; Fill in non-zero PUBDEF_STR items

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PSYM,ebx ; Save LA of symbol (SYM_STR)

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,edi ; Save matching PUBDEF_STR
PROC_SPEC_BEG_LOOP:

; Save the address of the SYM_STR back into the SPSYM_STR
; for ending processing

	mov	SPECSYM[edx].SPSYM_PSYMBOL,ebx ; Save as LA of SYM_STR

	add	edx,type SPSYM_STR ; Skip to next entry

;;;;;;; loop	PROC_SPEC_BEG_NEXT ; Jump if more special symbols
	dec	ecx		; Less one special symbol
	jnz	near ptr PROC_SPEC_BEG_NEXT ; Jump if more special symbols

	clc			; Mark as successful
PROC_SPEC_BEG_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_SPEC_BEG endp		; End PROC_SPEC_BEG procedure
	NPPROC	PROC_SPEC_END -- Process Special Symbols At End
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process special symbols at end

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

; This step is needed only if /DOSSEG has been specified

	test	ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
	jz	near ptr PROC_SPEC_END_EXIT ; Jump if not (note CF=0)

; Create a NUL PEROBJ_STR

	call	PROC_NULOBJ	; Create NUL .OBJ filename

	xor	edx,edx 	; Initialize index into SPECSYM
	mov	ecx,NSPECSYM	; Get # special symbols
PROC_SPEC_END_NEXT:
	push	SPECSYM[edx].SPSYM_PGRP ; Pass offset in DGROUP of group name
	push	SPECSYM[edx].SPSYM_PCLS ; ...			   class name
	push	SPECSYM[edx].SPSYM_PSCT ; ...			   SCT data
	push	SPECSYM[edx].SPSYM_LEN ; Pass length of SCT data
	call	FIND_GSCT	; Find a Group-Segment-Class-CombineType
				; Return with SPSYM_GRP, SPSYM_SEG filled in
	jc	near ptr PROC_SPEC_END_ERR ; Jump if something went wrong

; Mark this symbol as no longer temporary

	mov	ebx,SPECSYM[edx].SPSYM_PSYMBOL ; Get LA of symbol (SYM_STR)
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PERITEM ; Get LA of public (PUBDEF_STR)
	UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PUBDEF_PSYM ; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	and	AGROUP:[eax].SYM_FLAG,not @SYMFL_TEMP ; Clear temp flag

; Fill in undefined PUBDEF_STR items

	UNCURB	edi,PUBDEF	; Ensure within current bounds
	cmp	AGROUP:[edi].PUBDEF_PPERGRP,0 ; Izit undefined?
	jne	short @F	; Jump if not

	mov	eax,SPSYM_GRP	; Get LA of PERGRP_STR
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PPERGRP,eax ; Save for later use
@@:
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	cmp	AGROUP:[edi].PUBDEF_PPERSEG,0 ; Izit undefined?
	jne	short @F	; Jump if not

	mov	eax,SPSYM_SEG	; Get LA of PERSEG_STR
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PPERSEG,eax ; Save for later use
@@:
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	cmp	AGROUP:[edi].PUBDEF_PPEROBJ,0 ; Izit undefined?
	jne	short @F	; Jump if not

	mov	eax,LaNULOBJ	; Get LA of NUL .OBJ (PEROBJ_STR)
;;;;;;; UNCURB	edi,PUBDEF	; Ensure within current bounds
	mov	AGROUP:[edi].PUBDEF_PPEROBJ,eax ; Save for later use
@@:

; If this segment has stack combine type, save its PERSEG_STR for later use

	mov	eax,SPSYM_SEG	; Get LA of PERSEG_STR

	UNCURB	eax,PERSEG	; Ensure within current bounds
	test	AGROUP:[eax].PERSEG_FLAG,@PERSEG_STACK ; Izit a stack?
	jz	short @F	; Jump if not

;;;;;;; UNCURB	eax,PERSEG	; Ensure within current bounds
;;;;;;; mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
;;;;;;; UNCURB	eax,SYMBOL	; Ensure within current bounds
;;;;;;; mov	eax,AGROUP:[eax].SYM_FLAG ; Get the flags
;;;;;;; and	al,@SYMFL_C	; Isolate the combine type bits
;;;;;;;
;;;;;;; cmp	al,@ACBP_C_STACK shl $SYMFL_C ; Izit combine type stack?
;;;;;;; jne	short @F	; Jump if not
;;;;;;;
	cmp	STACK_PPERSEG,0 ; Izit still undefined?
	jne	short @F	; Jump if not

;;;;;;; mov	eax,SPSYM_SEG	; Get LA of PERSEG_STR
	mov	STACK_PPERSEG,eax ; Save for later use
@@:
	add	edx,type SPSYM_STR ; Skip to next entry

;;;;;;; loop	PROC_SPEC_END_NEXT ; Jump if more special symbols
	dec	ecx		; Less one special symbol
	jnz	near ptr PROC_SPEC_END_NEXT ; Jump if more special symbols

	clc			; Mark as successful

	jmp	PROC_SPEC_END_EXIT ; Join common exit code

; We're missing a Group-Segment-Class-CombineType as specified
; by SPECSYM[edx].  Display an appropriate error message.

PROC_SPEC_END_ERR:

; Display the symbol name

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_SPSYM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	edi,SPECSYM[edx].SPSYM_PTXT ; Get offset in DGROUP of (Count, Char[])
	add	edi,LaDATA	; Plus LA of DGROUP to get linear address
	push	edi		; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

; Display the group name

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_SPSYM1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	edi,SPECSYM[edx].SPSYM_PGRP ; Get offset in DGROUP of (Count, Char[])
	add	edi,LaDATA	; Plus LA of DGROUP to get linear address
	push	edi		; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

; Display the segment name

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_SPSYM2) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	edi,SPECSYM[edx].SPSYM_PSCT ; Get offset in DGROUP of SCT data
	add	edi,LaDATA	; Plus LA of DGROUP to get linear address
	push	edi		; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

; Display the class name

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_SPSYM3) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	edi,SPECSYM[edx].SPSYM_PCLS ; Get offset in DGROUP of (Count, Char[])
	add	edi,LaDATA	; Plus LA of DGROUP to get linear address
	push	edi		; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

; Display the combine type

;;;;;;; push	fs		; Pass DGROUP segment
;;;;;;; push	dword ptr (offset DGROUP:MSG_SPSYM4) ; Pass offset of message
;;;;;;; call	U32_DISP_MSG	; Display the message






	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_SPSYM5) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	stc			; Mark as in error
PROC_SPEC_END_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_SPEC_END endp		; End PROC_SPEC_END procedure
	NPPROC	FIND_GSCT -- Find Group-Segment-Class-CombineType
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find Group-Segment-Class-CombineType

On exit:

CF	=	0 if successful
	=	1 if not

SPSYM_SEG =	 LA of segment (PERSEG_STR)
SPSYM_SEGSYM =	 LA of segment symbol (SYM_STR)
SPSYM_GRP =	 LA of group (PERGRP_STR)
SPSYM_GRPSYM =	 LA of group symbol (SYM_STR)

|

FIND_GSCT_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIND_GSCT_LEN  dd ?		; Length of SCT data
FIND_GSCT_PSCT dd ?		; Offset in DGROUP of SCT data
FIND_GSCT_PCLS dd ?		; ...		      class name (Count, Char[])
FIND_GSCT_PGRP dd ?		; ...		      group ...

FIND_GSCT_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers

; Find the group name

	mov	eax,[ebp].FIND_GSCT_PGRP ; Get offset in DGROUP of group name
	add	eax,LaDATA	; Plus LA of DGROUP

	mov	SPSYM_GRP,0	; Assume no group
	mov	SPSYM_GRPSYM,0	; ...

	cmp	AGROUP:[eax].LO,0 ; Izit empty?
	je	short FIND_GSCT_XGRP ; Jump if so

	push	0		; Do nothing
	push	eax		; Pass LA of text (Count, Char[])
	push	@SYMFL_CL_GRP or @SYMFL_GRP ; Mark as group class
	call	LOOKUP_SYM	; Lookup the symbol
				; Return EBX = LA of matching entry (SYM_STR)
	jc	near ptr FIND_GSCT_EXIT ; Jump if not already in the table (note CF=1)

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of group (PERGRP_STR)
	mov	SPSYM_GRP,eax	; Save for later use
	mov	SPSYM_GRPSYM,ebx ; ...
FIND_GSCT_XGRP:

; Find the Segment-Class-CombineType
; It might not already be in the symbol table

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

	mov	esi,[ebp].FIND_GSCT_PSCT ; Get offset in DGROUP of SCT data

	push	ecx		; Save for a moment

	mov	ecx,[ebp].FIND_GSCT_LEN ; Get length of SPSYM_PSCT data
    rep movs	AGROUP:[edi].LO,DGROUP:[esi].LO ; Copy to work area

	pop	ecx		; Restore

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,@SYM_NEW ; ...
	mov	WORKAREA_SYM.SYM_FLAG,@SYMFL_CL_SEG or \
				      @SYMFL_SCC ; Mark as segment-class-combinetype class

; See if this entry already exists in the symbol table

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return AGROUP:EBX = matching entry (SYM_STR)
	mov	SPSYM_SEGSYM,ebx ; Save for later use
	jnc	near ptr FIND_GSCT_SEG ; Jump if already in the table

;;;;;;; lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
;;;;;;; add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return AGROUP:EBX = new entry (SYM_STR)
	jc	near ptr FIND_GSCT_EXIT ; Jump if not successful (note CF=1)

	push	0		; Pass length of this segment
	push	0		; Mark as normal segment
	call	SETUP_NEWSEG	; Setup a new segment
	jc	near ptr FIND_GSCT_EXIT ; Jump if something went wrong (note CF=1)

	mov	SPSYM_SEGSYM,ebx ; Save for later use

	mov	edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	edi,type PERSEG_STR ; Back off to previous struc
	mov	SPSYM_SEG,edi	; Save for later use

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_PERITEM,edi ; Save in symbol table

	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_SEGSYM,ebx ; Save as ptr to SYM_STR

	mov	eax,SPSYM_GRPSYM ; Get LA of group symbol (SYM_STR)
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_GRPSYM,eax ; Save as ptr to SYM_STR

; Link this segment in with the other entries in the same group

	cmp	SPSYM_GRP,0	; Izit undefined?
	je	short @F	; Jump if so

	push	SPSYM_GRP	; Pass LA of group (PERGRP_STR)
	push	SPSYM_SEG	; ...	     segment (PERSEG_STR)
	call	LINK_GRP	; Link it into the group chain
@@:

; If this is DGROUP, transfer that bit to PERSEG_FLAG

	push	SPSYM_GRPSYM	; Pass LA of group symbol (SYM_STR)
	push	SPSYM_SEG	; ...	     segment (PERSEG_STR)
	call	CHECK_DGROUP	; Check it out

	mov	esi,[ebp].FIND_GSCT_PSCT ; Get offset in DGROUP of SCT data
	add	esi,[ebp].FIND_GSCT_LEN ; Plus length of SCT data

; ESI = offset in DGROUP of ACBP byte

	lods	DGROUP:[esi].LO ; Get and skip over the ACBP byte
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	AGROUP:[ebx].SYM_FLAG.LO,al ; Save flags

; ESI = offset in DGROUP of PERSEG_FLAG values

	lods	DGROUP:[esi].EDD ; Get PERSEG_FLAG
;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	or	AGROUP:[edi].PERSEG_FLAG,eax ; Save flags

; If this segment has stack combine type, save its PERSEG_STR for later use

	and	al,@SYMFL_C	; Isolate the combine type bits

	cmp	al,@ACBP_C_STACK shl $SYMFL_C ; Izit combine type stack?
	jne	short @F	; Jump if not

	cmp	STACK_PPERSEG,0 ; Izit undefined?
	jne	short @F	; Jump if not

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get LA of PERSEG strucs
	mov	STACK_PPERSEG,eax ; Save for later use
@@:

; Find the class name

	mov	eax,[ebp].FIND_GSCT_PCLS ; Get offset in DGROUP of class name
	add	eax,LaDATA	; Plus LA of DGROUP

	push	SPSYM_SEG	; Pass LA of segment (PERSEG_STR)
	push	eax		; Pass LA of symbol (Count, Char[])
	call	FIND_CLASS	; Find class name symbol
				; Return AGROUP:EBX = new entry (SYM_STR)
	jc	short FIND_GSCT_EXIT ; Jump if not successful (note CF=1)

	mov	edi,SPSYM_SEG	; Get LA of segment (PERSEG_STR)
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERSEG_CLS ; Get LA of class (PERCLS_STR)

	and	eax,eax 	; Izit undefined?
	jnz	short @F	; Jump if not

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].SYM_PERITEM ; Get the class (PERCLS_STR

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_CLS,eax ; Save LA of class (PERCLS_STR)
@@:
	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	AGROUP:[eax].PERCLS_PSYM,ebx ; Save LA of name (SYM_STR)
FIND_GSCT_SEG:
	mov	ebx,SPSYM_SEGSYM ; Get LA of segment symbol (SYM_STR)
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	edi,AGROUP:[ebx].SYM_PERITEM ; Get LA of segment (PERSEG_STR)
	mov	SPSYM_SEG,edi	; Save for later use

; Set flags (PERSEG_FLAG) for the class name

	push	edi		; Pass LA of segment (PERSEG_STR)
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERSEG_CLS ; Get LA of class (PERCLS)
	UNCURB	eax,PERCLS	; Ensure within current bounds
	push	AGROUP:[eax].PERCLS_PSYM ; Pass LA of class symbol (SYM_STR)
	call	FLAG_CLASS	; Set flags for class name

; If the user has specified /MAP:FULL, save info about this segment
; piece in LMB_SEGOBJ

	push	0		; Pass length of this segment
	push	edi		; ...  LA of segment (PERSEG_STR)
	call	LINK_SEGOBJ	; Link in this segment

	clc			; Mark as successful
FIND_GSCT_EXIT:
	popad			; Restore

	pop	ebp		; Restore

	ret	4*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_GSCT endp			; End FIND_GSCT procedure
	NPPROC	PROC_NULOBJ -- Create A NUL .OBJ Filename
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Create a NUL .OBJ filename

|

	pushad			; Save registers

; Zero the PEROBJ fields

.errnz (4-1) and (type PEROBJ_STR)
	mov	ecx,(type PEROBJ_STR)/4 ; # dwords in struc
	xor	eax,eax 	; Fill with this
	mov	edi,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry

	UNCURB	edi,PEROBJ	; Ensure within current bounds
    rep stos	AGROUP:[edi].EDD ; Zero the fields

	xchg	edi,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Save for next time, get old value

	lea	eax,TXT_NULOBJ	; Get offset in DGROUP of NULOBJ text
	add	eax,LaDATA	; Plus LA of DGROUP

	UNCURB	edi,PEROBJ	; Ensure within current bounds
	mov	AGROUP:[edi].PEROBJ_PFID,eax ; Save LA of (Count, Char[]) of FID

	mov	LaNULOBJ,edi	; Save as LA of NULOBJ
PROC_NULOBJ_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_NULOBJ endp		; End PROC_NULOBJ procedure
	NPPROC	GET_SYMFLAGS -- Get Symbol Flags
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get symbol flags

On entry:

EDI	=	LA of SYM_STR

On exit:

EAX	=	symbol flags

|

	REGSAVE <ebx>		; Save register

	UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[edi].SYM_FLAG ; Get the symbol flags

; If this symbol is a substitute, include the flags of the resolver symbol

	test	AGROUP:[edi].SYM_FLAG,@SYMFL_SUBST ; Izit substituted?
	jz	short @F	; Jump if not

;;;;;;; UNCURB	edi,SYMBOL	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].SYM_SUBST ; Get the substitute SYM_STR
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	or	eax,AGROUP:[ebx].SYM_FLAG ; Include the flags
@@:
	REGREST <ebx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_SYMFLAGS endp		; End GET_SYMFLAGS procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_EXT module
