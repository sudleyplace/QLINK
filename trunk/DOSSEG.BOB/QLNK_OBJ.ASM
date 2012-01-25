;' $Header:   P:/PVCS/MISC/QLINK/QLNK_OBJ.ASV   1.2   07 Aug 1998 16:00:12   BOB  $
	title	QLNK_OBJ -- QLINK Object Module Processor
	page	58,122
	name	QLNK_OBJ

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
	include DOSCALL.INC
	include BITFLAGS.INC
	include DPMI.INC
	include OPEN.INC
	include DIR.INC
	include ALLMEM.INC
	include OMF.INC

	include QLNK_COM.INC
	include QLNK_SEG.INC
	include QLNK_SYM.INC
.list

FLTRET32_STR struc		; 32-bit fault return structure

FLTRET32_REIP dd ?		; Return EIP
FLTRET32_RCS dw  ?,0		; ...	 CS w/filler
FLTRET32_ERR dd  ?		; Error code

FLTRET32_EIP dd  ?		; Error  EIP
FLTRET32_CS  dw ?,0		; ...	 CS w/filler
FLTRET32_EFL dd  ?		; ...	 EFL
FLTRET32_ESP dd  ?		; ...	 ESP
FLTRET32_SS  dw  ?,0		; ...	 SS w/filler

FLTRET32_STR ends


EXPFRAME_STR struc		; Expanded stack frame

EXPFRAME_RET  dq ?		; Return address of expanded frame
EXPFRAME_ERR  dd ?		; Error code
EXPFRAME_EIP  dd ?		; EIP
EXPFRAME_CS   dw ?		; CS
EXPFRAME_EIB  dw ?		; Exception Information Bits
EXPFRAME_EFL  dd ?		; EFL
EXPFRAME_ESP  dd ?		; ESP
EXPFRAME_SS   dw ?,0		; SS w/filler
EXPFRAME_ES   dw ?,0		; ES w/filler
EXPFRAME_DS   dw ?,0		; DS w/filler
EXPFRAME_FS   dw ?,0		; FS w/filler
EXPFRAME_GS   dw ?,0		; GS w/filler
EXPFRAME_CR2  dd ?		; CR2
EXPFRAME_PTE  dd ?		; PTE

EXPFRAME_STR ends


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	IWF_FLAG:dword
	extrn	IW2_FLAG:dword
	include QLNK_IWF.INC

	extrn	LCL_FLAG:dword
	include QLNK_LCL.INC

	extrn	SEGOBJ_1ST:word
	extrn	NEXTSEG:word
	extrn	LAST_DATREC:dword

	extrn	F_THREAD:tbyte
	extrn	T_THREAD:tbyte

	extrn	LaDATA:dword
	extrn	IWFCNT:dword

	extrn	DBGMSG_READOBJ:byte
	extrn	MSG_CRLF:byte
	extrn	MSG_RQEND:byte

	public	ERRCNT
ERRCNT	dd	0		; When > 0, write output to error file

	 public  THISOBJ_STR,THISOBJ_FID,THISOBJ_FIL,THISOBJ_REC
	 public  THISOBJ_CSUM,NEXTOBJ_REC,THISOBJ_RLEN
THISOBJ_STR dd	 ?		; Linear address of this .OBJ structure
THISOBJ_FID dd	 ?		; ...			      FID (Count, Char[])
THISOBJ_FIL dd	 ?		; ...			      file
THISOBJ_REC dd	 ?		; ...			      record
THISOBJ_CSUM dd  ?		; ...			      checksum
NEXTOBJ_REC dd	 ?		; ...		    next ...  record
THISOBJ_RLEN dd  ?		; This record length (including the header)

	 public  FLT_TERM_ESP
FLT_TERM_ESP dd  ?		; Save area for any Fault-terminated ESP


LMB_MAC  macro	 NAM
	 local	 L1,L2

	 public  LMB_&NAM
LMB_&NAM LMB_STR <@LMB_&NAM&_LEN,,,>


TEXT	 segment		; Start TEXT segment
	 assume  ds:DGROUP

L1	 db	 L2,'&NAM&'     ; The LMB name
L2	 equ	 $-L1-1 	; Length of ...

TEXT	 ends			; End TEXT segment


DTAB	 segment		; Start DTAB segment
	 assume  ds:DGROUP

	 dd	 offset DGROUP:L1

DTAB	 ends			; End DTAB segment

	 endm			; LMB_MAC


DTAB	 segment		; Start DTAB segment
	 assume  ds:DGROUP

	 public  LMBNAM
LMBNAM	 label	 dword		; LMB name table

DTAB	 ends			; End DTAB segment


@LMB_TXTSTR_LEN equ  1024*@CON1KB ; Room for small text strings
@LMB_PEROBJ_LEN equ  1024*@CON1KB ; ...      per .OBJ data
@LMB_PERSEG_LEN equ  1024*@CON1KB ; ...      per SEG ...
@LMB_PERGRP_LEN equ  1024*@CON1KB ; ...      per GRP ...
@LMB_LINNUM_LEN equ  1024*@CON1KB ; ...      line numbers
@LMB_SYMBOL_LEN equ  1024*@CON1KB ; ...      symbols
@LMB_SYMHSH_LEN equ  1024*@CON1KB ; ...      symbol hashes
@LMB_PUBDEF_LEN equ  1024*@CON1KB ; ...      public symbols
@LMB_COMDEF_LEN equ  1024*@CON1KB ; ...      communal ...
@LMB_FIXUPP_LEN equ  1024*@CON1KB ; ...      fixup records
@LMB_SEGOBJ_LEN equ  1024*@CON1KB ; ...      segment per .OBJ data
@LMB_EXEFIL_LEN equ  1024*@CON4KB ; ...      executable file (size of largest segment)
@LMB_BAKPAT_LEN equ  1024*@CON4KB ; ...      bakpatch records

	 public  LMBTAB,LMBTAB_LEN,LMBIND_HSH
	 public  LMBTAB_ACC,LMBTAB_ACC_LEN
LMBTAB	 label	 tbyte		; Start of LMB table
LMBTAB_ACC label tbyte		; Start of accumulated LMB table
	 LMB_MAC TXTSTR 	; Small text strings
	 LMB_MAC PEROBJ 	; Per .OBJ data
	 LMB_MAC PERSEG 	; Per SEG  ...
	 LMB_MAC PERGRP 	; Per GRP  ...
	 LMB_MAC LINNUM 	; Line numbers
	 LMB_MAC SYMBOL 	; Symbols
LMBIND_HSH equ	 ($-LMBTAB_ACC)/(type LMB_STR) ; Index for SYMHSH
	 LMB_MAC SYMHSH 	; Symbols Name Hash
	 LMB_MAC PUBDEF 	; Public ...
	 LMB_MAC COMDEF 	; Communal ...
	 LMB_MAC FIXUPP 	; Fixup records
	 LMB_MAC SEGOBJ 	; Segment per .OBJ data
	 LMB_MAC EXEFIL 	; Executable file
	 LMB_MAC BAKPAT 	; Back patch records
LMBTAB_ACC_LEN equ ($-LMBTAB_ACC)/(type LMB_STR) ; # accumulated entries in table

; The following LMBs are re-initialized at the start of each .OBJ file

@LMB_LNAMES_LEN equ  1024*@CON1KB ; Room for list of names
@LMB_SEGDEF_LEN equ  1024*@CON1KB ; ...      segment names table
@LMB_GRPDEF_LEN equ  1024*@CON1KB ; ...      group ...
@LMB_EXTDEF_LEN equ  1024*@CON1KB ; ...      external ...

	 public  LMBTAB_INI,LMBTAB_INI_LEN
LMBTAB_INI label tbyte		; Start of re-initialized LMBs
	 LMB_MAC LNAMES 	; List of names
	 LMB_MAC SEGDEF 	; Segment names table
	 LMB_MAC GRPDEF 	; Group ...
	 LMB_MAC EXTDEF 	; External ...
LMBTAB_INI_LEN equ ($-LMBTAB_INI)/(type LMB_STR) ; # LMBs to re-initialize per .OBJ
LMBTAB_LEN equ	 ($-LMBTAB)/(type LMB_STR) ; # entries in table

	 public  MAXINI
MAXINI	 dd	 LMBTAB_INI_LEN dup (0) ; Maximum size for re-initialized data

	 public  OLDINT05_FVEC,OLDINT0E_FVEC
OLDINT05_FVEC df ?		; Save area for old INT 05h handler
OLDINT0E_FVEC df ?		; ...			0Eh ...

	 public  UNPAGE_ATTR
UNPAGE_ATTR dw	 ?		; Attribute word for uncommited pages

	 public  ERRHNDL
ERRHNDL  dw	 -1		; Error file handle (-1=none)

	 public  OMFTYP
OMFTYP	 db	 ?		; Type of current OMF record

	 public  OLDINT0E_FLG
OLDINT0E_FLG db  ?		; 1 if OLDINT0E_FVEC is valid, 0 if it isn't

;-------------------------------------------------------------------------------

; The following error messages terminate QLINK without user control

	 public  MSG_OBJOPEN,MSG_OBJREAD
	 public  MSG_OBJLEN,MSG_OBJREC,MSG_PFTERM,MSG_BFTERM,MSG_CBTERM
MSG_OBJOPEN db	 '様> FAIL:  Unable to open .OBJ file:  ',EOS
MSG_OBJREAD db	 '様> FAIL:  Unable to read .OBJ file:  ',EOS

MSG_OBJLEN  db	 '様> FAIL:  Invalid OMF record length',CR,LF
	    db	 @I,'at offset '
MSG_OBJLEN1 db	 '________ in file ',EOS

MSG_OBJREC  db	 '様> FAIL:  Record length at end of parse is non-zero processing OMF record',CR,LF
	    db	 @I,'at offset '
MSG_OBJREC1 db	 '________ in file ',EOS

MSG_PFTERM  db	 '様> FAIL:  Unhandled Page Fault at '
MSG_PFTERM_CS db '____:'
MSG_PFTERM_EIP db '________ processing OMF record',CR,LF
	    db	 @I,'at offset '
MSG_PFTERM1 db	 '________ in file ',EOS

MSG_BFTERM  db	 '様> FAIL:  Unbounded array reference at '
MSG_BFTERM_CS db '____:'
MSG_BFTERM_EIP db '________ processing OMF record',CR,LF
	    db	 @I,'at offset '
MSG_BFTERM1 db	 '________ in file ',EOS

MSG_CBTERM  db	 CR,LF,'様> FAIL:  Control-Break encountered...',CR,LF,EOS

;-------------------------------------------------------------------------------

; The following error messages can be ignored/warned/failed on user control

	public	MSG_EXTMAT
MSG_EXTMAT db	'(EXTMAT) Unmatched EXTDEF for symbol ',@LQ,EOS
MSG_EXTMAT1 db	@I,'in file ',EOS

	 public  MSG_CSUMINV
MSG_CSUMINV db	 '(CSUMINV) Invalid OMF checksum',CR,LF
	    db	 @I,'at offset '
MSG_CSUMINV1 db  '________ in file ',EOS

@UNK_LEN equ	 16		; # triples '__ ' in the line

	 public  MSG_UNKREC
MSG_UNKREC db	 @UNK_LEN dup ('__ '),'- ' ; Hex display area
MSG_UNKREC1 db	 @UNK_LEN dup ('_'),CR,LF ; ASCII display area
MSG_UNKREC_LEN equ $-MSG_UNKREC ; Length of ...

	 public  MSG_INT0E,MSG_LMB
MSG_INT05 label  byte
MSG_INT0E db	 '様> FAIL:  The DPMI host doesn''t support functions 210h/212h.',CR,LF,EOS
MSG_LMB  db	 '様> FAIL:  Unable to allocate Linear Memory Block.',CR,LF,EOS

	 public  MSG_LSEP,MSG_RSEP
MSG_LSEP db	 ' (',EOS
MSG_RSEP db	 ')',EOS

	 CCMAC	 <@PRODNAME,'.ERR'>,ERRNAME
	 db	 0		; ASCIIZ terminator

DATA	 ends			; End DATA segment


OMFTAB_MAC macro NUM,DEF32,ACT

DATA	 segment		; Start DATA segment
	 assume  ds:DGROUP

	 org	 OMFTAB+((@OMF_&NUM-@OMF1ST)/2)*(type OMFTAB)
	 dd	 offset PGROUP:OMF_&ACT
	 org	 OMFTABZ

DATA	 ends			; End DATA segment


TEXT	 segment		; Start TEXT segment
	 assume  ds:DGROUP

	 org	 DEF32TAB+((@OMF_&NUM-@OMF1ST)/2)*(type DEF32TAB)
	 db	 DEF32
	 org	 DEF32TABZ

TEXT	 ends			; End TEXT segment


CODE	 segment		; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 OMF_&ACT:near

CODE	 ends			; End CODE segment

	 endm			; OMFTAB_MAC

DATA	 segment		; Start DATA segment
	 assume  ds:DGROUP

	 public  OMFTAB
OMFTAB	 dd	 (1+@OMFLAST-@OMF1ST) dup (offset PGROUP:OMF_UNK) ; Define the table
OMFTABZ  label	 dword		; End of the table

DATA	 ends			; End DATA segment


TEXT	 segment		; Start TEXT segment
	 assume  ds:DGROUP

	 public  DEF32
DEF32	 db	 ?		; 1 = current OMF record is 32-bit, 0 = not

	 public  DEF32TAB
DEF32TAB db	 128 dup (0)	; 1 = has 32-bit definition, 0 = not
DEF32TABZ label  byte		; End of the table

TEXT	 ends			; End TEXT segment

				   ; + = 16- and 32-bit records
				   ; * = unsupported
   OMFTAB_MAC RHEADR , 0 , IGN	   ; * R-module header record
   OMFTAB_MAC REGINT , 0 , IGN	   ; * Register initialization record
   OMFTAB_MAC REDATA , 0 , IGN	   ; * Relocatable enumerated data record
   OMFTAB_MAC RIDATA , 0 , IGN	   ; * Relocatable iterated data record
   OMFTAB_MAC OVLDEF , 0 , IGN	   ; * Overlay definition record
   OMFTAB_MAC ENDREC , 0 , IGN	   ; * End record
   OMFTAB_MAC BLKDEF , 0 , BLKDEF  ; * Block definition record
   OMFTAB_MAC BLKEND , 0 , BLKEND  ; * Block end record
   OMFTAB_MAC DEBSYM , 0 , IGN	   ; * Debug symbols record
   OMFTAB_MAC THEADR , 0 , THEADR  ;   Translator header record
   OMFTAB_MAC LHEADR , 0 , THEADR  ;   Library module header record (=THEADR)
   OMFTAB_MAC PEDATA , 0 , IGN	   ; * Physical enumerated data record
   OMFTAB_MAC PIDATA , 0 , IGN	   ; * Physical iterated data record
   OMFTAB_MAC COMENT , 0 , COMENT  ;   Comment record
   OMFTAB_MAC MODEND , 1 , MODEND  ; + Module end record
   OMFTAB_MAC EXTDEF , 0 , EXTDEF  ;   External names definition record
   OMFTAB_MAC TYPDEF , 0 , TYPDEF  ; * Type definition record
   OMFTAB_MAC PUBDEF , 1 , PUBDEF  ; + Public names definition record
   OMFTAB_MAC LOCSYM , 0 , IGN	   ; * Local symbols record
   OMFTAB_MAC LINNUM , 1 , LINNUM  ; + Line numbers record
   OMFTAB_MAC LNAMES , 0 , LNAMES  ;   List of names record
   OMFTAB_MAC SEGDEF , 1 , SEGDEF  ; + Segment definition record
   OMFTAB_MAC GRPDEF , 0 , GRPDEF  ;   Group definition record
   OMFTAB_MAC FIXUPP , 1 , FIXUPP  ; + Fixup record
   OMFTAB_MAC IGNORE , 0 , IGN	   ; * Undefined record
   OMFTAB_MAC LEDATA , 1 , LEDATA  ; + Logical enumerated data record
   OMFTAB_MAC LIDATA , 1 , LEDATA  ; + Logical iterated data record (=LEDATA)
   OMFTAB_MAC LIBHED , 0 , IGN	   ; * Library header record
   OMFTAB_MAC LIBNAM , 0 , IGN	   ; * Library module names record
   OMFTAB_MAC LIBLOC , 0 , IGN	   ; * Library module locations record
   OMFTAB_MAC LIBDIC , 0 , IGN	   ; * Library dictionary record
   OMFTAB_MAC COMDEF , 0 , COMDEF  ;   Communal names definition record
   OMFTAB_MAC BAKPAT , 1 , BAKPAT  ; + Backpatch record
   OMFTAB_MAC LEXTDEF, 1 , EXTDEF  ; + Local EXTDEF (=EXTDEF)
   OMFTAB_MAC LPUBDEF, 1 , PUBDEF  ; + Local PUBDEF (=PUBDEF)
   OMFTAB_MAC LCOMDEF, 0 , COMDEF  ;   Local COMDEF (=COMDEF)
   OMFTAB_MAC COMFIX , 1 , UNK	   ; + Communal fixup record (never implemented)
   OMFTAB_MAC CEXTDEF, 0 , CEXTDEF ;   COMDAT external names definition record
   OMFTAB_MAC SELDEF , 0 , UNK	   ;   Selector definition record (never implemented)
   OMFTAB_MAC COMDAT , 1 , COMDAT  ; + Initialized communal data record
;; OMFTAB_MAC LINSYM , 1 , LINSYM  ; + Symbol line numbers record
   OMFTAB_MAC ALIAS  , 0 , ALIAS   ;   Alias definition record
;; OMFTAB_MAC NBKPAT , 1 , NBKPAT  ; + Named backpatch record
   OMFTAB_MAC LLNAMES, 0 , LNAMES  ;   Local logical list of names record


CODEZ	segment 		; Start CODEZ segment
	assume	cs:PGROUP,ds:PGROUP

	public	CTAIL
CTAIL	label	byte		; Next byte after PGROUP

CODEZ	ends			; End CODEZ segment


CODE	 segment		; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 CSEL_DATA:word
	 extrn	 CSEL_4GB:word

	 extrn	 DUMPIT:near

	 extrn	 U32_DISP_MSG:near
	 extrn	 U32_DISP_MSGL:near
	 extrn	 U32_NEWLINE:near
	 extrn	 U32_CALC_HIGHSEG:near
	 extrn	 DB2HEX:near
	 extrn	 DW2HEX:near
	 extrn	 DD2HEX:near
	 extrn	 DISP_CNTCHR:near
	 extrn	 PROC_EXTS:near
	 extrn	 PROC_SEGS:near
	 extrn	 PROC_GRPS:near
	 extrn	 PROC_PUBS:near
	 extrn	 PROC_FIXUP:near
	 extrn	 WRITE_OUT:near
	 extrn	 WRITE_EXE:near
	 extrn	 WRITE_MAP:near
	 extrn	 DISP_STAT:near
	 extrn	 IWF_TEST:near
	 extrn	 DISP_IWFCNT:near

	 FPPROC  PROC_FILES -- Process All Object Modules
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Process all of the .OBJ modules.

Runs in PM only.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save registers
	 REGSAVE <ds,es,fs>	; ...

	 mov	 ds,CSEL_4GB	; Get AGROUP data selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 es,CSEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 FLT_TERM_ESP,esp ; Save current stack offset to strip
				; in one of the Fault termination handlers
	 call	 INST_FLTS	; Install our Fault handlers
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

	 call	 ALLOC_LMB	; Allocate the linear memory blocks we need
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

; For debugging purposes, create an error file

	 test	 ARG_FLAG,@ARG_DBGERR or @ARG_DBGSTA ; Are we in a debuggin' mood?
	 jz	 short @F	; Jump if not

	 lea	 edx,ERRNAME	; DS:EDX ==> error filename
	 add	 edx,LaDATA	; Plus LA of DGROUP
	 mov	 THISOBJ_FID,edx ; Save for later use
	 inc	 edx		; Skip over length byte
	 mov	 cx,DIR_ATTR_NORM ; Normal directory attrs
	 DOSCALL @CREAF2	; Create the error file
	 jc	 near ptr PROC_FILES_ERROPEN ; Jump if something went wrong

	 mov	 ERRHNDL,ax	; Save for later use
@@:

; Read in the .OBJ files one by one and process them

	 movzx	 edi,SEGOBJ_1ST ; Get the first segment
PROC_FILES_NEXTOBJ:
	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 shl	 edi,4-0	; Convert from paras to bytes

; Attempt to open the .OBJ file

	 lea	 edx,AGROUP:[edi].POBJ_LEN ; Get LA of filename (Count, Char[])
	 mov	 THISOBJ_FID,edx ; Save for later use
	 inc	 edx		; Skip over length byte
	 mov	 al,@OPEN_R	; Open as read-only
	 DOSCALL @OPENF2	; Open the .OBJ file
	 jc	 near ptr PROC_FILES_ERROPEN ; Jump if something went wrong

; Read in the .OBJ file

	 mov	 bx,ax		; Copy to handle register
	 movzx	 edx,NEXTSEG	; Get next available segment
	 shl	 edx,4-0	; Convert from paras to bytes
	 mov	 ecx,-1 	; Read in the whole file
	 DOSCALL @READF2	; Read it in
	 mov	 ecx,eax	; Copy as actual length
	 pushfd 		; Save CF
	 DOSCALL @CLOSF2	; Close it up (clobbering AX)
	 popfd			; Restore
	 jc	 near ptr PROC_FILES_ERRREAD ; Jump if something went wrong

	 push	 ecx		; Pass # bytes used
	 call	 U32_CALC_HIGHSEG ; Calculate new HIGHSEG value

	 mov	 esi,edx	; Copy for LODS operations

	 mov	 THISOBJ_STR,edi ; Save for later use
	 mov	 THISOBJ_FIL,esi ; ...

	test	ARG_FLAG,@ARG_DBGMSG ; Displaying debugging messages?
	jz	short PROC_FILES_XDBG ; Jump if not

	pushad			; Save for a moment

	lea	edx,DBGMSG_READOBJ ; Get line start
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	mov	edx,THISOBJ_FID ; DS:EDX ==> filename (Count, Char[])
	movzx	ecx,ds:[edx].LO ; Get the count
	inc	edx		; Skip over it
	mov	bx,@STD_OUT	; Send to standard output
	DOSCALL @WRITF2 	; Write it out

	lea	edx,MSG_CRLF	; Get line ending
	add	edx,LaDATA	; Plus LA of DGROUP
	DOSCALL @STROUT 	; Display it

	popad			; Restore
PROC_FILES_XDBG:
	 call	 PROC_OBJ	; Process a single .OBJ file at DS:ESI, len ECX
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

	 movzx	 edi,AGROUP:[edi].POBJ_NEXT ; Get the next segment

	 cmp	 di,-1		; Izit the last one?
	 jne	 near ptr PROC_FILES_NEXTOBJ ; Jump if not

	 call	 DUMPIT 	; Dump all the tables

; All .OBJ files are processed:  validate the whole mess.

; Ensure all externals are matched with publics
; If not, this routine also checks the .LIB files

	 call	 PROC_EXTS	; Process them
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

; Calculate the start of all segments

	 call	 PROC_SEGS	; Process them
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

; Calculate the start of all groups

	 call	 PROC_GRPS	; Process them
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

; Calculate the base address of all public symbols

	 call	 PROC_PUBS	; Process them

; Perform all fixups

	 call	 PROC_FIXUP	; Process them
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if something went wrong

; Write out the executable file

	 call	 WRITE_EXE	; Do it
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if not

; Write out the .MAP file

	 call	 WRITE_MAP	; Do it
	 jc	 near ptr PROC_FILES_ERRCOM ; Jump if not

; Display statistics

	 call	 DISP_STAT	; Display 'em

	 call	 DUMPIT 	; Dump all the tables

	 jmp	 PROC_FILES_CLC ; Join common exit code


COMMENT|

Unbounded array reference.

|

	 public  BF_TERM
BF_TERM:
	 mov	 ds,CSEL_4GB	; Get AGROUP data selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 es,CSEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 esp,FLT_TERM_ESP ; Strip the stack

	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_BFTERM) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_BFTERM1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 jmp	 PROC_FILES_ERRCOM ; Join common error code


COMMENT|

Unhandled Page Fault.

|

	 public  PF_TERM
PF_TERM:
	 mov	 ds,CSEL_4GB	; Get AGROUP data selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 es,CSEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 esp,FLT_TERM_ESP ; Strip the stack

	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_PFTERM) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_PFTERM1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 jmp	 PROC_FILES_ERRCOM ; Join common error code


COMMENT|

Ctrl-Break termination.

|

	 public  CB_TERM
CB_TERM:
	 mov	 ds,CSEL_4GB	; Get AGROUP data selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 es,CSEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 esp,FLT_TERM_ESP ; Strip the stack

	 inc	 ERRCNT 	; Mark as writing to error file

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_CBTERM) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 jmp	 short PROC_FILES_ERRCOM ; Join common error code


COMMENT|

Unable to open .OBJ file.

|

PROC_FILES_ERROPEN:
	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_OBJOPEN) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 push	 0		; Don't display THEADR (it's not valid)
	 call	 DISP_FIDNAME	; Display name of the .OBJ file at THISOBJ_FID

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 jmp	 short PROC_FILES_ERRCOM ; Join common error code


COMMENT|

Unable to read .OBJ file.

|

PROC_FILES_ERRREAD:
	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_OBJREAD) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 push	 0		; Don't display THEADR (it's not valid)
	 call	 DISP_FIDNAME	; Display name of the .OBJ file at THISOBJ_FID

	 dec	 ERRCNT 	; Mark as no longer writing to error file
PROC_FILES_ERRCOM:
	 call	 DUMPIT 	; Dump all the tables

	 call	 DISP_IWFCNT	; Display Ignore/Warn/Fail counters if non-zero

	 stc			; Mark as in error

	 jmp	 short PROC_FILES_EXIT ; Join common exit code


PROC_FILES_CLC:
	 call	 DISP_IWFCNT	; Display Ignore/Warn/Fail counters if non-zero

	 clc			; Mark as successful
PROC_FILES_EXIT:
	pushfd			; Save flags (CF in particular)
	call	REL_LMB 	; Release the linear memory blocks we allocated
	popfd			; Restore

	 REGREST <fs,es,ds>	; Restore
	 assume  ds:DGROUP,es:DGROUP,fs:nothing ; Tell the assembler about it
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_FILES endp 		; End PROC_FILES procedure
	 NPPROC  PROC_OBJ -- Process A Single .OBJ File
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process the .OBJ file at DS:ESI of length ECX bytes

On entry:

DS:EDX	 ==>	 start of .OBJ file
DS:ESI	 ==>	 current record
ECX	 =	 # remaining bytes in the .OBJ file
		 (including the current record)
On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

; Append per .OBJ data

	 call	 SETUP_NEWOBJ	; Setup a new .OBJ file
	 jc	 near ptr PROC_OBJ_ERRCOM ; Jump if something went wrong
PROC_OBJ_NEXTREC:
	 btr	 LCL_FLAG,$LCL_BRK ; Izit break time?
	 jc	 near ptr CB_TERM ; Jump if so

	 movzx	 eax,ds:[esi].OBJHDR_LEN ; Get the record length
	 add	 eax,type OBJHDR_STR ; Include the header
	 mov	 THISOBJ_RLEN,eax ; Save for later use
	 add	 eax,esi	; Skip over the record
	 mov	 THISOBJ_REC,esi ; Save for later use
	 mov	 NEXTOBJ_REC,eax ; ...
	 dec	 eax		; Back off to checksum
	 mov	 THISOBJ_CSUM,eax ; Save for later use

	 movzx	 eax,ds:[esi].OBJHDR_LEN ; Get the record length
	 add	 eax,type OBJHDR_STR ; Plus the size of the header

	 cmp	 eax,ecx	; Izit too large?
	 ja	 short PROC_OBJ_ERRLEN ; Jump if so

	 call	 CHECK_CSUM	; Validate the checksum of the record at DS:ESI
	 jc	 near ptr PROC_OBJ_ERRCOM ; Jump if it's fatal

	 movzx	 eax,ds:[esi].OBJHDR_TYP ; Get the record type
	 mov	 OMFTYP,al	; Save for later use

	 cmp	 eax,@OMFLAST	; Izit above the last valid record
	 ja	 short PROC_OBJ_ERRTYP ; Jump if so

	 sub	 eax,@OMF1ST	; Izit below the first valid record?
	 jae	 short @F	; Jump if not
PROC_OBJ_ERRTYP:
	 call	 OMF_UNK	; Warn/Ignore/Fail on unknown OMF record type
	 jc	 short PROC_OBJ_ERRCOM ; Jump if it's fatal

	 btr	 eax,$BIT0	; Clear 32-bit bit in case we come here from below
@@:
	 shr	 eax,1		; Shift out the 32-bit definition bit
	 setc	 DEF32		; Save for later use
	 jnc	 short @F	; Jump if not 32-bit this time

	 cmp	 DEF32TAB[eax*(type DEF32TAB)],1 ; Is there a 32-bit definition?
	 jne	 short PROC_OBJ_ERRTYP; Jump if not
@@:
	 call	 OMFTAB[eax*(type OMFTAB)] ; Take appropriate action
	 jc	 short PROC_OBJ_ERRCOM ; Jump if something went wrong

	 btr	 LCL_FLAG,$LCL_MODEND ; Have we hit a MODEND record?
	 jc	 short @F	; Jump if so

	 mov	 esi,NEXTOBJ_REC ; Skip over the record

	 sub	 ecx,THISOBJ_RLEN ; Decrement the length
	 ja	 near ptr PROC_OBJ_NEXTREC ; Jump if there's more to do
@@:
	call	PROC_ENDOBJ	; Process end-of-.OBJ file
				; Return with CF significant
	jmp	short PROC_OBJ_EXIT ; Join common exit code


COMMENT|

Invalid record length.

|

PROC_OBJ_ERRLEN:
	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_OBJLEN) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_OBJLEN1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 dec	 ERRCNT 	; Mark as no longer writing to error file
PROC_OBJ_ERRCOM:
	 stc			; Mark as in error
PROC_OBJ_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_OBJ endp			; End PROC_OBJ procedure
	NPPROC	PROC_ENDOBJ -- Process End-.Of-.OBJ File
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Process end-of-.OBJ file

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

	mov	eax,IW2_FLAG	; Get flags
	and	eax,@IW2_EXTMAT ; Isolate bits

	cmp	eax,@IWF_IGN shl $IW2_EXTMAT ; Are we ignoring unmatched EXTDEFs?
	je	short PROC_ENDOBJ1 ; Jump if so

	mov	edi,LMB_EXTDEF.LMB_CURB.BOUND_BEG ; Get starting address
PROC_ENDOBJ_NEXT0:
	cmp	edi,LMB_EXTDEF.LMB_CURB.BOUND_NXT; Are we at the end?
	je	short PROC_ENDOBJ1 ; Jump if so

	UNCURB	edi,EXTDEF	; Ensure within current bounds
	test	AGROUP:[edi].EXTDEF_FLAG,@EXTDEF_MAT ; Izit matched?
	jnz	short PROC_ENDOBJ_LOOP0 ; Jump if so

; Some C compilers put both an EXTDEF and PUBDEF for a symbol
; in the same file.  Check for this and don't mark as unmatched.

;;;;;;; UNCURB	edi,EXTDEF	; Ensure within current bounds
	mov	esi,AGROUP:[edi].EXTDEF_PSYM ; Get LA of symbol

	mov	eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	sub	eax,type PEROBJ_STR ; Back off to previous entry

	UNCURB	esi,SYMBOL	; Ensure within current bounds
	cmp	eax,AGROUP:[esi].SYM_PPEROBJ ; Izit public in this module?
	je	short PROC_ENDOBJ_LOOP0 ; Jump if so

	push	dword ptr (offset PGROUP:IW2_EXTMAT) ; Pass offset of action routine
	push	IW2_FLAG	; Pass value of flags
	push	$IW2_EXTMAT	; Pass offset of bit mask
	call	IWF_TEST	; Test for invalid checksum
				; Return with CF=1 if it's fatal
	jc	short PROC_ENDOBJ_EXIT ; Jump if it's fatal (note CF=1)
PROC_ENDOBJ_LOOP0:
	add	edi,type EXTDEF_STR ; Skip to next entry

	jmp	PROC_ENDOBJ_NEXT0 ; Go around again


PROC_ENDOBJ1:


	clc			; Mark as successful
PROC_ENDOBJ_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_ENDOBJ	endp		; End PROC_ENDOBJ procedure
	NPPROC	IW2_EXTMAT -- Ignore/Warn/Fail About Unmatched EXTDEFs
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about unmatched EXTDEFs

On entry:

EDI	=	LA of EXTDEF (EXTDEF_STR)

|

	REGSAVE <ebx>		; Save register

; Display the message header

	push	fs	       ; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_EXTMAT) ; Pass offset of message
	call	U32_DISP_MSG   ; Display the message

; Display the symbol name

	mov	ebx,AGROUP:[edi].EXTDEF_PSYM ; Get LA of symbol (SYM_STR)
	UNCURB	ebx,SYMBOL	; Ensure within current bounds
	push	AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	call	DISP_CNTCHR	; Display (Count, Char[])

	push	fs		; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_RQEND) ; Pass offset of message
	call	U32_DISP_MSG	; Display the message

	push	fs	       ; Pass DGROUP segment
	push	dword ptr (offset DGROUP:MSG_EXTMAT1) ; Pass offset of message
	call	U32_DISP_MSG   ; Display the message

; Display the name of the .OBJ file

	push	1		; Display THEADR
	call	DISP_FIDNAME	; Display name of the .OBJ file at THISOBJ_FID

	REGREST <ebx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IW2_EXTMAT endp 		; End IW2_EXTMAT procedure
	 NPPROC  DISP_ERRDD -- Format And Display Error Message
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Format and fill in a DD and display error message.

|

DISP_ERRDD_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DISP_ERRDD_FILL dd ?		; Offset in DGROUP of fill area
DISP_ERRDD_MSG	dd ?		; ...		      message start

DISP_ERRDD_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,edi,es>	; Save for a moment

	 mov	 es,CSEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

; Format the value of the offset of the erroneous record into the message

	 mov	 eax,THISOBJ_REC ; Get LA of start of this .OBJ record
	 sub	 eax,THISOBJ_FIL ; Less LA of start of this .OBJ file
				; to get relative offset

	 mov	 edi,[ebp].DISP_ERRDD_FILL ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 REGREST <es,edi,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 inc	 ERRCNT 	; Mark as writing to error file

	 push	 fs		; Pass DGROUP segment
	 push	 [ebp].DISP_ERRDD_MSG ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 push	 1		; Display THEADR
	 call	 DISP_FIDNAME	; Display name of the .OBJ file at THISOBJ_FID

	 call	 DISP_OBJREC	; Display .OBJ record at THISOBJ_REC

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRDD endp 		; End DISP_ERRDD procedure
	 NPPROC  DISP_FIDNAME -- Display The Name of The FID
	 assume  ds:AGROUP,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display the name of the FID.

|

DISP_FID_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DISP_FID_FLAG dd ?		; Flag:  1 = display THEADR, 0 = don't

DISP_FID_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,esi>	; Save registers

	 xor	 eax,eax	; Zero to use as dword
	 mov	 esi,THISOBJ_FID ; Get LA of filename (Count, Char[])
	 lods	 AGROUP:[esi].LO ; Get and skip over the byte length

	 inc	 ERRCNT 	; Mark as writing to error file

	 push	 eax		; Pass length in bytes
	 push	 ds		; Pass segment of message
	 push	 esi		; ...  offset ...
	 call	 U32_DISP_MSGL	; Display the message

; If there's a THEADR record, display that, too

	 cmp	 [ebp].DISP_FID_FLAG,1 ; Display THEADR?
	 jne	 short @F	; Jump if not

	 mov	 eax,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 sub	 eax,type PEROBJ_STR ; Back off to previous entry

	 push	 1		; Display leading blank
	 push	 eax		; Pass LA of PEROBJ_STR as argument
	 call	 DISP_THEADR	; Display the THEADR if present
@@:
	 call	 U32_NEWLINE	; Goto a new line

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 REGREST <esi,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_FIDNAME endp		; End DISP_FIDNAME procedure
	 NPPROC  DISP_THEADR -- Display THEADR Name If Present
	 assume  ds:AGROUP,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display THEADR record if present.

|

DTH_STR  struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DTH_PPEROBJ dd	 ?		; LA of PEROBJ_STR
DTH_FLAG dd	 ?		; Flags:  1 = display leading blank, 0 = don't

DTH_STR  ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx>	; Save registers

	 mov	 eax,[ebp].DTH_PPEROBJ ; Get LA of PEROBJ_STR

	 UNCURB  eax,PEROBJ	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PEROBJ_PTHEADR ; Get LA of THEADR text

	 and	 eax,eax	; Izit valid?
	 jz	 short DISP_THEADR_EXIT ; Jump if not

	 inc	 ERRCNT 	; Mark as writing to error file

	 lea	 ebx,MSG_LSEP[1] ; Get offset in DGROUP (assuming no leading blank)
	 sub	 ebx,[ebp].DTH_FLAG ; Less flag

	 push	 fs		; Pass DGROUP segment
	 push	 ebx		; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 push	 eax		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display (Count, Char[])

	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_RSEP) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 dec	 ERRCNT 	; Mark as no longer writing to error file
DISP_THEADR_EXIT:
	 REGREST <ebx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_THEADR endp		; End DISP_THEADR procedure
	 NPPROC  DISP_OBJREC -- Display The Contents Of An OMF Record
	 assume  ds:AGROUP,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display the contents of an OMF record

|

	 pushad 		; Save registers
	 REGSAVE <ds,es>	; ...

	 mov	 es,CSEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 esi,THISOBJ_REC ; Get LA of start of this .OBJ record
	 movzx	 ecx,ds:[esi].OBJHDR_LEN ; Get the record length
	 add	 ecx,type OBJHDR_STR ; Plus the size of the header
	 mov	 ebx,5		; Initialize maximum # lines to display
DISPOBJ_REC_NEXT:
	 call	 CLEAR_UNKREC	; Clear MSG_UNKREC fields

	 push	 ecx		; Save for a moment

	 cmp	 ecx,16 	; Display no more than one row of bytes
	 jb	 short @F	; Jump if smaller

	 mov	 ecx,16 	; Use maximum
@@:
	 lea	 edi,MSG_UNKREC ; ES:EDI ==> hex display area

	 REGSAVE <ecx,esi>	; Save for a moment
DISP_OBJREC_NEXT:
	 lods	 ds:[esi].LO	; Get the next byte

	 call	 DB2HEX 	; Convert AL to hex at ES:EDI

	 inc	 edi		; Skip over the intervening blank

	 loop	 DISP_OBJREC_NEXT ; Jump if more bytes to display

	 REGREST <esi,ecx>	; Restore

; Copy the data to the ASCII display area

	 lea	 edi,MSG_UNKREC1 ; ES:EDI ==> ASCII display area
     rep movs	 MSG_UNKREC1[edi],ds:[esi].LO ; Copy to ASCII display area

; Convert cursor control chars in the ASCII display area to blanks

	 mov	 ecx,16 	; # characters to check
	 lea	 edi,MSG_UNKREC1 ; ES:EDI ==> ASCII display area
DISP_OBJREC_NEXTCHAR:
	 cmp	 es:[edi].LO,' ' ; Izit a control char?
	 jae	 short @F	; Jump if not

	 mov	 es:[edi].LO,' ' ; Blank it
@@:
	 inc	 edi		; Skip to next char

	 loop	 DISP_OBJREC_NEXTCHAR ; Jump if more chars to check

; Display the record

	 lea	 edx,MSG_UNKREC ; DS:EDX ==> line to display
	 add	 edx,LaDATA	; Plus LA of DGROUP
	 mov	 ecx,MSG_UNKREC_LEN ; # bytes to write out
	 call	 WRITE_OUT	; Write DS:EDX for ECX bytes to output file

	 pop	 ecx		; Restore

	 dec	 ebx		; Less one line displayed
	 jz	 short @F	; Jump if that's enough

	 sub	 ecx,16 	; Less maximum line length
	 ja	 short DISPOBJ_REC_NEXT ; Jump if more lines to display
@@:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_OBJREC endp		; End DISP_OBJREC procedure
	 NPPROC  CLEAR_UNKREC -- Clear MSG_UNKREC Fields
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear MSG_UNKREC fields

|

	 pushad 		; Save registers

; Clear the hex display area (MSG_UNKREC)

	 lea	 edi,MSG_UNKREC ; ES:EDI ==> format area
	 mov	 ecx,@UNK_LEN	; Get # triples in line
@@:
	 mov	 ax,'  '        ; Get word filler
	 stos	 MSG_UNKREC[edi].ELO ; Fill the word
	 mov	 al,' '         ; Get byte fill
	 stos	 MSG_UNKREC[edi].LO ; Fill the byte
	 loop	 @B		; Jump if more to fill

; Clear the ASCII display area (MSG_UNKREC1)

	 lea	 edi,MSG_UNKREC1 ; ES:EDI ==> format area
	 mov	 ecx,@UNK_LEN	; Get # triples in line
	 mov	 al,' '         ; Get byte fill
     rep stos	 MSG_UNKREC1[edi] ; Fill the ASCII display area

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_UNKREC endp		; End CLEAR_UNKREC procedure
	 NPPROC  CHECK_CSUM -- Validate Checksum
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Validate checksum

The checksum is stored in the last byte of the record.	An
uninitialized checksum is zero.  The sum of all the bytes in the
record (including the checksum) should be zero for the checksum to be
valid.

Some language translators always write zero in this byte.

On entry:

DS:ESI	 ==>	 OMF record

On exit:

CF	 =	 0 if valid
	 =	 1 if not

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save registers

	 xor	 ah,ah		; Initialize accumulator

	 movzx	 ecx,ds:[esi].OBJHDR_LEN ; Get the record length
	 add	 ecx,type OBJHDR_STR ; Plus the size of the header

	 cmp	 ds:[esi+ecx-1].LO,0 ; Is the checksum uninitialized?
	 je	 short CHECK_CSUM_DONE ; Jump if so (note CF=0)
CHECK_CSUM_NEXT:
	 lods	 ds:[esi].LO	; Get the next byte

	 add	 ah,al		; Accumulate it

	 loop	 CHECK_CSUM_NEXT ; Jump if more bytes in the record
CHECK_CSUM_DONE:
	 cmp	 ah,1		; Izit valid?
	 cmc			; Complement so CF=0 is valid, CF=1 is invalid
	 jnc	 short CHECK_CSUM_EXIT ; Jumpif it's valid (note CF=0)

	 push	 dword ptr (offset PGROUP:IWF_CSUMINV) ; Pass offset of action routine
	 push	 IWF_FLAG	; Pass value of flags
	 push	 $IWF_CSUMINV	; Pass offset of bit mask
	 call	 IWF_TEST	; Test for invalid checksum
				; Return with CF=1 if it's fatal
CHECK_CSUM_EXIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CSUM endp 		; End CHECK_CSUM procedure
	 NPPROC  IWF_CSUMINV -- Ignore/Warn/Fail On Invalid Checksum
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Ignore/Warn/Fail about invalid checksum.

|

	 push	 dword ptr (offset DGROUP:MSG_CSUMINV) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_CSUMINV1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IWF_CSUMINV endp		; End IWF_CSUMINV procedure
	 NPPROC  INST_FLTS -- Install Our Fault Handlers
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Install our Fault handlers

|

	 REGSAVE <eax,ebx,ecx,edx> ; Save registers

; Save old INT 05h (Bound Fault) address
; Note that the Borland WINDPMI.386 VxD supports function
; 0212h (@DPMI_SETEPMPEHV), not 0210h (@DPMI_GETEPMPEHV) and for
; Page Faults only (not Bound Faults).

	 mov	 bl,05h 	; Intercept this one
	 DPMICALL @DPMI_GETPEHV ; Return with CX:EDX ==> old handler
	 jc	 short INST_FLTS_ERR05 ; Jump if something went wrong

	 mov	 OLDINT05_FVEC.FOFF,edx ; Save to restore later
	 mov	 OLDINT05_FVEC.FSEL,cx	; ...

; Install our INT 05h handler

	 mov	 cx,cs		; Copy code selector
	 lea	 edx,INT05_UNBOUND ; CX:EDX ==> local INT 0Eh handler
	 mov	 bl,05h 	; Intercept this one
	 DPMICALL @DPMI_SETPEHV ; Set INT BL to CX:EDX
	 jc	 short INST_FLTS_ERR05 ; Jump if something went wrong

; Save old INT 0Eh (Page Fault) address
; In case the DPMI host doesn't support this function (CF=1),
; save the return flag for later use, so we don't attempt to use the
; "return address" in CX:EDX as it isn't valid.

	 mov	 bl,0Eh 	; Intercept this one
	 DPMICALL @DPMI_GETEPMPEHV ; Return with CX:EDX ==> old handler
	 setnc	 OLDINT0E_FLG	; Save whether or not it worked
				; (1 = OLDINT0E_FVEC is valid, 0 = isn't)
	 jc	 short @F	; Jump if something went wrong

	 mov	 OLDINT0E_FVEC.FOFF,edx ; Save to restore later
	 mov	 OLDINT0E_FVEC.FSEL,cx	; ...
@@:

; Install our INT 0Eh handler

	 mov	 cx,cs		; Copy code selector
	 lea	 edx,INT0E_UNPAGE ; CX:EDX ==> local INT 0Eh handler
	 mov	 bl,0Eh 	; Intercept this one
	 DPMICALL @DPMI_SETEPMPEHV ; Set INT BL to CX:EDX
	 jnc	 short INST_FLTS_EXIT ; Jump if OK (note CF=0)
INST_FLTS_ERR0E:
	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_INT0E) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 jmp	 short INST_FLTS_ERRCOM ; Join common error code

INST_FLTS_ERR05:
	 push	 fs		; Pass DGROUP segment
	 push	 dword ptr (offset DGROUP:MSG_INT05) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message
INST_FLTS_ERRCOM:
	 stc			; Mark as in error
INST_FLTS_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_FLTS endp			; End INST_FLTS procedure
	 NPPROC  INT05_UNBOUND -- Handle Unbounded Array Reference
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Unbounded Fault handler

Note that this fault handler does not have an expanded stack frame.

|

INT05_UNB_RET32 struc

INT05_UNB_EGP	db (size PUSHAD_STR)   dup (?) ; Caller's EGPs
INT05_UNB_NXT32 db (size FLTRET32_STR) dup (?) ; The old fault return structure

INT05_UNB_RET32 ends

	 pushad 		; Save all EGP registers
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <es,fs>	; Save registers

	 mov	 es,CSEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 ax,cs		; Copy the expected CS

	 cmp	 ax,[ebp].INT05_UNB_NXT32.FLTRET32_CS ; Izit us faulting?
	 jne	 short INT05_UNBOUND_ORIG ; Jump if not

; Format the faulting CS|EIP into the message

;;;;;;;; xchg	 ax,[ebp].INT05_UNB_NXT32.FLTRET32_CS ; Swap with faulting CS
	 lea	 edi,MSG_BFTERM_CS ; ES:EDI ==> format area
	 call	 DW2HEX 	; Convert AX to hex at ES:EDI

	 lea	 eax,BF_TERM	; Get offset of terminating handler
	 xchg	 eax,[ebp].INT05_UNB_NXT32.FLTRET32_EIP ; Swap with faulting EIP
	 lea	 edi,MSG_BFTERM_EIP ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 clc			; Mark as returning to caller

	 jmp	 short INT05_UNBOUND_EXIT ; Join common exit code

INT05_UNBOUND_ORIG:
	 stc			; Mark as continuing with next handler
INT05_UNBOUND_EXIT:
	 REGREST <fs,es>	; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler about it
	 popad			; Restore
	 jnc	 short INT05_UNBOUND_RETFD ; Jump if we're returning to caller

	 PUSHW	 ds		; Save register

	 mov	 ds,CSEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 push	 OLDINT05_FVEC.FSEL ; Pass selector
	 push	 OLDINT05_FVEC.FOFF ; ...  offset

INT05_EXIT_STR struc

	 dd	 ?		; Return offset
	 dw	 ?		; Return CS
INT05_EXIT_DS dw ?		; Caller's DS

INT05_EXIT_STR ends

	 mov	 ds,[esp].INT05_EXIT_DS ; Restore
	 assume  ds:nothing	; Tell the assembler about it
INT05_UNBOUND_RETFD:
	 RETFD			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT05_UNBOUND endp		; End INT05_UNBOUND procedure
	 NPPROC  INT0E_UNPAGE -- Commit An Uncommitted Page
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Paqe Fault handler

If we're called on an uncommitted page, commit it.

If we fail for some reason, change the return address to that
of a terminator.

|

INT0E_UNP_RET32 struc

INT0E_UNP_EGP	db (size PUSHAD_STR)   dup (?) ; Caller's EGPs
;;;;;_UNP_NXT32 db (size FLTRET32_STR) dup (?) ; The old fault return structure
INT0E_UNP_EXPFR db (size EXPFRAME_STR) dup (?) ; The expanded stack frame

INT0E_UNP_RET32 ends

	 add	 esp,type FLTRET32_STR ; Strip off the old stack frame

	 pushad 		; Save all EGP registers
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <es,fs,gs>	; Save registers

	 mov	 es,CSEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 gs,CSEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

; Figure out which handle this Page Fault is in

	 mov	 eax,[ebp].INT0E_UNP_EXPFR.EXPFRAME_CR2 ; Get the faulting address
	 mov	 ecx,LMBTAB_LEN ; Get # LMB table entries
	 xor	 ebx,ebx	; Initialize index into LMBTAB
INT0E_UNPAGE_NEXTLMB:
	 cmp	 eax,LMBTAB[ebx].LMB_OVRB.BOUND_BEG ; Izit at or above the start?
	 jb	 short @F	; Jump if not

	 cmp	 eax,LMBTAB[ebx].LMB_OVRB.BOUND_NXT ; Izit below the end?
	 jb	 short INT0E_UNPAGE_FOUND_LMB ; Jump if so
@@:
	 add	 ebx,type LMB_STR ; Skip to next entry

	 loop	 INT0E_UNPAGE_NEXTLMB ; Jump if more entries to check


; Maybe it's in segment data

	 mov	 ebx,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get the starting address
INT0E_UNPAGE_NEXTSEG:
	 cmp	 ebx,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 short INT0E_UNPAGE_TERM ; Jump if so

	 cmp	 eax,AGROUP:[ebx].PERSEG_LMB.LMB_OVRB.BOUND_BEG ; Izit at or above start?
	 jb	 short @F	; Jump if not

	 cmp	 eax,AGROUP:[ebx].PERSEG_LMB.LMB_OVRB.BOUND_NXT ; Izit below the end?
	 jb	 short INT0E_UNPAGE_FOUND_SEG ; Jump if so
@@:
	 add	 ebx,type PERSEG_STR ; Skip to next entry

	 jmp	 short INT0E_UNPAGE_NEXTSEG ; Go around again

INT0E_UNPAGE_TERM:
	 mov	 ax,cs		; Copy the expected CS

	 cmp	 OLDINT0E_FLG,1 ; Do we have a valid return address?
	 jne	 short @F	; Jump if not

	 cmp	 ax,[ebp].INT0E_UNP_EXPFR.EXPFRAME_CS ; Izit us faulting?
	 jne	 short INT0E_UNPAGE_ORIG ; Jump if not
@@:

; Format the faulting CS|EIP into the message

	 xchg	 ax,[ebp].INT0E_UNP_EXPFR.EXPFRAME_CS ; Swap with faulting CS
	 lea	 edi,MSG_PFTERM_CS ; ES:EDI ==> format area
	 call	 DW2HEX 	; Convert AX to hex at ES:EDI

	 lea	 eax,PF_TERM	; Get offset of terminating handler
	 xchg	 eax,[ebp].INT0E_UNP_EXPFR.EXPFRAME_EIP ; Swap with faulting EIP
	 lea	 edi,MSG_PFTERM_EIP ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 clc			; Mark as returning to caller

	 jmp	 short INT0E_UNPAGE_EXIT ; Join common exit code

INT0E_UNPAGE_ORIG:
	 stc			; Mark as continuing with next handler

	 jmp	 short INT0E_UNPAGE_EXIT ; Join common exit code

INT0E_UNPAGE_FOUND_SEG:
	 mov	 esi,AGROUP:[ebx].PERSEG_LMB.LMB_HNDL ; Get the block's handle
	 sub	 eax,AGROUP:[ebx].PERSEG_LMB.LMB_OVRB.BOUND_BEG ; Less the starting address

	 jmp	 short INT0E_UNPAGE_FOUND_COM ; Join common code

INT0E_UNPAGE_FOUND_LMB:
	 mov	 esi,LMBTAB[ebx].LMB_HNDL ; Get the block's handle
	 sub	 eax,LMBTAB[ebx].LMB_OVRB.BOUND_BEG ; Less the starting address
INT0E_UNPAGE_FOUND_COM:
	 mov	 ebx,eax	; Get offset within the block
	 mov	 ecx,1		; # pages to commit

; Mark as read/write, committed

	 mov	 UNPAGE_ATTR,@SPATTR_RW or (@SPTYP_COM shl $SPATTR_TYP) ; Mark it

	 lea	 edx,UNPAGE_ATTR ; ES:EDX ==> page attributes

	 DPMICALL @DPMI_SPGATTR ; Set page attributes
	 jc	 near ptr INT0E_UNPAGE_TERM ; Jump if not successful
				; Fall through with CF=0
INT0E_UNPAGE_EXIT:
	 REGREST <gs,fs,es>	; Restore
	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it
	 popad			; Restore
	 jnc	 short INT0E_UNPAGE_RETFD ; Jump if we're returning to caller

	 PUSHW	 ds		; Save register

	 mov	 ds,CSEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 push	 OLDINT0E_FVEC.FSEL ; Pass selector
	 push	 OLDINT0E_FVEC.FOFF ; ...  offset

INT0E_EXIT_STR struc

	 dd	 ?		; Return offset
	 dw	 ?		; Return CS
INT0E_EXIT_DS dw ?		; Caller's DS

INT0E_EXIT_STR ends

	 mov	 ds,[esp].INT0E_EXIT_DS ; Restore
	 assume  ds:nothing	; Tell the assembler about it
INT0E_UNPAGE_RETFD:
	 RETFD			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0E_UNPAGE endp		; End INT0E_UNPAGE procedure
	 NPPROC  ALLOC_LMB -- Allocate Linear Memory Blocks
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Allocate linear memory blocks

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

; Allocate LMBs

	 mov	 ecx,LMBTAB_LEN ; Get # entries in LMBTAB
	 xor	 edi,edi	; Initialize index into LMBTAB
ALLOC_LMB_NEXT:
	 push	 ecx		; Save for a moment

	 xor	 ebx,ebx	; Starting linear address unspecified
	 mov	 ecx,LMBTAB[edi].LMB_LEN ; Allocate this many bytes
	 xor	 edx,edx	; Flags:  uncommitted pages
	 DPMICALL @DPMI_GETLMB	; Return EBX = linear address
				;	 ESI = handle for memory block
	 jc	 short ALLOC_LMB_ERR ; Join common error code

	 mov	 LMBTAB[edi].LMB_HNDL,esi ; Save for later use
	 mov	 LMBTAB[edi].LMB_CURB.BOUND_BEG,ebx ; ...
	 mov	 LMBTAB[edi].LMB_CURB.BOUND_NXT,ebx ; ...

; Note that we don't allow the last two pages of a Linear Memory Block
; to be committed so as to reduce overwriting into the next LMB.

	 mov	 LMBTAB[edi].LMB_OVRB.BOUND_BEG,ebx ; ...
	 add	 ebx,ecx	; Plus length of the array
	 sub	 ebx,2*@CON4KB+1 ; Less 2*4KB+1 to get ending address
	 mov	 LMBTAB[edi].LMB_OVRB.BOUND_NXT,ebx ; Save for later use

	 add	 edi,type LMB_STR ; Skip to next table entry

	 pop	 ecx		; Restore

	 loop	 ALLOC_LMB_NEXT ; Jump if more entries to process

	 clc			; Mark as successful

	 jmp	 short ALLOC_LMB_EXIT ; Join common exit code

ALLOC_LMB_ERR:
	 inc	 ERRCNT 	; Mark as writing to error file

	 push	 fs		; Pass DGROUP selector
	 push	 dword ptr (offset DGROUP:MSG_LMB) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 stc			; Mark as in error
ALLOC_LMB_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALLOC_LMB endp			; End ALLOC_LMB procedure
	NPPROC	REL_LMB -- Release Linear Memory Blocks
	assume	ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Release linear memory blocks

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save registers

; Release LMBs in the per-segment tables

	mov	ebx,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get the starting address
REL_LMB_NEXT1:
	cmp	ebx,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	je	short REL_LMB_END1 ; Jump if so

	mov	esi,AGROUP:[ebx].PERSEG_LMB.LMB_HNDL ; Get the memory handle

	cmp	esi,-1		; Izit invalid?
	je	short @F	; Jump if so

	mov	di,si		; Setup so
	shr	esi,16		; ...SI:DI = memory handle
	DPMICALL @DPMI_RELMEM	; Release memory handle SI:DI
	jnc	short @F	; Jump if successful

	int	03h		; Call our debugger
@@:
	add	ebx,type PERSEG_STR ; Skip to next entry

	jmp	REL_LMB_NEXT1	; Go around again

REL_LMB_END1:

; Release LMBs

	mov	ecx,LMBTAB_LEN	; Get # entries in LMBTAB
	xor	ebx,ebx 	; Initialize index into LMBTAB
REL_LMB_NEXT2:
	mov	esi,LMBTAB[ebx].LMB_HNDL ; Get the memory handle
	mov	di,si		; Setup so
	shr	esi,16		; ...SI:DI = block's handle
	DPMICALL @DPMI_RELMEM	; Release memory handle SI:DI
	jnc	short @F	; Jump if successful

	int	03h		; Call our debugger
@@:
	add	ebx,type LMB_STR ; Skip to next table entry

	loop	REL_LMB_NEXT2	; Jump if more entries to process

	clc			; Mark as successful

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REL_LMB endp			; End REL_LMB procedure
	 NPPROC  SETUP_NEWOBJ -- Setup A New .OBJ File
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Setup a new .OBJ file

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pushad 		; Save registers

	 mov	 ebx,THISOBJ_FID ; Get address of (Count, Char[])

; Zero the PEROBJ fields

.errnz (4-1) and (type PEROBJ_STR)
	 mov	 ecx,(type PEROBJ_STR)/4 ; # dwords in struc
	 xor	 eax,eax	; Fill with this
	 mov	 LAST_DATREC,eax ; Clear LA of last LEDATA/LIDATA/COMDAT record
	 mov	 edi,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Get LA of next entry

	 UNCURB  edi,PEROBJ	; Ensure within current bounds
     rep stos	 AGROUP:[edi].EDD ; Zero the fields

	 xchg	 LMB_PEROBJ.LMB_CURB.BOUND_NXT,edi ; Save for next time, get old value

;;;;;;;; UNCURB  edi,PEROBJ	; Ensure within current bounds
	 mov	 AGROUP:[edi].PEROBJ_PFID,ebx ; Save LA of (Count, Char[]) of FID

; Start LMBTAB_INI over again and calculate maximum sizes

	 mov	 ecx,LMBTAB_INI_LEN ; Get # LMBs to re-initialize
	 xor	 ebx,ebx	; Initialize index to LMBTAB_INI
	 xor	 edx,edx	; ...		      MAXINI
SETUP_NEWOBJ_NEXT:
	 mov	 eax,LMBTAB_INI[ebx].LMB_CURB.BOUND_BEG ; Get the starting address
	 xchg	 LMBTAB_INI[ebx].LMB_CURB.BOUND_NXT,eax ; Start over again
	 sub	 eax,LMBTAB_INI[ebx].LMB_CURB.BOUND_NXT ; Subtract to get length

	 cmp	 eax,MAXINI[edx*(type MAXINI)] ; Izit any bigger?
	 jbe	 short @F	; Jump if not

	 mov	 MAXINI[edx*(type MAXINI)],eax ; Same larger size
@@:
	 add	 ebx,type LMB_STR ; Skip to next LMBTAB_INI entry
	 inc	 edx		; ...		 MAXINI ...

	 loop	 SETUP_NEWOBJ_NEXT ; Jump if more LMBs to re-initialize

; Invalidate the method fields in the thread strucs

	 mov	 ecx,4		; Get # threads
	 xor	 ebx,ebx	; Inititalize index
@@:
	 mov	 F_THREAD[ebx].THRED_M,-1 ; Invalidate it
	 mov	 T_THREAD[ebx].THRED_M,-1 ; ...
	 add	 ebx,type THRED_STR ; Skip to next entry

	 loop	 @B		; Jump if more method fields to invalidate

; Save the starting address of the LINNUM_STR records

	 mov	 eax,LMB_LINNUM.LMB_CURB.BOUND_NXT ; Get LA of next entry
	 UNCURB  edi,PEROBJ	; Ensure within current bounds
	 mov	 AGROUP:[edi].PEROBJ_PLINNUM,eax ; Save LA of line #s (LINNUM_STR)

	 clc			; Mark as successful

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_NEWOBJ endp		; End SETUP_NEWOBJ procedure
	 NPPROC  CHECK_CNT -- Check Record Count
	 assume  ds:AGROUP,es:AGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Check the record count to ensure it comes out even.

On entry:

DS:ESI	 ==>	 checksum byte (if count is correct)

On exit:

CF	 =	 0 if correct
	 =	 1 if not

|

	 REGSAVE <esi>		; Save register

	 inc	 esi		; Skip over the checksum byte

	 cmp	 esi,NEXTOBJ_REC ; Are we at the end?
	 je	 short CHECK_CNT_EXIT ; Jump if so (note CF=0)

	 inc	 ERRCNT 	; Mark as writing to error file

	 inc	 IWFCNT[@IWF_FAL*(type IWFCNT)] ; Count in a failure

	 push	 dword ptr (offset DGROUP:MSG_OBJREC) ; Pass offset of message
	 push	 dword ptr (offset DGROUP:MSG_OBJREC1) ; ...
	 call	 DISP_ERRDD	; Format and fill in a DD and display error msg

	 dec	 ERRCNT 	; Mark as no longer writing to error file

	 stc			; Mark as in error
CHECK_CNT_EXIT:
	 REGREST <esi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CNT endp			; End CHECK_CNT procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_OBJ module
