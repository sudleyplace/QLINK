;' $Header:   P:/PVCS/MISC/QLINK/QLNK_STA.ASV   1.1   17 Jul 1997 12:36:52   BOB  $
	title	QLNK_STA -- QLINK Statistics
	page	58,122
	name	QLNK_STA

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
	 include DPMI.INC

	 include QLNK_COM.INC
	 include QLNK_SEG.INC
	 include QLNK_SYM.INC
.list

DATA	 segment		; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 ARG_FLAG:dword
	 include QLNK_ARG.INC

	 extrn	 LCL_FLAG:dword
	 include QLNK_LCL.INC

	 extrn	 LaDATA:dword
	 extrn	 ERRHNDL:word
	 extrn	 UNPAGE_ATTR:word
	 extrn	 NEXTSEG:word
	 extrn	 HIGHSEG:word

	 extrn	 LMBTAB_LEN:abs
	 extrn	 LMBTAB_ACC:tbyte
	 extrn	 LMBTAB_ACC_LEN:abs
	 extrn	 LMBIND_HSH:abs

	 extrn	 LMBNAM:dword
	 extrn	 MAXINI:dword

	 extrn	 LMB_TXTSTR:tbyte
	 extrn	 LMB_PERSEG:tbyte
	 extrn	 LMB_SYMBOL:tbyte
	 extrn	 LMB_SYMHSH:tbyte

	 extrn	 HASHPRIME:dword

	 public  LENACC,LENRND
LENACC	 dd	 0		; Length of accumulated data
LENRND	 dd	 0		; ...	    rounded data

COMMENT|

QLINK Statistics   mm/dd/yy   hh:mm:ss

Name		 Size	Rounded to 4KB
--------------------------------------
PEROBJ		n,nnn bytes   n,nnn KB


--------------------------------------
Subtotal	n,nnn bytes   n,nnn KB

DATA		n,nnn	      n,nnn KB


--------------------------------------
Grand Total	n,nnn bytes   n,nnn KB
Conventional  nnn,nnn

|

	 public  STA_HDR
STA_HDR  db	 'QLINK Statistics   mm/dd/yy   hh:mm:ss',CR,LF
	 db	 CR,LF
	 db	 'Name             Size   Rounded to 4KB',CR,LF
STA_SEP  db	 '--------------------------------------',CR,LF,EOS

	 public  STA_LIN
STA_LIN  db	 '                    '
STA_LIN_NAMLEN equ $-STA_LIN
STA_LIN_SIZ db	 '_ bytes       '
STA_LIN_RND db	 '_ KB'
STA_LIN_CLR equ  $-STA_LIN
	 db	 CR,LF
STA_LIN_LEN equ  $-STA_LIN

STA_TOT  db	 'Subtotal            '
STA_TOT_SIZ db	 '_ bytes       '
STA_TOT_RND db	 '_ KB'
	 db	 CR,LF,CR,LF,EOS

STA_GTOT db	 'Grand Total         '
STA_GTOT_SIZ db  '_ bytes       '
STA_GTOT_RND db  '_ KB'
	 db	 CR,LF,EOS

STA_CNV  db	 'Conventional        '
STA_CNV_SIZ db	 '_ bytes'
	 db	 CR,LF,EOS

DATA	 ends			; End DATA segment


CODE	 segment		; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 U32_DISP_MSG:near
	 extrn	 U32_DISP_MSGL:near
	 extrn	 CB_TERM:near
	 extrn	 DD2DEC:near

	 NPPROC  DISP_STAT -- Display Statistics
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display statistics

|

	 pushad 		; Save registers

	 test	 ARG_FLAG,@ARG_DBGSTA ; Are we in a debuggin' mood?
	 jz	 near ptr DISP_STAT_EXIT ; Jump if not

	 test	 LCL_FLAG,@LCL_QUIT ; Izit quittin' time?
	 jnz	 near ptr DISP_STAT_EXIT ; Jump if so

; If the error file is open, send all output there; otherwise, send to console

	 cmp	 ERRHNDL,-1	; Izit invalid?
	 je	 short @F	; Jump if so

	 or	 LCL_FLAG,@LCL_ERROUT ; Mark as writing to map file
@@:

; Display the header

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_HDR) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display each fixed LMB

	 mov	 ecx,LMBTAB_LEN ; Get # accumulated and re-initialized LMBs
	 xor	 ebx,ebx	; Initialize index to LMBTAB_ACC
	 xor	 edx,edx	; ...		      LMBNAM
DISP_STAT_NEXTFIX:
	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 push	 ecx		; Save for a moment

	 cmp	 edx,LMBTAB_ACC_LEN ; Izit at start re-initialized LMBs?
	 jne	 short @F	; Jump if not

; Display separator

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_SEP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message
@@:

; Copy the LMB name into the line

	 lea	 edi,STA_LIN	; Get offset in DGROUP of line
	 add	 edi,LaDATA	; Plus LA of DGROUP

	 mov	 esi,LMBNAM[edx*(type LMBNAM)] ; Get offset in DGROUP of name
				; in (Count, Char[]) format
	 add	 esi,LaDATA	; Plus LA of DGROUP

	 lods	 AGROUP:[esi].LO ; Get the name length

	 cmp	 al,STA_LIN_NAMLEN ; Izit too long?
	 jbe	 short @F	; Jump if not

	 mov	 al,STA_LIN_NAMLEN ; Use maximum length
@@:
	 movzx	 ecx,al 	; Copy to count register
     rep movs	 AGROUP:[edi].LO,AGROUP:[esi].LO

; Format the LMB length rounded up to 1KB boundary

	 cmp	 edx,LMBTAB_ACC_LEN ; Izit into re-initialized LMBs?
	 jb	 short DISP_STAT_FIX1 ; Jump if not

; Calculate index into MAXINI of EDX-(LMBTAB_ACC_LEN*(type MAXINI))

	 mov	 eax,edx	; Copy current index
	 sub	 eax,LMBTAB_ACC_LEN ; Less amount not in MAXINI
	 mov	 eax,MAXINI[eax*(type MAXINI)] ; Get maximum length

	 jmp	 short DISP_STAT_FIX1_COM ; Join common code

DISP_STAT_FIX1:
	 mov	 eax,LMBTAB_ACC[ebx].LMB_CURB.BOUND_NXT ; Get next address
	 sub	 eax,LMBTAB_ACC[ebx].LMB_CURB.BOUND_BEG ; Less starting address

; If this is LMB_SYMHSH, the length is calculated differently as that
; array is written into sparsely.  In that case, we trundle through the
; Page Attributes.

	 cmp	 edx,LMBIND_HSH ; Izit LMB_SYMHSH?
	 jne	 short DISP_STAT_FIX1_COM ; Jump if not

	 REGSAVE <ebx,edx>	; Save for a moment

	 mov	 esi,LMB_SYMHSH.LMB_HNDL ; Get the block handle
	 mov	 ecx,HASHPRIME	; Get maximum # buckets
	 add	 ecx,@CON1KB-1	; Round up to 1KB boundary
	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 xor	 ebx,ebx	; Initialize starting offset
	 xor	 edx,edx	; Initialize byte count
DISP_STAT_FIX1_NEXTPAGE:
	 REGSAVE <ecx,edx>	; Save for a moment

	 lea	 edx,UNPAGE_ATTR ; ES:EDX ==> page attributes
	 add	 edx,LaDATA	; Plus LA of DGROUP
	 mov	 ecx,1		; Get attributes for one page

	 DPMICALL @DPMI_GPGATTR ; Get Page Attributes
	 REGREST <edx,ecx>	; Restore
	 jc	 short @F	; Jump if something went wrong???

	 mov	 ax,UNPAGE_ATTR ; Get the page attributes
	 and	 ax,@SPATTR_TYP ; Isolate the type bits
	 shr	 ax,$SPATTR_TYP ; Shift to low order

	 cmp	 ax,@SPTYP_UNC	; Izit still uncommitted?
	 je	 short @F	; Jump if so

	 add	 edx,@CON4KB	; Count in another page
@@:
	 add	 ebx,@CON4KB	; Skip to the next block

	 loop	 DISP_STAT_FIX1_NEXTPAGE ; Jump if more pages to check

	 mov	 eax,edx	; Copy to return register

	 REGREST <edx,ebx>	; Restore
DISP_STAT_FIX1_COM:
	 add	 LENACC,eax	; Accumulate it

	 lea	 edi,STA_LIN_SIZ ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the length in kilobytes rounded up to 4KB boundary

	 add	 eax,@CON4KB-1	; Round up to 1KB boundary
	 shr	 eax,12-0	; Convert from bytes to 4KB
	 shl	 eax,12-10	; Convert from 4KB to 1KB
	 add	 LENRND,eax	; Accumulate it

	 lea	 edi,STA_LIN_RND ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the line

	 push	 STA_LIN_LEN	; Pass the length in bytes
	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_LIN) ; Pass offset of message
	 call	 U32_DISP_MSGL	; Display the message

; Clear the line for the next time

	 lea	 edi,STA_LIN	; Get offset in DGROUP of line
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 mov	 ecx,STA_LIN_CLR ; # bytes in the line
	 mov	 al,' '         ; Set to this value
     rep stos	 AGROUP:[edi].LO ; Clear the line

; Skip to next entry

	 add	 ebx,type LMB_STR ; Skip to next LMBTAB_ACC entry
	 inc	 edx		; ...		 LMBNAM ...

	 pop	 ecx		; Restore

;;;;;;;; loop	 DISP_STAT_NEXTFIX ; Jump if more accumulated LMBs
	 dec	 ecx		; Count one out
	 jnz	 near ptr DISP_STAT_NEXTFIX ; Jump if more accumulated LMBs

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

; Display separator

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_SEP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Format total figures

	 mov	 eax,LENACC	; Get actual length in bytes

	 lea	 edi,STA_TOT_SIZ ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the length in kilobytes rounded up to 4KB boundary

	 mov	 eax,LENRND	; Get rounded length

	 lea	 edi,STA_TOT_RND ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the Total line

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_TOT) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Display per segment sizes

	 mov	 ebx,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get starting LA
DISP_STAT_NEXTSEG:
	 cmp	 ebx,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Are we at the end?
	 je	 near ptr DISP_STAT_ENDSEG ; Jump if so

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

; Copy the SEG name into the line

	 lea	 edi,STA_LIN	; Get offset in DGROUP of line
	 add	 edi,LaDATA	; Plus LA of DGROUP

	 UNCURB  ebx,PERSEG	; Ensure within current bounds
	 mov	 esi,AGROUP:[ebx].PERSEG_SEGSYM ; Get LA of symbol (SYM_STR)
	 UNCURB  esi,SYMBOL	; Ensure within current bounds
	 mov	 esi,AGROUP:[esi].SYM_PNAM ; Get LA of symbol (Count, Char[])
	 UNCURB  esi,TXTSTR	; Ensure within current bounds
	 lods	 AGROUP:[esi].LO ; Get the length of the symbol

	 cmp	 al,STA_LIN_NAMLEN ; Izit too long?
	 jbe	 short @F	; Jump if not

	 mov	 al,STA_LIN_NAMLEN ; Use maximum length
@@:
	 movzx	 ecx,al 	; Copy to count register
     rep movs	 AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy the segment name

; Format the SEG length rounded up to 1KB boundary

	 mov	 eax,AGROUP:[ebx].PERSEG_LMB.LMB_CURB.BOUND_NXT ; Get next address
	 sub	 eax,AGROUP:[ebx].PERSEG_LMB.LMB_CURB.BOUND_BEG ; Less starting address

	 add	 LENACC,eax	; Accumulate it

	 lea	 edi,STA_LIN_SIZ ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the length in kilobytes rounded up to 4KB boundary

	 add	 eax,@CON4KB-1	; Round up to 1KB boundary
	 shr	 eax,12-0	; Convert from bytes to 4KB
	 shl	 eax,12-10	; Convert from 4KB to 1KB
	 add	 LENRND,eax	; Accumulate it

	 lea	 edi,STA_LIN_RND ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the line

	 push	 STA_LIN_LEN	; Pass the length in bytes
	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_LIN) ; Pass offset of message
	 call	 U32_DISP_MSGL	; Display the message

; Clear the line for the next time

	 lea	 edi,STA_LIN	; Get offset in DGROUP of line
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 mov	 ecx,STA_LIN_CLR ; # bytes in the line
	 mov	 al,' '         ; Set to this value
     rep stos	 AGROUP:[edi].LO ; Clear the line

; Skip to next entry

	 add	 ebx,type PERSEG_STR ; Skip to next PERSEG_STR entry

	 jmp	 DISP_STAT_NEXTSEG ; Go around again

DISP_STAT_ENDSEG:
	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

; Display separator

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_SEP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Format Grand Total figures

	 mov	 eax,LENACC	; Get actual length in bytes

	 lea	 edi,STA_GTOT_SIZ ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the length in kilobytes rounded up to 4KB boundary

	 mov	 eax,LENRND	; Get rounded length

	 lea	 edi,STA_GTOT_RND ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the Grand Total line

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_GTOT) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

; Format the conventional memory used

	 movzx	 eax,HIGHSEG	; Get highest used segment

	 cmp	 ax,NEXTSEG	; Izit above the nxt available segment?
	 jae	 short @F	; Jump if so

	 mov	 ax,NEXTSEG	; Use next available segment
@@:
	 sub	 ax,seg PGROUP	; Less the lowest segment
	 add	 ax,10h 	; Plus size of PSP in paras
	 shl	 eax,4-0	; Convert from paras to bytes

	 lea	 edi,STA_CNV_SIZ ; Get offset in DGROUP of format area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 push	 @DEC_COMMA	; Insert commas
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI

; Display the conventional memory line

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:STA_CNV) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message








	 and	 LCL_FLAG,not @LCL_ERROUT ; Mark as no longer writing to error file
DISP_STAT_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STAT endp			; End DISP_STAT procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_STA module
