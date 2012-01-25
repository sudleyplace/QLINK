;' $Header:   P:/PVCS/MISC/QLINK/QLNK_GRP.ASV   1.1   17 Jul 1997 12:36:46   BOB  $
	title	QLNK_GRP -- QLINK Group Processor
	page	58,122
	name	QLNK_GRP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-7 Qualitas, Inc.  All rights reserved.

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
	 include DOSCALL.INC

	 include QLNK_COM.INC
	 include QLNK_SEG.INC
	 include QLNK_SYM.INC
.list

DATA	 segment		; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 LCL_FLAG:dword
	 include QLNK_LCL.INC

	 extrn	 IWF_FLAG:dword
	 include QLNK_IWF.INC

	 extrn	 LMB_PEROBJ:dword
	 extrn	 LMB_PERGRP:dword
	 extrn	 LMB_PERSEG:dword
	 extrn	 LMB_SYMBOL:dword
	 extrn	 LMB_LINNUM:dword

	 extrn	 LaDATA:dword

	 public  GRP_BASE,GRP_PERSEG
GRP_BASE dd	 ?		; Base address of segment in group
GRP_PERSEG dd	 ?		; Last PERSEG_STR in group

GRP_REC  record  $GRP_ABS1:1,$GRP_REL:1,$GRP_ABS:1

@GRP_ABS1 equ	 (mask $GRP_ABS1) ; First occurrence of absolute segment
@GRP_REL  equ	 (mask $GRP_REL)  ; Relocatable segment in this group
@GRP_ABS  equ	 (mask $GRP_ABS)  ; Absolute ...

	 public  GRP_FLAG
GRP_FLAG dd	 ?		; Group flags

	 public  GRP_XLAT
GRP_XLAT db	 @GRP_ABS	; 0 = ABS (from SETNE)
	 db	 @GRP_REL	; 1 = REL ...

	 public  MSG_GRPBIG
MSG_GRPBIG  db	 '(GRPBIG) A 16-bit segment ',@LQ,EOS
MSG_GRPBIG1 db	 @RQ,CR,LF,@I,'in group ',@LQ,EOS
MSG_GRPBIG2 db	 @RQ,' ends above 64KB.',CR,LF,EOS

	 public  MSG_GRPMIX
MSG_GRPMIX  db	 '(GRPMIX) The group ',@LQ,EOS
MSG_GRPMIX1 db	 @RQ,' has mixed absolute and',CR,LF
	    db	 @I,'relocatable segments:',EOS

MSG_GRPMIX2 db	 CR,LF,@I,@LQ,EOS
MSG_GRPMIX3 db	 @RQ,' last grouped in file ',EOS

	 public  MSG_ABSDIF
MSG_ABSDIF  db	 '(ABSDIF) The group ',@LQ,EOS
MSG_ABSDIF1 db	 @RQ,' has absolute segments',CR,LF
	    db	 @I,'with differing bases:',CR,LF
	    db	 @I,@LQ,EOS
MSG_ABSDIF2 db	 '________) last grouped in file ',EOS
MSG_ABSDIF3 db	 ', and',CR,LF,@I,@LQ,EOS
MSG_ABSDIF4 db	 '________) last grouped in file ',EOS
MSG_ABSDIFSEP db @RQ,' (',EOS

DATA	 ends			; End DATA segment


CODE	 segment		; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_CNTCHR:near
	 extrn	 U32_DISP_MSG:near
	 extrn	 U32_NEWLINE:near
	 extrn	 DISP_THEADR:near
	 extrn	 DD2HEX:near
	 extrn	 IWF_TEST:near
	 extrn	 CB_TERM:near

	 NPPROC  PROC_GRPS -- Calculate Start Of All Groups
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Calculate the start of all groups, and the position of each segment
in its group.

Note that this routine must be serially reusable as it
may be entered multiple times due to library processing.

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

; Loop through all the groups

	 mov	 edi,LMB_PERGRP.LMB_CURB.BOUND_BEG ; Get starting address
PROC_GRPS_NEXTGRP:
	 cmp	 edi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 near ptr PROC_GRPS_DONE ; Jump if so

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

; For this group, trundle through all its associated segments
; calculating the lowest and highest ending starting address.

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 esi,AGROUP:[edi].PERGRP_GRPLNK ; Get LA of next PERSEG_STR

	 and	 esi,esi	; Are there any segments?
	 jz	 near ptr PROC_GRPS_LOOPGRP ; Jump if not

	 mov	 eax,-1 	; Get identity element for minimum
	 mov	 edx,0		; ...			   maximum
	 mov	 GRP_FLAG,0	; Initialize group flags
PROC_GRPS_NEXTSEG1:

; If this segment is skippable, do so

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 test	 AGROUP:[esi].PERSEG_FLAG,@PERSEG_SKIP ; Izit skippable?
	 jnz	 near ptr PROC_GRPS_LOOPSEG1 ; Jump if so

; Keep track of absolute and non-absolute segments to be sure we
; don't mix the two as well as catch differing bases for grouped
; absolute segments.

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 ecx,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR
	 UNCURB  ecx,SYMBOL	; Ensure within current bounds
	 movzx	 ecx,AGROUP:[ecx].SYM_FLAG.LO ; Get the ACBP byte
	 and	 ecx,@SYMFL_A	; Isolate the alignment type
	 shr	 ecx,$SYMFL_A	; Shift to low-order

; Ensure we don't mix absolute and relocatable segments

	 cmp	 ecx,@ACBP_A_ABS ; Izit absolute?
	 setne	 cl		; CL = 0 if ABS, 1 if REL
	 movzx	 ecx,GRP_XLAT[ecx*(type GRP_XLAT)] ; Get corresponding flags
				; ECX has @GRP_ABS set iff absolute segment
				; ...	  @GRP_REL ...	   relocatable ...
	 mov	 ebx,ecx	; Copy flags:  10b or 10b

	 test	 GRP_FLAG,@GRP_REL or @GRP_ABS ; Izit a new state?
	 jz	 short PROC_GRPS0 ; Jump if so

	 xor	 ecx,GRP_FLAG	; Merge with previous flags
	 and	 ecx,@GRP_REL or @GRP_ABS ; Isolate the flags
	 jz	 short PROC_GRPS0 ; Jump if same state as before
				;    | 10    01     Incoming state
				; -------------
				; 00#| 10    01     Initial state
				; 01 | 11    00*    Previous abs
				; 10 | 00*   11     Previous rel
				; 11 | 01    10     Both previous
				; -------------
				; * = handled by above AND/JZ
				; # = handled by above TEST/JZ

	 push	 dword ptr (offset PGROUP:IWF_GRPMIX) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_GRPMIX	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for mixed abs and rel segments
	 jc	 near ptr PROC_GRPS_ERR ; Jump if it's fatal
PROC_GRPS0:
	 or	 GRP_FLAG,ebx	; Include new flags

; If this is an absolute segment, ensure that it has the same base as other
; absolute segments in the group.

	 test	 ebx,@GRP_ABS	; Izit an absolute segment?
	 jz	 short PROC_GRPS2 ; Jump if not

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 ecx,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Get starting address

	 bts	 GRP_FLAG,$GRP_ABS1 ; Izit the first absolute segment?
	 jnc	 short PROC_GRPS1 ; Jump if so

	 cmp	 ecx,GRP_BASE	; Izit the same base?
	 je	 short PROC_GRPS2 ; Jump if so

	 push	 dword ptr (offset PGROUP:IWF_ABSDIF) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_ABSDIF	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for differing base in abs segments
	 jc	 near ptr PROC_GRPS_ERR ; Jump if it's fatal
PROC_GRPS1:
	 mov	 GRP_BASE,ecx	; Save for later use
	 mov	 GRP_PERSEG,esi ; Save for error display purposes
PROC_GRPS2:

; Calculate lower starting address

	 UNCURB  esi,PERSEG	; Ensure within current bounds

	 cmp	 eax,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Is this segment lower?
	 jb	 short @F	; Jump if not

	 mov	 eax,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Use the lower address
@@:

; Calculate upper ending address

	 UNCURB  esi,PERSEG	; Ensure within current bounds

	 cmp	 edx,AGROUP:[esi].PERSEG_ADRB.BOUND_NXT ; Is this segment upper?
	 jae	 short @F	; Jump if not

	 mov	 edx,AGROUP:[esi].PERSEG_ADRB.BOUND_NXT ; Use the upper address
@@:
PROC_GRPS_LOOPSEG1:
	 mov	 esi,AGROUP:[esi].PERSEG_GRPLNK ; Get LA of next segment in group

	 and	 esi,esi	; Is this the last one?
	 jnz	 near ptr PROC_GRPS_NEXTSEG1 ; Jump if not

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERGRP_ADRB.BOUND_BEG,eax ; Save as starting address
	 mov	 AGROUP:[edi].PERGRP_ADRB.BOUND_NXT,edx ; ...	  ending ...

; If we encountered all absolute segments in this group, the group base
; must be that of the first segment in sequence.  This reflects the behavior
; (like it or not) of the MS linker.

	 test	 GRP_FLAG,@GRP_REL ; Did we see any relocatable segments?
	 jnz	 short @F	; Jump if so

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 esi,AGROUP:[edi].PERGRP_GRPLNK ; Get LA of 1st PERSEG_STR
	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Get starting addr
;;;;;;;; UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERGRP_ADRB.BOUND_BEG,eax ; Save as ...

;;;;;;;; UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_ADRB.BOUND_NXT ; Get ending addr
;;;;;;;; UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 AGROUP:[edi].PERGRP_ADRB.BOUND_NXT,eax ; Save as ...
@@:

; Trundle through the segments again, this time ensuring that any
; 16-bit segments don't end above 64KB, and calculate and save the
; offset of each segment in its group.

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 esi,AGROUP:[edi].PERGRP_GRPLNK ; Get LA of next PERSEG_STR
	 mov	 edx,AGROUP:[edi].PERGRP_ADRB.BOUND_BEG ; Get LA of GRP's start
PROC_GRPS_NEXTSEG2:
	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

; If this segment is skippable, do so

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 test	 AGROUP:[esi].PERSEG_FLAG,@PERSEG_SKIP ; Izit skippable?
	 jnz	 near ptr PROC_GRPS_LOOPSEG2 ; Jump if so

; Calculate and save the offset of this segment in its group.

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_ADRB.BOUND_BEG ; Get LA of SEG's start
	 sub	 eax,edx	; Less LA of GRP's start
;;;;;;;; UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 AGROUP:[esi].PERSEG_GRPOFF,eax ; Save for later use

; If this is a 16-bit non-absolute segment, ensure it doesn't end above 64KB

;;;;;;;; UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 ebx,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of segment name SYM_STR

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 mov	 al,AGROUP:[ebx].SYM_FLAG.LO ; Get the ACBP byte

	 test	 al,@SYMFL_P	; Izit a 32-bitter?
	 jnz	 short PROC_GRPS_LOOPSEG2 ; Jump if so

	 and	 al,@SYMFL_A	; Isolate the alignment type
	 shr	 al,$SYMFL_A	; Shift to low-order

	 cmp	 al,@ACBP_A_ABS ; Izit absolute?
	 je	 short PROC_GRPS_LOOPSEG2 ; Jump if so

;;;;;;;; UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_ADRB.BOUND_NXT ; Get LA of SEG's end
	 sub	 eax,edx	; Less LA of GRP's start
	 inc	 eax		; Plus one to get length

	 cmp	 eax,@CON64KB	; Duzit end above 64KB?
	 jbe	 short @F	; Jump if not

	 push	 dword ptr (offset PGROUP:IWF_GRPBIG) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_GRPBIG	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for USE16 segment in group ending > 64KB
	 jc	 short PROC_GRPS_ERR ; Jump if it's fatal
@@:
PROC_GRPS_LOOPSEG2:
;;;;;;;; UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 esi,AGROUP:[esi].PERSEG_GRPLNK ; Get LA of next segment in group

	 and	 esi,esi	; Is this the last one?
	 jnz	 short PROC_GRPS_NEXTSEG2 ; Jump if not

; Finished with this group

PROC_GRPS_LOOPGRP:
	 add	 edi,type PERGRP_STR ; Skip to next entry

	 jmp	 PROC_GRPS_NEXTGRP ; Go around again


; Now that we have determined the base of all groups we need to
; adjust upwards various offsets which are based in a group
; by the difference between the start of the segment and the
; group's 64KB frame.

PROC_GRPS_DONE:


; Trundle through LINNUM records looking for ones which are group based

	 mov	 edi,LMB_LINNUM.LMB_CURB.BOUND_BEG ; Get LA of starting address
PROC_GRPS_NEXTLIN:
	 cmp	 edi,LMB_LINNUM.LMB_CURB.BOUND_NXT ; Are we done yet?
	 je	 short PROC_GRPS_ENDLIN ; Jump if so

	 UNCURB  edi,LINNUM	; Ensure within current bounds
	 push	 AGROUP:[edi].LINNUM_PPERGRP ; Pass LA of group (PERGRP_STR)
	 push	 AGROUP:[edi].LINNUM_PPERSEG ; ...	  segment (PERSEG_STR)
	 call	 GRPSEG_DIF	; Process group segment differences
				; Return with EAX = difference
;;;;;;;; UNCURB  edi,LINNUM	; Ensure within current bounds
	 add	 AGROUP:[edi].LINNUM_NUMOFF,eax ; Add into offset
PROC_GRPS_LOOPLIN:
	 add	 edi,type LINNUM_STR ; Skip to next entry

	 jmp	 PROC_GRPS_NEXTLIN ; Go around again

PROC_GRPS_ENDLIN:
	 clc			; Mark as successful

	 jmp	 short PROC_GRPS_EXIT ; Join common exit code

PROC_GRPS_ERR:
	 stc			; Mark as in error
PROC_GRPS_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_GRPS endp			; End PROC_GRPS procedure
	 NPPROC  GRPSEG_DIF -- Process Group/Segment Differences
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process group/segment differences

On exit:

EAX	 =	 difference

|

GRPSEG_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
GRPSEG_SEG dd	 ?		; LA of segment (PERSEG_STR) (0=none)
GRPSEG_GRP dd	 ?		; ...	group	(PERGRP_STR) (0=none)

GRPSEG_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx>		; Save register

	 mov	 eax,[ebp].GRPSEG_GRP ; Get LA of group (PERGRP_STR) (0=none)

	 cmp	 eax,0		; Izit undefined?
	 je	 short GRPSEG_DIF_EXIT ; Jump if so (note EAX=0)

	 UNCURB  eax,PERGRP	; Ensure within current bounds
	 mov	 ebx,AGROUP:[eax].PERGRP_ADRB.BOUND_BEG ; Get starting address
	 and	 ebx,not (16-1) ; Round down to para boundary

	 mov	 eax,[ebp].GRPSEG_SEG ; Get LA of segment (PERSEG_STR) (0=none)

	 cmp	 eax,0		; Izit undefined?
	 je	 short GRPSEG_DIF_EXIT ; Jump if so (note EAX=0)

	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_ADRB.BOUND_BEG ; Get starting address
	 sub	 eax,ebx	; Subtract to get difference
GRPSEG_DIF_EXIT:
	 REGREST <ebx>		; Restore

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GRPSEG_DIF endp 		; End GRPSEG_DIF procedure
	 NPPROC  IWF_GRPBIG -- Ignore/Warn/Fail On 16-Bit Segment in Group Ending Above 64KB
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail on 16-bit segment in group ending above 64KB.

On entry:

EBX	 =	 LA of segment name SYM_STR
EDI	 =	 PERGRP_STR

|

	 pushad 		; Save registers

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPBIG) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the segment name

	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPBIG1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the group name

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 eax,AGROUP:[edi].PERGRP_GRPSYM ; Get LA of group name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPBIG2) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_GRPBIG endp 		; End IWF_GRPBIG procedure
	 NPPROC  IWF_GRPMIX -- Ignore/Warn/Fail On Mixed Absolute And Relocatable Segments
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail on mixed absolute and relocatable segments.

On entry:

EDI	 =	 PERGRP_STR

|

	 pushad 		; Save registers

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPMIX) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the group name

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 eax,AGROUP:[edi].PERGRP_GRPSYM ; Get LA of group name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPMIX1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Trundle through this group's segments, displaying each segment name
; and the name of the last file which grouped this segment

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 esi,AGROUP:[edi].PERGRP_GRPLNK ; Get LA of first segment (PERSEG_STR)
IWF_GRPMIX_NEXT:

; Display the segment name

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPMIX2) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; Display the last .OBJ which grouped this segment

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_GRPMIX3) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_GRPOBJ ; Get LA of last .OBJ which
				; grouped this segment (PEROBJ_STR)
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

;;;;;;;; UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 esi,AGROUP:[esi].PERSEG_GRPLNK ; Get LA of next segment in group

	 and	 esi,esi	; Is this the last one?
	 jnz	 short IWF_GRPMIX_NEXT ; Jump if not

	 call	 U32_NEWLINE	; Goto a new line

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_GRPMIX endp 		; End IWF_GRPMIX procedure
	 NPPROC  IWF_ABSDIF -- Ignore/Warn/Fail On Differing Absolute Segment Bases
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail on differing absolute segment bases.

On entry:

ECX	 =	 incoming segment base
GRP_BASE =	 previous ...
ESI	 =	 LA of incoming segment's PERSEG_STR
GRP_PERSEG =	 LA of previous ...
EDI	 =	 PERGRP_STR

|

	 pushad 		; Save registers

; Format the incoming and previous segment's bases

	 push	 edi		; Save for a moment

	 mov	 eax,GRP_BASE	; Get the previous segment's base

	 lea	 edi,MSG_ABSDIF2 ; ES:EDI ==> format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 mov	 eax,ecx	; Get the incoming segment's base

	 lea	 edi,MSG_ABSDIF4 ; ES:EDI ==> format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 pop	 edi		; Restore

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the group name

	 UNCURB  edi,PERGRP	; Ensure within current bounds
	 mov	 eax,AGROUP:[edi].PERGRP_GRPSYM ; Get LA of group name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIF1) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the previous segment's name

	 mov	 eax,GRP_PERSEG ; Get LA of previous segment (PERSEG_STR)
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIFSEP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the previous segment's base

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIF2) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the last .OBJ which grouped the previous segment

	 mov	 eax,GRP_PERSEG ; Get LA of previous segment (PERSEG_STR)
	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_GRPOBJ ; Get LA of last .OBJ which
				; grouped the previous segment (PEROBJ_STR)
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIF3) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the incoming segment's name

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_SEGSYM ; Get LA of segment name (SYM_STR)
	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIFSEP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the incoming segment's base

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_ABSDIF4) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display the last .OBJ which grouped the incoming segment

	 UNCURB  esi,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[esi].PERSEG_GRPOBJ ; Get LA of last .OBJ which
				; grouped the incoming segment (PEROBJ_STR)
	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 push	 AGROUP:[eax].PEROBJ_PFID ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display (Count, Char[])

; If there's a THEADR record, display that, too

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present

	 call	 U32_NEWLINE	; Goto a new line

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_ABSDIF endp 		; End IWF_ABSDIF procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_GRP module
