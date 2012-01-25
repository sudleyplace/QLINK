;' $Header:   P:/PVCS/MISC/QLINK/QLNK_MSC.ASV   1.1   17 Jul 1997 12:36:48   BOB  $
	title	QLNK_MSC -- QLINK Miscellaneous Routines
	page	58,122
	name	QLNK_MSC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-7 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, August, 1994.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include PTR.INC
	include ASCII.INC
	include ALLMEM.INC
	include BITFLAGS.INC
	include DOSCALL.INC
	include DPMI.INC
	include CPUFLAGS.INC

	include QLNK_COM.INC
	include QLNK_IWF.INC
	include QLNK_SEG.INC
.list

DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	ERRCNT:dword
	extrn	NUMBERS_HI:byte
	extrn	DEF32:byte
	extrn	ERRHNDL:word
	extrn	MAPHNDL:word
	extrn	MAPOUT_SEG:word
	extrn	LaDATA:dword
	extrn	WORKAREA:byte

	public	LaMAPOUT,LaMAPOUTZ
LaMAPOUT dd	?		; LA of start of MAPOUT buffer
LaMAPOUTZ dd	?		; LA of end ...

	public	IWFCNT
IWFCNT	dd	3 dup (0)	; Ignore/Warn/Fail counters

	public	VMCREGS
VMCREGS VMC_STR <>		; VM call registers

	public	MSG_IWFHDR
MSG_IWFHDR db	@PRODNAME,' error summary:  ',EOS
MSG_IWFIGN db	' ignores'
MSG_IWFIGN_LEN equ $-MSG_IWFIGN ; Length of ...
MSG_IWFWRN db	' warnings'
MSG_IWFWRN_LEN equ $-MSG_IWFWRN ; Length of ...
MSG_IWFFAL db	' failures'
MSG_IWFFAL_LEN equ $-MSG_IWFFAL ; Length of ...

	public	MSG_IWFSEP
MSG_IWFSEP db	', ',EOS        ; Separator between messages

	public	MSG_WARN,MSG_FAIL
MSG_WARN db	'ออ> WARN:  ',EOS
MSG_FAIL db	'ออ> FAIL:  ',EOS

	public	IWF_CHK
IWF_CHK db	?		; @IWF_xxx values

DATA	ends			; End DATA segment


CODE	segment use32 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	CSEL_4GB:word
	extrn	CSEL_DATA:word

	extrn	U32_DISP_MSG:near
	extrn	U32_DISP_MSGL:near
	extrn	U32_NEWLINE:near
	extrn	CB_TERM:near

	NPPROC	DISP_ASCIIZ -- Display ASCIIZ String
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ASCIIZ string.

This routine is bimodal.

On entry:

DS:ESI	==>	ASCIIZ string to display

|

	 REGSAVE <eax,edx,esi>	; Save registers
@@:
	 lods	 ds:[esi].LO	; Get next character

	 cmp	 al,0		; Izit EOL?
	 je	 short @F	; Jump if so

	 mov	 dl,al		; Copy to output register
	 DOSCALL @DCONIO	; Output character in DL

	 jmp	 short @B	; Go around again

@@:
	 REGREST <esi,edx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ASCIIZ endp		; End DISP_ASCIIZ procedure
	 NPPROC  DG2HEX -- Convert Low-order Digit in AL to Hex At ES:EDI
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,1		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DG2HEX	 endp			; End DG2HEX procedure
	 NPPROC  DB2HEX -- Convert AL to Hex At ES:EDI
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,2		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Convert AX to Hex At ES:EDI
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,4		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  D52HEX -- Convert EAX to Hex At ES:EDI
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,5		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D52HEX	 endp			; End D52HEX procedure
	 NPPROC  DD2HEX -- Convert EAX to Hex At ES:EDI
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,8		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	 endp			; End DD2HEX procedure
	 NPPROC  BIN2HEX_SUB
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,ebx,edx>	; Save registers

	 pushfd 		; Save flags
	 std			; Store backwards

	 mov	 edx,eax	; Copy to secondary register
	 lea	 ebx,NUMBERS_HI ; XLAT table
	 add	 edi,ecx	; Skip to the end+1

	 push	 edi		; Save to return

	 dec	 edi		; Now the last digit
BIN2HEX_MORE:
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate low-order digit
	 xlat	 NUMBERS_HI[ebx] ; Convert to ASCII hex
	 stos	 es:[edi].LO	; Save in output stream

	 shr	 edx,4		; Shift next digit down to low-order

	 loop	 BIN2HEX_MORE	; Jump if more digits to format

	 pop	 edi		; Restore

	 popfd			; Restore flags

	 REGREST <edx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure
	 NPPROC  GET_INDEX -- Get One- Or Two-Byte Index
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Get one- or two-byte index

On entry:

DS:ESI	 ==>	 index

On exit:

CF	 =	 1 if index is zero
	 =	 0 if not
EAX	 =	 index
DS:ESI	 ==>	 (updated)

|

	 xor	 eax,eax	; Zero to use as dword
	 lods	 ds:[esi].LO	; Get the next byte

	 btr	 eax,$BIT7	; Izit two-byte form?
	 jnc	 short GET_INDEX_EXIT ; Jump if not

	 mov	 ah,al		; Copy to high-order byte

	 lods	 ds:[esi].LO	; Get the next byte
GET_INDEX_EXIT:
	 sub	 eax,1		; Convert to origin-0
				; Return with CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_INDEX endp			; End GET_INDEX procedure
	 NPPROC  COPY_CNTCHR -- Copy (Count, Char[])
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Copy name from (Count, Char[]) to destination.

On entry:

ES:EDI	 ==>	 destination

On exit:

ES:EDI	 ==>	 (updated)

|

COPYCC_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
COPYCC_SRCLA dd  ?		; Source ...

COPYCC_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi>	; Save registers

	 mov	 esi,[ebp].COPYCC_SRCLA ; Get source linear address
	 movzx	 ecx,AGROUP:[esi].LO ; Get the Count byte
	 inc	 ecx		; Include it into the count
     rep movs	 AGROUP:[edi].LO,AGROUP:[esi].LO

	 REGREST <esi,ecx>	; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_CNTCHR endp		; End COPY_CNTCHR procedure
	 NPPROC  DISP_CNTCHR -- Display A Name in (Count, Char[]) Format
	 assume  ds:nothing,es:nothing,fs:nothing,ss:nothing,ss:nothing
COMMENT|

Display a name in (Count, Char[]) format.

|

DCC_STR  struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DCC_OFF  dd	 ?		; Offset in AGROUP of (Count, Char[])

DCC_STR  ends

	 push	 ebp		 ; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,edx,ds> ; Save registers

	 mov	 eax,[ebp].DCC_OFF ; Get the offset in AGROUP

	 cmp	 eax,0		; Izit initialized?
	 je	 short DISP_CNTCHR_EXIT ; Jump if not

	 cmp	 eax,-1 	; Izit initialized?
	 je	 short DISP_CNTCHR_EXIT ; Jump if not

	 mov	 ds,CSEL_4GB	; Get AGROUP data selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 ecx,AGROUP:[eax].LO ; Get the length byte
	 lea	 edx,AGROUP:[eax+1] ; Skip over it
	 call	 WRITE_OUT	; Write DS:EDX for ECX bytes to output file
				; Return with CF significant
DISP_CNTCHR_EXIT:
	 REGREST <ds,edx,ecx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CNTCHR endp		; End DISP_CNTCHR procedure
	 NPPROC  WRITE_OUT -- Write To Output File
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write to console and/or output file

On entry:

ECX	 =	 # bytes to write
DS:EDX	 ==>	 text to write out

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ebx,fs>	; Save registers

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

; If we're writing to the map file, don't send to the console

	 mov	 bx,MAPHNDL	; Get map file handle

	 cmp	 bx,-1		; Izit invalid?
	 je	 short @F	; Jump if so

	 test	 LCL_FLAG,@LCL_MAPOUT ; Writing to map file?
	 jnz	 short WRITE_OUT_MAP ; Jump if so
@@:

; If we're writing to the error file, don't send to the console

	 mov	 bx,ERRHNDL	; Get error file handle

	 cmp	 bx,-1		; Izit invalid?
	 je	 short @F	; Jump if so

	 test	 LCL_FLAG,@LCL_ERROUT ; Writing to error file?
	 jnz	 short WRITE_OUT_NOW ; Jump if so
@@:
	 mov	 bx,@STD_OUT	; Display to standard output
	 DOSCALL @WRITF2	; Display the FID
	 jc	 short WRITE_OUT_EXIT ; Jump if something went wrong (note CF=1)

	 cmp	 eax,ecx	; Did everything make it?
	 jb	 short WRITE_OUT_EXIT ; Jump if not (note CF=1)

	 mov	 bx,ERRHNDL	; Get error file handle

	 cmp	 bx,-1		; Izit invalid?
	 je	 short WRITE_OUT_EXIT ; Jump if so

	 cmp	 ERRCNT,0	; Writing to error file?
	 je	 short WRITE_OUT_EXIT ; Jump if not
WRITE_OUT_NOW:
	 DOSCALL @WRITF2	; Write out to error file
	 jc	 short WRITE_OUT_EXIT ; Jump if something went wrong (note CF=1)

	 cmp	 eax,ecx	; Did everything make it?
	 jb	 short WRITE_OUT_EXIT ; Jump if not (note CF=1)

; Duplicate the file handle and close the duplicate to force
; the data to disk

	 DOSCALL @FHCOPY	; Copy file handle BX to AX
	 jc	 short WRITE_OUT_EXIT ; Jump if that didn't work (note CF=1)

	 mov	 bx,ax		; Copy handle register
	 DOSCALL @CLOSF2	; Close the secondary file
				; Return with CF significant
	 jmp	 short WRITE_OUT_EXIT ; Join common exit code

WRITE_OUT_MAP:
	 call	 WRITE_MAPOUT	; Buffer and write out when full
				; Return with CF significant
WRITE_OUT_EXIT:
	 REGREST <fs,ebx,eax>	; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_OUT endp			; End WRITE_OUT procedure
	 NPPROC  WRITE_MAPOUT -- Buffer MAPOUT, Write Out When Full
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Buffer MAPOUT output, write out when full

On entry:

BX	 =	 MAPHNDL
ECX	 =	 # bytes to write
DS:EDX	 ==>	 text to write out

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers
	 REGSAVE <es>		; ...

	 mov	 es,CSEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

; Copy as much of the data to the MAPOUT buffer as will fit

	 mov	 esi,edx	; DS:ESI ==> source
	 mov	 edi,LaMAPOUT	; Get next address of MAPOUT buffer
	 lea	 eax,AGROUP:[edi+ecx] ; Point to end of copy

; Ensure this copy doesn't exceed the length of the buffer

	 sub	 eax,LaMAPOUTZ	; Izit too large?
	 jbe	 short @F	; Jump if not

	 sub	 ecx,eax	; Subtract to get remaining # bytes to copy
     rep movs	 AGROUP:[edi].LO,ds:[esi].LO ; Copy what will fit
	 mov	 LaMAPOUT,edi	; Save for next time
	 mov	 ecx,eax	; Restore remaining length

	 call	 WRITE_MAPBUF	; Write out the MAPOUT buffer
				; resetting LaMAPOUT in the process
	 jc	 short WRITE_MAPOUT_EXIT ; Jump if something went wrong (note CF=1)
@@:
	 mov	 edi,LaMAPOUT	; Get next address of MAPOUT buffer
     rep movs	 AGROUP:[edi].LO,ds:[esi].LO ; Copy data to buffer
	 mov	 LaMAPOUT,edi	; Save for next time

	 clc			; Mark as successful
WRITE_MAPOUT_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_MAPOUT endp		; End WRITE_MAPOUT procedure
	 NPPROC  WRITE_MAPBUF -- Write Out The MAPOUT Buffer
	 assume  ds:nothing,es:AGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Write out a the MAPOUT buffer

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 movzx	 edx,MAPOUT_SEG ; Get segment of MAPOUT buffer
	 shl	 edx,4-0	; Convert from paras to bytes
	 mov	 ecx,edx	; Copy starting address
	 xchg	 ecx,LaMAPOUT	; Swap with next available address
	 sub	 ecx,edx	; Subtract to get length

; Setup registers for VM call

	 shr	 edx,4-0	; Convert from bytes to paras
	 mov	 VMCREGS.VMC_DS,dx	; Save as DS
	 mov	 VMCREGS.VMC_EDX.ELO,0	; ...	  DX
	 mov	 VMCREGS.VMC_ECX.ELO,cx ; ...	  CX
	 mov	 ax,MAPHNDL	; Get map file handle
	 mov	 VMCREGS.VMC_EBX.ELO,ax ; ...	  BX
	 mov	 VMCREGS.VMC_EAX.ELO.HI,@WRITF2 ; Save as AH

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; Get offset in DGROUP of VMC register structure
	 add	 edi,LaDATA	; Plus LA of DGROUP
				; ES:EDI ==> VMC register structure
	 DPMICALL @DPMI_SIMVMI	; Request DPMI service
	 jc	 short WRITE_MAPBUF_EXIT ; Jump if something went wrong (note CF=1)

	 test	 VMCREGS.VMC_FL,mask $CF ; Did DOS like that value?
	 stc			; Assume it didn't
	 jnz	 short WRITE_MAPBUF_EXIT ; Jump if something went wrong (note CF=1)

	 cmp	 VMCREGS.VMC_EAX.ELO,cx ; Dis everything make it out?
				; Return with CF significant
WRITE_MAPBUF_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_MAPBUF endp		; End WRITE_MAPBUF procedure
	 NPPROC  GET_OFF32 -- Get D/Word Depending Upon DEF32
	 assume  ds:AGROUP,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Get d/word depending upon DEF32.

On entry:

DS:ESI	 ==>	 d/word

On exit:

EAX	 =	 d/word value
DS:ESI	 ==>	 (updated)

|

	 movzx	 eax,AGROUP:[esi].ELO ; Get the public offset as a word

	 cmp	 DEF32,1	; Izit a 32-bit record?
	 jne	 short @F	; Jump if not

	 mov	 eax,AGROUP:[esi].EDD ; Get the public offset as a dword
	 add	 esi,2		; Skip over half of dword field
@@:
	 add	 esi,2		; Skip over public offset field

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_OFF32 endp			; End GET_OFF32 procedure
	 NPPROC  DD2DEC -- Convert EAX To Decimal At ES:EDI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert EAX to decimal at ES:EDI.

On entry:

EAX	 =	 # to convert
ES:EDI	 ==>	 units digit of save area

On exit:

ES:EDI	 ==>	 next available byte

|

DD2DEC_STR struc

DD2DEC_FVEC df	 ?		; Address of caller's buffer if left-justified
DD2DEC_BUF db	 13 dup (?)	; Local buffer big enough to handle
				; 4G with commas (4,xxx,xxx,xxx)
	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DD2DEC_FLG dd	 ?		; Flags

DD2DEC_STR ends

@DD2DEC_SIZE equ (size DD2DEC_STR)-3*4 ; Size of local stack in bytes

	 push	 ebp		; Prepare to address the stack
	 sub	 esp,@DD2DEC_SIZE ; Make room on stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushfd 		; Save flags

	 REGSAVE <eax,ebx,ecx,edx,esi,es> ; Save registers

	 test	 [ebp].DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	 jz	 short @F	; Not this time

	 mov	 [ebp].DD2DEC_FVEC.FOFF,edi ; Save address of caller's buffer
	 mov	 [ebp].DD2DEC_FVEC.FSEL,es ; ...

	 push	 ss		; Setup ES for string operations
	 pop	 es
	 assume  es:nothing	; Tell the assembler about it

	 lea	 edi,[ebp].DD2DEC_BUF[(size DD2DEC_BUF)-1] ; ES:DI ==> buffer end
@@:
	 xor	 ecx,ecx	; Initialize byte count
	 xor	 edx,edx	; ...	     high-order word of number
	 std			; String ops backwards
DD2DEC_COMMA:
	 xor	 esi,esi	; Initialize comma count
DD2DEC_NEXT:
	 call	 DD2DEC_DIG	; Split off another decimal digit from (EDX,EAX)
				; (EDX,EAX) = quotient
				; BL	  = remainder
	 xchg	 al,bl		; Swap to display AL
	 add	 al,'0'         ; Convert to decimal ASCII
	 stos	 es:[edi].LO	; Save in local buffer
	 inc	 ecx		; Account for it
	 mov	 al,bl		; Restore

	 mov	 ebx,edx	; Copy high-order of quotient
	 or	 ebx,eax	; Check the remainder
	 jz	 short DD2DEC_END ; Jump if that's all

	 test	 [ebp].DD2DEC_FLG,@DEC_COMMA ; Comma insertion requested?
	 jz	 short DD2DEC_NEXT ; Not this time

	 inc	 esi		; Account for it

	 cmp	 esi,3		; Izit time to comma-insert?
	 jne	 short DD2DEC_NEXT ; Not as yet

	 push	 eax		; Save for a moment
	 mov	 al,@NATL_THOU	; Separator
	 stos	 es:[edi].LO	; Save in buffer
	 pop	 eax		; Restore

	 inc	 ecx		; Account for it

	 jmp	 DD2DEC_COMMA	; Go around again

DD2DEC_END:
	 lea	 esi,[edi+1]	; SS:ESI ==> start of buffer
	 add	 edi,ecx	; Skip to next available byte in
				; case not left-justified

	 test	 [ebp].DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	 jz	 short DD2DEC_XLJ ; Not this time

	 les	 edi,[ebp].DD2DEC_FVEC ; ES:EDI ==> caller's buffer
	 assume  es:nothing	; Tell the assembler about it

	 cld			; String ops forwards
     rep movs	 es:[edi].LO,ss:[esi].LO ; Move into caller's data area
DD2DEC_XLJ:
	 REGREST <es,esi,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popfd			; Restore flags

	 add	 esp,@DD2DEC_SIZE ; Remove room from stack
	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2DEC	 endp			; End DD2DEC procedure
	 NPPROC  DD2DEC_DIG -- Subroutine to DD2DEC
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Divide by 10

On entry:

(EDX,EAX) =	 dividend

On exit:

(EDX,EAX) =	 quotient
BL	 =	 remainder

|

	 REGSAVE <ecx>		; Save register

	 mov	 ecx,10 	; Divisor

	 push	 eax		; Save low-order word

	 mov	 eax,edx	; Copy high-order to low-order word
	 xor	 edx,edx	; Zero high-order word
	 div	 ecx		; Strip off a decimal digit
				; EAX = quotient
				; EDX = remainder < 10
	 mov	 ebx,eax	; Save quotient as high-order result

	 pop	 eax		; Restore low-order word

	 div	 ecx		; Strip off a decimal digit
				; EAX = quotient
				; EDX = remainder < 10
	 xchg	 edx,ebx	; Swap new high-order result and remainder

	 REGREST <ecx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2DEC_DIG endp 		; End DD2DEC_DIG procedure
	 NPPROC  IWF_TEST -- Check On IWF Testing
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check on IWF testing.

On exit:

CF	 =	 0 if we're to continue processing
	 =	 1 if this event is fatal

|

IWF_STR  struc

IWF_EBP  dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
IWF_BITOFF dd	 ?		; Get bit offset in IW?_FLAG
IWF_VAL  dd	 ?		; Value of IW?_FLAG
IWF_ACT  dd	 ?		; Action routine to call on Warn/Fail

IWF_STR  ends

	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx>	; Save registers

	 mov	 ecx,[ebp].IWF_BITOFF ; Get bit offset in IW?_FLAG
	 mov	 eax,@IWF_ACT	; Get action flags
	 shl	 eax,cl 	; Shift into position

	 test	 eax,[ebp].IWF_VAL ; Should we take some action?
	 mov	 IWF_CHK,@IWF_IGN ; Assume we're to ignore
	 jz	 short IWF_TEST_EXIT ; Jump if not

	 inc	 ERRCNT 	; Mark as writing to error file

; See if we should display warning or failing message

;;;;;;;; mov	 ecx,[ebp].IWF_BITOFF ; Get bit offset in IW?_FLAG
	 mov	 eax,@IWF_WRN	; Get warn flags
	 shl	 eax,cl 	; Shift into position

	 test	 eax,[ebp].IWF_VAL ; Should we warn?
	 lea	 eax,DGROUP:MSG_WARN ; Assume so
	 mov	 IWF_CHK,@IWF_WRN ; Assume we're to warn
	 jnz	 short @F	; Jump if so (note CF=0)

	 lea	 eax,DGROUP:MSG_FAIL ; Tell 'em we're failing
	 mov	 IWF_CHK,@IWF_FAL ; Mark as failing
@@:
	 push	 fs		; Pass DGROUP segment
	 push	 eax		; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message
IWF_TEST_EXIT:
	 movzx	 eax,IWF_CHK	; Get the type code (0, 1, 2)
	 inc	 IWFCNT[eax*(type IWFCNT)] ; Count in another Ignore, Warn, or Fail

	 REGREST <ecx,eax>	; Restore

	 cmp	 IWF_CHK,@IWF_IGN ; Are we ignoring this event?
	 je	 short @F	; Jump if so (note CF=0)

; Note we need to restore EBP to its original value in case it's used
; by the IWF_xxx routine.  This means we use ESP as a base register, so
; don't push anything else

	 mov	 ebp,[ebp].IWF_EBP ; Restore
	 call	 [esp].IWF_ACT	; Take appropriate action

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 cmp	 IWF_CHK,@IWF_WRN ; Are we warning this event?
	 je	 short @F	; Jump if so (note CF=0)

	 stc			; Mark as failing
@@:
	 pop	 ebp		; Restore

	 ret	 4+4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_TEST endp			; End IWF_TEST procedure
	 NPPROC  DISP_IWFCNT -- Display Ignore/Warn/Fail Counters
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Display Ignore/Warn/Fail counters

|

	 REGSAVE <eax>		; Save register

; If any of the counters is non-zero, display the header

	 mov	 eax,IWFCNT[@IWF_IGN*(type IWFCNT)] ; Get Ignore counter
	 or	 eax,IWFCNT[@IWF_WRN*(type IWFCNT)] ; Include Warn ...
	 or	 eax,IWFCNT[@IWF_FAL*(type IWFCNT)] ; ...     Fail ...
	 jz	 short DISP_IWFCNT_EXIT ; Jump if we've nothing to say

	 inc	 ERRCNT 	; Mark as writing to error file

	 push	 fs		; Pass DGROUP segment
	 push	 offset DGROUP:MSG_IWFHDR ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 push	 0		; Mark as no leading separator for 1st msg
	 push	 IWFCNT[@IWF_IGN*(type IWFCNT)] ; Pass Ignore counter
	 push	 offset DGROUP:MSG_IWFIGN ; Pass offset of message
	 push	 MSG_IWFIGN_LEN ; ...  length ...
	 call	 DISP_IWFSUB	; Handle via subroutine
				; Return EAX = 1 if message displayed
	 push	 eax		; Pass leading separator flag
	 push	 IWFCNT[@IWF_WRN*(type IWFCNT)] ; Pass Warn counter
	 push	 offset DGROUP:MSG_IWFWRN ; Pass offset of message
	 push	 MSG_IWFWRN_LEN ; ...  length ...
	 call	 DISP_IWFSUB	; Handle via subroutine
				; Return EAX = 1 if message displayed
	 push	 eax		; Pass leading separator flag
	 push	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Pass Fail counter
	 push	 offset DGROUP:MSG_IWFFAL ; Pass offset of message
	 push	 MSG_IWFFAL_LEN ; ...  length ...
	 call	 DISP_IWFSUB	; Handle via subroutine

	 call	 U32_NEWLINE	; Goto a new line

	 dec	 ERRCNT 	; Mark as no longer writing to error file
DISP_IWFCNT_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IWFCNT endp		; End DISP_IWFCNT procedure
	 NPPROC  DISP_IWFSUB -- Subroutine to DISP_IWFCNT
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Subroutine to DISP_IWFCNT to display messages

On exit:

EAX	 =	 0 if no message displayed
	 =	 1 otherwise

|

DISP_IWF_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DISP_IWF_LEN dd  ?		; Length of message
DISP_IWF_MSG dd  ?		; Offset in DGROUP of trailer message
DISP_IWF_CNT dd  ?		; Counter value
DISP_IWF_FLG dd  ?		; Flag:  0 = don't display leading separator
				;	 1 = do display it
DISP_IWF_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,esi,edi> ; Save registers

	 mov	 eax,[ebp].DISP_IWF_CNT ; Get counter value

	 cmp	 eax,0		; Do we have anything to say about this?
	 je	 short DISP_IWFSUB_EXIT ; Jump if not (note EAX=0)

	 cmp	 [ebp].DISP_IWF_FLG,1 ; Display leading separator?
	 jne	 short @F	; Jump if not

	 push	 fs		; Pass DGROUP segment
	 push	 offset DGROUP:MSG_IWFSEP ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message
@@:
	 lea	 edi,WORKAREA	; Get offset in DGROUP of work area
	 add	 edi,LaDATA	; Plus LA of DGROUP
	 mov	 ebx,edi	; Save for later use

	 push	 @DEC_LEFT	; No commas, left-justified
	 call	 DD2DEC 	; Convert EAX to decimal ending at ES:EDI
				; Returning ES:EDI ==> next byte
	 mov	 esi,[ebp].DISP_IWF_MSG ; Get offset in DGROUP of trailer message
	 mov	 ecx,[ebp].DISP_IWF_LEN ; Get length of ...
	 dec	 eax		; Less one to handle singular
	 cmp	 eax,1		; Izit a single count (CF=1 if so)?
	 sbb	 ecx,0		; Delete 's' from length if so
     rep movs	 AGROUP:[edi].LO,DGROUP:[esi].LO ; Copy to message area

	 sub	 edi,ebx	; Less starting address to get length

	 push	 edi		; Pass length in bytes
	 push	 es		; Pass segment of message
	 push	 ebx		; ...  offset ...
	 call	 U32_DISP_MSGL	; Display the message

	 mov	 eax,1		; Mark as message displayed
DISP_IWFSUB_EXIT:
	 or	 eax,[ebp].DISP_IWF_FLG ; Include previous separator

	 REGREST <edi,esi,ecx,ebx> ; Restore

	 pop	 ebp		; Restore

	 ret	 4*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IWFSUB endp		; End DISP_IWFSUB procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_MSC module
