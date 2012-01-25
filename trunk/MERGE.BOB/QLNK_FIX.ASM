;' $Header:   P:/PVCS/MISC/QLINK/QLNK_FIX.ASV   1.2   07 Aug 1998 16:00:10   BOB  $
	title	QLNK_FIX -- QLINK Fixup Routines
	page	58,122
	name	QLNK_FIX

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, August, 1994.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include ALLMEM.INC
	include BITFLAGS.INC
	include OMF.INC
	include DOSCALL.INC
	include OPCODES.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	IWF_FLAG:dword
	extrn	IW2_FLAG:dword
	extrn	IW3_FLAG:dword
	include QLNK_IWF.INC

	extrn	LMB_PEROBJ:tbyte
	extrn	LMB_PERSEG:tbyte
	extrn	LMB_PERGRP:tbyte
	extrn	LMB_SYMBOL:tbyte
	extrn	LMB_PUBDEF:tbyte
	extrn	LMB_FIXUPP:tbyte
	extrn	LMB_EXEFIL:tbyte
	extrn	LMB_LINNUM:tbyte
	extrn	LaDATA:dword
	extrn	SEGFIX_NXT:dword
	extrn	SEGFIX_CNT:dword
	extrn	WRBLK_FLAG:byte
	extrn	WRBLK_START:dword
	extrn	DEF32:byte
	extrn	TXT_NONE:byte

	public	FRM_BASE
FRM_BASE dd	?		; Frame base LA used in segment fixups

	public	EXTDEF_GRP,EXTDEF_SEG
EXTDEF_GRP dd	?		; LA of PERGRP_STR for external variable (0=none)
EXTDEF_SEG dd	?		; ...	PERSEG_STR ...

	public	FIXLOC_TAB
FIXLOC_TAB dd	offset PGROUP:FIXLOC0  ;  0:  Low-order byte
	dd	offset PGROUP:FIXLOC1  ;  1:  16-bit offset
	dd	offset PGROUP:FIXLOC2  ;  2:  16-bit base segment/group
	dd	offset PGROUP:FIXLOC3  ;  3:  Ptr16:16
	dd	?		       ;  4:  High-order byte (not supported)
	dd	offset PGROUP:FIXLOC1  ;  5:  Same as 1
	dd	?		       ;  6:  (Invalid, already ruled out)
	dd	?		       ;  7:  (Invalid, already ruled out)
	dd	?		       ;  8:  (Invalid, already ruled out)
	dd	offset PGROUP:FIXLOC9  ;  9:  32-bit offset
	dd	?		       ; 10:  (Invalid, already ruled out)
	dd	offset PGROUP:FIXLOC11 ; 11:  Ptr16:32
	dd	?		       ; 12:  (Invalid, already ruled out)
	dd	offset PGROUP:FIXLOC9  ; 13:  Same as 9
;;;;;;; dd	?		       ; 14:  (Invalid, already ruled out)
;;;;;;; dd	?		       ; 15:  (Invalid, already ruled out)

	public	FIXWID_TAB
FIXWID_TAB dd	1		;  0:  Low-order byte
	dd	2		;  1:  16-bit offset
	dd	2		;  2:  16-bit base segment/group
	dd	2+2		;  3:  Ptr16:16
	dd	1		;  4:  High-order byte (not supported)
	dd	2		;  5:  Same as 1
	dd	?		;  6:  (Invalid, already ruled out)
	dd	?		;  7:  (Invalid, already ruled out)
	dd	?		;  8:  (Invalid, already ruled out)
	dd	4		;  9:  32-bit offset
	dd	?		; 10:  (Invalid, already ruled out)
	dd	4+2		; 11:  Ptr16:32
	dd	?		; 12:  (Invalid, already ruled out)
	dd	4		; 13:  Same as 9
;;;;;;; dd	?		; 14:  (Invalid, already ruled out)
;;;;;;; dd	?		; 15:  (Invalid, already ruled out)

	public	WIDOVF
WIDOVF	dd	?		; Offset in DGROUP of fixup overflow width text

	public	FIX_FT_TABMSG
FIX_FT_TABMSG label dword
	dd	offset DGROUP:MSG_FT00 ; FT00 -- 00
	dd	offset DGROUP:MSG_FT01 ; FT01 -- 01
	dd	offset DGROUP:MSG_FT02 ; FT02 -- 02
	dd	?		       ; FT03 -- 03
	dd	offset DGROUP:MSG_FT10 ; FT10 -- 04
	dd	offset DGROUP:MSG_FT11 ; FT11 -- 05
	dd	offset DGROUP:MSG_FT12 ; FT12 -- 06
	dd	?		       ; FT13 -- 07
	dd	offset DGROUP:MSG_FT20 ; FT20 -- 08
	dd	offset DGROUP:MSG_FT21 ; FT21 -- 09
	dd	offset DGROUP:MSG_FT22 ; FT22 -- 0A
	dd	?		       ; FT23 -- 0B
	dd	?		       ; FT30 -- 0C -- already ruled out
	dd	?		       ; FT31 -- 0D -- already ruled out
	dd	?		       ; FT32 -- 0E -- already ruled out
	dd	?		       ; FT33 -- 0F -- already ruled out
	dd	offset DGROUP:MSG_FT40 ; FT40 -- 10
	dd	offset DGROUP:MSG_FT41 ; FT41 -- 11
	dd	offset DGROUP:MSG_FT42 ; FT42 -- 12
	dd	?		       ; FT43 -- 13
	dd	offset DGROUP:MSG_FT50 ; FT50 -- 14
	dd	offset DGROUP:MSG_FT51 ; FT51 -- 15
	dd	offset DGROUP:MSG_FT52 ; FT52 -- 16
	dd	?		       ; FT53 -- 17


FIX_FT_MAC macro FNUM,PREF

ifnb <FNUM>
	dd	offset PGROUP:&PREF&_FT&FNUM&0 ; F? vs. T0 (SEGDEF)
	dd	offset PGROUP:&PREF&_FT&FNUM&1 ; F? vs. T1 (GRPDEF)
	dd	offset PGROUP:&PREF&_FT&FNUM&2 ; F? vs. T2 (EXTDEF)
	dd	?			       ; F? vs. T3 (invalid)
else
	dd	4 dup (?)	; Invalid
endif				; IFNB <FNUM>

	endm			; FIX_FT_MAC

	public	FIX_FT_TAB
FIX_FT_TAB label dword		; Table for Frame (by rows) vs. Target (by cols)
	FIX_FT_MAC 0,FIX	; F0:  SEGDEF index
	FIX_FT_MAC 1,FIX	; F1:  GRPDEF ...
	FIX_FT_MAC 2,FIX	; F2:  EXTDEF ...
	FIX_FT_MAC		; F3:  (Invalid, already ruled out)
	FIX_FT_MAC 0,FIX	; F4:  segment of LAST_DATREC (same as 0)
	FIX_FT_MAC 5,FIX	; F5:  target's index
;;;;;;; FIX_FT_MAC 6,FIX	; F6:  (Invalid, already ruled out)
;;;;;;; FIX_FT_MAC 7,FIX	; F7:  (Invalid, already ruled out)

	public	FIXOVF_FT_TAB
FIXOVF_FT_TAB label dword	; Table for Frame (by rows) vs. Target (by cols)
	FIX_FT_MAC 0,FIXOVF	; F0:  SEGDEF index
	FIX_FT_MAC 1,FIXOVF	; F1:  GRPDEF ...
	FIX_FT_MAC 2,FIXOVF	; F2:  EXTDEF ...
	FIX_FT_MAC		; F3:  (Invalid, already ruled out)
	FIX_FT_MAC 0,FIXOVF	; F4:  segment of LAST_DATREC (same as 0)
	FIX_FT_MAC 5,FIXOVF	; F5:  target's index
;;;;;;; FIX_FT_MAC 6,FIXOVF	; F6:  (Invalid, already ruled out)
;;;;;;; FIX_FT_MAC 7,FIXOVF	; F7:  (Invalid, already ruled out)

	public	LINNUM_SIZ
LINNUM_SIZ dd	type LINNUM_STR ; Divisor used in DISP_LINNUM

	public	LAST_OLDLEN
LAST_OLDLEN dd	?		; Last FIXUPP_OLDLEN

	public	MSG_FT00,MSG_FT01,MSG_FT02
MSG_FT00 db	'FT00',CR,LF,EOS
MSG_FT01 db	'FT01',CR,LF,EOS
MSG_FT02 db	'FT02',CR,LF,EOS
	public	MSG_FT10,MSG_FT11,MSG_FT12
MSG_FT10 db	'FT10',CR,LF,EOS
MSG_FT11 db	'FT11',CR,LF,EOS
MSG_FT12 db	'FT12',CR,LF,EOS
	public	MSG_FT20,MSG_FT21,MSG_FT22
MSG_FT20 db	'FT20',CR,LF,EOS
MSG_FT21 db	'FT21',CR,LF,EOS
MSG_FT22 db	'FT22',CR,LF,EOS
	public	MSG_FT40,MSG_FT41,MSG_FT42
MSG_FT40 db	'FT40',CR,LF,EOS
MSG_FT41 db	'FT41',CR,LF,EOS
MSG_FT42 db	'FT42',CR,LF,EOS
	public	MSG_FT50,MSG_FT51,MSG_FT52
MSG_FT50 db	'FT50',CR,LF,EOS
MSG_FT51 db	'FT51',CR,LF,EOS
MSG_FT52 db	'FT52',CR,LF,EOS

	public	MSG_BYTE,MSG_WORD
MSG_BYTE db	'byte',EOS
MSG_WORD db	'word',EOS

	public	MSG_FIXOVF,MSG_ABSOVF
MSG_FIXOVF  db	'(FIXOVF) Fixup overflow of ',EOS
MSG_ABSOVF  db	'(ABSOVF) Absolute constant fixup overflow of ',EOS
MSG_FIXOVF1 db	'________ at ',EOS
MSG_FIXOVF2 db	' offset',CR,LF,@I
MSG_FIXOVF3 db	'________ in segment ',@LQ,EOS

	public	MSG_RQEND
MSG_RQEND db	@RQ,CR,LF,EOS

MSG_FIXOVF_FRM db @I,'Frame ',EOS
MSG_FIXOVF_TGT db @I,'Target ',EOS
MSG_FIXOVF_SEG db 'segment ',@LQ,EOS
MSG_FIXOVF_GRP db 'group ',@LQ,EOS
MSG_FIXOVF_EXT db 'external ',@LQ,EOS
MSG_FIXOVF_PUB db @I,'Symbol declared public in ',EOS
MSG_FIXOVF_OFF db @I,'Target offset '
MSG_FIXOVF_OFF1 db '________',CR,LF,EOS
MSG_FIXOVF_OBJ db @I,'from FIXUPP record in file ',EOS
MSG_FIXOVF_FIXSEG db @I,'Fixup segment ',@LQ,EOS

	public	MSG_GRPEXT,MSG_GRPEXT0
MSG_GRPEXT db	'(GRPEXT) A FIXUPP record has an external target in a different',CR,LF
	   db	@I,'group than the frame group.',CR,LF,EOS
MSG_GRPEXT0 db	'(GRPEXT0) A FIXUPP record has an external target not in a group',CR,LF
	   db	@I,'whereas the frame is a group.',CR,LF,EOS

	public	MSG_SEGEXT,MSG_SEGEXT0
MSG_SEGEXT db	'(SEGEXT) A FIXUPP record has an external target in a different',CR,LF
	   db	@I,'segment than the frame segment.',CR,LF,EOS
MSG_SEGEXT0 db	'(SEGEXT0) A FIXUPP record has an external target not in a segment',CR,LF
	   db	@I,'whereas the frame is a segment.',CR,LF,EOS

	public	MSG_RELSEG
MSG_RELSEG db	'(RELSEG) A self-relative FIXUPP record has a frame segment which',CR,LF
	   db	@I,'is not the same as the fixup segment.',CR,LF,EOS
	public	MSG_RELGRP
MSG_RELGRP db	'(RELGRP) A self-relative FIXUPP record has a frame group which',CR,LF
	   db	@I,'does not contain the fixup segment.',CR,LF,EOS

	public	MSG_RELSEGX
MSG_RELSEGX db	'(RELSEGX) A self-relative FIXUPP record has a external frame segment',CR,LF
	   db	@I,'which is not the same as the fixup segment.',CR,LF,EOS
	public	MSG_RELGRPX
MSG_RELGRPX db	'(RELGRPX) A self-relative FIXUPP record has a external frame group',CR,LF
	   db	@I,'which does not contain the fixup segment.',CR,LF,EOS

	public	MSG_FIXOVF_INSEG,MSG_FIXOVF_INGRP
MSG_FIXOVF_INSEG db @RQ,' in seg ',@LQ,EOS
MSG_FIXOVF_INGRP db @RQ,' in grp ',@LQ,EOS

	public	MSG_FIXDIF
MSG_FIXDIF  db	'(FIXDIF) The ',EOS
MSG_FIXDIF1 db	'segment ',@LQ,EOS
MSG_FIXDIF2 db	@RQ,' is not contained',CR,LF,@I,'in the ',EOS
MSG_FIXDIF3 db	'group ',@LQ,EOS
MSG_FIXDIF4 db	@RQ,CR,LF,EOS

	public	MSG_FIXDIFX
MSG_FIXDIFX  db '(FIXDIFX) The ',EOS
MSG_FIXDIFX1 db 'segment ',@LQ,EOS
MSG_FIXDIFX2 db @RQ,' is not contained in any group,',CR,LF
	     db @I,'but there''s a ',EOS
MSG_FIXDIFX3 db 'group',CR,LF,EOS

	public	MSG_FRMSEG
MSG_FRMSEG db	'(FRMSEG) The Frame base of a FIXUPP record is the segment ',@LQ,EOS
MSG_FRMSEG1 db	@RQ,CR,LF,@I,'but perhaps should be the group ',@LQ,EOS
MSG_FRMSEG2 db	@RQ,' which contains that segment.',CR,LF,EOS

	public	MSG_FRMSEG0
MSG_FRMSEG0 db	'(FRMSEG0) The Frame base of a FIXUPP record is the segment ',@LQ,EOS
MSG_FRMSEG01 db @RQ,CR,LF,@I,'but perhaps should be the group ',@LQ,EOS
MSG_FRMSEG02 db @RQ,' which contains that segment,',CR,LF
	     db @I,'although the segment is the first one in the group.',CR,LF,EOS

	public	MSG_LINNUM
MSG_LINNUM db	@I,'at source code line # '
MSG_LINNUM1 db	'_    ',CR,LF,EOS

	public	MSG_LINNUM_NONE
MSG_LINNUM_NONE db @I,'No source code line #s available for this segment.',CR,LF,EOS

DATA	ends			; End DATA segment


CODE	segment use32 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	U32_DISP_MSG:near
	extrn	DD2HEX:near
	extrn	DD2DEC:near
	extrn	DISP_CNTCHR:near
	extrn	DISP_THEADR:near
	extrn	U32_NEWLINE:near
	extrn	IWF_TEST:near
	extrn	WRITE_BLK:near
	extrn	CB_TERM:near

	NPPROC	PROC_FIXUP -- Process Fixups
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process fixups

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	mov	edi,LMB_FIXUPP.LMB_CURB.BOUND_BEG ; Get starting address
PROC_FIXUP_NEXT:
	cmp	edi,LMB_FIXUPP.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr PROC_FIXUP_EXIT ; Jump if so (note CF=0)

	btr	LCL_FLAG,$LCL_BRK ; Izit break time?
	jc	near ptr CB_TERM ; Jump if so

; Save FIXUPP_OLDLEN for line number calcuations as we modify it
; for self-relative fixups

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_OLDLEN ; Get the old length
	mov	LAST_OLDLEN,eax ; Save for later use

; Process the Frame vs. target fields

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	movzx	eax,AGROUP:[edi].FIXUPP_FIXDAT ; Get the FIXDAT byte
	mov	ebx,eax 	; Save for later use

; Note that threads have been resolved in OMF_FIXUPP

	and	eax,@FIXDAT_FRM ; Isolate the frame method
	shr	eax,$FIXDAT_FRM ; Shift to low-order
	shl	eax,width $FIXDAT_TGT ; Shift over

	and	ebx,@FIXDAT_TGT ; Isolate the target method
	shr	ebx,$FIXDAT_TGT ; Shift to low-order
	add	eax,ebx 	; Add to get FIX_FT_TAB index

; Display the type of fixup

	test	ARG_FLAG,@ARG_DBGMSG ; Are we displaying debugging messages?
	jz	short @F	; Jump if not

	mov	edx,FIX_FT_TABMSG[eax*(type FIX_FT_TABMSG)]
	add	edx,LaDATA	; Add to get linear address
	push	eax		; Save for a moment
	DOSCALL @STROUT 	; Display it
	pop	eax		; Restore
@@:
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	edx,AGROUP:[edi].FIXUPP_DRO_CUR ; Get LA of the DRO fixup

; Check for Far Call Translation
; Note that this check must be made before calling the FIX_FTnn
; routine because if FCT is in effect, we need to change the fixup
; to self-relative and the FIX_FTnn routine is sensitive to that state.

	call	CheckFCT	; Is FCT in effect?
	jc	short @F	; Jump if not

; Mark as self-relative

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	and	AGROUP:[edi].FIXUPP_LOCAT,not @LOCAT_M ; Mark as self-relative(0)
	or	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_FCT ; Mark as present
@@:
	call	FIX_FT_TAB[eax*(type FIX_FT_TAB)] ; Call to action
	jc	near ptr PROC_FIXUP_EXIT ; Jump if it's fatal
				; Return with EBX = fixup value

; Calculate LOCAT.LOC value for self-relative fixups and later processing

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	movzx	ecx,AGROUP:[edi].FIXUPP_LOCAT ; Get the LOCAT word
	and	ecx,@LOCAT_LOC	; Isolate the location bits
	shr	ecx,$LOCAT_LOC	; Shift to low-order

; Handle self-relative fixups

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	short PROC_FIXUP_SEGREL ; Jump if so

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	ebx,AGROUP:[edi].FIXUPP_DRO_BEG ; Plus LA of the DRO start
	sub	ebx,AGROUP:[edi].FIXUPP_DRO_CUR ; Less LA of the DRO current
	sub	ebx,AGROUP:[edi].FIXUPP_OFF ; Less offset of DRO
	sub	ebx,AGROUP:[edi].FIXUPP_OLDLEN ; Less length before appending
				; this segment
	sub	ebx,FIXWID_TAB[ecx*(type FIXWID_TAB)] ; Less the location width
PROC_FIXUP_SEGREL:

; Process the LOCAT.LOC field

	call	FIXLOC_TAB[ecx*(type FIXLOC_TAB)] ; Call to location action
				; Clobbering EAX, EBX and ECX
	jc	short PROC_FIXUP_EXIT ; Jump if it's fatal

	add	edi,type FIXUPP_STR ; Skip to next entry

	jmp	PROC_FIXUP_NEXT ; Go around again

PROC_FIXUP_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_FIXUP endp 		; End PROC_FIXUP procedure
	NPPROC	FIXLOC0 -- Fixup Location #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup location #0 - low-order byte

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

On exit:

EAX	=	clobbered
EBX	=	clobbered
CF	=	0 if successful
	=	1 if not

|

; Check for fixup overflow

	cmp	ebx,0FFh	; Izit bigger than a byte?
	jbe	short FIXLOC0_DONE ; Jump if not

; If this is a self-relative fixup, allow the value if its negative
; is in range of a byte (i.e., all the upper bits above the byte are set).

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	short @F	; Jump if so

	cmp	ebx,0FFFFFF00h	; Izit bigger than a byte?
	jae	short FIXLOC0_DONE ; Jump if not
@@:
	mov	WIDOVF,offset DGROUP:MSG_BYTE ; Mark as byte overflow

	push	dword ptr (offset PGROUP:IWF_FIXOVF) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_FIXOVF	; Pass offset of bit mask
	call	IWF_TEST	; Test for fixup overflow
	jc	short FIXLOC0_EXIT ; Jump if it's fatal (note CF=1)
FIXLOC0_DONE:
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	ebx,AGROUP:[edi].FIXUPP_DSP ; Plus the Target Displacement

; Perform the offset fixup to the low-order byte

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	add	AGROUP:[edx].LO,bl ; Fixup the location

	clc			; Mark as successful
FIXLOC0_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXLOC0 endp			; End FIXLOC0 procedure
	NPPROC	FIXLOC1 -- Fixup Location #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup location #1 - 16-bit offset

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

On exit:

EAX	=	clobbered
EBX	=	clobbered
CF	=	0 if successful
	=	1 if not

|

; Check for fixup overflow

	cmp	ebx,0FFFFh	; Izit bigger than a word?
	jbe	short FIXLOC1_DONE ; Jump if not

; If this is a self-relative fixup, allow the value if its negative
; is in range of a word (i.e., all the upper bits above the word are set).

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	short @F	; Jump if so

	cmp	ebx,0FFFF0000h	; Izit bigger than a word?
	jae	short FIXLOC1_DONE ; Jump if not
@@:
	mov	WIDOVF,offset DGROUP:MSG_WORD ; Mark as word overflow

; If this symbol is an absolute constant, use a separate
; message as MASM doesn't create correct .OBJ files for such fixups
; if they exceed the width when, in fact, the fixup should be to
; a dword, not a word.

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_ABS ; Izit an absolute constant?
	jnz	short FIXLOC1_ABS ; Jump if so

	push	dword ptr (offset PGROUP:IWF_FIXOVF) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_FIXOVF	; Pass offset of bit mask
	call	IWF_TEST	; Test for large segments
	jc	short FIXLOC1_EXIT ; Jump if it's fatal (note CF=1)

	jmp	short FIXLOC1_DONE ; Join common done code


FIXLOC1_ABS:
	push	dword ptr (offset PGROUP:IWF_ABSOVF) ; Pass offset of action routine
	push	IWF_FLAG	; Pass value of flags
	push	$IWF_ABSOVF	; Pass offset of bit mask
	call	IWF_TEST	; Test for large segments
	jc	short FIXLOC1_EXIT ; Jump if it's fatal (note CF=1)

	call	FIXLOC9 	; Check for 32-bit fixup overflow
				; Clobbering EAX & EBX
				; Return with CF significant
	jmp	short FIXLOC1_EXIT ; Join common exit code


FIXLOC1_DONE:
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	ebx,AGROUP:[edi].FIXUPP_DSP ; Plus the Target Displacement

; Perform the offset fixup to the low-order word

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	add	AGROUP:[edx].ELO,bx ; Fixup the location
FIXLOC1_CLC:
	clc			; Mark as successful
FIXLOC1_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXLOC1 endp			; End FIXLOC1 procedure
	NPPROC	FIXLOC2 -- Fixup Location #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup location #2 - 16-bit base segment/group

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

On exit:

EAX	=	clobbered
ECX	=	clobbered
CF	=	0 if successful
	=	1 if not

|

; Note that for base fixups, the target offset (in EBX) is discarded as
; we're interested in its base only.

	mov	ecx,FRM_BASE	; Get the Frame base
	shr	ecx,4-0 	; Convert from bytes to paras

; For 16-bit base segment/group fixups, the target displacement field
; applies to the segment, so we add it in here.

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	ecx,AGROUP:[edi].FIXUPP_DSP ; Plus the Target Displacement

; Perform the segment fixup

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	mov	eax,0		; Skip to segment location
	add	AGROUP:[edx+eax].ELO,cx ; Fixup the segment location

; Append this address to the segment fixup table

	call	APP_SEGFIX	; Append EAX = additional fixup
				;	 EDI = LA of FIXUPP_STR
				; Return with CF significant
FIXLOC2_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXLOC2 endp			; End FIXLOC2 procedure
	NPPROC	FIXLOC3 -- Fixup Location #3
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup location #3 - Ptr16:16

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

On exit:

EAX	=	clobbered
EBX	=	clobbered
ECX	=	clobbered
CF	=	0 if successful
	=	1 if not

|

	call	FIXLOC1 	; Check for 16-bit fixup overflow
				; Clobbering EAX & EBX
	jc	short FIXLOC3_EXIT ; Jump if it's fatal (note CF=1)

	mov	ecx,FRM_BASE	; Get the Frame base
	shr	ecx,4-0 	; Convert from bytes to paras

; For Ptr16:16 fixups, the target displacement field applies to the
; offset, so we do not add it in here.

; Perform the segment fixup

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG,eax	; Ensure within current bounds

; Check for Far Call Translations

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_FCT ; Izit a FCT?
	jnz	short FIXLOC3_FCT ; Jump if so

;;;;;;; UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	mov	eax,2		; Skip to segment location
	add	AGROUP:[edx+eax].ELO,cx ; Fixup the segment location

; Append this address to the segment fixup table

	call	APP_SEGFIX	; Append EAX = additional fixup
				;	 EDI = LA of FIXUPP_STR
				; Return with CF significant
	jmp	short FIXLOC3_EXIT ; Join comon exit code

; Change the code to a near call

FIXLOC3_FCT:
;;;;;;; UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	mov	AGROUP:[edx-1].LO,@OPCOD_NOP
	mov	ebx,@OPCOD_PUSHCS or (@OPCOD_CALLN shl 8)
	xchg	bx,AGROUP:[edx] ; Swap with offset value
	mov	AGROUP:[edx+2],bx ; Save offset value

	clc			; Mark as successful
FIXLOC3_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXLOC3 endp			; End FIXLOC3 procedure
	NPPROC	FIXLOC9 -- Fixup Location #9
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup location #9 - 32-bit offset

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

On exit:

EAX	=	clobbered
EBX	=	clobbered
CF	=	0 if successful
	=	1 if not

|

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	ebx,AGROUP:[edi].FIXUPP_DSP ; Plus the Target Displacement

; Perform the offset fixup to the dword

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	add	AGROUP:[edx].EDD,ebx ; Fixup the location

	clc			; Mark as successful

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXLOC9 endp			; End FIXLOC9 procedure
	NPPROC	FIXLOC11 -- Fixup Location #11
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup location #11 - Ptr16:32

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

On exit:

EAX	=	clobbered
EBX	=	clobbered
ECX	=	clobbered
CF	=	0 if successful
	=	1 if not

|

	call	FIXLOC9 	; Check for 32-bit fixup overflow
				; Clobbering EAX & EBX
	jc	short FIXLOC11_EXIT ; Jump if it's fatal (note CF=1)

	mov	ecx,FRM_BASE	; Get the Frame base
	shr	ecx,4-0 	; Convert from bytes to paras

; For Ptr16:32 fixups, the target displacement field applies to the
; offset, so we do not add it in here.

; Perform the segment fixup

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG,eax	; Ensure within current bounds

; Check for Far Call Translations

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_FCT ; Izit a FCT?
	jnz	short FIXLOC11_FCT ; Jump if so

;;;;;;; UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	mov	eax,4		; Skip to segment location
	add	AGROUP:[edx+eax].ELO,cx ; Fixup the segment location

; Append this address to the segment fixup table

	call	APP_SEGFIX	; Append EAX = additional fixup
				;	 EDI = LA of FIXUPP_STR
				; Return with CF significant
	jmp	short FIXLOC11_EXIT ; Join comon exit code

; Change the code to a near call

FIXLOC11_FCT:
;;;;;;; UNCURB	edx,PERSEG,eax	; Ensure within current bounds
	mov	AGROUP:[edx-1].LO,@OPCOD_NOP
	mov	ebx,@OPCOD_PUSHCS or (@OPCOD_CALLN shl 8)
	xchg	ebx,AGROUP:[edx] ; Swap with offset value
	mov	AGROUP:[edx+2],ebx ; Save offset value

	clc			; Mark as successful
FIXLOC11_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXLOC11 endp			; End FIXLOC11 procedure
	NPPROC	APP_SEGFIX -- Append Address To Segment Fixup table
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Append an address to the segment fixup table

On entry:

EAX	=	additional offset to segment fixup
EDI	=	LA of FIXUPP_STR entry

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_MOD ; Is this a MODEND fixup?
	jnz	near ptr APP_SEGFIX_EXIT ; Jump if so (note CF=0)

; If this is a skippable segment (e.g. $$SYMBOLS, $$TYPES, or _end/_edata seg)
; don't bother appending a segment fixup record to the .EXE header

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	edx,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

	UNCURB	edx,PERSEG	; Ensure within current bounds
	test	AGROUP:[edx].PERSEG_FLAG,@PERSEG_SKIP ; Izit skippable?
	jnz	near ptr APP_SEGFIX_EXIT ; Jump if so (note CF=0)

; If the target is an absolute segment or a group whose first segment is
; an absolute segment, then there's no .EXE header segment fixup

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	cl,AGROUP:[edi].FIXUPP_FIXDAT ; Get the FIXDAT byte
	and	cl,@FIXDAT_TGT	; Isolate Target bits
	shr	cl,$FIXDAT_TGT	; Shift to low-order

	cmp	cl,@FIXDAT_FT_SEG ; Izit a segment?
	je	short APP_SEGFIX1 ; Jump if so

	cmp	cl,@FIXDAT_FT_GRP ; Izit a group?
	jne	short APP_SEGFIX_DOIT ; Jump if not

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	ecx,AGROUP:[edi].FIXUPP_TGT ; Get the LA of this segment PERGRP_STR

	UNCURB	ecx,PERGRP	; Ensure within current bounds
	mov	ecx,AGROUP:[ecx].PERGRP_GRPLNK ; Get LA of next PERSEG_STR entry

	and	ecx,ecx 	; Izit valid?
	jz	short APP_SEGFIX_DOIT ; Jump if so (just do it)

	jmp	short APP_SEGFIX2 ; Join common code

APP_SEGFIX1:
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	ecx,AGROUP:[edi].FIXUPP_TGT ; Get the LA of this segment PERSEG_STR
APP_SEGFIX2:
	UNCURB	ecx,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[ecx].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)

	UNCURB	ecx,SYMBOL	; Ensure within current bounds
	mov	cl,AGROUP:[ecx].SYM_FLAG.LO ; Get the ACBP byte

	and	cl,@SYMFL_A	; Isolate the alignment bits
	shr	cl,$SYMFL_A	; Shift to low-order

	cmp	cl,@ACBP_A_ABS	; Izit an absolute segment?
	je	short APP_SEGFIX_EXIT ; Jump if so (note CF=0)
APP_SEGFIX_DOIT:
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	AGROUP:[edi].FIXUPP_DRO_CUR,eax ; Include in current offset

; Check for segment fixups inside LIDATA records

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_LID ; Izit an LIDATA record?
	jz	short APP_SEGFIX_DOIT1 ; Jump if not

; Trundle through the LIDATA record, spitting out a segment fixup for each
; entry which matches the address in FIXUPP_DRO_CUR.

; Setup DEF32 for WRITE_BLK to test

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_32 ; Izit a 32-bit record?
	setnz	DEF32		; DEF32 = 1 iff 32-bit record

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	esi,AGROUP:[edi].FIXUPP_DRO_BEG ; Get start of LIDATA record
;;;;;;; mov	edx,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	mov	eax,AGROUP:[esi-(type DATREC_STR)].DATREC_LEN ; Get length
	add	eax,esi 	; Add to current offset to get ending offset

	mov	WRBLK_FLAG,0	; Mark as writing out segment fixups
	mov	WRBLK_START,0	; Initialize starting address
APP_SEGFIX_LIDATA_NEXT:
	call	WRITE_BLK	; Write out an LIDATA block record segment fixup
				; Return ESI as new offset
	cmp	eax,esi 	; Are we at the end?
	jne	short APP_SEGFIX_LIDATA_NEXT ; Jump if not

	jmp	short APP_SEGFIX_CLC ; Join common code

APP_SEGFIX_DOIT1:
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_DRO_CUR ; Plus LA of the DRO current
	sub	eax,AGROUP:[edi].FIXUPP_DRO_BEG ; Less LA of the DRO start
APP_SEGFIX_DOIT2:
	call	APP_SEGFIX_COM	; Write out the segment fixup using EAX
APP_SEGFIX_CLC:
	clc			; Mark as successful
APP_SEGFIX_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APP_SEGFIX endp 		; End APP_SEGFIX procedure
	NPPROC	APP_SEGFIX_COM -- Subroutine to APP_SEGFIX
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Apply the fixups

On entry:

EAX	=	offset into LEDATA/LEDATA record
EDI	=	LA of FIXUPP_STR entry

|

	REGSAVE <eax,edx>	; Save registers

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	eax,AGROUP:[edi].FIXUPP_OFF ; Plus offset of DRO
	add	eax,AGROUP:[edi].FIXUPP_OLDLEN ; Plus length before appending
				; this segment
	cmp	eax,@CON64KB	; Izit beyond a 16-bit offset?
	jb	short @F	; Jump if not

	rol	eax,16		; Swap high- and low-order words
	shl	ax,16-4 	; Convert from 64KB to paras
	ror	eax,16		; Swap back
@@:
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	edx,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	edx,AGROUP:[edx].PERSEG_ADRB.BOUND_BEG ; Get start of this segment
	shl	edx,16-4	; Shift to high-order word *FIXME* (overflow>1MB)
				; Converting from bytes to paras
	shr	dx,16-4 	; Shift low-order nibble back
	add	eax,edx 	; Add to get Seg:Off

	mov	edx,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	add	edx,SEGFIX_NXT	; Plus offset to next available location

	UNOVRB	edx,EXEFIL	; Ensure within overall bounds
	mov	AGROUP:[edx].EDD,eax ; Save in segment fixup table

	inc	SEGFIX_CNT	; Count in another segment fixup

	add	SEGFIX_NXT,4	; Skip over the segment fixup

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APP_SEGFIX_COM endp		; End APP_SEGFIX_COM procedure
	NPPROC	CheckFCT -- Check For far Call Translation
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check for Far Call Translation

We substitute a near call for a far call immediate if

1.  /FARCALL is specified.
2.  The opcode is a far Call Immediate.
3.  The fixup segment's class ends with 'CODE'..
4.  The fixup segment is the same as the frame segment, or
    the fixup group   is the same as the frame group.
5.  The fixup is for a Ptr16:16 or Ptr16:32.

On entry:

EDI	=	LA of FIXUPP_STR entry
EDX	=	LA of fixup location

On exit:

CF	=	0 if Far Call Translation
	=	1 if not

|

	REGSAVE <ebx>		; Save register

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

	test	ARG_FLAG,@ARG_FCT ; Doing Far Call Translation?
	jz	short CheckFCTNo ; Jump if not

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_MOD ; Is this a MODEND fixup?
	jnz	short CheckFCTNo ; Jump if so

; Check for Far Call Immediate opcode

	UNCURB	edx,PERSEG,ebx	; Ensure within current bounds
	cmp	AGROUP:[edx-1].LO,@OPCOD_CALLF ; Izit a far call?
	jne	short CheckFCTNo ; Jump if not

; Check for class name ending in 'CODE'

	UNCURB	ebx,PERSEG     ; Ensure within current bounds
	test	AGROUP:[ebx].PERSEG_FLAG,@PERSEG_SUFCODE ; Izit a 'CODE' segment?
	jz	short CheckFCTNo ; Jump if not

; Check for the fixup and frame segments or groups are the same

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	ebx,AGROUP:[edi].FIXUPP_FRM ; Izit the same?
	je	short CheckFCT1 ; Jump if so
	
; If the fixup segment is in a group, check that against the
; target	

;;;;;;; UNCURB	ebx,PERSEG     ; Ensure within current bounds
	cmp	AGROUP:[ebx].PERSEG_GRPSYM,0 ; Izit ungrouped?
	je	short CheckFCTNo ; Jump if so
	
;;;;;;; UNCURB	ebx,PERSEG     ; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].PERSEG_GRPSYM ; Get the group's SYM_STR
	UNCURB	ebx,SYMBOL     ; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].SYM_PERITEM ; Get the group's PERGRP_STR
	
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	ebx,AGROUP:[edi].FIXUPP_FRM ; Izit the same?
	jne	short CheckFCTNo ; Jump if not
CheckFCT1:

; Ensure it's a Ptr16:16 or Ptr16:32 location

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	bx,AGROUP:[edi].FIXUPP_LOCAT ; Get LOCAT byte
	and	ebx,mask $LOCAT_LOC ; Isolate the location field

	cmp	ebx,@LOCAT_LOC_VEC shl $LOCAT_LOC ; Izit Ptr16:16?
	je	short CheckFCTYes ; Jump if so

	cmp	ebx,@LOCAT_LOC_FVEC shl $LOCAT_LOC ; Izit Ptr16:32?
	jne	short CheckFCTNo ; Jump if not
CheckFCTYes:
	clc			; Mark as FCT
	
	jmp	short CheckFCTExit ; Join common exit code

CheckFCTNo:
	stc			; Mark as not FCT
CheckFCTExit:
	REGREST <ebx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckFCT	endp		; End CheckFCT procedure
	NPPROC	CompareSegNames -- Compare Segment Names
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Compare segment names

On exit:

ZF	=	1 if segment names are equal
	=	0 if not

|

CSN_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CSN_SEG2 dd	?		; LA of 2nd PERSEG_STR
CSN_SEG1 dd	?		; ...	1st ...

CSN_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	mov	esi,[ebp].CSN_SEG1 ; Get LA of 1st PERSEG_STR
	UNCURB	esi,PERSEG	; Ensure within current bounds
	mov	esi,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	esi,SYMBOL     ; Ensure within current bounds
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of symbol (Cnt, Char[])

	mov	edi,[ebp].CSN_SEG1 ; Get LA of 2nd PERSEG_STR
	UNCURB	edi,PERSEG	; Ensure within current bounds
	mov	edi,AGROUP:[edi].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	edi,SYMBOL     ; Ensure within current bounds
	mov	edi,AGROUP:[edi].SYM_PNAM ; Get LA of symbol (Cnt, Char[])

	movzx	ecx,AGROUP:[esi] ; Get length of 1st symbol

	cmp	cl,AGROUP:[edi] ; Same length?
	jne	short CompareSegNamesExit ; Jump if not (note ZF=0)
@@:
   repe cmps	AGROUP:[edi].LO,AGROUP:[esi].LO ; Compare the rest
	je	short CompareSegNamesExit ; Jump if the same (note ZF=1)

; Handle case differences

	mov	al,AGROUP:[edi-1] ; Get last mismatch
	mov	ah,AGROUP:[esi-1] ; ...

	or	ax,2020h	; Convert to lowercase

	cmp	al,ah		; Compare 'em
	je	short @B	; Jump if the same (note ZF=1 in case ECX=0)
CompareSegNamesExit:
	REGREST <edi,esi,ecx,eax> ; Restore

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CompareSegNames endp		; End CompareSegNames procedure
	NPPROC	FIX_FT00 -- Fixup Frame Method #0 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #0 (SEGDEF)
  vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Frame address
; In case this segment doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; For self-relative fixups, the Frame segment must equal
; the Fixup segment, or we complain.

	call	CHECK_FRMFIX_SEG ; Ensure they're the same
	jc	short FIX_FT00_EXIT ; Join common exit code (note CF=1)

; If the Frame segment is in a group, this is likely an error
; which we complain about.

	call	CHECK_FRM_GRP	; Complain if Frame seg is in a group
				; Return with CF significant
FIX_FT00_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT00 endp			; End FIX_FT00 procedure
	NPPROC	FIX_FT01 -- Fixup Frame Method #0 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #0 (SEGDEF)
  vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Frame address
; In case this segment doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; Ensure that the Target group contains the Frame segment

	push	offset DGROUP:MSG_FIXOVF_TGT ; Pass offset in DGROUP of reference
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	push	offset DGROUP:MSG_FIXOVF_FRM ; Pass offset in DGROUP of reference
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	CHECK_FIXDIF	; Ensure Group contains Segment
				; Return with CF significant
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT01 endp			; End FIX_FT01 procedure
	NPPROC	FIX_FT02 -- Fixup Frame Method #0 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #0 (SEGDEF)
  vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PUBDEF_ADDR ; Get the entire address for Target

; Perhaps the external target is an absolute symbol
; in which case we don't care about groups and segments

	mov	eax,AGROUP:[edi].FIXUPP_TGT ; Get LA of SYM_STR for Target

	UNCURB	eax,SYMBOL     ; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_ABSCON ; Izit a constant?
	jnz	near ptr FIX_FT02_EXIT ; Jump if so (note CF=0)

; Calculate starting address of the Frame using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Frame address
; In case this segment doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; For self-relative fixups, the Frame segment must equal
; the Fixup segment, or we complain.

	call	CHECK_FRMFIX_SEG ; Ensure they're the same
	jc	short FIX_FT02_EXIT ; Join common exit code (note CF=1)

; If the Frame segment is in a group, this is likely an error
; which we complain about.

	call	CHECK_FRM_GRP	; Complain if Frame seg is in a group
	jc	short FIX_FT02_EXIT ; Join common exit code (note CF=1)

; Ensure that the Frame segment contains the Target external
; The call to FIX_EXTDEF sets the variable EXTDEF_SEG with the
; LA of the corresponding target segment (or 0 if unsegmented).

	mov	eax,EXTDEF_SEG	; Get LA of PERSEG_STR for external Target

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].FIXUPP_FRM ; Izit the same segment?
	je	short FIX_FT02_EXIT ; Jump if so (note CF=0)

; If the segment names are the same, consider them equal as this could be
; two segments one or both of which are not marked as public

	push	eax		; Pass LA of 1st PERSEG_STR
	push	AGROUP:[edi].FIXUPP_FRM ; ... 2nd ...
	call	CompareSegNames ; Compare 'em
	je	short FIX_FT02_EXIT ; Jump if they're the same

	cmp	eax,0		; Is the external target in a segment?
	je	short FIX_FT02A ; Jump if not

	push	dword ptr (offset PGROUP:IWF_SEGEXT) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_SEGEXT	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame seg, target ext mismatch
				; Return with CF significant
	jmp	short FIX_FT02_EXIT ; Join common exit code


FIX_FT02A:
	push	dword ptr (offset PGROUP:IWF_SEGEXT0) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_SEGEXT0	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext mismatch
				; Return with CF significant
FIX_FT02_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT02 endp			; End FIX_FT02 procedure
	NPPROC	FIX_FT10 -- Fixup Frame Method #1 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #1 (GRPDEF)
  vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using PERGRP_STR (method #1)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Frame address
; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; Ensure that the Frame group contains the Target segment

	push	offset DGROUP:MSG_FIXOVF_FRM ; Pass offset in DGROUP of reference
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	offset DGROUP:MSG_FIXOVF_TGT ; Pass offset in DGROUP of reference
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	CHECK_FIXDIF	; Ensure Group contains Segment
				; Return with CF significant
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT10 endp			; End FIX_FT10 procedure
	NPPROC	FIX_FT11 -- Fixup Frame Method #1 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #1 (GRPDEF)
  vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Frame address
; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

	clc			; Mark as sucessful

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT11 endp			; End FIX_FT11 procedure
	NPPROC	FIX_FT12 -- Fixup Frame Method #1 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #1 (GRPDEF)
  vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PUBDEF_ADDR ; Get the entire address for Target

; Perhaps the external target is an absolute symbol
; in which case we don't care about groups and segments

	mov	eax,AGROUP:[edi].FIXUPP_TGT ; Get LA of SYM_STR for Target

	UNCURB	eax,SYMBOL     ; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_ABSCON ; Izit a constant?
	jnz	near ptr FIX_FT12_EXIT ; Jump if so (note CF=0)

; Calculate starting address of the Frame using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Frame address
; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; For self-relative fixups, the Frame group must contain
; the Fixup segment, or we complain.

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	short FIX_FT12_XREL ; Jump if so

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group name (SYM_STR)

	cmp	eax,0		; Izit valid?
	je	short FIX_FT12_XREL ; Jump if not (not a problem)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of PERGRP_STR

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].FIXUPP_FRM ; Izit the same group?
	je	short FIX_FT12_XREL ; Jump if so

; If this group is FLAT (and we're creating a VxD *FIXME*), ignore test

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_FRM ; Get the LA of group (PERGRP_STR)
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of symbol (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_FLAT ; Izit FLAT?
	jnz	near ptr FIX_FT12_EXIT ; Jump if so (note CF=0)

	push	dword ptr (offset PGROUP:IW2_RELGRP) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_RELGRP	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext self-rel mismatch
	jc	near ptr FIX_FT12_EXIT ; Join common exit code (note CF=1)
FIX_FT12_XREL:

; Ensure that the Frame group contains the Target external
; The call to FIX_EXTDEF sets the variable EXTDEF_GRP with the
; LA of the corresponding group (or 0 if ungrouped).

	mov	eax,EXTDEF_GRP	; Get LA of PERGRP_STR for external Target

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].FIXUPP_FRM ; Izit the same group?
	je	near ptr FIX_FT12_EXIT ; Jump if so (note CF=0)

; If this group is FLAT (and we're creating a VxD *FIXME*), ignore test

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_FRM ; Get the LA of group (PERGRP_STR)
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of symbol (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_FLAT ; Izit FLAT?
	jnz	short FIX_FT12_EXIT ; Jump if so (note CF=0)

	cmp	EXTDEF_GRP,0	; Is the external target grouped?
	je	short FIX_FT12_GRPEXT0 ; Jump if not
;;;_FT12_GREPEXT:

	push	dword ptr (offset PGROUP:IW2_GRPEXT) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_GRPEXT	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext mismatch
				; Return with CF significant
	jmp	short FIX_FT12_EXIT ; Join common exit code


FIX_FT12_GRPEXT0:

; Perhaps the external target is in a segment and that segment is in a group

	mov	eax,EXTDEF_SEG	; Get LA of PERSEG_STR for external Target

	cmp	eax,0		; Izit invalid?
	je	short @F	; Jump if so

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group symbol (SYM_STR)

	cmp	eax,0		; Izit invalid?
	je	short @F	; Jump if so

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of group (PERGRP_STR)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].FIXUPP_FRM ; Izit the same group?
	je	short FIX_FT12_EXIT ; Jump if so (note CF=0)
@@:
	push	dword ptr (offset PGROUP:IW2_GRPEXT0) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_GRPEXT0	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext mismatch
				; Return with CF significant
FIX_FT12_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT12 endp			; End FIX_FT12 procedure
	NPPROC	FIX_FT20 -- Fixup Frame Method #2 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #2 (EXTDEF)
  vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of SYM_STR for Frame
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PUBDEF_BASE ; Get the base address for Frame

; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; Ensure that the Frame external (if a group) contains the Target segment

; The call to FIX_EXTDEF sets the variable EXTDEF_GRP with the
; LA of the corresponding group (or 0 if ungrouped).

	cmp	EXTDEF_GRP,0	; Is the external frame grouped?
	je	short FIX_FT20_EXIT ; Jump if not (note CF=0)

; Ensure that the Frame group contains the Target segment

	push	offset DGROUP:MSG_FIXOVF_FRM ; Pass offset in DGROUP of reference
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	EXTDEF_GRP	; Pass LA of PERGRP_STR for Frame
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	offset DGROUP:MSG_FIXOVF_TGT ; Pass offset in DGROUP of reference
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	CHECK_FIXDIF	; Ensure Group contains Segment
				; Return with CF significant
FIX_FT20_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT20 endp			; End FIX_FT20 procedure
	NPPROC	FIX_FT21 -- Fixup Frame Method #2 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #2 (EXTDEF)
  vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of SYM_STR for Frame
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PUBDEF_BASE ; Get the base address for Frame

; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; Ensure that the Target group contains the Frame external
; The call to FIX_EXTDEF sets the variable EXTDEF_SEG with the
; LA of the corresponding segment (or 0 if unsegmented).

	cmp	EXTDEF_SEG,0	; Is Frame external in segment?
	je	short FIX_FT21_EXIT ; Jump if not (note CF=0)

	push	offset DGROUP:MSG_FIXOVF_TGT ; Pass offset in DGROUP of reference
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	offset DGROUP:MSG_FIXOVF_EXT ; Pass offset in DGROUP of reference
	push	EXTDEF_SEG	; Pass LA of PERSEG_STR for Frame
	call	CHECK_FIXDIF	; Ensure Group contains Segment
				; Return with CF significant
FIX_FT21_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT21 endp			; End FIX_FT21 procedure
	NPPROC	FIX_FT22 -- Fixup Frame Method #2 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #2 (EXTDEF)
  vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax,ecx>	; Save registers

; Calculate starting address of the Target using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PUBDEF_ADDR ; Get the entire address for Target

; Calculate starting address of the Frame using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of SYM_STR for Frame
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PUBDEF_BASE ; Get the base address for Frame

; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; Note that the order of the above calls to FIX_EXTDEF is important as
; they set global variables EXTDEF_GRP and EXTDEF_SEG which we need below.

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

; For self-relative fixups, if there's a Frame group,
; it must contain the Fixup segment.  Further, if there's no Frame group,
; but there's a Frame segment, then it must be the same as the Fixup segment
; or, in both cases, we complain.

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	near ptr FIX_FT22_XREL ; Jump if so

	cmp	EXTDEF_GRP,0	; Is the LA of the Frame grp (PERGRP_STR) valid?
	je	short FIX_FT22_XGRP ; Jump if not

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group name (SYM_STR)

	cmp	eax,0		; Izit ungrouped?
	je	short @F	; Jump if so (not a problem)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of PERGRP_STR

	cmp	eax,EXTDEF_GRP	; Izit the same group?
	je	short @F	; Jump if so

	push	dword ptr (offset PGROUP:IW2_RELGRPX) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_RELGRPX	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext self-rel mismatch
	jc	near ptr FIX_FT22_EXIT ; Join common exit code (note CF=1)
@@:
	jmp	short FIX_FT22_XREL ; Join common code


; This is a self-relative fixup, and there's no Frame group.
; If there's a Frame segment, then it must be the same as the Fixup segment,
; or we complain.

FIX_FT22_XGRP:
	cmp	EXTDEF_SEG,0	; Is the LA of the Frame seg (PERSEG_STR) valid?
	je	short FIX_FT22_XREL ; Jump if not

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	eax,EXTDEF_SEG	; Izit the same segment?
	je	short @F	; Jump if so

	push	dword ptr (offset PGROUP:IW2_RELSEGX) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_RELSEGX	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext self-rel mismatch
	jc	near ptr FIX_FT22_EXIT ; Join common exit code (note CF=1)
@@:
FIX_FT22_XREL:

; If the Frame has no group and no segment, call it an absolute constant
; and set the bit in the flags.

	mov	eax,EXTDEF_GRP	; Get the LA of the Frame grp (PERGRP_STR)
	or	eax,EXTDEF_SEG	; ...			  seg (PERSEG_STR)
	jnz	short @F	; Jump one or the other is valid

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	or	AGROUP:[edi].FIXUPP_FLAG,@FIXFL_ABS ; Mark as absolute constant
@@:

; Ensure that the Frame group/segment contains the Target external
; The call to FIX_EXTDEF sets the variable EXTDEF_SEG with the
; LA of the corresponding segment (or 0 if unsegmented).

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_FRM ; Get LA of ext symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of PUBDEF_STR

	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].PUBDEF_PPERGRP ; Get LA of PERGRP_STR (0=none)

	cmp	ecx,EXTDEF_GRP	; Izit in the same group?
	je	short FIX_FT22_SEG ; Jump if so (check the segment)

	cmp	EXTDEF_GRP,0	; Is the Frame group invalid?
	je	short FIX_FT22_SEG ; Jump if so (check the segment)

	push	dword ptr (offset PGROUP:IW2_GRPEXT) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_GRPEXT	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame seg, target ext mismatch
				; Return with CF significant
	jmp	short FIX_FT22_EXIT ; Join common exit code

FIX_FT22_SEG:
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].PUBDEF_PPERSEG ; Get LA of PERSEG_STR (0=none)

	cmp	ecx,EXTDEF_SEG	; Izit in the same segment?
	je	short FIX_FT22_EXIT ; Jump if so (note CF=0)

	cmp	EXTDEF_SEG,0	; Is the Frame segment invalid?
	je	short FIX_FT22_EXIT ; Jump if so (note CF=0)

	push	dword ptr (offset PGROUP:IWF_SEGEXT) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_SEGEXT	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame seg, target ext mismatch
				; Return with CF significant
FIX_FT22_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT22 endp			; End FIX_FT22 procedure
	NPPROC	FIX_FT50 -- Fixup Frame Method #5 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #5 (Target's index)
  vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIX_SEGDEF	; Get fixup based upon SEGDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using target's PERSEG_STR (method #5)
; (already done above)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
;;;;;;; push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
;;;;;;; call	FIX_SEGDEF	; Get fixup based upon SEGDEF
;;;;;;; 			; Return EAX = Frame address
; In case this segment doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

	clc			; Mark as sucessful

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT50 endp			; End FIX_FT50 procedure
	NPPROC	FIX_FT51 -- Fixup Frame Method #5 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #5 (Target's index)
  vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIX_GRPDEF	; Get fixup based upon GRPDEF
				; Return EAX = Target address
	mov	ebx,eax 	; Copy to return register

; Calculate starting address of the Frame using target's PERGRP_STR (method #5)
; (already done above)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
;;;;;;; push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
;;;;;;; call	FIX_GRPDEF	; Get fixup based upon GRPDEF
;;;;;;; 			; Return EAX = Frame address
; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

	clc			; Mark as sucessful

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT51 endp			; End FIX_FT51 procedure
	NPPROC	FIX_FT52 -- Fixup Frame Method #5 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #5 (Target's index)
  vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

EBX	=	fixup value
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

; Calculate starting address of the Target using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIX_EXTDEF	; Get fixup based upon EXTDEF
				; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PUBDEF_ADDR ; Get the entire address for Target

; Calculate starting address of the Frame using target's SYM_STR (method #5)
; (already done above)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
;;;;;;; push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
;;;;;;; 			; (using the Target's index)
;;;;;;; call	FIX_EXTDEF	; Get fixup based upon EXTDEF
;;;;;;; 			; Return EAX = LA of PUBDEF_STR
	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PUBDEF_BASE ; Get the base address for Frame

; In case this group doesn't start on a para boundary, we need to modify
; the old segment length because this is a one-pass linker.

	and	eax,not (16-1)	; Round down to para boundary
	mov	FRM_BASE,eax	; Save in case of segment fixup

; The fixup value is the Target address less the Frame address

	sub	ebx,eax 	; Diff is fixup value

; For self-relative fixups, add into the old length the base of
; the fixup segment.

	call	SELFMOD_OLDLEN	; Modify the old length

	clc			; Mark as sucessful

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_FT52 endp			; End FIX_FT52 procedure
	NPPROC	CHECK_FRMFIX_SEG -- Ensure Frame and Fixup Segment Same
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

For self-relative fixups, the Frame segment must equal
the Fixup segment, or we complain.

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

CF	=	0 if OK
	=	1 if not and it's not fatal

|

	REGSAVE <eax>		; Save register

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	short @F	; Jump if so (note CF=0)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	cmp	eax,AGROUP:[edi].FIXUPP_FRM ; Izit the same segment?
	je	short @F	; Jump if so (note CF=0)

	push	dword ptr (offset PGROUP:IW2_RELSEG) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_RELSEG	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame grp, target ext self-rel mismatch
				; Return with CF significant
@@:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FRMFIX_SEG endp		; End CHECK_FRMFIX_SEG procedure
	NPPROC	CHECK_FRM_GRP -- Complain If Frame Segment In Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Complain if Frame segment is in a group

On entry:

EDI	=	LA of FIXUPP_STR entry

On exit:

CF	=	0 if not in group
	=	1 if in group and it's not fatal

|

	REGSAVE <eax,ecx>	; Save registers

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_FRM ; Get LA of frame segment (PERSEG_STR)

	UNCURB	eax,PERSEG	; Ensure within current bounds
	cmp	AGROUP:[eax].PERSEG_GRPSYM,0 ; Is the external frame ungrouped?
	je	short CHECK_FRM_GRP_EXIT ; Jump if so (note CF=0)

COMMENT|

The difference between the above test and the one below is that
EXTDEF_GRP comes from the PUBDEF_PPERGRP.  This value might be zero if
the symbol was declared without a group reference (because there was
an ASSUME DS:NOTHING present when the PUBLIC declaration was made).

The above test is catches more cases (but maybe too many) as it
detects whether or not the segment was ever grouped even if the
PUBDEF_STR has no record of it.

|

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
;;;	mov	eax,AGROUP:[edi].FIXUPP_FRM ; Get LA of PERSEG_STR for Frame
;;;	UNCURB	eax,PERSEG	; Ensure within current bounds
;;;	cmp	AGROUP:[eax].PERSEG_GRPSYM,0 ; Get LA of group name (SYM_STR)
;;;	je	short CHECK_FRM_GRP_EXIT ; Jump if so (note CF=0)

;;;;;;; cmp	EXTDEF_GRP,0	; Is the external frame ungrouped?
;;;;;;; je	short CHECK_FRM_GRP_EXIT ; Jump if so (note CF=0)
;;;;;;;

; So far, a segment-relative fixup was used and we think a
; group-relative fixup should have been used.

; Here we distinguish the cases where the segment is the first one
; in the group (in which case the result is the same for segment-
; and group-relative fixups), and where it is not (in which case the
; fixup result is different).

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].PERSEG_ADRB.BOUND_BEG ; Get the segment's starting addr

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group name symbol (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of PERGRP_STR

	UNCURB	eax,PERGRP	; Ensure within current bounds
	cmp	ecx,AGROUP:[eax].PERGRP_ADRB.BOUND_BEG ; Izit start in the same place?
	je	short CHECK_FRM_GRP0 ; Jump if so

	push	dword ptr (offset PGROUP:IW2_FRMSEG) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_FRMSEG	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame segment
				; Return with CF significant
	jmp	short CHECK_FRM_GRP_EXIT ; Join common exit code


CHECK_FRM_GRP0:
	push	dword ptr (offset PGROUP:IW3_FRMSEG0) ; Pass offset of action routine
	push	IW3_FLAG	; Pass value of flags
	push	$IW3_FRMSEG0	; Pass offset of bit mask
	call	IWF_TEST	; Test for frame segment
				; Return with CF significant
CHECK_FRM_GRP_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FRM_GRP endp		; End CHECK_FRM_GRP procedure
	NPPROC	FIX_SEGDEF -- Get Fixup Based Upon SEGDEF
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get fixup based upon SEGDEF.

On exit:

EAX	=	SEGDEF address

|

FIX_SEGDEF_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIX_SEGDEF_PPERSEG dd ? 	; LA of PERSEG_STR

FIX_SEGDEF_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	eax,[ebp].FIX_SEGDEF_PPERSEG ; Get LA of PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_ADRB.BOUND_BEG ; Get starting address

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_SEGDEF endp 		; End FIX_SEGDEF procedure
	NPPROC	FIX_GRPDEF -- Get Fixup Based Upon GRPDEF
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get fixup based upon GRPDEF.

On exit:

EAX	=	GRPDEF address

|

FIX_GRPDEF_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIX_GRPDEF_PPERGRP dd ? 	; LA of PERGRP_STR

FIX_GRPDEF_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	eax,[ebp].FIX_GRPDEF_PPERGRP ; Get LA of PERGRP_STR
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_ADRB.BOUND_BEG ; Get starting address

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_GRPDEF endp 		; End FIX_GRPDEF procedure
	NPPROC	FIX_EXTDEF -- Get Fixup Based Upon External Symbol
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get fixup based upon external symbol.

On exit:

EAX	=	LA of PUBDEF_STR

|

FIX_EXTDEF_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIX_EXTDEF_PSYM dd ?		; LA of SYM_STR

FIX_EXTDEF_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	eax,[ebp].FIX_EXTDEF_PSYM ; Get LA of SYM_STR

; Handle external non-public substituted symboles

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_PUB ; Izit public?
	jnz	short @F	; Jump if so

;;;;;;; UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_SUBST ; Izit substituted?
	jz	short @F	; Jump if not

	mov	eax,AGROUP:[eax].SYM_SUBST ; Get subst symbol

	UNCURB	eax,SYMBOL	; Ensure within current bounds
@@:
;;;;;;; UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of PUBDEF_STR

; Save the LA of the corresponding PERGRP_STR in EXTDEF_GRP,
; and PERSEG_STR in EXTDEF_SEG.

	push	ebx		; Save for a moment

	UNCURB	eax,PUBDEF	; Ensure within current bounds
	mov	ebx,AGROUP:[eax].PUBDEF_PPERSEG ; Get LA of PERSEG_STR (0=none)
	mov	EXTDEF_SEG,ebx	; Save for later use

;;;;;;; UNCURB	eax,PUBDEF	; Ensure within current bounds
;;;;;;; mov	ebx,AGROUP:[eax].PUBDEF_PPERGRP ; Get LA of PERGRP_STR (0=none)
;;;;;;; mov	EXTDEF_GRP,ebx	; Save for later use

; Get the group symbol directly from the PERSEG record (the above gets it
; from the PUBDEF record)

	mov	ebx,EXTDEF_SEG	; Get LA of PERSEG_STR (0=none)

	cmp	ebx,0		; Is it in a segment?
	je	short @F	; Jump if not

	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].PERSEG_GRPSYM ; Get LA of group name (SYM_STR)

	cmp	ebx,0		; Is it in a group?
	je	short @F	; Jump if not

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].SYM_PERITEM ; Get LA of group (PERGRP_STR)
@@:
	mov	EXTDEF_GRP,ebx	; Save for later use

	pop	ebx		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIX_EXTDEF endp 		; End FIX_EXTDEF procedure
	NPPROC	IWF_FIXOVF -- Ignore/Warn/Fail About Fixup Overflow
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about fixup overflow

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

|

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short IWF_COMOVF ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_FIXOVF endp 		; End IWF_FIXOVF procedure
	NPPROC	IWF_ABSOVF -- Ignore/Warn/Fail About Absolute Fixup Overflow
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about absolute fixup overflow

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

|

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_ABSOVF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short IWF_COMOVF ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_ABSOVF endp 		; End IWF_ABSOVF procedure
	NPPROC	IWF_COMOVF -- Common Routine For Fixup Overflows
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Common routine for fixup overflows

On entry:

EBX	=	fixup value
EDX	=	LA of fixup location
EDI	=	LA of FIXUPP_STR entry

|

	pushad			; Save registers

; Format the fixup value

	mov	eax,ebx 	; Copy fixup value

	push	edi		; Save for a moment

	lea	edi,MSG_FIXOVF1 ; ES:EDI ==> format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DD2HEX		; Convert EAX to hex at ES:EDI

	pop	edi		; Restore

; Format the offset of the fixup

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_DRO_CUR ; Get LA of the DRO current
	sub	eax,AGROUP:[edi].FIXUPP_DRO_BEG ; Less LA of the DRO start
	add	eax,AGROUP:[edi].FIXUPP_OFF ; Plus offset of DRO
	add	eax,AGROUP:[edi].FIXUPP_OLDLEN ; Plus length before appending
				; this segment
	push	edi		; Save for a moment

	lea	edi,MSG_FIXOVF3 ; ES:EDI ==> format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DD2HEX		; Convert EAX to hex at ES:EDI

	pop	edi		; Restore

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the fixup width

	push	fs		; Pass DGROUP segment
	push	WIDOVF		; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF2) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the segment name

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display information about the Frame and Target (Group, Segment, or External)

	call	DISP_FRMTGT	; Display it

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_COMOVF endp 		; End IWF_COMOVF procedure
	NPPROC	DISP_FRMTGT -- Display Frame/Target Information
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display Frame/Target information

On entry:

EDI	=	LA of fixup (FIXUPP_STR)

|

	pushad			; Save registers

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	movzx	eax,AGROUP:[edi].FIXUPP_FIXDAT ; Get the FIXDAT byte
	mov	ebx,eax 	; Copy for later use
	and	eax,@FIXDAT_FRM ; Isolate the frame method
	shr	eax,$FIXDAT_FRM ; Shift to low-order
	shl	eax,width $FIXDAT_TGT ; Shift over

	and	ebx,@FIXDAT_TGT ; Isolate the target method
	shr	ebx,$FIXDAT_TGT ; Shift to low-order
	add	eax,ebx 	; Add to get FIX_FT_TAB index

	call	FIXOVF_FT_TAB[eax*(type FIXOVF_FT_TAB)] ; Call to action

; Display Target displacement if present

	call	DISP_TGTDSP	; Display it

; Display the .OBJ filename

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_OBJ) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPEROBJ ; Get LA of .OBJ (PEROBJ_STR)

	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	push	1		; Display leading blank
	push	eax		; Pass LA of PEROBJ_STR as argument
	call	DISP_THEADR	; Display the THEADR if present

	call	U32_NEWLINE	; Goto a new line

; If there's line number information, display that

	call	DISP_LINNUM	; Display line # info for EDI (FIXUPP_STR)

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_FRMTGT endp		; End DISP_FRMTGT procedure
	NPPROC	DISP_TGTDSP -- Display Target Displacement
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display target displacement

On entry:

EDI	=	LA of FIXUPP_STR

|

	REGSAVE <eax>		; Save register

; Display the Target Displacement if present

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_FIXDAT,@FIXDAT_P ; Izit present?
	jnz	short DISP_TGTDSP_EXIT ; Jump if not (note P=1 means no displacement)

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_DSP ; Get the Target Displacement

	push	edi		; Save for a moment

	lea	edi,MSG_FIXOVF_OFF1 ; ES:EDI ==> format area
	add	edi,LaDATA	; Plus LA of DGROUP
	call	DD2HEX		; Convert EAX to hex at ES:EDI

	pop	edi		; Restore

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_OFF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DISP_TGTDSP_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TGTDSP endp		; End DISP_TGTDSP procedure
	NPPROC	DISP_LINNUM -- Display Line Number Information
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display line number information

On entry:

EDI	=	LA of fixup (FIXUPP_STR)

|

	pushad			; Save registers

; Calculate the offset of the fixup

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	esi,AGROUP:[edi].FIXUPP_DRO_CUR ; Get LA of the DRO current
	sub	esi,AGROUP:[edi].FIXUPP_DRO_BEG ; Less LA of the DRO start
	add	esi,AGROUP:[edi].FIXUPP_OFF ; Plus offset of DRO
	add	esi,LAST_OLDLEN ; Plus length before appending
				; this segment

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup segment (PERSEG_STR)
	mov	edx,AGROUP:[edi].FIXUPP_PPEROBJ ; ...	    .OBJ file (PEROBJ_STR)

COMMENT|

Determine the count of line #s in this .OBJ file.

If this is the last .OBJ file, use the LA of the next line # record;
otherwise, use the address in the next PEROBJ record.

|

	mov	eax,LMB_LINNUM.LMB_CURB.BOUND_NXT ; Get LA of next LINNUM_STR
				; assuming this is the last .OBJ file
	mov	edi,edx 	; Copy LA of .OBJ file (PEROBJ_STR)
	add	edi,type PEROBJ_STR ; Skip to next entry

	cmp	edi,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Izit the last .OBJ file?
	je	short @F	; Jump if so

	UNCURB	edi,PEROBJ	; Ensure within current bounds
	mov	eax,AGROUP:[edi].PEROBJ_PLINNUM ; Get LA of line numbers (LINNUM_STR)
@@:
	UNCURB	edx,PEROBJ	; Ensure within current bounds
	mov	edi,AGROUP:[edx].PEROBJ_PLINNUM ; Get LA of line numbers (LINNUM_STR)

	sub	eax,edi 	; Subtract to get byte count of LINNUM records
	jz	short DISP_LINNUM_NONE ; Jump if no line # records

	push	edx		; Save for a moment

	xor	edx,edx 	; Zero to use EDX:EAX as qword
	div	LINNUM_SIZ	; Divide by struc size (LINNUM_STR)

	mov	ecx,eax 	; Copy quotient to count register

	pop	edx		; Restore

; Trundle through the line number records looking for this offset
; in the same .OBJ file and the same segment.

DISP_LINNUM_NEXT:
	UNCURB	edi,LINNUM	; Ensure within current bounds
	cmp	ebx,AGROUP:[edi].LINNUM_PPERSEG ; Izit the same segment?
	jne	short DISP_LINNUM_LOOP ; Jump if not

	cmp	esi,AGROUP:[edi].LINNUM_NUMOFF ; Izit this one?
	jbe	short DISP_LINNUM_MATCH ; Jump if so (with ZF significant)
DISP_LINNUM_LOOP:
	add	edi,type LINNUM_STR ; Skip to next entry

	loop	DISP_LINNUM_NEXT ; Jump if more line #s to check
DISP_LINNUM_NONE:
	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_LINNUM_NONE) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	jmp	short DISP_LINNUM_EXIT ; Join common exit code


; Format the line #
; Note ZF is significant

DISP_LINNUM_MATCH:

; We have a match (or a near match) on the line # offset
; and it's either this LINNUM record or the on before that
; depending upon the ZF flag.

	mov	eax,AGROUP:[edi].LINNUM_LINNUM ; Get the line #
	je	short @F	; Jump if exact match with line # offset

	cmp	edi,LMB_LINNUM.LMB_CURB.BOUND_BEG ; Izit the 1st LINNUM record?
	je	short @F	; Jump if so

	cmp	edx,AGROUP:[edi-(type LINNUM_STR)].LINNUM_PPEROBJ ; Izit the same .OBJ file?
	jne	short @F	; Jump if not

	cmp	ebx,AGROUP:[edi-(type LINNUM_STR)].LINNUM_PPERSEG ; Izit the same segment?
	jne	short @F	; Jump if not

	mov	eax,AGROUP:[edi-(type LINNUM_STR)].LINNUM_LINNUM ; Get the line #
@@:
	lea	edi,MSG_LINNUM1 ; Get offset in DGROUP of format area
	add	edi,LaDATA	; Plus LA of DGROUP

	push	@DEC_LEFT	; No commas, left-justified
	call	DD2DEC		; Convert EAX to decimal ending at ES:EDI
				; Returning ES:EDI ==> next byte
; Display the line #

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_LINNUM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message
DISP_LINNUM_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_LINNUM endp		; End DISP_LINNUM procedure
	NPPROC	FIXOVF_FT00 -- Fixup Overflow Frame Method #0 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #0 (SEGDEF)
	   vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT00 endp		; End FIXOVF_FT00 procedure
	NPPROC	FIXOVF_FT01 -- Fixup Overflow Frame Method #0 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #0 (SEGDEF)
	   vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT01 endp		; End FIXOVF_FT01 procedure
	NPPROC	FIXOVF_FT02 -- Fixup Overflow Frame Method #0 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #0 (SEGDEF)
	   vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERSEG_STR for Frame
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT02 endp		; End FIXOVF_FT02 procedure
	NPPROC	FIXOVF_FT10 -- Fixup Overflow Frame Method #1 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #1 (GRPDEF)
	   vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT10 endp		; End FIXOVF_FT10 procedure
	NPPROC	FIXOVF_FT11 -- Fixup Overflow Frame Method #1 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #1 (GRPDEF)
  vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT11 endp		; End FIXOVF_FT11 procedure
	NPPROC	FIXOVF_FT12 -- Fixup Overflow Frame Method #1 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #1 (GRPDEF)
	   vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of PERGRP_STR for Frame
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT12 endp		; End FIXOVF_FT12 procedure
	NPPROC	FIXOVF_FT20 -- Fixup Overflow Frame Method #2 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #2 (EXTDEF)
	   vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of SYM_STR for Frame
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT20 endp		; End FIXOVF_FT20 procedure
	NPPROC	FIXOVF_FT21 -- Fixup Overflow Frame Method #2 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #2 (EXTDEF)
	   vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of SYM_STR for Frame
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT21 endp		; End FIXOVF_FT21 procedure
	NPPROC	FIXOVF_FT22 -- Fixup Overflow Frame Method #2 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #2 (EXTDEF)
	   vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_FRM ; Pass LA of SYM_STR for Frame
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT22 endp		; End FIXOVF_FT22 procedure
	NPPROC	FIXOVF_FT50 -- Fixup Overflow Frame Method #5 vs. Target Method #0
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #5 (Target's index)
	   vs. Target Method #0 (SEGDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using target's PERSEG_STR (method #5)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERSEG_STR (method #0)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERSEG_STR for Target
	call	FIXOVF_SEGDEF	; Display fixup overflow based upon SEGDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT50 endp		; End FIXOVF_FT50 procedure
	NPPROC	FIXOVF_FT51 -- Fixup Overflow Frame Method #5 vs. Target Method #1
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Overflow Frame  Method #5 (Target's index)
	   vs. Target Method #1 (GRPDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry


|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using target's PERGRP_STR (method #5)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using PERGRP_STR (method #1)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of PERGRP_STR for Target
	call	FIXOVF_GRPDEF	; Display fixup overflow based upon GRPDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT51 endp		; End FIXOVF_FT51 procedure
	NPPROC	FIXOVF_FT52 -- Fixup Frame Method #5 vs. Target Method #2
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Fixup Frame  Method #5 (Target's index)
  vs. Target Method #2 (EXTDEF)

On entry:

EDI	=	LA of FIXUPP_STR entry

|

; Display leading Frame text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FRM) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Frame name using target's SYM_STR (method #5)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
				; (using the Target's index)
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

; Display leading Target text

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_TGT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display Target name using SYM_STR/PUBDEF_STR (method #2)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	push	AGROUP:[edi].FIXUPP_TGT ; Pass LA of SYM_STR for Target
	call	FIXOVF_EXTDEF	; Display fixup overflow based upon EXTDEF

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_FT52 endp		   ; End FIXOVF_FT52 procedure
	NPPROC	FIXOVF_SEGDEF -- Display Fixup Overflow Based Upon SEGDEF
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display fixup overflow based upon SEGDEF.

|

FIXOVF_SEGDEF_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIXOVF_SEGDEF_PPERSEG dd ?	; LA of PERSEG_STR

FIXOVF_SEGDEF_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_SEG) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	eax,[ebp].FIXOVF_SEGDEF_PPERSEG ; Get LA of PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_SEGDEF endp		; End FIXOVF_SEGDEF procedure
	NPPROC	FIXOVF_GRPDEF -- Display Fixup Overflow Based Upon GRPDEF
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display fixup overflow based upon GRPDEF.

|

FIXOVF_GRPDEF_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIXOVF_GRPDEF_PPERGRP dd ?	; LA of PERGRP_STR

FIXOVF_GRPDEF_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_GRP) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	eax,[ebp].FIXOVF_GRPDEF_PPERGRP ; Get LA of PERGRP_STR
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_GRPDEF endp		; End FIXOVF_GRPDEF procedure
	NPPROC	FIXOVF_EXTDEF -- Display Fixup Overflow Based Upon EXTDEF
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display fixup overflow based upon EXTDEF.

On entry:

EDI	=	LA of FIXUPP_STR entry

|

FIXOVF_EXTDEF_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
FIXOVF_EXTDEF_PSYM dd ? 	; LA of SYM_STR

FIXOVF_EXTDEF_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx>	; Save registers

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_EXT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	mov	ebx,[ebp].FIXOVF_EXTDEF_PSYM ; Get LA of SYM_STR

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	push	AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	mov	ebx,AGROUP:[ebx].SYM_PERITEM ; Get LA of PUBDEF_STR

; If this symbol has an associated segment, display that

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_PPERSEG ; Get LA of PERSEG_STR (0=none)

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_INSEG) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	lea	ecx,TXT_NONE	; Assume not in a segment
	add	ecx,LaDATA	; Plus LA of DGROUP

	cmp	eax,0		; Izit valid?
	je	short @F	; Jump if not

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of SYM_STR
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].SYM_PNAM ; Get LA of symbol (Count, Char[])
@@:
	push	ecx		; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display (Count, Char[])

; If this symbol has an associated group, display that

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_PPERGRP ; Get LA of PERGRP_STR (0=none)

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_INGRP) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	lea	ecx,TXT_NONE	; Assume not in a segment
	add	ecx,LaDATA	; Plus LA of DGROUP

	cmp	eax,0		; Izit valid?
	je	short @F	; Jump if not

	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of SYM_STR
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	ecx,AGROUP:[eax].SYM_PNAM ; Get LA of symbol (Count, Char[])
@@:
	push	ecx		; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the .OBJ filename in which this symbol was declared public

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_PUB) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	UNCURB	ebx,PUBDEF	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PUBDEF_PPEROBJ ; Get LA of PEROBJ_STR

	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	push	1		; Display leading blank
	push	eax		; Pass LA of PEROBJ_STR as argument
	call	DISP_THEADR	; Display the THEADR if present

	call	U32_NEWLINE	; Goto a new line

	REGREST <ecx,ebx,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIXOVF_EXTDEF endp		; End FIXOVF_EXTDEF procedure
	NPPROC	IWF_SEGEXT -- Ignore/Warn/Fail About Frame Segment Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame segment, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_SEGEXT) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_SEGEXT endp 		; End IWF_SEGEXT procedure
	NPPROC	IWF_SEGEXT0 -- Ignore/Warn/Fail About Frame Segment Target External Ungrouped
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame segment, target external unsegmented

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_SEGEXT0) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_SEGEXT0 endp		; End IWF_SEGEXT0 procedure
	NPPROC	IW2_GRPEXT -- Ignore/Warn/Fail About Frame Group Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame group, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_GRPEXT) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_GRPEXT endp 		; End IW2_GRPEXT procedure
	NPPROC	IW2_GRPEXT0 -- Ignore/Warn/Fail About Frame Group Target External Ungrouped
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame group, target external ungrouped

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_GRPEXT0) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_GRPEXT0 endp		; End IW2_GRPEXT0 procedure
	NPPROC	IW2_FRMSEG -- Ignore/Warn/Fail About Frame Segment Should Be Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame segment should be group

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	REGSAVE <eax,ebx>	; Save registers

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FRMSEG) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the name of the frame segment

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].FIXUPP_FRM ; Get LA of PERSEG_STR for Frame
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FRMSEG1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the name of the group which contains the frame segment

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
;;;;;;; mov	ebx,AGROUP:[edi].FIXUPP_FRM ; Get LA of PERSEG_STR for Frame
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_GRPSYM ; Get LA of group name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	dword ptr (offset DGROUP:MSG_FRMSEG2) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_FRMSEG endp 		; End IW2_FRMSEG procedure
	NPPROC	IW3_FRMSEG0 -- Ignore/Warn/Fail About Frame Segment Should Be Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame segment should be group,
but the segment is the first one in the group.

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	REGSAVE <eax,ebx>	; Save registers

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FRMSEG0) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the name of the frame segment

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	ebx,AGROUP:[edi].FIXUPP_FRM ; Get LA of PERSEG_STR for Frame
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FRMSEG01) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the name of the group which contains the frame segment

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
;;;;;;; mov	ebx,AGROUP:[edi].FIXUPP_FRM ; Get LA of PERSEG_STR for Frame
	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_GRPSYM ; Get LA of group name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	dword ptr (offset DGROUP:MSG_FRMSEG02) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW3_FRMSEG0 endp		; End IW3_FRMSEG0 procedure
	NPPROC	IW2_RELSEG -- Ignore/Warn/Fail About Self-Relative Frame Segment Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about self-relative frame segment, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_RELSEG) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_RELSEG endp 		; End IW2_RELSEG procedure
	NPPROC	IW2_RELGRP -- Ignore/Warn/Fail About Self-Relative Frame Group Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about self-relative frame group, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_RELGRP) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_RELGRP endp 		; End IW2_RELGRP procedure
	NPPROC	IW2_RELSEGX -- Ignore/Warn/Fail About Self-Relative Frame Segment Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about self-relative frame segment, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_RELSEGX) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_RELSEGX endp		; End IW2_RELSEGX procedure
	NPPROC	IW2_RELGRPX -- Ignore/Warn/Fail About Self-Relative Frame Group Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about self-relative frame group, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

	push	dword ptr (offset DGROUP:MSG_RELGRPX) ; Pass offset of message
	call	IWF_GRPSEG_EXTCOM ; Call common routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_RELGRPX endp		; End IW2_RELGRPX procedure
	NPPROC	IWF_GRPSEG_EXTCOM -- Ignore/Warn/Fail About Frame Group/Segment Target External
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about frame group/segment, target external

On entry:

EDI	=	LA of FIXUPP_STR entry

|

GRPSEG_EXT_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
GRPSEG_EXT_PMSG dd ?		; Offset in DGROUP of message to print

GRPSEG_EXT_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers

	push	fs		; Pass DGROUP segment
	push	[ebp].GRPSEG_EXT_PMSG ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display information about the Frame and Target (Group, Segment, or External)

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	movzx	eax,AGROUP:[edi].FIXUPP_FIXDAT ; Get the FIXDAT byte
	mov	ebx,eax 	; Copy for later use
	and	eax,@FIXDAT_FRM ; Isolate the frame method
	shr	eax,$FIXDAT_FRM ; Shift to low-order
	shl	eax,width $FIXDAT_TGT ; Shift over

	and	ebx,@FIXDAT_TGT ; Isolate the target method
	shr	ebx,$FIXDAT_TGT ; Shift to low-order
	add	eax,ebx 	; Add to get FIX_FT_TAB index

	call	FIXOVF_FT_TAB[eax*(type FIXOVF_FT_TAB)] ; Call to action

; Display Target displacement if present

	call	DISP_TGTDSP	; Display it

; Display the fixup segment

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_FIXSEG) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM; Get LA of symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the .OBJ filename

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXOVF_OBJ) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPEROBJ ; Get LA of .OBJ (PEROBJ_STR)

	UNCURB	eax,PEROBJ	; Ensure within current bounds
	push	AGROUP:[eax].PEROBJ_PFID ; Pass the offset in AGROUP
	call	DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	push	1		; Display leading blank
	push	eax		; Pass LA of PEROBJ_STR as argument
	call	DISP_THEADR	; Display the THEADR if present

	call	U32_NEWLINE	; Goto a new line

; If there's line number information, display that

	call	DISP_LINNUM	; Display line # info for EDI (FIXUPP_STR)

	popad			; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_GRPSEG_EXTCOM endp		; End IWF_GRPSEG_EXTCOM procedure
	NPPROC	CHECK_FIXDIF -- Check Segment In A Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ensure that a segment is contained in a group

On entry:

EDI	=	LA of FIXUPP record (FIXUPP_STR)

On exit:

CF	=	0 if contained, or Ignore/Warn
	=	1 if not

|

CHKFD_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CHKFD_SEG dd	?		; LA of segment (PERSEG_STR)
CHKFD_SEGREF dd ?		; Offset in DGROUP of segment reference (FRM/TGT/EXT)
CHKFD_GRP dd	?		; LA of group	(PERGRP_STR)
CHKFD_GRPREF dd ?		; Offset in DGROUP of group reference (FRM/TGT/EXT)

CHKFD_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	mov	eax,[ebp].CHKFD_SEG ; Get LA of PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_GRPSYM ; Get LA of group symbol (SYM_STR)

	and	eax,eax 	; Izit in a group?
	jz	short CHECK_FIXDIFX ; Jump if not

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	mov	eax,AGROUP:[eax].SYM_PERITEM ; Get LA of group (PERGRP_STR)

	cmp	eax,[ebp].CHKFD_GRP ; Izit in the same group?
	je	short CHECK_FIXDIF_EXIT ; Jump if so (note CF=0)

; If this group is FLAT (and we're creating a VxD *FIXME*), ignore test

	mov	eax,[ebp].CHKFD_GRP ; Get the LA of group (PERGRP_STR)
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of symbol (SYM_STR)

	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_FLAT ; Izit FLAT?
	jnz	short CHECK_FIXDIF_EXIT ; Jump if so (note CF=0)

	push	dword ptr (offset PGROUP:IW2_FIXDIF) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_FIXDIF	; Pass offset of bit mask
	call	IWF_TEST	; Test for large segments
				; Return with CF significant
	jmp	short CHECK_FIXDIF_EXIT ; Join common exit code

CHECK_FIXDIFX:
	push	dword ptr (offset PGROUP:IW2_FIXDIFX) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_FIXDIFX	; Pass offset of bit mask
	call	IWF_TEST	; Test for large segments
				; Return with CF significant
CHECK_FIXDIF_EXIT:
	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	4*4		; Return to caller, popping argumentss

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FIXDIF endp		; End CHECK_FIXDIF procedure
	NPPROC	IW2_FIXDIF -- Ignore/Warn/Fail About Segment Not In Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about segment not in group

On entry:

SS:EBP	==>	CHKFD_STR
EDI	=	LA of FIXUPP record (FIXUPP_STR)

|

	pushad			; Save registers

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIF) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the segment reference

	mov	eax,[ebp].CHKFD_SEGREF ; Get offset of message
	add	eax,@MSG_INDENT ; Skip over indent

	push	fs		; Pass DGROUP segment
	push	eax		; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIF1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the segment name

	mov	eax,[ebp].CHKFD_SEG ; Get LA of PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIF2) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the group reference

	mov	eax,[ebp].CHKFD_GRPREF ; Get offset of message
	add	eax,@MSG_INDENT ; Skip over indent

	push	fs		; Pass DGROUP segment
	push	eax		; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIF3) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the group name

	mov	eax,[ebp].CHKFD_GRP ; Get LA of PERGRP_STR
	UNCURB	eax,PERGRP	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERGRP_GRPSYM ; Get LA of group symbol (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIF4) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display information about the Frame and Target (Group, Segment, or External)

	call	DISP_FRMTGT	; Display it

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_FIXDIF endp 		; End IW2_FIXDIF procedure
	NPPROC	IW2_FIXDIFX -- Ignore/Warn/Fail About Segment Not In Group
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about segment not in group

On entry:

SS:EBP	==>	CHKFD_STR
EDI	=	LA of FIXUPP record (FIXUPP_STR)

|

	pushad			; Save registers

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIFX) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the segment reference

	mov	eax,[ebp].CHKFD_SEGREF ; Get offset of message
	add	eax,@MSG_INDENT ; Skip over indent

	push	fs		; Pass DGROUP segment
	push	eax		; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIFX1) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the segment name

	mov	eax,[ebp].CHKFD_SEG ; Get LA of PERSEG_STR
	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	push	AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIFX2) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the group reference

	mov	eax,[ebp].CHKFD_GRPREF ; Get offset of message
	add	eax,@MSG_INDENT ; Skip over indent

	push	fs		; Pass DGROUP segment
	push	eax		; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_FIXDIFX3) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display information about the Frame and Target (Group, Segment, or External)

	call	DISP_FRMTGT	; Display it

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_FIXDIFX endp		; End IW2_FIXDIFX procedure
	NPPROC	SELFMOD_OLDLEN -- Modify Old Length For Self-Relative Fixups
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Modify old length for self-relative fixups

On entry:

EDI	=	LA of FIXUPP record (FIXUPP_STR)

|

	REGSAVE <eax>		; Save register

	UNCURB	edi,FIXUPP	; Ensure within current bounds
	test	AGROUP:[edi].FIXUPP_LOCAT,@LOCAT_M ; Izit segment-relative(1)?
	jnz	short SELFMOD_OLDLEN_EXIT ; Jump if so

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	mov	eax,AGROUP:[edi].FIXUPP_PPERSEG ; Get LA of fixup seg (PERSEG_STR)

	UNCURB	eax,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERSEG_ADRB.BOUND_BEG ; Get start addr of fixup seg

;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	add	AGROUP:[edi].FIXUPP_OLDLEN,eax ; Add into fixup

	mov	eax,FRM_BASE	; Get the Frame base
	and	eax,not (16-1)	; Round down to para boundary
;;;;;;; UNCURB	edi,FIXUPP	; Ensure within current bounds
	sub	AGROUP:[edi].FIXUPP_OLDLEN,eax ; Subtract from fixup
SELFMOD_OLDLEN_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SELFMOD_OLDLEN endp		; End SELFMOD_OLDLEN procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_FIX module
