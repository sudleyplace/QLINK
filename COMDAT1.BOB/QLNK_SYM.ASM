;' $Header:   P:/PVCS/MISC/QLINK/QLNK_SYM.ASV   1.2   07 Aug 1998 16:00:14   BOB  $
	title	QLNK_SYM -- QLINK Symbol Table Management Functions
	page	58,122
	name	QLNK_SYM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Henry Groover.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include BITFLAGS.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	LaDATA:dword
	extrn	LMB_TXTSTR:tbyte
	extrn	LMB_SYMBOL:tbyte
	extrn	LMB_SYMHSH:tbyte
	extrn	WORKAREA:byte
	extrn	WORKAREA_SYM:tbyte

	public	SYMCASE_BEG,SYMCASE_END
SYMCASE_BEG dd	offset DGROUP:WORKAREA+1 ; LA of offset of case-insensitive match
SYMCASE_END dd	?		; ...

SYMNEXT equ	LMB_TXTSTR.LMB_CURB.BOUND_NXT ; Next available byte
SYMNHASH equ	LMB_SYMHSH.LMB_CURB.BOUND_BEG ; Hashed string values for symbol name search

	public	SYMCOUNT
SYMCOUNT dd	 0		; # symbols in the table

; The symbol records themselves are linked into
; unsorted chains for symbol name hashing.

	public	HASHPRIME
HASHPRIME dd	1021		; Prime value for hash remainder (default for
				; BUCKETS=1)

DATA	ends			; End DATA segment


CODE	segment 		; Start CODE segment
	assume	cs:PGROUP

	extrn	U32_LOWERCASE:near

	NPPROC	SYMAPPND -- Symbol Table Append
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Append

On entry:

ESI	==>	LA of SYM_STR

On exit:

CF	=	0 if successful
	=	1 if not
EBX	=	offset in AGROUP of new entry

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

; If we're adding symbols and SYMCOUNT is 0, we need to re-initialize the
; hash tables.

	cmp	SYMCOUNT,0	; Are there any symbols?
	jne	short @F	; Jump if so

	call	HASH_INIT	; Initialize symbol name hash
@@:

; Copy entry to the SYMBOL struc

.errnz (4-1) and (type SYM_STR)
	mov	ecx,(type SYM_STR)/4 ; # dwords to zero
	xor	eax,eax 	; Set to this
	mov	edi,LMB_SYMBOL.LMB_CURB.BOUND_NXT ; Get LA of next entry
	mov	ebx,edi 	; Save starting offset of SYM_STR

	UNOVRB	edi,SYMBOL	; Ensure within overall bounds
    rep movs	AGROUP:[edi].EDD,AGROUP:[esi].EDD
	mov	LMB_SYMBOL.LMB_CURB.BOUND_NXT,edi ; Save LA of next entry

	mov	edi,SYMNEXT	; ES:EDI ==> next available entry in table
	mov	ecx,AGROUP:[ebx].SYM_NAMLEN ; Get the symbol name length
	mov	esi,AGROUP:[ebx].SYM_PNAM ; Get LA of symbol

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to our table

	xchg	SYMNEXT,edi	; Save as offset of next available byte

	mov	AGROUP:[ebx].SYM_PNAM,edi ; Save LA of name
	mov	esi,ebx 	; Copy LA of symbol (SYM_STR)
	call	UPDATE_SYMNHASH ; Update name hash entry

	inc	SYMCOUNT	; Count in another symbol

	clc			; Mark as successful

	jmp	short SYMAPPND_EXIT ; Join common exit code

SYMAPPND_ERR_NOROOM:
	stc			; Indicate something went wrong
SYMAPPND_EXIT:
	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMAPPND endp			; End SYMAPPND procedure
	NPPROC	SYMSRCH -- Symbol Table Search
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Search

On entry:

ESI	==>	LA of SYM_STR

On exit:

CF	=	0 if successful
	=	1 if not
EBX	=	offset in AGROUP of matching entry

|

	REGSAVE <eax,ecx,edi>	; Save registers

	mov	ecx,SYMCOUNT	; Get # entries in the table
	jecxz	SYMSRCH_ERR	; Jump if the table is empty (not found)

	call	HASH_STR	; Get hash index of SYM_STR at DS:ESI into EAX

	mov	ecx,AGROUP:[esi].SYM_NAMLEN ; Get length of string to compare
	mov	edi,SYMNHASH	; DS:EDI ==> symbol name hash table
	mov	edi,AGROUP:[edi+eax*4].EDD ; Get bucket pointer
SYMSRCH_NEXTTAB:

; If bucket is empty, fail

	cmp	edi,-1		; Izit an empty bucket?
	je	short SYMSRCH_ERR ; Jump if so

; Compare this entry

	REGSAVE <ecx,esi,edi>	; Save for a moment

	mov	eax,AGROUP:[esi].SYM_FLAG ; Get incoming symbol's flags
	xor	eax,AGROUP:[edi].SYM_FLAG ; Merge with this symmbol's flags

	test	eax,@SYMFL_CL	; Is there a matching class?
	jnz	short SYMSRCH_LOOPTAB ; Jump if not (note ZF=0)

	cmp	ecx,AGROUP:[edi].SYM_NAMLEN ; Does the length match?
	jne	short SYMSRCH_LOOPTAB ; Jump if not (note ZF=0)

	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of name
	mov	edi,AGROUP:[edi].SYM_PNAM ; ...
SYMSRCH_NEXTCHAR:
	cmp	ax,ax		; Ensure ZF=1 in case CX=0 because
				; REPE CMPS doesn't set ZF if ECX=0
   repe cmps	AGROUP:[esi].LO,AGROUP:[edi].LO ; Same name?
	je	short SYMSRCH_LOOPTAB ; Jump if the same
    
; Unless /NOI is specified, ignore case differences

	test	ARG_FLAG,@ARG_NOI ; Izit to be case-sensitive?
	jz	short @F	; Jump if so

	cmp	esi,SYMCASE_BEG ; Izit below the case-insensitive start?
	jb	short SYMSRCH_LOOPTAB ; Jump if so (note ZF=0)

	cmp	esi,SYMCASE_END ; Izit above the case-insensitive end?
	ja	short SYMSRCH_LOOPTAB ; Jump if so (note ZF=0)
@@:
	mov	al,AGROUP:[esi-1] ; Get last mismatch
	mov	ah,AGROUP:[edi-1] ; ...
    
	or	ax,2020h	; Convert both to lowercase
	
	cmp	al,ah		; Izit the same?
	je	short SYMSRCH_NEXTCHAR ; Jump if so
SYMSRCH_LOOPTAB:
	REGREST <edi,esi,ecx>	; Restore
	je	short SYMSRCH_DONE ; Jump if it matches

; Skip over this entry

	mov	edi,AGROUP:[edi].SYM_NEXTNH ; Get next name hash record

	jmp	short SYMSRCH_NEXTTAB ; Check next entry

SYMSRCH_ERR:
	stc			; Mark as not found

	jmp	short SYMSRCH_EXIT ; Join common exit code

SYMSRCH_DONE:

; DS:EDI ==> matching symbol table entry

	mov	ebx,edi 	; Put record offset in EBX

;;;;;;;; ; If this symbol is substituted, return the substituted symbol address
;;;;;;;;
;;;;;;;; test	 AGROUP:[ebx].SYM_FLAG,@SYMFL_SUBST ; Izit substituted?
;;;;;;;; jz	 short @F	; Jump if not
;;;;;;;;
;;;;;;;; mov	 ebx,AGROUP:[ebx].SYM_PERITEM ; Get LA of substituted symbol (SYM_STR)
;;;;;;;; @@:
	clc			; Mark as found
SYMSRCH_EXIT:
	mov	SYMCASE_END,0	; Clear for next time

	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMSRCH endp			; End SYMSRCH procedure
	NPPROC	UPDATE_SYMNHASH -- Process/Update Symbol Name Hash Table
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Hash name string for symbol and link it into name hash table.  We don't
need to de-link, since this is only done when a new symbol is added and
we don't (currently) support deletion of individual symbols.

On entry:

AGROUP:ESI ==>	 SYM_STR

|

	REGSAVE <eax,ebx,esi,edi> ; Save registers

	mov	AGROUP:[esi].SYM_NEXTNH,-1 ; We always go at the end

	call	HASH_STR	; Get hash index of SYM_STR at DS:ESI into EAX

	shl	eax,2-0 	; Index DWORD table
	add	eax,SYMNHASH	; Add base of name hash table
	mov	edi,eax 	; Load index register
	mov	ebx,AGROUP:[edi].EDD ; Get bucket pointer

	cmp	ebx,-1		; Izit empty?
	jnz	short @F	; Jump if not

	mov	AGROUP:[edi].EDD,esi ; Put us at the head of the chain

	jmp	short UPDATE_SYMNHASH_EXIT ; We're done

@@:

; AGROUP:EBX ==> Next record in bucket

	mov	eax,AGROUP:[ebx].SYM_NEXTNH ; Get pointer to next record

	cmp	eax,-1		; Izit the end?
	je	short @F	; Jump if so

	mov	ebx,eax 	; Point to next

	jmp	short @B	; Go around again

@@:
	mov	AGROUP:[ebx].SYM_NEXTNH,esi ; Append symbol record ptr to chain
UPDATE_SYMNHASH_EXIT:
	REGREST <edi,esi,ebx,eax> ; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPDATE_SYMNHASH endp		; End UPDATE_SYMNHASH procedure
	NPPROC	HASH_STR -- Convert String at AGROUP:ESI To Hash
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Convert length-prefixed string to a hash value using the hashpjw
algorithm shown below.	HASHPRIME is determined at initialization time from
buckets parameter or from SYMSIZE, and may range from 257 to 65287.

extern unsigned int HASHPRIME;

int hashpjw(char *s)
{
 char *p;
 unsigned long h=0, g;

 for (p=s; *p; p++) {
	h = (h << 4) + (unsigned) tolower (*p);
	if (g = (h & 0xf0000000)) {
	  h = h ^ (g >> 24);
	  h = h ^ g;
	}
 }

 return (h % HASHPRIME);

}

On entry:

AGROUP:ESI ==>	SYM_STR

On exit:

EAX	=      16-bit hash value (modulo HASHPRIME)

|

	REGSAVE <ebx,ecx,edx,esi> ; Save registers

	mov	ecx,AGROUP:[esi].SYM_NAMLEN ; Get length in bytes
	mov	esi,AGROUP:[esi].SYM_PNAM ; Get LA of name
	xor	ebx,ebx 	; Initialize hash value to 0
	mov	eax,ebx 	; Clear high bytes of EAX
	jecxz	HASH_STR_EXIT	; Bail out if string is empty
HASH_STR_NEXT:
	lods	AGROUP:[esi].LO ; Get byte value
	shl	ebx,4		; Shift over hash value

	test	ARG_FLAG,@ARG_NOI ; Izit NOIGNORECASE?
	jnz	short @F	; Jump if so

	call	U32_LOWERCASE	; Convert AL to lowercase
@@:
	add	ebx,eax 	; Add in character
	mov	edx,ebx 	; Save a copy

	and	edx,@NIB7	; Isolate high nybble
	jz	short @F	; Jump if zero

	rol	edx,4		; Move high nybble into low nybble
	xor	ebx,edx 	; Toggle bits
	ror	edx,4		; Restore EDX
	xor	ebx,edx 	; Toggle bits again
@@:
	loop	HASH_STR_NEXT	; Repeat till end
HASH_STR_EXIT:
	xor	edx,edx 	; Prepare to divide EAX
	mov	eax,ebx 	; Get dividend in EAX
	div	HASHPRIME	; EDX contains hash value (remainder)
	mov	eax,edx 	; Return value in EAX

	REGREST <esi,edx,ecx,ebx> ; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HASH_STR endp			; End HASH_STR procedure
	NPPROC	HASH_INIT -- Initialize Symbol Address And Name Hash Tables
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Mark all hash table entries as unused.	Must be done before adding the
first symbol when SYMCOUNT = 0.  This covers both the initial state
after startup as well as reset condition (after flush function is called).

|

	REGSAVE <eax,ecx,edi>	; Save registers

	mov	edi,SYMNHASH	; Start of name hash table
	mov	ecx,HASHPRIME	; Get number of dword elements in table
	mov	eax,-1		; Mark buckets as empty

    rep stos	AGROUP:[edi].EDD ; Initialize name table
	mov	LMB_SYMHSH.LMB_CURB.BOUND_NXT,edi ; Save as next available byte

	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HASH_INIT endp			; End HASH_INIT procedure
	NPPROC	LOOKUP_SYM -- Lookup Symbol
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Lookup symbol

On exit:

CF	=	0 if found
	=	1 if not
EBX	=	LA of matching entry (SYM_STR) if found
ESI	=	LA of next character after PTXT

|

LOOKUP_STR struc

	dd	?		; Caller's EBP
LOOKUP_ESI dd	?		; ...	   ESI
	dd	?		; ...	   EIP
LOOKUP_SYMFL dd ?		; Flags for SYM_FLAG
LOOKUP_PTXT dd	?		; LA of text (Count, Char[])
LOOKUP_FLAG dd	?		; Flags:  see LOOKUP_REC

LOOKUP_STR ends

	push	esi		; Save register

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,edi>	; Save registers

	lea	edi,WORKAREA	; Get offset in DGROUP of work area
	add	edi,LaDATA	; Plus LA of DGROUP
	mov	ebx,edi 	; Save starting address

	mov	esi,[ebp].LOOKUP_PTXT ; Get LA of text (Count, Char[])
	movzx	ecx,ds:[esi].LO ; Get the byte length
	inc	ecx		; Count in the length byte

; Copy the (Count, Char[]) pair to the work area

    rep movs	AGROUP:[edi].LO,AGROUP:[esi].LO ; Copy to the work area

	test	[ebp].LOOKUP_FLAG,@LOOKUP_ESI ; Should we advance ESI?
	jz	short @F	; Jump if not

	mov	[ebp].LOOKUP_ESI,esi ; Save as return result
@@:

; Fill in the work area fields

	sub	edi,ebx 	; Subtract to get length
	mov	WORKAREA_SYM.SYM_NAMLEN,edi ; Save for later use
	mov	WORKAREA_SYM.SYM_PNAM,ebx   ; ...
;;;;;;; mov	WORKAREA_SYM.SYM_PERITEM,-1 ; ...
	mov	ecx,[ebp].LOOKUP_SYMFL ; Get flags
	mov	WORKAREA_SYM.SYM_FLAG,ecx ; Save flags

; See if this entry already exists in the symbol table

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMSRCH 	; Search for struc at DS:ESI
				; Return EBX = LA of matching entry (SYM_STR)
	jnc	short LOOKUP_SYM_EXIT ; Jump if found

	test	[ebp].LOOKUP_FLAG,@LOOKUP_APP ; Should we append?
	stc			; Assume so
	jz	short LOOKUP_SYM_EXIT ; Jump if not (note CF=1)

; Append the entry to the symbol table

	lea	esi,WORKAREA_SYM ; DS:ESI ==> SYM_STR
	add	esi,LaDATA	; Plus LA of DGROUP
	call	SYMAPPND	; Append struc at DS:ESI
				; Return EBX = LA of matching entry (SYM_STR)
				; Return with CF significant
LOOKUP_SYM_EXIT:
	REGREST <edi,ecx>	; Restore

	pop	ebp		; Restore

	pop	esi		; Restore

	ret	3*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOOKUP_SYM endp 		; End LOOKUP_SYM procedure

CODE	ends			; End CODE segment

	MEND			; End QLNK_SYM module
