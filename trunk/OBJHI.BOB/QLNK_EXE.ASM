;' $Header:   P:/PVCS/MISC/QLINK/QLNK_EXE.ASV   1.2   07 Aug 1998 16:00:08   BOB  $
	title	QLNK_EXE -- QLINK Executable File Routines
	page	58,122
	name	QLNK_EXE

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
	include DIR.INC
	include EXE.INC
	include ASCII.INC
	include DOSCALL.INC
	include ALLMEM.INC
	include OMF.INC
	include WINSTR.INC

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

	extrn	DEF32:byte
	extrn	PFLDS:dword
	extrn	LaDATA:dword
	extrn	LMB_SYMBOL:tbyte
	extrn	LMB_PERSEG:tbyte
	extrn	LMB_PERCLS:tbyte
	extrn	LMB_PERLSEG:tbyte
	extrn	LMB_EXEHDR:tbyte
	extrn	LMB_EXEFIL:tbyte
	extrn	LMB_BAKPAT:tbyte
	extrn	SEGLNK_1ST:dword
	extrn	STACK_PPERSEG:dword
	extrn	IWFCNT:dword
	extrn	ERRCNT:dword
	extrn	LAST_PERSEG:dword
	extrn	LAST_LSEG:dword
	extrn	EXE_WIN:byte
	extrn	LaSEGTAB:dword
	extrn	ALIGN_LOG2:byte
	extrn	ALIGN_MASK:dword
	extrn	ALIGN_COMP:dword
	extrn	La1stSegFix:dword

	public	EXEFIL_SIZE,EXEFIL_ASIZ,EXEFIL_BSIZ,EXEFIL_LEN,EXEFIL_START
	public	EXEFIL_HDRLEN,EXEFIL_TINY,SEG_ASIZ,SEG_GORE
	public	EXEFIL_TOT,EXEFIL_DIF
EXEFIL_SIZE dd	?		; Size of .EXE/.COM file w/o header
EXEFIL_ASIZ dd	?		; Actual size of the file w/o header
				; counting only bytes actually written
EXEFIL_BSIZ dd	?		; Actual size of the file w/o header
EXEFIL_LEN  dd	0		; Length of last segment
EXEFIL_TOT  dd	?		; Total size of .EXE file so far
EXEFIL_DIF  dd	0 ; *FIXME*	; Difference in actual and rounded logical segment size
EXEFIL_START dd 0		; Starting offset in EXEFIL buffer
EXEFIL_HDRLEN dd 0		; Size of .EXE header w/segment fixups
EXEFIL_TINY dd 0		; Additive offset for first segment if /TINY
SEG_ASIZ dd	?		; Actual size of current segment
SEG_GORE dd	?		; Difference in last segment between actual
				; and length

	public	SEGFIX_CNT,SEGFIX_BEG,SEGFIX_NXT
SEGFIX_CNT dd	0		; # segment fixups in .EXE header
SEGFIX_BEG dd	EXE_HDR_LEN	; Starting offset of segment fixups
SEGFIX_NXT dd	EXE_HDR_LEN	; Next available offset in EXEFIL buffer

	public	LAST_SEGEND
LAST_SEGEND dd	?		; Last segment's ending address

	public	MINSTACK,MINSIZE
MINSTACK dd	0		; Minimum .EXE file stack (0=none)
MINSIZE dd	0		; ...		    size

	public	SEGDEF_A_TAB
SEGDEF_A_TAB dd 0-1		; 0:  Absolute alignment
	dd	0-1		; 1:  Byte ...
	dd	0-2		; 2:  Word ...
	dd	0-16		; 3:  Para ...
	dd	0-256		; 4:  256b ...
	dd	0-4		; 5:  Dword...
	dd	0-4*1024	; 6:  4KB  ...
;;;;;;; dd	?		; 7:  Not defined

	public	WRBLK_FLAG,WRBLK_START
WRBLK_START dd	?		; Starting address for WRITE_BLK segment fixups
WRBLK_FLAG db	?		; WRITE_BLK flag:  1 = write out data
				;		   0 = wite out segment fixups
	align	4

	public	EXE_HDR
EXE_HDR EXE_STR <,?,?,?,?,?,-1,?,?,?,?,?,?,?> ; .EXE header
	dw	1		; Only MS knows what this is there for
EXE_HDR_LEN equ $-EXE_HDR	; Length of ...

	public	EXEFIL_MAXMEM
EXEFIL_MAXMEM equ EXE_HDR.EXE_MAX ; Maximum # paras allocated to .EXE file

;;; L1	    label   byte
;;;	    org     EXEFIL_MAXMEM
;;;	    dw	    -1		    ; ...    maximum
;;;	    org     L1		    ; Restore pointer
;;;
	public	EXEFIL_HNDL
EXEFIL_HNDL dw	?		; .EXE/.COM file handle

	public	MSG_EXECREA,MSG_EXEWRIT,MSG_NOSTK,MSG_STKBIG,MSG_NOFIX
	public	MSG_NO100,MSG_NOSTK0,MSG_NOSTART
MSG_EXECREA db	'様> FAIL:  Unable to create .EXE file.',CR,LF,EOS
MSG_EXEWRIT db	'様> FAIL:  Unable to write .EXE file.',CR,LF,EOS
MSG_NOSTK db	'様> WARN:  No segment defined with stack combine type.',CR,LF,EOS
MSG_STKBIG db	'様> WARN:  Stack size > 64KB:  using 64KB as size.',CR,LF,EOS
MSG_NOFIX db	'様> FAIL:  No segment fixups allowed with /TINY.',CR,LF
MSG_NOFIX1 db	@I,'The first segment fixup occurs in ',EOS
MSG_NO100 db	'様> FAIL:  Start address is not 0000:0100 for /TINY.',CR,LF,EOS
MSG_NOSTK0 db	'様> WARN:  /STACK:nnnn  ignored for /TINY.',CR,LF,EOS
MSG_NOSTART db	'様> WARN:  No starting address defined.',CR,LF,EOS

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	U32_DISP_MSG:near
	extrn	GET_OFF32:near
	extrn	APP_SEGFIX_COM:near
	extrn	WRITE_NE:near
	extrn	DispFidLin:near

	NPPROC	WRITE_EXE -- Write Out The Executable File
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Write out the executable file.

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	cmp	IWFCNT[@IWF_WRN*(type IWFCNT)],0 ; Any warning messages?
	je	short @F	; Jump if not

	test	ARG_FLAG,@ARG_NOEXE ; Create EXE on error?
	jnz	near ptr WRITE_EXE_EXIT ; Jump if not (note CF=0)
@@:

; If /TINY is specified, ensure it can be created

	call	CHK_TINY	; Check 'em out
	jc	near ptr WRITE_EXE_EXIT ; Jump if it didn't (note CF=1)

; Create the .EXE or .COM file

	movzx	eax,PFLDS[@FLD_EXE*(type PFLDS)].VSEG ; Get the segment
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	edx,PFLDS[@FLD_EXE*(type PFLDS)].VOFF ; Get the offset
	add	edx,eax 	; Add to get LA

	mov	cx,DIR_ATTR_NORM ; Normal directory attrs
	DOSCALL @CREAF2 	; Create the file
	jc	near ptr WRITE_EXE_ERRCREA ; Jump if something went wrong

	mov	EXEFIL_HNDL,ax	; Save for later use

; Complain if no stack combine type

	cmp	STACK_PPERSEG,0 ; Izit defined?
	jne	short @F	; Jump if so

	inc	IWFCNT[@IWF_WRN*(type IWFCNT)] ; Count in a warning
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_NOSTK) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file
@@:

; Complain if no starting address

	test	LCL_FLAG,@LCL_START ; Is there an entry point?
	jnz	short @F	; Jump if so

	inc	IWFCNT[@IWF_WRN*(type IWFCNT)] ; Count in a warning
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_NOSTART) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file
@@:

; If EXETYPE WINDOWS, call subroutine

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	short @F	; Jump if not

	call	WRITE_NE	; Write out NE file
	jnc	near ptr WRITE_EXE_HDRCOM  ; Join common code

	jmp	WRITE_EXE_ERRWRIT ; Join error code


@@:

; Write out the header if it's an .EXE file

	test	ARG_FLAG,@ARG_TINY ; Izit a .COM file?
	jnz	near ptr WRITE_EXE_HDRCOM ; Jump if so (no header)

; Fill in the .EXE header information

	mov	eax,SEGFIX_BEG	; Get starting offset of segment fixups
	mov	EXE_HDR.EXE_IREL,ax ; Save as offset to first reltab item

	mov	eax,SEGFIX_CNT	; Get count of # segment fixups
	mov	EXE_HDR.EXE_NREL,ax ; Save as # reltab items

	mov	ebx,STACK_PPERSEG ; Get LA of stack combine type segment (PERSEG_STR)

	cmp	ebx,0		; Izit undefined?
	je	short WRITE_EXE_NOSTK ; Jump if so

	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_ADRB.BOUND_NXT ; Get ending addr
	inc	eax		; Plus one to get length
	sub	eax,AGROUP:[ebx].PERSEG_ADRB.BOUND_BEG ; Less starting addr

; Use the larger of this value and the /STACK parameter (if any)

	cmp	eax,MINSTACK	; Use the larger
	jae	short @F	; Jump if command line parameter is smaller

	mov	eax,MINSTACK	; Use the command line parameter
@@:
	cmp	eax,@CON64KB	; Izit too big?
	jbe	short @F	; Jump if not

	inc	IWFCNT[@IWF_WRN*(type IWFCNT)] ; Count in a warning
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_STKBIG) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file

	mov	eax,@CON64KB	; Use maximum
@@:
	mov	EXE_HDR.EXE_SP,ax ; Save as stack offset

	UNCURB	ebx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[ebx].PERSEG_ADRB.BOUND_BEG ; Get starting addr
	shr	eax,4-0 	; Convert from bytes to paras
	mov	EXE_HDR.EXE_SS,ax ; Save as stack segment
WRITE_EXE_NOSTK:
;;;;;;;
; Set minimum # paras needed to run this program
;;;;;;;
;;;;;;; mov	eax,MINSIZE	; Get minimum size
;;;;;;; add	eax,16-1	; Round up to para boundary
;;;;;;; shr	eax,4-0 	; Convert from bytes to paras
;;;;;;; mov	EXE_HDR.EXE_MIN,ax ; Save in .EXE header

; Copy .EXE header to .EXE/.COM file buffer

	lea	esi,EXE_HDR	; Get offset of .EXE header
	add	esi,LaDATA	; Plus LA of DGROUP to get LA of header
	mov	edi,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	mov	edx,edi 	; Copy start for later use
	mov	ecx,EXE_HDR_LEN ; Get # bytes to write out

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to file buffer

; Zero the filler between the end of the header and the start of the fixups

	xor	eax,eax 	; Filler
	mov	ecx,SEGFIX_BEG	; Get start of fixups
	sub	ecx,EXE_HDR_LEN ; Less length of header
    rep stos	AGROUP:[edi].LO ; FIll it with zeros

; Skip over the segment fixups

	mov	eax,SEGFIX_NXT	; Get the next available address
	sub	eax,SEGFIX_BEG	; Less the starting address
	add	edi,eax 	; Skip over the segment fixups

; Pad out the .EXE header w/segment fixups to a multiple of 16 or 512 bytes

	mov	eax,512-1	; Get header size mask

	test	ARG_FLAG,@ARG_OPTHDR ; Optimize .EXE header?
	jz	short @F	; Jump if not

	mov	eax,16-1	; Get header size mask
@@:
	mov	ecx,edi 	; Copy current LA
	sub	ecx,edx 	; Less start of .EXE/.COM file buffer
	add	ecx,eax 	; Round up to 16 or 512-byte boundary
	not	eax		; Complement to round down
	and	ecx,eax 	; ...
	add	ecx,edx 	; Plus start of .EXE/.COM file buffer
	sub	ecx,edi 	; Less start to get length

; Fill the remaining space with zeros

	mov	al,0		; Fill value
    rep stos	AGROUP:[edi].LO ; Fill with zeros

	mov	eax,edi 	; Copy end of segment fixup area
	sub	eax,edx 	; Less start of EXE_HDR
	shr	eax,4-0 	; Convert from bytes to paras
	mov	AGROUP:[edx].EXE_HSIZ,ax ; Save as size of header in paras

;;; ; Save size of .EXE header
;;;
;;;	    mov     eax,edi	    ; Copy current LA
;;;	    sub     eax,edx	    ; Less start of .EXE/.COM file buffer
;;;	    mov     EXEFIL_HDRLEN,eax ; Save as size of .EXE header w/segment fixups
;;;
;;; ; Write out the .EXE header with segment fixups
;;;
;;; ;;;;;;; mov     edx,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
;;;	    mov     ecx,EXEFIL_HDRLEN ; Get size of .EXE header w/segment fixups
;;;	    mov     bx,EXEFIL_HNDL  ; Get the file handle
;;;	    DOSCALL @WRITF2	    ; Write it all out
;;;	    jc	    near ptr WRITE_EXE_ERRWRIT ; Jump if something went wrong
;;;
;;;	    cmp     eax,ecx	    ; Did it all make it out?
;;;	    jne     near ptr WRITE_EXE_ERRWRIT ; Jump if something went wrong
;;;
; Save this as highwater mark for statistics display

	cmp	edi,LMB_EXEHDR.LMB_CURB.BOUND_NXT ; Izit a new high?
	jb	short @F	; Jump if not

	mov	LMB_EXEHDR.LMB_CURB.BOUND_NXT,edi ; Save as new high
@@:
WRITE_EXE_HDRCOM:
	mov	eax,LMB_EXEHDR.LMB_CURB.BOUND_NXT ; Get LA of next header byte
	sub	eax,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; Less start to get length
	mov	EXEFIL_TOT,eax	; Save as amount written so far
	mov	EXEFIL_HDRLEN,eax ; ...

; Move the file pointer past the .EXE header

	mov	cx,EXEFIL_TOT.EHI ; CX:DX = position after header
	mov	dx,EXEFIL_TOT.ELO ; ...
	mov	al,0		; Move from start of file
	mov	bx,EXEFIL_HNDL	; Get the file handle
	DOSCALL @MOVFP2 	; Move file pointer
	jc	near ptr WRITE_EXE_ERRWRIT ; Jump if something went wrong

; Trundle through all the segments in sequence using the SEGLNK chain

	mov	edx,SEGLNK_1ST	; Get starting LA
	mov	EXEFIL_LEN,0	; Initialize last segment's length
	mov	EXEFIL_START,0	; ...	     starting address
	mov	EXEFIL_ASIZ,0	; ...	     actual size
	mov	EXEFIL_BSIZ,0	; ...	     before size

; EDX	=	LA of PERSEG_STR

	mov	bx,EXEFIL_HNDL	; Get the file handle
	mov	LAST_LSEG,0	; Initialize logical segment #
WRITE_EXE_NEXTSEG:
	cmp	edx,-1		; Are we at the end?
	je	near ptr WRITE_EXE_ENDSEG ; Jump if so

; Skip this if it's an Absolute alignment type

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edx].PERSEG_SEGSYM ; Get LA of SYM_STR
	UNCURB	eax,SYMBOL	; Ensure within current bounds
	test	AGROUP:[eax].SYM_FLAG,@SYMFL_A ; Izit Absolute alignment?
	jz	near ptr WRITE_EXE_LOOPSEG ; Jump if so

; Write out the previous segment's data (if any) to disk

	call	WRITE_LASTSEG	; Write it out
	jc	near ptr WRITE_EXE_ERRWRIT ; Jump if something went wrong

	mov	LAST_PERSEG,edx ; Save for next time

; Save this segment's ending address for the next time

	mov	eax,AGROUP:[edx].PERSEG_ADRB.BOUND_NXT ; Get this seg's end
	inc	eax		; Count in the last byte
	mov	LAST_SEGEND,eax ; Save for later use

	mov	SEG_ASIZ,0	; Initialize this segment's actual size

; Write out the segment offset (if EXETYPE WINDOWS)
; and this is a different logical segment #

	cmp	EXE_WIN,1	; Izit EXETYPE WINDOWS?
	jne	near ptr WRITE_EXE_NEXTSEG1 ; Jump if not

	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edx].PERSEG_CLS ; Get the class (PERCLS_STR)

	UNCURB	eax,PERCLS	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERCLS_PERLSEG ; Get logical segment (PERLSEG_STR)

	UNCURB	eax,PERLSEG	; Ensure within current bounds
	mov	eax,AGROUP:[eax].PERLSEG_LSEG ; Get logical segment #

	cmp	eax,LAST_LSEG	; Izit same?
	je	short WRITE_EXE_NEXTSEG1 ; Jump if so

	mov	LAST_LSEG,eax	; Save for later use

; Round up to alignment boundary

	mov	eax,EXEFIL_TOT	; Get total size so far
	mov	ecx,eax 	; Save unrounded value
	add	eax,ALIGN_MASK	; Round up to
	and	eax,ALIGN_COMP	; ... alignment boundary
	mov	EXEFIL_TOT,eax	; Save for later use
	sub	eax,ecx 	; Subtract to get difference
;;;;;;; mov	EXEFIL_DIF,eax	; Save for later use
	sub	SEG_GORE,eax	; Save for later use

; Save offset (in alignment units) to this logical segment #

	mov	cl,ALIGN_LOG2	; Get alignment shift amount
	mov	eax,EXEFIL_TOT	; Get amount written out so far
	shr	eax,cl		; Convert from bytes to alignment units
	mov	edi,LaSEGTAB	; Get LA of segment table
	mov	AGROUP:[edi].NE_SEGTAB_ODATA,ax ; Save in table
	add	LaSEGTAB,type NE_SEGTAB_STR ; Skip to next entry
WRITE_EXE_NEXTSEG1:

; Initialize the buffer to all zeros for the next segment

	xor	eax,eax 	; Fill value
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[edx].PERSEG_NEWLEN ; Get length of this SEG
	add	ecx,4*1024-1	; Round up to next 4KB
	shr	ecx,2-0 	; Convert from bytes to dwords
	mov	edi,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
    rep stos	AGROUP:[edi].EDD ; Zero the buffer

; Loop through the LEDATA/LIDATA records

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	esi,AGROUP:[edx].PERSEG_LMB.LMB_CURB.BOUND_BEG ; Get LA of start of SEG
WRITE_EXE_NEXTREC:
	UNCURB	edx,PERSEG	; Ensure within current bounds
	cmp	esi,AGROUP:[edx].PERSEG_LMB.LMB_CURB.BOUND_NXT ; Are we at the end?
	je	near ptr WRITE_EXE_ENDREC ; Jump if so

	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	lods	AGROUP:[esi].LO ; Get the type byte (DATREC_TYP)
	btr	ax,0		; Clear bit the 32-bit bit, put into CF
	setc	DEF32		; Save for later use

	cmp	al,@OMF_LEDATA	; Izit an LEDATA record?
	je	short WRITE_EXE_LEDATA ; Jump if so

	cmp	al,@OMF_LIDATA	; Izit an LIDATA record?
	je	short WRITE_EXE_LIDATA ; Jump if so

; Unknown record

	int	03h		; Call our debugger *FIXME*


WRITE_EXE_LEDATA:
	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	lods	AGROUP:[esi].EDD ; Get the data offset (DATREC_OFF)
	mov	edi,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	add	edi,eax 	; Add to starting address

	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	lods	AGROUP:[esi].EDD ; Get the data length (DATREC_LEN)
	mov	ecx,eax 	; Copy to count register
    rep movs	es:[edi].LO,AGROUP:[esi].LO ; Copy to EXEFIL buffer

	jmp	short WRITE_EXE_NEXTCOM ; Join common code


WRITE_EXE_LIDATA:
	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	lods	AGROUP:[esi].EDD ; Get the data offset
	mov	edi,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	add	edi,eax 	; Add to starting address

	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	lods	AGROUP:[esi].EDD ; Get the data length
	add	eax,esi 	; Add to current offset to get ending offset
	mov	WRBLK_FLAG,1	; Mark as writing out data

; Trundle through the LIDATA records

WRITE_EXE_LIDATA_NEXT:
	UNCURB	esi,PERSEG,edx	; Ensure within current bounds
	call	WRITE_BLK	; Write out an LIDATA block record
				; Return ESI as new offset
	cmp	eax,esi 	; Are we at the end?
	jne	short WRITE_EXE_LIDATA_NEXT ; Jump if not

; ES:EDI ==>	 next available byte in output area

WRITE_EXE_NEXTCOM:
	mov	eax,edi 	; Copy LA of next available byte
	sub	eax,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Less start of .EXE/.COM file buffer

; Save high water mark for this segment

	cmp	eax,SEG_ASIZ	; Izit higher than previous writes?
	jbe	short @F	; Jump if not

	mov	SEG_ASIZ,eax	; Save for later use
@@:

; Because we just wrote out something, add in previous segment's gore (if any)

	xor	eax,eax 	; Zero for swap
	xchg	eax,SEG_GORE	; Get last gore, zero for next time
	sub	EXEFIL_BSIZ,eax ; Subtract from file size (actually adding
				; as the value is negative)
	jmp	WRITE_EXE_NEXTREC ; Go around again


WRITE_EXE_ENDREC:
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edx].PERSEG_ADRB.BOUND_BEG ; Get start of this segment
	add	eax,AGROUP:[edx].PERSEG_NEWLEN ; Plus length of the segment
	mov	EXEFIL_START,eax ; Save for later use

; Count in the size of the last segment

	mov	ecx,SEG_ASIZ	; Get this segment's actual size
	jecxz	@F		; Jump if nothing written out
	mov	eax,EXEFIL_BSIZ ; Get size before this segment
	add	eax,ecx 	; Plus this segment's actual size
	mov	EXEFIL_ASIZ,eax ; Save as actual size written
@@:

; Save this segment's length as last segment's length

;;;;;;; UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	eax,AGROUP:[edx].PERSEG_NEWLEN ; Get segment length
	mov	EXEFIL_LEN,eax	; Save for next time

	add	EXEFIL_BSIZ,eax ; Count in new segment's size
WRITE_EXE_LOOPSEG:
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	edx,AGROUP:[edx].PERSEG_SEGSEQ ; Skip to next entry

	jmp	WRITE_EXE_NEXTSEG ; Go around again


WRITE_EXE_ENDSEG:

; Write out the previous segment's data (if any) to disk

	call	WRITE_LASTSEG	; Write it out
	jc	near ptr WRITE_EXE_ERRWRIT ; Jump if something went wrong

	mov	edx,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer

; Calculate the file size and min paras in the .EXE header

	test	ARG_FLAG,@ARG_TINY ; Izit a .COM file?
	jnz	short WRITE_EXE_TINY ; Jump if so

	mov	eax,EXEFIL_HDRLEN ; Get size of .EXE header w/segment fixups
	add	eax,EXEFIL_ASIZ ; Plus actual size of file w/o header
	shl	eax,16-9	; Shift size up leaving remainder
				; (modulo 512) in AX
	shr	ax,16-9 	; Shift remainder to low-order
	jz	short @F	; Jump if evenly divisible

	add	eax,@CON64KB	; Count in another 512-byte chunk
@@:
	mov	AGROUP:[edx].EXE_R512.EDD,eax ; ...

	mov	eax,EXEFIL_SIZE ; Get the file size before truncation
	sub	eax,EXEFIL_ASIZ ; ...		    after  ...
	add	eax,16-1	; Round up to para boundary
	shr	eax,4-0 	; Convert from bytes to paras
	UNCURB	edx,EXEHDR	; Ensure within current bounds
	mov	AGROUP:[edx].EXE_MIN,ax ; Save in .EXE header

;;;;;;; UNCURB	edx,EXEHDR	; Ensure within current bounds
	cmp	ax,AGROUP:[edx].EXE_MAX ; Izit larger than maximum memory?
	jbe	short @F	; Jump if not

;;;;;;; UNCURB	edx,EXEHDR	; Ensure within current bounds
	mov	AGROUP:[edx].EXE_MAX,ax ; Save in .EXE header
@@:

; Move the file pointer to the start of the .EXE file

	xor	ecx,ecx 	; Start at 0:0
	xor	edx,edx 	; ...
	mov	al,0		; Move from start of file
;;;;;;; mov	bx,EXEFIL_HNDL	; Get the file handle
	DOSCALL @MOVFP2 	; Move file pointer
	jc	near ptr WRITE_EXE_ERRWRIT ; Jump if something went wrong

; Write out the changed .EXE header values

	mov	edx,LMB_EXEHDR.LMB_CURB.BOUND_BEG ; DS:EDX ==> start of buffer
	mov	ecx,LMB_EXEHDR.LMB_CURB.BOUND_NXT ; Get high address
	sub	ecx,edx 	; Less start to get length
;;;;;;; mov	bx,EXEFIL_HNDL	; Get the file handle
	DOSCALL @WRITF2 	; Write it all out
	jc	short WRITE_EXE_ERRWRIT ; Jump if something went wrong

	cmp	eax,ecx 	; Did it all make it out?
	jne	short WRITE_EXE_ERRWRIT ; Jump if something went wrong
WRITE_EXE_TINY:

; Truncate the file to the ending address of the highest non-empty segment

	mov	ecx,EXEFIL_ASIZ ; Get actual size of file w/o header
	add	ecx,EXEFIL_HDRLEN ; Add in size of .EXE header w/segment fixups

	mov	dx,cx		; Copy low-order word
	shr	ecx,16		; Shift down high-order word so CX:DX = size
	mov	al,0		; Move from start of file
;;;;;;; mov	bx,EXEFIL_HNDL	; Get the file handle
	DOSCALL @MOVFP2 	; Move file pointer
	jc	short WRITE_EXE_ERRWRIT ; Jump if something went wrong

	xor	ecx,ecx 	; Write out zero bytes to truncate
	xor	edx,edx 	; Arbitrary starting address
;;;;;;; mov	bx,EXEFIL_HNDL	; Get the file handle
	DOSCALL @WRITF2 	; Write it all out
	jc	short WRITE_EXE_ERRWRIT ; Jump if something went wrong

; Finally close it up

;;;;;;; mov	bx,EXEFIL_HNDL	; Get the file handle
	DOSCALL @CLOSF2 	; Close the file
				; Return with CF significant
	jmp	short WRITE_EXE_EXIT ; Join common exit code


WRITE_EXE_ERRCREA:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_EXECREA) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file

	jmp	short WRITE_EXE_ERRCOM ; Join common error code

WRITE_EXE_ERRWRIT:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_EXEWRIT) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file

	DOSCALL @CLOSF2 	; Close the file
WRITE_EXE_ERRCOM:
	stc			; Mark as in error
WRITE_EXE_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_EXE endp			; End WRITE_EXE procedure
	NPPROC	APPLY_BAKPAT -- Apply BAKPAT Records (If Any)
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Apply BAKPAT records (if any)

|

	pushad			; Save all EGP registers

	mov	edx,LAST_PERSEG ; Get LA of last PERSEG_STR
	UNCURB	edx,PERSEG	; Ensure within current bounds
	mov	ecx,AGROUP:[edx].PERSEG_BAKPAT_LNK ; Get link to next record
APPLY_BAKPAT_NEXT:
	jecxz	APPLY_BAKPAT_EXIT ; Jump if no more BAKPAT records
				; for this segment
	UNCURB	ecx,BAKPAT	; Ensure within current bounds
	mov	edi,AGROUP:[ecx].BAKPAT_OFF ; Get the offset
	add	edi,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	UNCURB	edi,EXEFIL	; Ensure within current bounds
;;;;;;; UNCURB	ecx,BAKPAT	; Ensure within current bounds
	mov	eax,AGROUP:[ecx].BAKPAT_VAL ; Get the value

;;;;;;; UNCURB	ecx,BAKPAT	; Ensure within current bounds
	cmp	AGROUP:[ecx].BAKPAT_TYPE,1 ; Split cases:  0=byte, 1=word, 2=dword
	jb	short APPLY_BAKPAT_BYTE ; Jump if byte width
	je	short APPLY_BAKPAT_WORD ; Jump if word width
				; Fall through if dword width
;;;;;;; UNCURB	edi,EXEFIL	; Ensure within current bounds
	add	AGROUP:[edi].EDD,eax ; Add into the file

	jmp	short APPLY_BAKPAT_LOOP ; Join common loop code

APPLY_BAKPAT_WORD:
;;;;;;; UNCURB	edi,EXEFIL	; Ensure within current bounds
	add	AGROUP:[edi].ELO,ax ; Add into the file

	jmp	short APPLY_BAKPAT_LOOP ; Join common loop code

APPLY_BAKPAT_BYTE:
;;;;;;; UNCURB	edi,EXEFIL	; Ensure within current bounds
	add	AGROUP:[edi].LO,al ; Add into the file

;;;;;;; jmp	 short APPLY_BAKPAT_LOOP ; Join common loop code

APPLY_BAKPAT_LOOP:
;;;;;;; UNCURB	ecx,BAKPAT	; Ensure within current bounds
	mov	ecx,AGROUP:[ecx].BAKPAT_LNK ; Get LA of next BAKPAT record

	jmp	APPLY_BAKPAT_NEXT ; Go around again

APPLY_BAKPAT_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APPLY_BAKPAT endp		; End APPLY_BAKPAT procedure
	NPPROC	WRITE_LASTSEG -- Write Out Last Segment
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Write out the last segment

On entry:

EDX	=	 LA of current segment (PERSEG_STR) (-1=end)

On exit:

CF	=	 0 if successful
	=	 1 if not

|

	pushad			; Save all EGP registers

; Round up the previous segment length to the starting point of the
; current segment.

	mov	ecx,SEG_ASIZ	; Get actual size of the segment

	cmp	edx,-1		; Are we at the end?
	je	short WRITE_LASTSEG1 ; Jump if so (note CF=0 in case ECX=0)

	mov	eax,LAST_SEGEND ; Get the last segment's ending address
	UNCURB	edx,PERSEG	; Ensure within current bounds
	sub	eax,AGROUP:[edx].PERSEG_ADRB.BOUND_BEG ; Less this seg's start
	add	SEG_GORE,eax	; Add into segment gore
	mov	ecx,EXEFIL_LEN	; Get size of previous segment
	sub	ecx,eax 	; Subtract to round up to curseg start
WRITE_LASTSEG1:
	jecxz	WRITE_LASTSEG_EXIT ; Jump if nothing to do
				; (such as the 1st time) (note CF=0)
	xor	eax,eax 	; A convenient zero
	xchg	eax,EXEFIL_TINY ; No longer needed
	mov	bx,EXEFIL_HNDL	; Get the file handle
	mov	edx,LMB_EXEFIL.LMB_CURB.BOUND_BEG ; Get start of .EXE/.COM file buffer
	add	edx,eax 	; Plus offset if /TINY specified
	sub	ecx,eax 	; Subtract from length, too
	sub	EXEFIL_ASIZ,eax ; Not actually written to disk
	sub	EXEFIL_BSIZ,eax ; ...

; Update LMB_EXEFIL.LMB_CURB.BOUND_NXT for APPLY_BAKPAT

	lea	eax,[ecx+edx]	; Add to get next address

	cmp	eax,LMB_EXEFIL.LMB_CURB.BOUND_NXT ; Izit a new high?
	jb	short @F	; Jump if not

	mov	LMB_EXEFIL.LMB_CURB.BOUND_NXT,eax ; Save as new high
@@:
	call	APPLY_BAKPAT	; Apply BAKPAT records (if any) to LAST_PERSEG

	DOSCALL @WRITF2 	; Write it all out
	jc	short WRITE_LASTSEG_EXIT ; Jump if something went wrong (note CF=1)

	add	EXEFIL_TOT,eax	; Add into total

	cmp	eax,ecx 	; Did it all make it out?
				; Return with CF significant
WRITE_LASTSEG_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_LASTSEG endp		; End WRITE_LASTSEG procedure
	NPPROC	WRITE_BLK -- Write Out An LIDATA Block Record
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Write out an LIDATA block record or its segment fixup values.

On entry:

DS:ESI	==>	 start of block record.

If writing out segment fixup values,
EDI	=	 LA of FIXUPP_STR
else
EDI	=	 LA of data output
endif

On exit:

DS:ESI	==>	 (updated)
ES:EDI	==>	 (updated if not writing out segment fixups)

|

	REGSAVE <eax,ecx,edx>	; Save registers

	call	GET_OFF32	; Get d/word from DS:ESI depending upon DEF32

	mov	ecx,eax 	; Copy repeat count to count register

	lods	AGROUP:[esi].ELO ; Get the block count

	and	ax,ax		; Izit immediate data?
	jz	short WRITE_BLK_IMM ; Jump if so
WRITE_BLK_RPT:
	REGSAVE <ecx,esi>	; Save for a moment

	movzx	ecx,ax		; Copy block count
WRITE_BLK_BLK:
	call	WRITE_BLK	; Write out an LIDATA block record

	loop	WRITE_BLK_BLK	; Jump if more block counts

	mov	edx,esi 	; Copy as ending source address

	REGREST <esi,ecx>	; Restore

	loop	WRITE_BLK_RPT	; Jump if more data blocks to repeat

	jmp	short WRITE_BLK_EXIT ; Join common exit code


WRITE_BLK_IMM:
	REGSAVE <ecx,esi>	; Save repeat count

	lods	AGROUP:[esi].LO ; Get the 1-byte count of immediate data
	movzx	ecx,al		; Copy to count register

	cmp	WRBLK_FLAG,1	; Izit write out data?
	je	short WRITE_IMM1 ; Jump if so

	mov	eax,AGROUP:[edi].FIXUPP_DRO_CUR ; Get segment fixup location

	cmp	eax,esi 	; Is the seg fixup below the current offset?
	jb	short WRITE_IMM0 ; Jump if so

	lea	edx,AGROUP:[esi+ecx] ; Skip to the end

	cmp	eax,edx 	; Is the seg fixup below the ending offset?
	jae	short WRITE_IMM0 ; Jump if not

	sub	eax,esi 	; Less starting offset
	add	eax,WRBLK_START ; Plus previous starting offset

	call	APP_SEGFIX_COM	; Write out the segment fixup using EAX
WRITE_IMM0:
	add	esi,ecx 	; Skip over the source
	add	WRBLK_START,ecx ; Skip over the destin

	jmp	short WRITE_IMM2 ; Join common code

WRITE_IMM1:
    rep movs	es:[edi].LO,AGROUP:[edi].LO ; Copy to EXEFIL buffer
WRITE_IMM2:
	mov	edx,esi 	; Copy as ending source address

	REGREST <esi,ecx>	; Restore repeat count

	loop	WRITE_BLK_IMM	; Jump if more content fields to repeat
WRITE_BLK_EXIT:
	mov	esi,edx 	; Return as ending source address

	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_BLK endp			; End WRITE_BLK procedure
	NPPROC	CHECK_ALIGN -- Check Alignment Types
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Round up the segment start address
to match the alignment type of this segment.

On entry:

On exit:

ECX	=	new starting address

|

CHECK_ALIGN_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CHECK_ALIGN_ADDR dd ?		; Starting address
CHECK_ALIGN_FLAG dd ?		; Flags:  see SYMFL_REC

CHECK_ALIGN_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	mov	eax,[ebp].CHECK_ALIGN_FLAG ; Get SYMFL_REC flags
	and	eax,@SYMFL_A	; Isolate alignment type
	shr	eax,$SYMFL_A	; Shift to low-order
	mov	eax,SEGDEF_A_TAB[eax*(type SEGDEF_A_TAB)] ; Get the mask

	mov	ecx,[ebp].CHECK_ALIGN_ADDR ; Get starting address

	sub	ecx,eax 	; Subtract to add the alignment width
	dec	ecx		; Less one to round up
	and	ecx,eax 	; Round to proper boundary

	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	2*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ALIGN endp		; End CHECK_ALIGN procedure
	NPPROC	CHK_TINY -- Check ON /TINY Keyword If Specified
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check on /TINY if specified

On exit:

CF	=	0 if successful
	=	1 if not

|

	test	ARG_FLAG,@ARG_TINY ; Izit a .COM file?
	jz	near ptr CHK_TINY_EXIT ; Jump if not (note CF=0)

	cmp	SEGFIX_CNT,0	; Are there any segment fixups?
	jne	short CHK_TINY_NOFIX ; Jump if so

	cmp	EXE_HDR.EXE_CS,0 ; Is the default CS unspecified?
	jne	near ptr CHK_TINY_NO100 ; Jump if not

	cmp	EXE_HDR.EXE_IP,0 ; Is the default IP unspecified?
	je	short @F	; Jump if so

	cmp	EXE_HDR.EXE_IP,0100h ; Is the default IP at end of PSP?
	jne	short CHK_TINY_NO100 ; Jump if not
@@:

; If a non-default stack size was specified, complain

	cmp	MINSTACK,0	; Izit unspecified?
	je	short @F	; Jump if so

	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_NOSTK0) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file
@@:
	movzx	eax,EXE_HDR.EXE_IP ; Get starting IP
	mov	EXEFIL_TINY,eax ; Set additive offset for 1st segment
	sub	EXEFIL_HDRLEN,eax ; Subtract from file header (was zero for .COM)

	clc			; Mark as successful

	jmp	short CHK_TINY_EXIT ; Join common exit code

CHK_TINY_NOFIX:
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_NOFIX) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

; Display the file info on the first segment fixup

	push	La1stSegFix	; Get LA of 1st segment fixup (FIXUPP_STR)
	call	DispFidLin	; Display File ID, THEADR, and line #
				; information if present for EDI (FIXUPP_STR)

	dec	ERRCNT		; Mark as no longer writing to error file

	jmp	short CHK_TINY_ERRCOM ; Join common error code

CHK_TINY_NO100:
	inc	ERRCNT		; Mark as writing to error file

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_NO100) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	dec	ERRCNT		; Mark as no longer writing to error file

;;;;;;; jmp	short CHK_TINY_ERRCOM ; Join common error code

CHK_TINY_ERRCOM:
	inc	IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

;;;;;;; and	ARG_FLAG,not @ARG_TINY ; No longer /TINY

	stc			; Mark as in error
CHK_TINY_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_TINY endp			; End CHK_TINY procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_EXE module
