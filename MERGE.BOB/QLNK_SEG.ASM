;' $Header:   P:/PVCS/MISC/QLINK/QLNK_SEG.ASV   1.1   17 Jul 1997 12:36:52   BOB  $
	title	QLNK_SEG -- QLINK Segment Processor
	page	58,122
	name	QLNK_SEG

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
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	IWF_FLAG:dword
	include QLNK_IWF.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	ERRCNT:dword
	extrn	EXEFIL_SIZE:dword
	extrn	LMB_TXTSTR:dword
	extrn	LMB_PERSEG:dword
	extrn	LMB_SYMBOL:dword
	extrn	LMB_PUBDEF:dword
	extrn	LMB_COMDEF:dword
	extrn	STACK_PPERSEG:dword
	extrn	MINSTACK:dword

	extrn	SPSYM_SEG:dword
	extrn	SPSYM_GRP:dword

	public	C_COMMON_PPERSEG,C_COMMON_PPERGRP
C_COMMON_PPERSEG dd ?		; LA of 'c_common' segment (PERSEG_STR)
C_COMMON_PPERGRP dd ?		; ...		   group   (PERGRP_STR)

	public	FAR_BSS_PPERSEG,FAR_BSS_PPERGRP
FAR_BSS_PPERSEG dd ?		; LA of 'FAR_BSS' segment (PERSEG_STR)
FAR_BSS_PPERGRP dd ?		; ...		  group   (PERGRP_STR)

	public	SEG_START,SEGLNK_1ST,SEGLNK_LAST
SEG_START dd	?		; Starting address for a segment
SEGLNK_1ST  dd	?		; 1st segment linked
SEGLNK_LAST dd	?		; Last ...

	public	SPECSEG_TAB
SPECSEG_TAB dd	offset DGROUP:SS_SYMBOLS ; Ignore these special segments
	dd	offset DGROUP:SS_TYPES
NSPECSEG_TAB equ ($-SPECSEG_TAB)/(type SPECSEG_TAB) ; Length of ...

	CCMAC	'$$SYMBOLS', SS_SYMBOLS ; Form (Count, Char[])
	CCMAC	'DEBSYM'                ; ...
	db	@ACBP_C_PRIVATE shl $ACBP_C ; CombineType only

	CCMAC	'$$TYPES', SS_TYPES     ; Form (Count, Char[])
	CCMAC	'DEBTYP'                ; ...
	db	@ACBP_C_PRIVATE shl $ACBP_C ; CombineType only

	public	MSG_SEGBIG
MSG_SEGBIG  db	'(SEGBIG) Segment ',@LQ,EOS
MSG_SEGBIG1 db	@RQ,' exceeds 64KB in size.',CR,LF,EOS


	public	C_COMMON_GRP
C_COMMON_GRP label byte
	CCMAC	'DGROUP'        ; Group name
C_COMMON_SCT label byte
	CCMAC	'c_common'      ; Segment ...
C_COMMON_CLS label byte
	CCMAC	'BSS'           ; Class ...
	db	@ACBP_C_PUBLIC shl $ACBP_C ; Mark as public
C_COMMON_LEN equ $-C_COMMON_SCT ; Length of ...
	db	(@ACBP_A_PARA	shl $ACBP_A) or \
		(@ACBP_C_PUBLIC shl $ACBP_C) or \
		(0		shl $ACBP_B) or \
		(0		shl $ACBP_P) ; ACBP byte for SYM_FLAG.LO
	dd	0		; PERSEG_FLAG value


	public	FAR_BSS_GRP
FAR_BSS_GRP label byte
	db	0		; Group name (empty)
FAR_BSS_SCT label byte
	CCMAC	'FAR_BSS'       ; Segment ...
FAR_BSS_CLS label byte
	CCMAC	'FAR_BSS'       ; Class ...
	db	@ACBP_C_PUBLIC shl $ACBP_C ; Mark as public
FAR_BSS_LEN equ $-FAR_BSS_SCT ; Length of ...
	db	(@ACBP_A_BYTE	shl $ACBP_A) or \
		(@ACBP_C_PUBLIC shl $ACBP_C) or \
		(0		shl $ACBP_B) or \
		(0		shl $ACBP_P) ; ACBP byte for SYM_FLAG.LO
	dd	0		; PERSEG_FLAG value

DATA	ends			; End DATA segment


CODE	segment use32 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	CHECK_ALIGN:near
	extrn	DISP_CNTCHR:near
	extrn	U32_DISP_MSG:near
	extrn	IWF_TEST:near
	extrn	CB_TERM:near
	extrn	FIND_GSCT:near

	NPPROC	PROC_SEGS -- Calculate Start Of All Segments
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Calculate the sequence and start of all segments.

Loop through all the segments twice:

Once to calculate the segment order and once to calculate the starting
address now that adjacency has been determined.

If /DOSSEG is specified, the segment order is as follows:

* All segments with a class name ending in 'CODE' (@CLSFLG_SUFCODE)
* All other segments not in DGROUP
* DGROUP segments in the following order:
  * Any segments of class 'BEGDATA' (@CLSFLG_BEGDATA)
  * Any segment not of class 'BEGDATA', 'BSS', or 'STACK'
  * Segments of class 'BSS' (@CLSFLG_BSS)
  * Segments of class 'STACK' (@CLSFLG_STACK)

Otherwise, the segment order is by class, and then by occurrence
within each class with unclassed segments ordered before all classed
segments.

On exit:

CF	=	0 if successful
	=	1 if not

|

; If there's a segment with stack combine type (in STACK_PPERSEG),
; and the user specified a new stack size, set the segment length to that

	 REGSAVE <eax,ebx>	; Save registers

	 mov	 ebx,STACK_PPERSEG ; Get LA of stack segment (PERSEG_STR)

	 cmp	 ebx,0		; Izit undefined?
	 je	 short @F	; Jump if so

	 mov	 eax,MINSTACK	; Get minimum stack

	 cmp	 eax,0		; Izit unspecified?
	 je	 short @F	; Jump if so

	 UNCURB  ebx,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[ebx].PERSEG_NEWLEN,eax ; Save as new length
@@:
	 REGREST <ebx,eax>	; Restore

; If there were any COMDEF records, process them now

	 call	 PROC_COMDEF	; Process 'em

	 test	 ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
	 jnz	 short @F	; Jump if so

	 call	 PROC_SEGS_ORD	; Determine their order

	 jmp	 short PROC_SEGS_COM ; Join common code

@@:
	 call	 PROC_SEGS_DOSSEG ; Determine their order
PROC_SEGS_COM:
	 call	 CALC_SEGS	; Calculate segment starting addresses
				; Return with CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_SEGS endp			; End PROC_SEGS procedure
	 NPPROC  PROC_SEGS_ORD -- Determine Segment Order
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Determine segment order for non-DOSSEG contexts.

|

	 REGSAVE <eax,edi>	; Save registers

	 mov	 edi,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get starting LA
	 xor	 eax,eax	; Value of unclassed segment
PROC_SEGS_ORD_NEXT:
	 call	 FIND_SEGSEQ	; Find and sequence segments of
				; class EAX starting with EDI
PROC_SEGS_ORD_NEXTSEG:
	 call	 FIND_NEXTSEG	; Find next unsequenced segment starting with EDI
				; Return next unsequenced segment in EDI
	 cmp	 edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 short PROC_SEGS_ORD_EXIT ; Jump if so

; Determine if this segment is one of the special ones

	 call	 SPEC_SEG	; Izit EDI a special segment?

; Skip this segment (and mark it) if it's skippable

	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 test	 AGROUP:[edi].PERSEG_FLAG,@PERSEG_SKIP ; Izit skippable?
	 jnz	 short PROC_SEGS_ORD_MARK ; Jump if so

;;;;;;;; UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[edi].PERSEG_CLSSYM ; Get next class symbol (SYM_STR)

	 jmp	 PROC_SEGS_ORD_NEXT ; Go around again

PROC_SEGS_ORD_MARK:
	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERSEG_CLSSYM,-1 ; Mark as sequenced

	 jmp	 PROC_SEGS_ORD_NEXTSEG ; Go around again

PROC_SEGS_ORD_EXIT:
	 REGREST <edi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_SEGS_ORD endp		; End PROC_SEGS_ORD procedure
	 NPPROC  PROC_SEGS_DOSSEG -- Determine Segment Order
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Determine segment order for DOSSEG contexts.

|

	 REGSAVE <ebx>		; Save register

	 mov	 ebx,@PERSEG_SUFCODE ; Flag for 'CODE'-suffixed segments
	 call	 FIND_SEGFLG	; Find and sequence segments of
				; class flag EBX (PERSEG_FLAG)
	 mov	 ebx,@PERSEG_OTHGRP ; Flag for none of the other groups
	 call	 FIND_SEGFLG	; Find and sequence segments of
				; class flag EBX (PERSEG_FLAG)
	 mov	 ebx,@PERSEG_BEGDATA ; Flag for 'BEGDATA' segments
	 call	 FIND_SEGFLG	; Find and sequence segments of
				; class flag EBX (PERSEG_FLAG)
	 mov	 ebx,@PERSEG_OTHCLS ; Flag for none of the other classes
	 call	 FIND_SEGFLG	; Find and sequence segments of
				; class flag EBX (PERSEG_FLAG)
	 mov	 ebx,@PERSEG_BSS     ; Flag for 'BSS' segments
	 call	 FIND_SEGFLG	; Find and sequence segments of
				; class flag EBX (PERSEG_FLAG)
	 mov	 ebx,@PERSEG_STACK   ; Flag for 'STACK' segments
	 call	 FIND_SEGFLG	; Find and sequence segments of
				; class flag EBX (PERSEG_FLAG)
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_SEGS_DOSSEG endp		; End PROC_SEGS_DOSSEG procedure
	NPPROC	FIND_SEGFLG -- Find And Sequence Segments by Class Flag
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find and sequence segments by class flag.

On entry:

EBX	=	class flag (PERSEG_FLAG)

|

	REGSAVE <eax,edi>	; Save registers

	mov	edi,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get starting LA
FIND_SEGFLG_NEXT:
	call	FIND_NEXTSEG	; Find next unsequenced segment starting with EDI
				; Return next unsequenced segment in EDI
	cmp	edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	short FIND_SEGFLG_EXIT ; Jump if so

; Determine if this segment is one of the special ones

	call	SPEC_SEG	; Izit EDI a special segment?

; Skip this segment (and mark it) if it's skippable

	UNCURB	edi,PERSEG	; Ensure within current bounds
	test	AGROUP:[edi].PERSEG_FLAG,@PERSEG_SKIP ; Izit skippable?
	jnz	short FIND_SEGFLG_MARK ; Jump if so

; Ensure this segment is of the proper type

	UNCURB	edi,PERSEG	; Ensure within current bounds
	test	ebx,AGROUP:[edi].PERSEG_FLAG ; Duzit match?
	jz	short @F	; Jump if not

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERSEG_CLSSYM ; Get next class symbol (SYM_STR)

	call	FIND_SEGCLS	; Find and sequence segments of
				; class name EAX (SYM_STR),
				; class flag EBX (PERSEG_FLAG)
				; starting with EDI
@@:
	add	edi,type PERSEG_STR ; Skip to next entry

	jmp	FIND_SEGFLG_NEXT ; Go around again

FIND_SEGFLG_MARK:
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	AGROUP:[edi].PERSEG_CLSSYM,-1 ; Mark as sequenced

	jmp	FIND_SEGFLG_NEXT ; Go around again

FIND_SEGFLG_EXIT:
	REGREST <edi,eax>	; Restore

	ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_SEGFLG endp		; End FIND_SEGFLG procedure
	 NPPROC  FIND_SEGCLS -- Find And Sequence Segments By Class Name And Flag
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find and sequence segments of specified class name and flag

On entry:

EAX	 =	 class name (SYM_STR)
EBX	 =	 class flag (PERSEG_FLAG)
EDI	 =	 LA of next segment to check (PERSEG_STR)

|

	 pushad 		; Save registers
FIND_SEGCLS_NEXT:
	 cmp	 edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 near ptr FIND_SEGCLS_EXIT ; Jump if so

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 test	 ebx,AGROUP:[edi].PERSEG_FLAG ; Duzit match?
	 jz	 short FIND_SEGCLS_LOOP ; Jump if not

	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 cmp	 eax,AGROUP:[edi].PERSEG_CLSSYM ; Izit the same class?
	 jne	 short FIND_SEGCLS_LOOP ; Jump if not

; Link this segment into the SEGLNK chain

	 call	 LINK_SEG	; Link in segment EDI
FIND_SEGCLS_LOOP:
	 add	 edi,type PERSEG_STR ; Skip to next entry

	 jmp	 FIND_SEGCLS_NEXT ; Go around again

FIND_SEGCLS_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_SEGCLS endp		; End FIND_SEGCLS procedure
	 NPPROC  FIND_SEGSEQ -- Find And Sequence Segments
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find and sequence segments of specified class

On entry:

EAX	 =	 LA of class to find (SYM_STR)
EDI	 =	 LA of next segment to check (PERSEG_STR)

|

	 pushad 		; Save registers
FIND_SEGSEQ_NEXT:
	 cmp	 edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 near ptr FIND_SEGSEQ_EXIT ; Jump if so

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 cmp	 eax,AGROUP:[edi].PERSEG_CLSSYM ; Izit the same class?
	 jne	 short FIND_SEGSEQ_LOOP ; Jump if not

; Link this segment into the SEGLNK chain

	 call	 LINK_SEG	; Link in segment EDI
FIND_SEGSEQ_LOOP:
	 add	 edi,type PERSEG_STR ; Skip to next entry

	 jmp	 FIND_SEGSEQ_NEXT ; Go around again

FIND_SEGSEQ_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_SEGSEQ endp		; End FIND_SEGSEQ procedure
	 NPPROC  LINK_SEG -- Link Segment Into Chain
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Link segment into chain

On entry:

EDI	 =	 LA of segment to link (PERSEG_STR)

|

	 REGSAVE <eax,ebx>	; Save registers

	 cmp	 SEGLNK_LAST,0	; Izit initialized?
	 jne	 short @F	; Jump if so

	 mov	 SEGLNK_1ST,edi ; Mark as the first one
	 mov	 SEGLNK_LAST,edi ; ...	      last  ...
@@:
	 mov	 eax,edi	; Copy current LA
	 xchg	 eax,SEGLNK_LAST ; Swap with previous link

	 mov	 ebx,edi	; Copy current LA
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 xchg	 ebx,AGROUP:[eax].PERSEG_SEGSEQ ; Save as ptr to next link
	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERSEG_SEGSEQ,ebx ; Mark as last in chain

	 cmp	 ebx,-1 	; Just to be safe
	 je	 short @F	; Jump if we're sane

	 int	 03h		; Call our debugger *FIXME*
@@:
	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERSEG_CLSSYM,-1 ; Mark as sequenced

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINK_SEG endp			; End LINK_SEG procedure
	 NPPROC  FIND_NEXTSEG -- Find Next Unsequenced Segment
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Find the next unsequenced segment

On entry:

EDI	 =	 LA of next segment to check (PERSEG_STR)

On exit:

EDI	 =	 LA of next unsequenced segment (PERSEG_STR)

|

FIND_NEXTSEG_NEXT:
	 cmp	 edi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 short FIND_NEXTSEG_EXIT ; Jump if so

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 cmp	 AGROUP:[edi].PERSEG_CLSSYM,-1 ; Izit already sequenced?
	 jne	 short FIND_NEXTSEG_EXIT ; Jump if not
FIND_NEXTSEG_LOOP:
	 add	 edi,type PERSEG_STR ; Skip to next entry

	 jmp	 FIND_NEXTSEG_NEXT ; Go around again

FIND_NEXTSEG_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_NEXTSEG endp		; End FIND_NEXTSEG procedure
	 NPPROC  CALC_SEGS -- Calculate Segment Starting Addresses
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Calculate segment starting addresses

On entry:

EDI	 =	 LA of PERSEG_STR

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 mov	 SEG_START,0	; Initialize starting address
	 mov	 EXEFIL_SIZE,0	; ...	     file size w/o header

	 mov	 edi,SEGLNK_1ST ; Get LA of first segment in chain
CALC_SEGS_NEXT:
	 cmp	 edi,-1 	; Are we at the end?
	 je	 near ptr CALC_SEGS_DONE ; Jump if so

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

; Skip this if it's an Absolute alignment type

	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERSEG_SEGSYM ; Get LA of SYM_STR
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_FLAG ; Get the flags w/ACBP byte in low-order

	test	al,@SYMFL_A	; Izit Absolute alignment?
	jz	near ptr CALC_SEGS_LOOP ; Jump if so

; Round up the segment start address
; to match the alignment type of this segment

	push	eax		; Pass the fags w/ACBP byte in low-order
	push	SEG_START	; Pass the current size
	call	CHECK_ALIGN	; Check alignment
				; Return ECX = new current size
	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERSEG_ADRB.BOUND_BEG,ecx ; Save for later use
	 add	 ecx,AGROUP:[edi].PERSEG_NEWLEN ; Plus length of the segment
	 mov	 SEG_START,ecx	; Save for later use
	 dec	 ecx		; Less one to get ending address
;;;;;;;; UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERSEG_ADRB.BOUND_NXT,ecx ; Save for later use

; Save the ending address of the highest non-empty segment
; as the file size

;;;;;;;; UNCURB  edi,PERSEG	; Ensure within current bounds
	 cmp	 AGROUP:[edi].PERSEG_NEWLEN,0 ; Izit empty?
	 je	 short @F	; Jump if so

	 inc	 ecx		; Add one to get next address

	 cmp	 ecx,EXEFIL_SIZE ; Izit above current high-water mark?
	 jb	 short @F	; Jump if not

	 mov	 EXEFIL_SIZE,ecx ; Save as new high-water mark
@@:

; If this is a 16-bit segment, ensure it's not bigger than 64KB

	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 ebx,AGROUP:[edi].PERSEG_SEGSYM ; Get LA of segment name SYM_STR

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 test	 AGROUP:[ebx].SYM_FLAG.LO,@SYMFL_P ; Izit a 32-bitter?
	 jnz	 short @F	; Jump if so

;;;;;;;; UNCURB  edi,PERSEG	; Ensure within current bounds
	 cmp	 AGROUP:[edi].PERSEG_NEWLEN,@CON64KB+1 ; Izit bigger than 64KB?
	 cmc			; Complement so CF=0 is valid
	 jnc	 short @F	; Jump if not (nopte CF=0)

	 push	 dword ptr (offset PGROUP:IWF_SEGBIG) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_SEGBIG	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for large segments
				; Return with CF=1 if it's fatal
	jc	short CALC_SEGS_EXIT ; Jump if it's fatal
@@:
CALC_SEGS_LOOP:
	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 edi,AGROUP:[edi].PERSEG_SEGSEQ ; Get LA of next segment
				; in sequence (PERSEG_STR)
	 jmp	 CALC_SEGS_NEXT ; Go around again

CALC_SEGS_DONE:
	 clc			; Mark as successful
CALC_SEGS_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_SEGS endp			; End CALC_SEGS procedure
	 NPPROC  SPEC_SEG -- Izit A Special Segment
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Determine whether or not this is a special segment.

On entry:

EDI	 =	 LA of PERSEG_STR

On exit:

CF	 =	 0 if it's a special segment
	 =	 1 if not

|

	 pushad 		; Save registers

	 mov	 edx,edi	; Copy LA of segment(PERSEG_STR)
	 UNCURB  edi,PERSEG	; Ensure within current bounds
	 mov	 edi,AGROUP:[edi].PERSEG_SEGSYM ; Get LA of Segment-Class-CombineType
				; (SYM_STR)
	 UNCURB  edi,SYMBOL	; Ensure within current bounds
	 mov	 eax,AGROUP:[edi].SYM_NAMLEN ; Get length of Seg-Class-ComType
	 UNCURB  edi,SYMBOL	; Ensure within current bounds
	 mov	 edi,AGROUP:[edi].SYM_PNAM ; Get LA of symbol (Count, Char[])
	 xor	 ebx,ebx	; Initialize index into SPECSEG_TAB
	 mov	 ecx,NSPECSEG_TAB ; Get # special segments
SPEC_SEG_NEXT:
	 mov	 esi,SPECSEG_TAB[ebx*(type SPECSEG_TAB)] ; Get offset in DGROUP

	 REGSAVE <ecx,edi>	; Save for a moment
	 mov	 ecx,eax	; Copy symbol length
	 UNCURB  edi,TXTSTR	; Ensure within current bounds
    repe cmps	 DGROUP:[esi].LO,AGROUP:[edi].LO ; Izit something special?
	 REGREST <edi,ecx>	; Restore
	 je	 short SPEC_SEG_MATCH ; Jump if it's a match

	 inc	 ebx		; Skip to next entry

	 loop	 SPEC_SEG_NEXT	; Jump if more special segments to check

	 stc			; Mark as not special

	 jmp	 short SPEC_SEG_EXIT ; Join common exit code

SPEC_SEG_MATCH:
	 UNCURB  edx,PERSEG	; Ensure within current bounds
	 or	 AGROUP:[edx].PERSEG_FLAG,@PERSEG_SKIP ; Mark as skippable

	 clc			; Mark as special segment
SPEC_SEG_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SPEC_SEG endp			; End SPEC_SEG procedure
	 NPPROC  IWF_SEGBIG -- Ignore/Warn/Fail On Segment Exceeding 64KB
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail on segment exceeding 64KB.

On entry:

EBX	 =	 LA of segment name SYM_STR

|

	 REGSAVE <eax>		; Save register

	 inc	 ERRCNT 	; Mark as writing to error file

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_SEGBIG) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the segment name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_SEGBIG1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_SEGBIG endp 		; End IWF_SEGBIG procedure
	 NPPROC  PROC_COMDEF -- Process COMDEF Records
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process COMDEF records

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 mov	 edi,LMB_COMDEF.LMB_CURB.BOUND_BEG ; Get starting address

	 cmp	 edi,LMB_COMDEF.LMB_CURB.BOUND_NXT ; Are there any COMDEF records?
	 je	 near ptr PROC_COMDEF_EXIT ; Jump if so (note CF=0)

; Create an entry for 'c_common' as a segment

	 push	 offset DGROUP:C_COMMON_GRP ; Pass offset in DGROUP of group name
	 push	 offset DGROUP:C_COMMON_CLS ; ...		       class name
	 push	 offset DGROUP:C_COMMON_SCT ; ...		       SCT data
	 push	 C_COMMON_LEN	; Pass length of SCT data
	 call	 FIND_GSCT	; Find a Group-Segment-Class-CombineType
				; Return with SPSYM_GRP, SPSYM_SEG filled in
	 jc	 near ptr PROC_COMDEF_EXIT ; Jump if something went wrong *FIXME*
				; Needs better error handling *FIXME*

	 mov	 eax,SPSYM_SEG	; Get LA of segment (PERSEG_STR)
	 mov	 C_COMMON_PPERSEG,eax ; Save for later use

	 mov	 eax,SPSYM_GRP	; Get LA of segment (PERGRP_STR)
	 mov	 C_COMMON_PPERGRP,eax ; Save for later use

; Create an entry for 'FAR_BSS' as a segment

	 push	 offset DGROUP:FAR_BSS_GRP ; Pass offset in DGROUP of group name
	 push	 offset DGROUP:FAR_BSS_CLS ; ...		      class name
	 push	 offset DGROUP:FAR_BSS_SCT ; ...		      SCT data
	 push	 FAR_BSS_LEN	; Pass length of SCT data
	 call	 FIND_GSCT	; Find a Group-Segment-Class-CombineType
				; Return with SPSYM_GRP, SPSYM_SEG filled in
	 jc	 near ptr PROC_COMDEF_EXIT ; Jump if something went wrong *FIXME*
				; Needs better error handling *FIXME*

	 mov	 eax,SPSYM_SEG	; Get LA of segment (PERSEG_STR)
	 mov	 FAR_BSS_PPERSEG,eax ; Save for later use

	 mov	 eax,SPSYM_GRP	; Get LA of segment (PERGRP_STR)
	 mov	 FAR_BSS_PPERGRP,eax ; Save for later use

; Trundle through the COMDEF records

;;;;;;;; mov	 edi,LMB_COMDEF.LMB_CURB.BOUND_BEG ; Get starting address
PROC_COMDEF_NEXT:
	 cmp	 edi,LMB_COMDEF.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 near ptr PROC_COMDEF_EXIT ; Jump if so (note CF=0)

	 UNCURB  edi,COMDEF	; Ensure within current bounds
	 mov	 edx,AGROUP:[edi].COMDEF_PPUBDEF ; Get LA of public (PUBDEF_STR)

	 UNCURB  edx,PUBDEF	; Ensure within current bounds
	 cmp	 AGROUP:[edx].PUBDEF_NELM,-1 ; Izit near data?
	 jne	 short PROC_COMDEF_FAR ; Jump if not

; It's a near COMDEF value

	 mov	 eax,C_COMMON_PPERGRP ; Get LA of 'c_common' group (PERGRP_STR)
	 UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPERGRP,eax ; Save as LA of PERGRP_STR

	 mov	 ebx,C_COMMON_PPERSEG ; Get LA of 'c_common' segment (PERSEG_STR)
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPERSEG,ebx ; Save as LA of PERSEG_STR

	 jmp	 short PROC_COMDEF_COM ; Join common code


; It's a far COMDEF value

PROC_COMDEF_FAR:
	 mov	 eax,FAR_BSS_PPERGRP ; Get LA of 'FAR_BSS' group (PERGRP_STR)
	 UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPERGRP,eax ; Save as LA of PERGRP_STR

	 mov	 ebx,FAR_BSS_PPERSEG ; Get LA of 'FAR_BSS' segment (PERSEG_STR)
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 AGROUP:[edx].PUBDEF_PPERSEG,ebx ; Save as LA of PERSEG_STR
PROC_COMDEF_COM:
	 UNCURB  ebx,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[ebx].PERSEG_NEWLEN ; Get size before adding in this data
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 add	 AGROUP:[edx].PUBDEF_ADDR,eax ; Add in the public offset
				; part of the entire address
;;;;;;;; UNCURB  edx,PUBDEF	; Ensure within current bounds
	 mov	 eax,AGROUP:[edx].PUBDEF_SIZ ; Get the data size
;;;;;;;; UNCURB  ebx,PERSEG	; Ensure within current bounds
	 add	 AGROUP:[ebx].PERSEG_NEWLEN,eax ; Add into segment length

	 add	 edi,type COMDEF_STR ; Skip to next entry

	 jmp	 PROC_COMDEF_NEXT ; Go around again

PROC_COMDEF_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_COMDEF endp		; End PROC_COMDEF procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_SEG module
