;' $Header$
	title	QLNK_NE -- QLINK New Executable File Routines
	page	58,122
	name	QLNK_NE

COMMENT|				Module Specifications

Copyright:  (C) Copyright 2000 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, May, 2000.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include EXE.INC
	include ALLMEM.INC
	include WINSTR.INC
	include DOSCALL.INC
	include OPEN.INC
	include BITFLAGS.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA16	segment 		; Start DATA16 segment
	assume	cs:PGROUP,ds:DGROUP

@OFF_RELO equ	WINSTUB_RELO - WINSTUB_HDR ; Offset to relocation table
@SIZ_HDR equ	(@OFF_RELO + (16 - 1)) / 16 ; Header size in paras

	public	WINSTUB_HDR,WINSTUB_BOD
WINSTUB_HDR EXE_STR <,?,?,0,@SIZ_HDR,0,-1,0,0B8h,0,0,0,@OFF_RELO,0>
	org	WINSTUB_HDR.DOSHDR_LFANEW
	dd	WINSTUB_BODZ - WINSTUB_HDR
;;;;;;; DOSHDR_STR <,,?,?,,WINSTUB_BODZ - WINSTUB_HDR>
	org	WINSTUB_HDR + (type DOSHDR_STR)
WINSTUB_RELO label word
WINSTUB_BOD label byte
	PUSH	CS
	POP	DS
	MOV	DX,(offset cs:WINSTUB_MSG) - (offset cs:WINSTUB_BOD)
	MOV	AH,@STROUT
	INT	21h
	MOV	AX,4C01h
	INT	21h
WINSTUB_MSG label byte
	db	'This program requires Microsoft Windows.',CR,LF,EOS
WINSTUB_BODZ label byte 	; End of header body
@WINSTUB_LEN equ $-WINSTUB_HDR	; Length of header

DATA16	ends			; End DATA16 segment


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	DEF_FLAG:dword
	include QLNK_DEF.INC

	extrn	VERS_HTU:abs
	extrn	WINVER:word
	extrn	LaDATA:dword
	extrn	MINSTACK:dword
	extrn	LMB_EXEHDR:tbyte
	extrn	LMB_IMPDEF:tbyte
	extrn	LMB_EXPDEF:tbyte
	extrn	LMB_PERSEG:tbyte
	extrn	LMB_PERCLS:tbyte
	extrn	LMB_PERGRP:tbyte
	extrn	LMB_PUBDEF:tbyte
	extrn	LMB_TXTSTR:tbyte
	extrn	LMB_PERMOD:tbyte
	extrn	LMB_PERLSEG:tbyte
	extrn	LMB_SYMBOL:tbyte
	extrn	LMB_FIXUPP:tbyte
	extrn	WIN_STUB:byte
	extrn	NEXTSEG:word
	extrn	SEGLNK_1ST:dword
	extrn	WIN_NAME:byte
	extrn	WIN_DESC:byte
	extrn	MODCNT:dword
	extrn	ALIGN_LOG2:byte
	extrn	LSEG_DGROUP:dword
	extrn	EXE_HDR:tbyte
	extrn	MODEND_FIXUPP:dword
	extrn	STACK_PPERSEG:dword
	extrn	ALIGN_MASK:dword
	extrn	ALIGN_COMP:dword

	public	MINHEAP
MINHEAP dd	0		; Minimum heap size

	public	LaNEHDR
LaNEHDR dd	?		; LA of NE header in extended memory

	public	NE_HDR
NE_HDR	NE_STR	<>		; NE header

	public	NE_HDR_OFF
NE_HDR_OFF dd	type NE_HDR	; Initial offset from start of NE header

	public	LaSEGTAB
LaSEGTAB dd	?		; LA of SEGTAB

	public	FIRST_ETAB,LAST_ORDNO,LAST_ETYP,LAST_ECNT,MOVCNT
FIRST_ETAB dd	?		; LA of first entry table entry
LAST_ORDNO dd	?		; Last ordinal #
MOVCNT	dw	0		; # movable entry points
LAST_ETYP db	?		; Last entry table type
LAST_ECNT db	?		; ...		   count

DATA	ends					; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP

	NPPROC	WRITE_NE -- Write Out New Executable File
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Write out the New Executable (NE) file.

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

; Check for and reject /TINY






;;; ; If there's no MINSTACK specified, set it to 10KB
;;;
;;;	    cmp     MINSTACK,0	    ; Izit empty?
;;;	    jne     short @F	    ; Jump if not
;;;
;;;	    mov     MINSTACK,10*@CON1KB ; Set to 10KB
;;; @@:
;;;
; Save the starting IP from the fixup calculations

	mov	ax,EXE_HDR.EXE_IP ; Get the starting IP
	mov	NE_HDR.NE_CSIP.VOFF,ax ; Save for later use

	mov	edi,MODEND_FIXUPP ; Get MODEND fixup (FIXUPP_STR)
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	edi,AGROUP:[edi].FIXUPP_TGT ; Get the target struc (PERSEG_STR)
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PERSEG_CLS ; Get the class (PERCLS_STR)
	UNCURB	edi,PERCLS	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PERCLS_PERLSEG ; Get the logical segment (PERLSEG_STR)
	UNCURB	edi,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERLSEG_LSEG ; Get the logical segment #
	mov	NE_HDR.NE_CSIP.VSEG,ax ; Save in NE header

	mov	edi,STACK_PPERSEG ; Get stack segment (PERSEG_STR)
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PERSEG_CLS ; Get the class (PERCLS_STR)
	UNCURB	edi,PERCLS	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PERCLS_PERLSEG ; Get the logical segment (PERLSEG_STR)
	UNCURB	edi,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERLSEG_LSEG ; Get the logical segment #
	mov	NE_HDR.NE_SSSP.VSEG,ax ; Save in NE header

;;	mov	NE_HDR.NE_SSSP,??? ; *FIXME*

; Write out the initial EXE header from either the
; user-specified STUB or the default one

	cmp	WIN_STUB[0],0	; Izit present?
	je	short WRITE_NE_STUB_DEF ; Jump if not (use default)

; Open the STUB file

	lea	edx,WIN_STUB	; DGROUP:EDX ==> WINSTUB
	add	edx,LaDATA	; Plus LA of DGROUP to get LA of header
	mov	al,@OPEN_R	; Open in read-only mode
	DOSCALL @OPENF2 	; Open the file
	jc	near ptr WRITE_NE_OPENERR ; Jump if something went wrong

	mov	bx,ax		; Copy to handle register

; Read in the file to low DOS memory

	movzx	edx,NEXTSEG	; Get next available segment
	shl	edx,4-0 	; Convert from paras to bytes
	mov	ecx,-1		; Read it in entirely
	DOSCALL @READF2 	; Read it in
	jc	near ptr WRITE_NE_READERR ; Jump if something went wrong

	push	eax		; Save # bytes actually read
	DOSCALL @CLOSF2 	; Close up the STUB file
	pop	eax		; Restore

; Copy the file to the .EXE file buffer

	mov	esi,edx 	; Copy as source offset
	mov	ecx,eax 	; Copy actual # bytes read

	mov	eax,512-1	; Set rounding mask to 512-byte boundary

	jmp	short WRITE_NE_DEF_COM ; Join common code


; Copy default WINSTUB to the .EXE file buffer

WRITE_NE_STUB_DEF:
	lea	esi,WINSTUB_HDR ; Get offset of .EXE header
	add	esi,LaDATA	; Plus LA of DGROUP to get LA of header
	mov	ecx,@WINSTUB_LEN ; Get # bytes to write out
	mov	eax,16-1	; Set rounding mask to para boundary
WRITE_NE_DEF_COM:
	mov	edi,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	mov	edx,edi 	; Copy start for later use
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to file buffer

; Round up to appropriate boundary

	mov	ecx,edi 	; Copy ending address
	sub	ecx,edx 	; Less start of .EXE/.COM file buffer
	add	ecx,eax 	; Round up to next boundary
	not	eax		; Complement to clear low-order bits
	and	ecx,eax 	; ...
	add	ecx,edx 	; Add start to get ending
	sub	ecx,edi 	; Less ending to get length

; Zero intervening storage

	xor	eax,eax 	; Fill with this
    rep stos	AGROUP:[edi].LO ; ...

	mov	eax,edi 	; Copy rounded length
	sub	eax,edx 	; Less start of .EXE/.COM file buffer
	mov	AGROUP:[edx].DOSHDR_LFANEW,eax ; Save in struc

; Common code after writing our WINSTUB
; EAX	=	# bytes written (rounded)
; EDI	==>	next address

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high

; Fill in the EXE header based upon the STUB

;;;;;;; mov	AGROUP:[edx].EXE_R512,??? ; *FIXME*
;;;;;;; mov	AGROUP:[edx].EXE_Q512,??? ; *FIXME*
;;;;;;; mov	AGROUP:[edx].EXE_MIN,??? ; *FIXME*

; If the relocation table items aren't already
; beyond DOSHDR, copy them there

	cmp	AGROUP:[edx].EXE_IREL,type DOSHDR_STR ; Izit at or above?
	jae	short WRITE_NE_DEF1 ; Jump if so

	movzx	ecx,AGROUP:[edx].EXE_NREL ; Get # relocation table items
	movzx	esi,AGROUP:[edx].EXE_IREL ; DS:ESI ==> source offset from EDX
	add	esi,edx 	; Add to get LA of source
	lea	edi,AGROUP:[edx].DOSHDR_LFANEW ; ES:EDI ==> destin
	add	edi,type DOSHDR_LFANEW ; ES:EDI ==> destin
	mov	eax,edi 	; Copy destin offset
	sub	eax,edx 	; Subtract to get new offset
	mov	AGROUP:[edx].EXE_IREL,ax ; Save in .EXE header

; Move data backwards in case there's an overlap

	lea	edi,[edi+ecx*4] ; Point to end
	lea	esi,[esi+ecx*4] ; ...
	sub	edi,4		; ...
	sub	esi,4		; ...
	std			; Backwards
    rep movs	AGROUP:[edi].EDD,AGROUP:[esi].EDD ; Copy to new location
	cld			; Restore
WRITE_NE_DEF1:

; Copy the .EXE header back to local storage so we can re-write it later on
; with entries which can't be calculated now

	lea	edi,WINSTUB_HDR ; DGROUP:EDI ==> destin
	add	edi,LaDATA	; AGROUP:EDI ==> destin
	mov	esi,edx 	; AGROUP:ESI ==> source
	mov	ecx,type DOSHDR_STR ; ECX = # bytes in header
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to file buffer

; Fill in the NE header locally

	mov	ax,VERS_HTU	; Get our version #
	mov	NE_HDR.NE_LMAJ,ah ; Save in struc
	mov	NE_HDR.NE_LMIN,al ; ...

	mov	NE_HDR.NE_CRC,0 ; No CRC calculated

; Determine the Program flags

	xor	al,al		; Initialize the flags

	test	DEF_FLAG,@DEF_PMODE ; Izit PROTMODE?
	jz	short @F	; Jump if not

	or	al,@NE_PFLAG_PMONLY ; Mark as such
@@:
	mov	ebx,DEF_FLAG	; Get defintitions flags
	and	ebx,@DEF_INST	; Isolate the instance flags
	shr	ebx,$DEF_INST	; Shift to low-order
	dec	bl		; Convert from origin-1 to origin-0
	shl	bl,$NE_PFLAG_DTYPE ; Shift into position
	or	al,bl		; Include in PFLAGs
	mov	NE_HDR.NE_PFLAG,al ; Save in struc

; Determine the Application Flags

	xor	al,al		; Initialize the flags
	mov	ebx,DEF_FLAG	; Get defintitions flags
	and	ebx,@DEF_ETYPE	; Isolate the executable type flags

	cmp	ebx,@DEF_ETYPE_LIB shl $DEF_ETYPE ; Izit a DLL?
	jne	short @F	; Jump if not

	or	al,@NE_AFLAG_DLL ; Mark as such
@@:
	mov	ebx,DEF_FLAG	; Get defintitions flags
	and	ebx,@DEF_NTYPE	; Isolate the name type flags
	shr	ebx,$DEF_NTYPE	; Shift to low-order
	shl	bl,$NE_AFLAG_ATYPE ; Shift into position
	or	al,bl		; Include in AFLAGs
	mov	NE_HDR.NE_AFLAG,al ; Save in struc

	mov	eax,LSEG_DGROUP ; Get logical segment # of DGROUP
	mov	NE_HDR.NE_AUTO,ax ; Save in struc

	mov	eax,MINHEAP	; Get minimum heap size
	mov	NE_HDR.NE_IHEAP,ax ; Save in struc

	mov	eax,MINSTACK	; Get minimum stack size
	mov	NE_HDR.NE_ISTK,ax ; Save in struc

	movzx	ax,ALIGN_LOG2	; Get Log2 of alignment
	mov	NE_HDR.NE_ALIN,ax ; Save in struc

	mov	NE_HDR.NE_TGTOS,@NE_TGTOS_WIN ; Mark as Windows Executable
	mov	NE_HDR.NE_OFLAG,0 ; No Other OS/2 EXE flags

;;	mov	NE_HDR.NE_ORTHUNK,??? ; *FIXME*
;;	mov	NE_HDR.NE_OSTHUNK,??? ; *FIXME*
;;	mov	NE_HDR.NE_MINSWAP,??? ; *FIXME*

	mov	ax,WINVER	; Get minimum version # of Windows
	mov	NE_HDR.NE_EXPVER.ELO,ax

; Copy the NE header to extended memory

	lea	esi,NE_HDR	; FS:ESI ==> NE header
	mov	edi,LMB_EXEHDR.LMB_CURB.BOUND_NXT ; ES:EDI ==> next address
	mov	LaNEHDR,edi	; Save as LA of NE header
	mov	ecx,type NE_HDR ; ECX = length
    rep movs	AGROUP:[edi].LO,NE_HDR[esi].LO ; Copy to new location

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create the segment table
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

COMMENT|

The segment table contains information that describes each segment in an
executable file. This information includes the segment length, segment type,
and segment-relocation data. The following list summarizes the values found
in the segment table (the locations are relative to the beginning of each
entry):

 Location ³ Description
 ÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
  00h	  ³ Specifies the offset, in sectors, to the segment data (relative
	  ³ to the beginning of the file). A value of zero means no data
	  ³ exists.
	  ³
  02h	  ³ Specifies the length, in bytes, of the segment, in the file. A
	  ³ value of zero indicates that the segment length is 64K, unless
	  ³ the selector offset is also zero.
	  ³
  04h	  ³ Specifies flags that describe the contents of the executable
	  ³ file. This value can be one or more of the following:
	  ³
	  ³ Bit  ³ Meaning
	  ³ ÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
	  ³  0	 ³ If this bit is set, the segment is a data segment.
	  ³	 ³ Otherwise, the segment is a code segment.
	  ³	 ³
	  ³  1	 ³ If this bit is set, the loader has allocated memory for
	  ³	 ³ the segment.
	  ³	 ³
	  ³  2	 ³ If this bit is set, the segment is loaded.
	  ³	 ³
	  ³  3	 ³ Iterated segment.
	  ³	 ³
	  ³  4	 ³ If this bit is set, the segment type is MOVABLE.
	  ³	 ³ Otherwise, the segment type is FIXED.
	  ³	 ³
	  ³  5	 ³ If this bit is set, the segment type is PURE or
	  ³	 ³ SHAREABLE. Otherwise, the segment type is IMPURE or
	  ³	 ³ NONSHAREABLE.
	  ³	 ³
	  ³  6	 ³ If this bit is set, the segment type is PRELOAD.
	  ³	 ³ Otherwise, the segment type is LOADONCALL.
	  ³	 ³
	  ³  7	 ³ If this bit is set and the segment is a code segment, the
	  ³	 ³ segment type is EXECUTEONLY. If this bit is set and the
	  ³	 ³ segment is a data segment, the segment type is READONLY.
	  ³	 ³
	  ³  8	 ³ If this bit is set, the segment contains relocation data.
	  ³	 ³
	  ³  9	 ³ Confirming segment.
	  ³	 ³
	  ³ 10-11³ I/O Privilege level
	  ³	 ³
	  ³ 12	 ³ If this bit is set, the segment is discardable.
	  ³	 ³
	  ³ 13	 ³ 32-bit segment.
	  ³	 ³
	  ³ 14	 ³ Huge segment.
	  ³	 ³
	  ³ 15	 ³ Reserved.
	  ³
  06h	  ³ Specifies the minimum allocation size of the segment, in bytes.
	  ³ A value of zero indicates that the minimum allocation size is
	  ³ 64K.

|

	mov	ebx,NE_HDR_OFF	; Copy next offset
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_OSEGTAB,bx ; Save in struc

; Trundle through all the segments in sequence using the SEGLNK chain
; filling in the segments table

	add	ebx,LaNEHDR	; Plus offset of NE header
	mov	LaSEGTAB,ebx	; Save for later use
	xor	ecx,ecx 	; Initialize segment count
	mov	edi,SEGLNK_1ST	; Get starting LA
WRITE_NE_SEGTAB_NEXT:
	cmp	edi,-1		; Are we at the end?
	je	near ptr WRITE_NE_SEGTAB_DONE ; Jump if so

; Consider only those segments which have a logical segment #

	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	esi,AGROUP:[edi].PERSEG_CLS ; Get LA of class (PERCLS_STR)

	UNCURB	esi,PERCLS	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)

	UNCURB	esi,PERLSEG	; Ensure within current bounds
	cmp	AGROUP:[esi].PERLSEG_LSEG,0 ; Izit invalid?
	je	short WRITE_NE_SEGTAB_LOOP ; Jump if so

; Skip this segment if its class has been used already

;;;;;;; UNCURB	esi,PERLSEG	; Ensure within current bounds
	bts	AGROUP:[esi].PERLSEG_FLAG,$PERLSEG_SEGTAB ; Izit already used?
	jc	short WRITE_NE_SEGTAB_LOOP ; Jump if so

; Skip this segment if its group has been used already

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERSEG_GRPSYM ; Get LA of group (SYM_STR)
	and	eax,eax 	; Izit invalid?
	jz	short @F	; Jump if so

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get the group (PERGRP_STR)

	UNCURB	eax,PERGRP	; Ensure within current bounds
	bts	AGROUP:[eax].PERGRP_FLAG,$PERGRP_SEGTAB ; Izit already used?
	jc	short WRITE_NE_SEGTAB_LOOP ; Jump if so
@@:

; If the Windows flags are valid, use them for this segment

;;;;;;; UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PERSEG_WFLAG ; Get Windows flags
	mov	AGROUP:[ebx].NE_SEGTAB_FLAG,ax ; Save in struc

; *FIXME* -- handle huge & 32-bit & relocatable segments

	UNCURB	esi,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PERLSEG_LEN ; Get length of the segments in this class
	mov	AGROUP:[ebx].NE_SEGTAB_LEN,ax ; Save in struc
	mov	AGROUP:[ebx].NE_SEGTAB_MIN,ax ; ...

	add	ebx,type NE_SEGTAB_STR ; Skip to next entry
	inc	ecx		; Count in another segment
WRITE_NE_SEGTAB_LOOP:
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PERSEG_SEGSEQ ; Skip to next entry

	jmp	WRITE_NE_SEGTAB_NEXT ; Go around again


WRITE_NE_SEGTAB_DONE:
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_SEGCNT,cx ; Save # segments in table

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,ebx ; Save as new high

	sub	ebx,LaNEHDR	; Less offset of NE header
	mov	NE_HDR_OFF,ebx	; Skip to next available NE header offset

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create the resource table
; (That's not our job.)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;;;;;;; mov	ebx,NE_HDR_OFF	; Copy next offset
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_ORESTAB,bx ; Save in struc
	mov	AGROUP:[edx + eax].NE_RESCNT,0 ; No resource segments

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create the resident names table
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

COMMENT|

The resident-name table contains strings that identify exported functions in
the executable file.  As the name implies, these strings are resident in
system memory and are never discarded.	The resident-name strings are
case-sensitive and are not null-terminated.  The following list summarizes
the values found in the resident-name table (the locations are relative to
the beginning of each entry):

 Location  ³ Description
 ÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
   00h	   ³ Specifies the length of a string.	If there are no more strings
	   ³ in the table, this value is zero.
	   ³
 01h - xxh ³ Specifies the resident-name text.	This string is case-sensitive
	   ³ and is not null-terminated.
	   ³
 xxh + 01h ³ Specifies a word ordinal number that identifies the string.  This
	   ³ number is an index into the entry table.

The first string in the resident-name table is the module name.

|

;;;;;;; mov	ebx,NE_HDR_OFF	; Copy next offset
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_ORNMTAB,bx ; Save in struc

; Copy the module name

	lea	esi,WIN_NAME	; DGROUP:ESI ==> source (CC_STR)
	mov	edi,ebx 	; Copy next offset
	add	edi,LaNEHDR	; Plus offset of NE header
				; AGROUP:EDI ==> destin
	movzx	ecx,WIN_NAME.CC_COUNT ; Get the length byte
	add	ecx,type CC_COUNT ; Count in the length byte

    rep movs	AGROUP:[edi].LO,WIN_NAME[esi] ; Copy to res name table

	xor	ax,ax		; Ordinal number for module name
	stos	AGROUP:[edi].ELO ; Save in res name table

; Trundle through EXPDEF_STRs looking for resident names

	mov	LAST_ORDNO,1	; Initialize ordinal #
	mov	ebx,LMB_EXPDEF.LMB_CURB.BOUND_BEG ; Get LA of 1st entry
WRITE_NE_RNMTAB_NEXT:
	cmp	ebx,LMB_EXPDEF.LMB_CURB.BOUND_NXT ; Izit over?
	jae	short WRITE_NE_RNMTAB_DONE ; Jump if so

	UNCURB	ebx,EXPDEF	; Ensure within current bounds
	test	AGROUP:[ebx].EXPDEF_FLAG,@EXPFL_RES ; Izit resident?
	jz	short WRITE_NE_RNMTAB_LOOP ; Jump if not

;;;;;;; UNCURB	ebx,EXPDEF	; Ensure within current bounds
	lea	esi,AGROUP:[ebx].EXPDEF_EXPNAME ; AGROUP:ESI ==> source
;;;;;;; UNCURB	ebx,EXPDEF	; Ensure within current bounds
	movzx	ecx,AGROUP:[ebx].EXPDEF_EXPNAME.CC_COUNT ; Get the length byte
	add	ecx,type CC_COUNT ; Count in the length byte
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to res name table

	mov	eax,LAST_ORDNO	; Copy ordinal #
	stos	AGROUP:[edi].ELO ; Save in res name table
WRITE_NE_RNMTAB_LOOP:
	inc	LAST_ORDNO	; Skip to next ordinal #
	add	ebx,type EXPDEF_STR ; Skip to next entry

	jmp	WRITE_NE_RNMTAB_NEXT ; Go around again


WRITE_NE_RNMTAB_DONE:
	mov	al,0		; Marker for end-of-table
	stos	AGROUP:[edi].LO ; Save in res name table

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high

	sub	edi,LaNEHDR	; Less offset of NE header
	mov	NE_HDR_OFF,edi	; Skip to next available NE header offset

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create the module reference table
; Create the imported names table
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

COMMENT|

The module-reference table contains offsets for module names stored in the
imported-name table.  Each entry in this table is 2 bytes long.  The offsets
are from the start of the imported names table.

The imported-name table contains the names of modules that the executable
file imports.  Each entry contains two parts: a single byte that specifies
the length of the string and the string itself.  The strings in this table
are not null-terminated.

|

	mov	ebx,NE_HDR_OFF	; Copy next offset
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_OMODTAB,bx ; Save in struc
	add	ebx,LaNEHDR	; Plus offset of NE header

	mov	ecx,MODCNT	; Get # unique module names
	mov	AGROUP:[edx + eax].NE_REFCNT,cx ; Save in NE header

	lea	edi,AGROUP:[ebx + ecx * (type NE_MODTAB_STR)] ; Skip over the module-reference table
	mov	ecx,edi 	; Copy LA
	sub	ecx,LaNEHDR	; Less offset of NE header
	mov	AGROUP:[edx + eax].NE_OIMPTAB,cx ; Save in struc

COMMENT|

EBX	==>	module reference table
EDI	==>	imported names table

|

	mov	ebp,edi 	; Copy LA of start of imported names table

; For some reason, the first entry in the imported names table is zero

	mov	al,0		; Get fill value
	stos	AGROUP:[edi].LO ; Fill it

; Loop through the entries in IMPDEF_STR, copying unique module names

	mov	ecx,LMB_IMPDEF.LMB_CURB.BOUND_BEG ; Get LA of start
WRITE_NE_MODTAB_NEXT:
	cmp	ecx,LMB_IMPDEF.LMB_CURB.BOUND_NXT ; Izit over?
	jae	short WRITE_NE_MODTAB_DONE ; Jump if so

	UNCURB	ecx,IMPDEF	; Ensure within current bounds
	mov	esi,AGROUP:[ecx].IMPDEF_PPERMOD ; Get LA of module (PERMOD_STR)

	UNCURB	esi,PERMOD	; Ensure within current bounds
	bts	AGROUP:[esi].PERMOD_FLAG,$PERMOD_USED ; Mark as copied
	jc	short WRITE_NE_MODTAB_LOOP ; Jump if already copied

;;;;;;; UNCURB	esi,PERMOD	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERMOD_MODSYM ; Get LA of module name (SYM_STR)

; Save the offset into the module reference table

	mov	eax,edi 	; Copy LA of next entry in imported names table
	sub	eax,ebp 	; Less LA of start of ...
	mov	AGROUP:[ebx].NE_MODTAB_OFF,ax ; Save in mod ref table
	add	ebx,type NE_MODTAB_STR ; Skip to next entry

; Copy the name to the imported names table

	push	ecx		; Save for a moment

	UNCURB	esi,SYMBOL	; Ensure within current bounds
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of name (CC_STR)
	UNCURB	esi,TXTSTR	; Ensure within current bounds
	movzx	ecx,AGROUP:[esi].CC_COUNT ; Get the length byte
	add	ecx,type CC_COUNT ; Skip over it
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to imported names table

	pop	ecx		; Restore
WRITE_NE_MODTAB_LOOP:
	add	ecx,type IMPDEF_STR ; SKip to next entry

	jmp	WRITE_NE_MODTAB_NEXT ; Go around again


WRITE_NE_MODTAB_DONE:

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high

	sub	edi,LaNEHDR	; Less offset of NE header
	mov	NE_HDR_OFF,edi	; Skip to next available NE header offset

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create the entry table
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

COMMENT|

The entry table contains bundles of entry points from the executable file
(the linker generates each bundle). The numbering system for these ordinal
values is 1-based--that is, the ordinal value corresponding to the first
entry point is 1.

The linker generates the densest possible bundles under the restriction that
it cannot reorder the entry points. This restriction is necessary because
other executable files may refer to entry points within a given bundle by
their ordinal values.

The entry-table data is organized by bundle, each of which begins with a
2-byte header. The first byte of the header specifies the number of entries
in the bundle (a value of 00h designates the end of the table). The second
byte specifies whether the corresponding segment is movable or fixed. If the
value in this byte is 0FFh, the segment is movable.

If the value in this byte is 0FEh, the entry does not refer to a segment
but refers, instead, to a constant defined within the module. If the value
in this byte is neither 0FFh nor 0FEh, it is a segment index.

For movable segments, each entry consists of 6 bytes and has the following
form:

 Location ³ Description
 ÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
  00h	  ³ Specifies a byte value. This value can be a combination of the
	  ³ following bits:
	  ³
	  ³ Bit(s) ³ Meaning
	  ³ ÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
	  ³   0    ³ If this bit is set, the entry is exported.
	  ³	   ³
	  ³   1    ³ If this bit is set, the segment uses a global (shared)
	  ³	   ³ data segment.
	  ³	   ³
	  ³  3-7   ³ If the executable file contains code that performs
	  ³	   ³ ring transitions, these bits specify the number of
	  ³	   ³ words that compose the stack. At the time of the ring
	  ³	   ³ transition, these words must be copied from one ring
	  ³	   ³ to the other.
	  ³
  01h	  ³ Specifies an int 3fh instruction.
	  ³
  03h	  ³ Specifies the segment number.
	  ³
  04h	  ³ Specifies the segment offset.

For fixed segments, each entry consists of 3 bytes and has the following
form:

 Location ³ Description
 ÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
  00h	  ³ Specifies a byte value. This value can be a combination of the
	  ³ following bits:
	  ³
	  ³ Bit(s) ³ Meaning
	  ³ ÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
	  ³  0	   ³ If this bit is set, the entry is exported.
	  ³	   ³
	  ³  1	   ³ If this bit is set, the entry uses a global (shared)
	  ³	   ³ data segment. (This may be set only for SINGLEDATA
	  ³	   ³ library modules.)
	  ³	   ³
	  ³ 3-7    ³ If the executable file contains code that performs
	  ³	   ³ ring transitions, these bits specify the number of
	  ³	   ³ words that compose the stack. At the time of the ring
	  ³	   ³ transition, these words must be copied from one ring
	  ³	   ³ to the other.
	  ³
  01h	  ³ Specifies an offset.

|

	mov	edi,NE_HDR_OFF	; Copy next offset
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_OffETAB,di ; Save in struc
	add	edi,LaNEHDR	; Plus offset of NE header
	mov	FIRST_ETAB,edi	; Save LA of start of entry table

	mov	ebx,LMB_EXPDEF.LMB_CURB.BOUND_BEG ; Get LA of start
	mov	LAST_ETYP,0	; Initialize last entry table type
WRITE_NE_ETAB_NEXT0:
	mov	ebp,edi 	; Copy LA of start of entry table

	add	edi,type NE_ETAB_STR ; Skip over header

; Trundle through EXPDEF_STRs looking for symbols in logical segments

	mov	LAST_ECNT,0	; Initialize last entry table count
WRITE_NE_ETAB_NEXT:
	cmp	ebx,LMB_EXPDEF.LMB_CURB.BOUND_NXT ; Izit over?
	jae	near ptr WRITE_NE_ETAB_DONE ; Jump if so

	UNCURB	ebx,EXPDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].EXPDEF_PSYM ; Get LA of symbol (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	esi,AGROUP:[eax].SYM_PERITEM ; Get LA of public def (PUBDEF_STR)

	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	ecx,AGROUP:[esi].PUBDEF_PPERSEG ; Get LA of segment (PERSEG_STR)

	mov	al,@NE_ETAB_TYP_MOVABLE ; Assume it's movable

	UNCURB	ecx,PERSEG	; Ensure within current bounds
	test	AGROUP:[ecx].PERSEG_WFLAG,@NE_SEGTAB_MOVABLE ; Izit movable?
	jnz	short @F	; Jump if so

;;;;;;; UNCURB	ecx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ecx].PERSEG_CLS ; Get LA of class (PERCLS_STR)

	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)

	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #

	cmp	eax,0		; Izit invalid?
	jne	short @F	; Jump if not

	int	03h		; *FIXME* -- put in IWF action?
@@:
	cmp	al,LAST_ETYP	; Izit in the same category?
	je	short @F	; Jump if so

	mov	LAST_ETYP,al	; Save as last entry table type
	mov	ah,LAST_ECNT	; Get the count

	cmp	ah,0		; Izit the first time?
	je	short @F	; Jump if so

	mov	AGROUP:[ebp].NE_ETAB_CNT,ah ; Save in struc
	mov	AGROUP:[ebp].NE_ETAB_TYP,al ; ...

	jmp	WRITE_NE_ETAB_NEXT0 ; Go around again


@@:
	inc	LAST_ECNT	; Count in another one

; Calculate the flags which are the same for
; both movable and fixed logical segments

;;;;;;; UNCURB	ebx,EXPDEF	; Ensure within current bounds
	mov	ax,AGROUP:[ebx].EXPDEF_FLAG ; Get the flags
	and	ax,@EXPFL_CNT	; Isolate the parm count
	shr	ax,$EXPFL_CNT	; Shift to low-order
	shl	ax,$NE_ETAB_CNT ; Shift into position
	or	al,@NE_ETAB_EXP ; Mark as exported

;;;;;;; UNCURB	ecx,PERSEG	; Ensure within current bounds
	test	AGROUP:[ecx].PERSEG_WFLAG,@NE_SEGTAB_SHARE ; Izit shared?
	jz	short @F	; Jump if not

	or	al,@NE_ETAB_SHARE ; Mark as shared
@@:

; If this is a movable segment write out the struc

	cmp	LAST_ETYP,@NE_ETAB_TYP_MOVABLE ; Izit movable?
	jne	short WRITE_NE_ETAB_FIXED ; Jump if not

	mov	AGROUP:[edi].NE_ETAB_M_FLAG,al ; Save in struc

	mov	AGROUP:[edi].NE_ETAB_M_INT3F,@NE_ETAB_INT3F ; Save in struc

;;;;;;; UNCURB	ecx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ecx].PERSEG_CLS ; Get LA of class (PERCLS_STR)

	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get LA of logical segment (PERLSEG_STR)

	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #
	mov	AGROUP:[edi].NE_ETAB_M_LSEG,al ; Save in struc

	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_ADDR ; Get address+offset
	sub	eax,AGROUP:[esi].PUBDEF_BASE ; Less base
	mov	AGROUP:[edi].NE_ETAB_M_OSEG,ax ; Save in struc

	inc	MOVCNT		; Count in another movable entry point
	add	edi,type NE_ETAB_M_STR ; Skip to next entry

	jmp	short WRITE_NE_ETAB_LOOP ; Join common loop code


WRITE_NE_ETAB_FIXED:
	mov	AGROUP:[edi].NE_ETAB_F_FLAG,al ; Save in struc

	UNCURB	esi,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[esi].PUBDEF_ADDR ; Get address+offset
	sub	eax,AGROUP:[esi].PUBDEF_BASE ; Less base
	mov	AGROUP:[edi].NE_ETAB_F_OSEG,ax ; Save in struc

	add	edi,type NE_ETAB_F_STR ; Skip to next entry
WRITE_NE_ETAB_LOOP:
	add	ebx,type EXPDEF_STR ; SKip to next entry

	jmp	WRITE_NE_ETAB_NEXT ; Go around again


WRITE_NE_ETAB_DONE:
	mov	al,LAST_ETYP	; Get the type
	mov	ah,LAST_ECNT	; Get the count
	mov	AGROUP:[ebp].NE_ETAB_CNT,ah ; Save in struc
	mov	AGROUP:[ebp].NE_ETAB_TYP,al ; ...

	cmp	ah,0		; Izit empty?
	jne	short @F	; Jump if not

	sub	edi,type NE_ETAB_STR ; Skip over header
@@:
	xor	al,al		; End-of-table marker
	stos	AGROUP:[edi].LO ; Save in struc

	mov	ecx,edi 	; Copy ending address
	sub	ecx,FIRST_ETAB	; Less start to get length
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_LenETAB,cx ; Save in struc

	mov	cx,MOVCNT	; Get # movable entry points
;;;;;;; mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_MEPCNT,cx ; Save in struc

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high

	sub	edi,LaNEHDR	; Less offset of NE header
	mov	NE_HDR_OFF,edi	; Skip to next available NE header offset

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create the non-resident names table
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

COMMENT|

The nonresident-name table contains strings that identify exported functions
in the executable file.  As the name implies, these strings are not always
resident in system memory and are discardable.	The nonresident-name strings
are case-sensitive; they are not null-terminated.  The following list
summarizes the values found in the nonresident-name table (the specified
locations are relative to the beginning of each entry):

 Location  ³ Description
 ÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
  00h	   ³ Specifies the length, in bytes, of a string.  If this byte is
	   ³ 00h, there are no more strings in the table.
	   ³
 01h - xxh ³ Specifies the nonresident-name text.  This string is
	   ³ case-sensitive and is not null-terminated.
	   ³
 xx + 01h  ³ Specifies an ordinal number that is an index to the entry
	   ³ table.

The first name that appears in the nonresident-name table is the module
description string (which was specified in the module-definition file).

|

	add	edi,LaNEHDR	; Plus offset of NE header
	sub	edi,edx 	; Less start of file
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_ONRMTAB,edi ; Save in struc
	add	edi,edx 	; Plus start of file
	mov	ebp,edi 	; Copy LA of start of non-resident names table

; The first entry is the description string

	lea	esi,WIN_DESC	; DGROUP:ESI ==> source
	movzx	ecx,WIN_DESC.CC_COUNT ; Get the length byte
	add	ecx,type CC_COUNT ; Include the length byte

    rep movs	AGROUP:[edi].LO,WIN_DESC[esi] ; Copy to nonresident names table

	xor	ax,ax		; Ordinal number for description
	stos	AGROUP:[edi].ELO ; Save in res name table

; Trundle through EXPDEF_STRs looking for non-resident names

	mov	LAST_ORDNO,1	; Initialize ordinal #
	mov	ebx,LMB_EXPDEF.LMB_CURB.BOUND_BEG ; Get LA of 1st entry
WRITE_NE_NRMTAB_NEXT:
	cmp	ebx,LMB_EXPDEF.LMB_CURB.BOUND_NXT ; Izit over?
	jae	short WRITE_NE_NRMTAB_DONE ; Jump if so

	UNCURB	ebx,EXPDEF	; Ensure within current bounds
	test	AGROUP:[ebx].EXPDEF_FLAG,@EXPFL_RES ; Izit resident?
	jnz	short WRITE_NE_NRMTAB_LOOP ; Jump if so

;;;;;;; UNCURB	ebx,EXPDEF	; Ensure within current bounds
	lea	esi,AGROUP:[ebx].EXPDEF_EXPNAME ; AGROUP:ESI ==> source
;;;;;;; UNCURB	ebx,EXPDEF	; Ensure within current bounds
	movzx	ecx,AGROUP:[ebx].EXPDEF_EXPNAME.CC_COUNT ; Get the length byte
	add	ecx,type CC_COUNT ; Count in the length byte
    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to res name table

	mov	eax,LAST_ORDNO	; Copy ordinal #
	stos	AGROUP:[edi].ELO ; Save in res name table
WRITE_NE_NRMTAB_LOOP:
	inc	LAST_ORDNO	; Skip to next ordinal #
	add	ebx,type EXPDEF_STR ; Skip to next entry

	jmp	WRITE_NE_NRMTAB_NEXT ; Go around again


WRITE_NE_NRMTAB_DONE:
	mov	al,0		; Marker for end-of-table
	stos	AGROUP:[edi].LO ; Save in res name table

	mov	ecx,edi 	; Copy next available offset
	sub	ecx,ebp 	; Less start
	mov	eax,AGROUP:[edx].DOSHDR_LFANEW ; Get offset to NE header
	mov	AGROUP:[edx + eax].NE_NRMSIZ,cx ; Save in struc

; Round up to alignment units boundary

	mov	ecx,edi 	; Copy LA of next available byte
	sub	ecx,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; Less start to get length
	mov	eax,ecx 	; Copy length
	add	ecx,ALIGN_MASK	; Round up to
	and	ecx,ALIGN_COMP	; ... alignment boundary
	sub	ecx,eax 	; Less length to get pad amount
	mov	al,0		; Fill with this
    rep stos	AGROUP:[edi].LO ; Pad out to alignment unit

; Save this as highwater mark

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high

	clc			; Mark as successful

	jmp	short WRITE_NE_EXIT ; Join common exit code


WRITE_NE_OPENERR:		; *FIXME*
WRITE_NE_READERR:		; *FIXME*



WRITE_NE_ERRWRIT:
	stc			; Mark as in error
WRITE_NE_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_NE endp			; End WRITE_NE procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_NE module
