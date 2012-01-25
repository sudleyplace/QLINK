;' $Header:   P:/PVCS/MISC/QLINK/QLNK_ARG.ASV   1.2   07 Aug 1998 16:00:06   BOB  $
	 title	 QLNK_ARG -- QLINK Argument Processor
	 page	 58,122
	 name	 QLNK_ARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-8 Qualitas, Inc.  All rights reserved.

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
	 include OPEN.INC

	 include QLNK_COM.INC
	 include QLNK_LIN.INC
	 include QLNK_SEG.INC
.list

PSPGRP	 group	 PSP_SEG


BUFINP_STR struc		; DOS Function 0Ah (@BKEYIN) structure

BUFINP_MAX db	 ?		; Maximum # characters buffer can hold
				; (including CR)
BUFINP_LEN db	 ?		; Actual length (excluding CR)
BUFINP_BUF db	 ?		; Buffer contents start here

BUFINP_STR ends


FSAMAC	 macro	 SYM,ACT

if FSA_CNT eq 0
	 public  FSATAB
FSATAB	 label	 dword
endif				; IF FSA_CNT eq 0

SYM	 =	 FSA_CNT	;; Define the symbol *MUST* use "=" not "equ"
FSA_CNT  =	 FSA_CNT+(type FSATAB) ;; Next index in FSATAB
	 dd	 offset NGROUP:CONV_ARF_&ACT ;; Entry in ACTION table

	 endm			; FSAMAC


PSP_SEG  segment use16 para at 0 ; Start PSP_SEG segment
	 assume  cs:PSPGRP

.xlist
	 include PSP.INC	; Define PSP area
.list

PSP_SEG  ends			; End PSP_SEG segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 LCL_FLAG:dword
	 include QLNK_LCL.INC

	 extrn	 NEXTSEG:word
	 extrn	 HIGHSEG:word
	 extrn	 PSPSEG:word
	 extrn	 LaLIBENV:dword
	 extrn	 NONULLS_OFF:dword

	 public  ARG_FLAG
	 include QLNK_ARG.INC
ARG_FLAG dd	 0		; Argument flags

	 public  LNKENV_VEC
LNKENV_VEC dd	 ?		; Seg:Off of QLINK= environment variable

	 public  DEFEXT_VEC,EXEFIL_EXTVEC
DEFEXT_VEC dd	 ?		; Seg:off where default extension appended
EXEFIL_EXTVEC dd ?		; DEFEXT_VEC for .EXE/.COM file

	 public  NUMBERS_LO,NUMBERS_HI
NUMBERS_LO db	 '0123456789abcdef' ; Conversion table
NUMBERS_HI db	 '0123456789ABCDEF' ; ...

	 public  SEGOBJ_1ST,SEGOBJ_LAST
SEGOBJ_1ST dw	 0		; Segment of 1st .OBJ file
SEGOBJ_LAST dw	 ?		; ...	     last ...

	 public  LaLIB_1ST,LaLIB_LAST
LaLIB_1ST dd	 0		; LA of 1st .LIB file
LaLIB_LAST dd	 ?		; ...	last ...

	 public  PFLDS
PFLDS	 dd	 @NFLDS dup (?) ; Pointers to field entries

	 public  FIELDNO
FIELDNO  dd	 0		; Field #:  0=objfiles,
				;	    1=exefile,
				;	    2=mapfile,
				;	    3=libraries,
				;	    4=deffile

	 public  PFID_FVEC,PFID_LEN
PFID_FVEC df	 ?		; Seg:Off to main filename.ext
PFID_LEN dw	 ?		; Length of ...

	 public  PNUL_FVEC
PNUL_FVEC label  fword		; Seg:Off to NUL filename
	 dd	 offset DGROUP:PMTNUL ; Offset of NUL filename
	 dw	 seg DGROUP	; Segment of ...
PNUL_LEN  dw	 PMTNUL_LEN	; Length of

	 public  PDISP
PDISP	 dw	 offset NGROUP:DISPOBJ ; Display routine for .OBJ
	 dw	 offset NGROUP:DISPEXE ; ...		     .EXE/.COM
	 dw	 offset NGROUP:DISPMAP ; ...		     .MAP
	 dw	 offset NGROUP:DISPLIB ; ...		     .LIB
	 dw	 offset NGROUP:DISPDEF ; ...		     .DEF

	 public  INPBUF_VEC
INPBUF_VEC dd	 ?		; Seg:Off of input buffer
@BUFSEG_LEN equ  256		; Length in bytes of input buffer (/16)

	 public  CUR_STATE
CUR_STATE dd	 @INI		; Current state, starting with the initial one

; The following table represents a Finite State Automaton for
; processing the .ARF file contents

; Symbols & Actions for FSA states

FSA_CNT  =	 0			; Initialize counter

; Recurring states

	 FSAMAC  @INI,	NEXT	; Initial state
	 FSAMAC  @WHT,	NEXT	; White space
	 FSAMAC  @FLD,	SAVE	; Field marker
	 FSAMAC  @PL1,	NEXT	; Plus
	 FSAMAC  @PLF,	NEXT	; Plus, LF
	 FSAMAC  @NAM,	SAVE	; Name
	 FSAMAC  @NAMW, NEXT	; Name, white space

	 FSAMAC  @INIS, SAVE	; Initial state, switch
	 FSAMAC  @WHTS, SAVE	; White space, switch
	 FSAMAC  @FLDS, SAVE	; Field marker, switch
	 FSAMAC  @PL1S, SAVE	; Plus, switch
	 FSAMAC  @PLFS, SAVE	; Plus, LF, switch
	 FSAMAC  @NAMS, SAVE	; Name, switch
	 FSAMAC  @NAMWS,SAVE	; Name, white space, switch

; One-time states

	 FSAMAC  @WNAM, WNAM	; White space, name
	 FSAMAC  @PNAM, PNAM	; Plus, name or plus, LF, name
	 FSAMAC  @INIF, INIF	; Save Field marker, goto initial state

	 public  FSASTM
FSASTM	 label	 dword		; State Transition Matrix
; Char in AL is
;   ' '    '+'    ','    '/'    LF    Name
dd @WHT,  @PL1,  @FLD,	@INIS, @INIF, @NAM    ; INI:   Initial state
dd @WHT,  @PL1,  @FLD,	@WHTS, @INIF, @WNAM   ; WHT:   White space
dd @FLD,  @PL1,  @FLD,	@FLDS, @WHT,  @NAM    ; FLD:   Field marker
dd @PL1,  @PL1,  @FLD,	@PL1S, @PLF,  @PNAM   ; PL1:   Plus
dd @PL1,  @PL1,  @FLD,	@PLFS, @INIF, @PNAM   ; PLF:   Plus LF
dd @NAMW, @PL1,  @FLD,	@NAMS, @INIF, @NAM    ; NAM:   Name
dd @NAMW, @PL1,  @FLD,	@NAMWS,@INIF, @PNAM   ; NAMW:  Name, white space

dd @WHT,  @PL1,  @FLD,	@INIS, @INIF, @INIS   ; INIS:  Initial state, switch
dd @WHT,  @PL1,  @FLD,	@WHTS, @INIF, @WHTS   ; WHTS:  White space, switch
dd @FLD,  @PL1,  @FLD,	@FLDS, @WHT,  @FLDS   ; FLDS:  Field marker, switch
dd @PL1,  @PL1,  @FLD,	@PL1S, @PLF,  @PL1S   ; PL1S:  Plus, switch
dd @PL1,  @PL1,  @FLD,	@PLFS, @INIF, @PLFS   ; PLFS:  Plus LF, switch
dd @NAMW, @PL1,  @FLD,	@NAMS, @INIF, @NAMS   ; NAMS:  Name, switch
dd @NAMW, @PL1,  @FLD,	@NAMWS,@INIF, @NAMWS  ; NAMWS: Name, white space, switch

	 public  LASTKEY,LASTCHAR
LASTKEY  dw	 ?		; Offset of last keyword
LASTCHAR db	 ?		; Last character in DISPOBJ input

	 public  FSASPEC
FSASPEC  db	 ' +,/',LF,LF   ; Special characters for FSA
				; Note LF is repeated, the 2nd one is the
				; placeholder for name
FSASPEC_LEN equ  $-FSASPEC	; Length of each row in the FSA_TAB

	 public  MSG_SEP,MSG_UNK,MSG_UNKCFG,MSG_UNKENV,MSG_OVF,MSG_UNF
	 public  MSG_FLD,MSG_OBJ
MSG_SEP  db	 '様> FAIL:  Missing separator.',CR,LF,EOS
MSG_UNK  db	 '様> FAIL:  Unknown keyword:  ',EOS
MSG_UNKCFG db	 '様> FAIL:  Unknown keyword in .CFG file:  ',EOS
MSG_UNKENV db	 '様> FAIL:  Unknown keyword in ',@PRODNAME,'= variable:  ',EOS
MSG_OVF  db	 '様> FAIL:  Value too large:  ',EOS
MSG_UNF  db	 '様> FAIL:  Value too small:  ',EOS
MSG_FLD  db	 '様> FAIL:  Too many fields.',CR,LF,EOS
MSG_OBJ  db	 '様> FAIL:  No .OBJ files specified.',CR,LF,EOS

	 public  PMTNUL
PMTNUL	 db	 'NUL'          ; NUL filename
PMTNUL_LEN equ	 $-PMTNUL	; Length of ...

	 public  PMTOBJ,PMTEXE1,PMTEXE2,PMTMAP2,PMTMAP2,PMTLIB,PMTDEF
PMTOBJ	 db	 'Object Module [.OBJ]: ',EOS
PMTEXE1  db	 'Executable File [',EOS
PMTEXE2  db	 '.EXE]: ',EOS
PMTMAP1  db	 'Map File [',EOS
PMTMAP2  db	 '.MAP]: ',EOS
PMTLIB	 db	 'Libraries [.LIB]: ',EOS
PMTDEF	 db	 'Definition File [.DEF]: ',EOS

	 public  ERR_ARF1,ERR_ARF2,ERR_CFG,ERR_CFGSW,ERR_ENVSW
ERR_ARF1 db	 '様> FAIL:  Unable to open response file.',CR,LF,EOS
ERR_ARF2 db	 '様> FAIL:  Unable to read response file.',CR,LF,EOS
ERR_CFG  db	 '様> FAIL:  Unable to read ',@PRODNAME,'.CFG file.',CR,LF,EOS
ERR_CFGSW db	 '様> FAIL:  Invalid switch in ',@PRODNAME,'.CFG file.',CR,LF,EOS
ERR_ENVSW db	 '様> FAIL:  Invalid switch in ',@PRODNAME,'= variable.',CR,LF,EOS

	 public  EXT_OBJ,EXT_EXE,EXT_COM,EXT_MAP,EXT_LIB,EXT_DEF
EXT_OBJ  db	 '.OBJ'         ; Default extension for .OBJ file
EXT_EXE  db	 '.EXE'         ; ...                   .EXE ...
EXT_COM  db	 '.COM'         ; ...                   .COM ...
EXT_MAP  db	 '.MAP'         ; ...                   .MAP ...
EXT_LIB  db	 '.LIB'         ; ...                   .LIB ...
EXT_DEF  db	 '.DEF'         ; ...                   .DEF ...

	 public  CFGNAME
CFGNAME  db	 @PRODNAME,'.CFG',0 ; Configuration file name
CFGNAME_LEN equ  $-CFGNAME	; Length of ...

	 public  ENVNAME
ENVNAME  db	 @PRODNAME,'='  ; Environment variable name
ENVNAME_LEN equ  $-ENVNAME	; Length of ...

	 public  MSG_CRLF
MSG_CRLF db	 CR,LF,EOS

	 public  LCLFID
LCLFID	 db	 128 dup (0)	; Local storage for main FID

DATA	 ends			; End DATA segment


	 INISEG_MAC CMD

; All keywords in this table *MUST* be in uppercase

  LINARG_MAC '/ALIGN',                   '/A',        FCN_ALIGN

  LINARG_MAC '/BATCH',                   '/B',        FCN_BATCH

  LINARG_MAC '/CODEVIEW',                '/CO',       FCN_CODEVIEW
  LINARG_MAC '/CPARMAXALLOC',            '/CP',       FCN_CPARMAXALLOC

  LINARG_MAC '/DEBUG',                   '/DEBUG',    FCN_DEBUG
  LINARG_MAC '/DOSSEG',                  '/DOSS',     FCN_DOSSEG
  LINARG_MAC '/DSALLOCATE',              '/DS',       FCN_DSALLOCATE
  LINARG_MAC '/DYNAMIC',                 '/DY',       FCN_DYNAMIC

  LINARG_MAC '/EXEPACK',                 '/E',        FCN_EXEPACK

  LINARG_MAC '/FARCALLTRANSLATION',      '/F',        FCN_FARCALLTRANSLATION

;;LINARG_MAC '/HELP',                    '/HE',       FCN_HELP
  LINARG_MAC '/HIGH',                    '/HI',       FCN_HIGH

  LINARG_MAC '/INFORMATION',             '/I',        FCN_INFORMATION

  LINARG_MAC '/LINENUMBERS',             '/L',        FCN_LINENUMBERS

  LINARG_MAC '/MAP',                     '/M',        FCN_MAP

  LINARG_MAC '/NODEFAULTLIBRARYSEARCH',  '/NOD',      FCN_NODEFAULTLIBRARYSEARCH
  LINARG_MAC '/NOEXTDICTIONARY',         '/NOE',      FCN_NOEXTDICTIONARY
  LINARG_MAC '/NOFARCALLTRANSLATION',    '/NOF',      FCN_NOFARCALLTRANSLATION
;;LINARG_MAC '/NOGROUPASSOCIATION',      '/NOG',      FCN_NOGROUPASSOCIATION
  LINARG_MAC '/NOIGNORECASE',            '/NOI',      FCN_NOIGNORECASE
  LINARG_MAC '/NOLOGO',                  '/NOL',      FCN_NOLOGO
  LINARG_MAC '/NONULLSDOSSEG',           '/NON',      FCN_NONULLSDOSSEG
  LINARG_MAC '/NOPACKCODE',              '/NOPACKC',  FCN_NOPACKCODE
  LINARG_MAC '/NOPACKDATA',              '/NOPACKD',  FCN_NOPACKDATA
  LINARG_MAC '/NOPACKFUNCTIONS',         '/NOPACKF',  FCN_NOPACKFUNCTIONS
  LINARG_MAC '/NOSWAP',                  '/NOS',      FCN_NOSWAP

;;LINARG_MAC '/OLDOVERLAY',              '/OL',       FCN_OLDOVERLAY
  LINARG_MAC '/ONERROR',                 '/ON',       FCN_ONERROR
  LINARG_MAC '/OPTHEADER',               '/OP',       FCN_OPTHEADER
;;LINARG_MAC '/OVERLAYINTERRUPT',        '/OV',       FCN_OVERLAYINTERRUPT

  LINARG_MAC '/PACKCODE',                '/PACKC',    FCN_PACKCODE
  LINARG_MAC '/PACKDATA',                '/PACKD',    FCN_PACKDATA
  LINARG_MAC '/PACKFUNCTIONS',           '/PACKF',    FCN_PACKFUNCTIONS
;;LINARG_MAC '/PAUSE',                   '/PAU',      FCN_PAUSE
;;LINARG_MAC '/PCODE',                   '/PC',       FCN_PCODE
;;LINARG_MAC '/PMTYPE',                  '/PM',       FCN_PMTYPE

;;LINARG_MAC '/QUICKLIBRARY',            '/Q',        FCN_QUICKLIBRARY

  LINARG_MAC '/R',                       '/R',        FCN_R

  LINARG_MAC '/SEGMENTS',                '/SE',       FCN_SEGMENTS
  LINARG_MAC '/STACK',                   '/ST',       FCN_STACK

  LINARG_MAC '/TINY',                    '/T',        FCN_TINY

  LINARG_MAC '/WARNFIXUP',               '/W',        FCN_WARNFIXUP

  LINARG_MAC '/?',                       '/?',        FCN_QUICKHELP

	 ENDSEG_MAC CMD


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP,ds:NGROUP

	 extrn	 DATASEG:word

	 NPPROC  CHECK_ARGS -- Check for Arguments
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for arguments

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,fs>	; Save segment registers

	 mov	 ax,es		; Copy DGROUP segment
	 mov	 fs,ax		; Address it
	 assume  fs:DGROUP	; Tell the assembler about it

; Make room for the input buffer

	 mov	 ax,NEXTSEG	; Get next available segment
	 mov	 INPBUF_VEC.VSEG,ax ; Save for later use
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds:[0].BUFINP_MAX,@BUFSEG_LEN-2 ; Set the length

	 add	 ax,@BUFSEG_LEN/16 ; Skip over it
	 mov	 NEXTSEG,ax	; Protect the input buffer

	 mov	 ds,PSPSEG	; Address the PSP
	 assume  ds:PSPGRP	; Tell the assembler about it

	 call	 PROC_ENV	; Process the environment variable
	 jc	 near ptr CHECK_ARGS_EXIT ; Jump if error (note CF=1)

	 call	 PROC_CFG	; Process the .CFG file
	 jc	 near ptr CHECK_ARGS_EXIT ; Jump if error (note CF=1)

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line
	 movzx	 bx,PSP_PARM_COUNT ; Get length of ...
	 mov	 ds:[bx+si].LO,EOF ; Ensure properly terminated

	 call	 CHECK_ARGS_SUB ; Handle via subroutine
	 jc	 near ptr CHECK_ARGS_EXIT ; Jump if error (note CF=1)

	 call	 FIND_MAIN	; Find the name of the main file
	 jnc	 short CHECK_ARGS_OKOBJ ; Jump if found

	 test	 ARG_FLAG,@ARG_BATCH ; Running in batch mode?
	 jz	 short CHECK_ARGS_PMTOBJ ; Jump if not

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_OBJ) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 stc			; Mark as in error

	 jmp	 CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS_PMTOBJ:

; Prompt for .OBJ files

	 push	 dword ptr (offset DGROUP:PMTOBJ) ; Pass the offset
	 call	 GET_BUFINP	; Get buffered input

	 lds	 si,INPBUF_VEC	; DS:SI ==> buffer struc
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	 call	 DISPOBJ	; Display .OBJ files from DS:SI

	 call	 FIND_MAIN	; Find the name of the main file
	 jc	 short CHECK_ARGS_PMTOBJ ; Jump if not found
CHECK_ARGS_OKOBJ:
	 cmp	 PFLDS[@FLD_EXE*(type PFLDS)],0 ; Izit filled in?
	 jne	 short CHECK_ARGS_OKEXE ; Jump if so

	 test	 LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	 jnz	 short CHECK_ARGS_DEFEXE ; Use the default value

; Prompt for .EXE file

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTEXE1) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 PFID_LEN	; Pass the length in bytes
	 push	 PFID_FVEC.FSEL ; Pass segment of message
	 push	 PFID_FVEC.FOFF ; ...  offset ...
	 call	 U16_DISP_MSGL	; Display the message

	 push	 dword ptr (offset DGROUP:PMTEXE2) ; Pass offset of message
	 call	 GET_BUFINP	; Get buffered input

	 lds	 si,INPBUF_VEC	; DS:SI ==> buffer struc
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	 call	 DISPEXE	; Display .EXE file from DS:SI

	 jmp	 short CHECK_ARGS_OKEXE ; Join common code

; Use the default name for the .EXE file

CHECK_ARGS_DEFEXE:
	 lds	 esi,PFID_FVEC	; DS:SI ==> base filename
	 assume  ds:nothing	; Tell the assembler about it

	 call	 DISPEXE	; Display .EXE file from DS:SI
CHECK_ARGS_OKEXE:
	 cmp	 PFLDS[@FLD_MAP*(type PFLDS)],0 ; Izit filled in?
	 jne	 near ptr CHECK_ARGS_OKMAP ; Jump if so

	 test	 ARG_FLAG,@ARG_MAP ; Izit present?
	 jz	 short @F	; Jump if not

	 lds	 si,PFLDS[@FLD_EXE*(type PFLDS)] ; DS:SI ==> EXE filename
	 assume  ds:nothing	; Tell the assembler about it

	 call	 FIND_FIDBEG	; Find start of FID in DS:SI
				; Return with DS:DX ==> start of FID, CX = length
	 call	 DISPMAP_ALLOC	; Allocate CX bytes for DS:DX
@@:
	 test	 LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	 jnz	 short CHECK_ARGS_OKMAP ; Skip it (we don't require one)

; Prompt for .MAP file

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTMAP1) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 test	 ARG_FLAG,@ARG_MAP ; Izit present?
	 jnz	 short CHECK_ARGS_MAP1 ; Jump if so

	 push	 PNUL_LEN	; Pass the length in bytes
	 push	 PNUL_FVEC.FSEL ; Pass segment of message
	 push	 PNUL_FVEC.FOFF ; ...  offset ...
	 call	 U16_DISP_MSGL	; Display the message

	 jmp	 short CHECK_ARGS_MAPCOM ; Join common code

CHECK_ARGS_MAP1:
	 push	 PFID_LEN	; Pass the length in bytes
	 push	 PFID_FVEC.FSEL ; Pass segment of message
	 push	 PFID_FVEC.FOFF ; ...  offset ...
	 call	 U16_DISP_MSGL	; Display the message
CHECK_ARGS_MAPCOM:
	 push	 dword ptr (offset DGROUP:PMTMAP2) ; Pass offset of message
	 call	 GET_BUFINP	; Get buffered input

	 lds	 si,INPBUF_VEC	; DS:SI ==> buffer struc
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	 call	 DISPMAP	; Display .MAP file from DS:SI
CHECK_ARGS_OKMAP:
	 cmp	 PFLDS[@FLD_LIB*(type PFLDS)],0 ; Izit filled in?
	 jne	 short CHECK_ARGS_OKLIB ; Jump if so

	 test	 LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	 jnz	 short CHECK_ARGS_OKLIB ; Skip it (we don't require one)

; Prompt for .LIB files

	 push	 dword ptr (offset DGROUP:PMTLIB) ; Pass offset of message
	 call	 GET_BUFINP	; Get buffered input

	 lds	 si,INPBUF_VEC	; DS:SI ==> buffer struc
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	 call	 DISPLIB	; Display .LIB files from DS:SI
CHECK_ARGS_OKLIB:
	 call	 FIND_LIBENV	; Find LIB= environment variable

	 cmp	 PFLDS[@FLD_DEF*(type PFLDS)],0 ; Izit filled in?
	 jne	 short CHECK_ARGS_OKDEF ; Jump if so

	 test	 LCL_FLAG,@LCL_ENDFLD ; Ending field marker present?
	 jnz	 short CHECK_ARGS_OKDEF ; Skip it (we don't require one)

; Prompt for .DEF file

	 push	 dword ptr (offset DGROUP:PMTDEF) ; Pass offset of message
	 call	 GET_BUFINP	; Get buffered input

	 lds	 si,INPBUF_VEC	; DS:SI ==> buffer struc
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	 call	 DISPDEF	; Display .DEF file from DS:SI
CHECK_ARGS_OKDEF:

COMMENT|

If /DOSSEG is specified
    If /NONULLSDOSSEG is not specified
       Set NONULLS_OFF to 0010h (one NULL para)
|

	 mov	 NONULLS_OFF,0	; No NULL para at start of _TEXT segment

	 test	 ARG_FLAG,@ARG_DOSSEG ; Is /DOSSEG specified?
	 jz	 short @F	; Jump if not

	 test	 ARG_FLAG,@ARG_NONULLS ; Is /NONULLSDOSSEG specified?
	 jnz	 short @F	; Jump if so

	 mov	 NONULLS_OFF,0010h ; Insert one para at start of _TEXT segment
@@:

; Parse the .DEF file (if present)

	 cmp	 PFLDS[@FLD_DEF*(type PFLDS)],0 ; Izit filled in?
	 je	 short @F	; Jump if not

	 call	 CHECK_DEFFILE	; Check it out
	 jc	 short CHECK_ARGS_EXIT ; Jump on error (note CF=1)
@@:











CHECK_ARGS_CLC:
	 clc			; Indicate all went well
CHECK_ARGS_EXIT:
	 REGREST <fs,ds>	; Restore
	 assume  ds:DGROUP,fs:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  PROC_ENV -- Process The Environment Variable
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Process the environment variable

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pusha			; Save registers
	 REGSAVE <ds,es>	; ...

	 call	 FIND_LNKENV	; Find QLINK= environment variable

	 cmp	 LNKENV_VEC,0	; Izit present?
	 je	 short PROC_ENV_EXIT ; Jump if not (ntoe CF=0)

	 lds	 si,LNKENV_VEC	; DS:SI ==> QLINK=, zero-terminated
	 assume  ds:nothing	; Tell the assembler about it

	 call	 STR_UPPER	; Convert the string at DS:SI to upper case
	 or	 LCL_FLAG,@LCL_ENV ; Mark as processing environment variable
PROC_ENV_NEXT:
	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,0		; Izit EOF marker?
	 je	 short PROC_ENV_EXIT ; Jump if so (note CF=0)

	 cmp	 al,'/'         ; Izit switch marker?
	 jne	 short PROC_ENV_ERRSW ; Jump if so

	 push	 dword ptr (offset DGROUP:TAB_CMDSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
	 jc	 short PROC_ENV_EXIT ; Jump if error (note CF=1)

	 jmp	 PROC_ENV_NEXT	; Go around again


PROC_ENV_ERRSW:
	 push	 fs		; Pass the segment
	 push	 dword ptr (offset DGROUP:ERR_ENVSW) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 stc			; Mark as in error
PROC_ENV_EXIT:
	 pushf			; Save flgs (CF in particular)
	 and	 LCL_FLAG,not @LCL_ENV ; Mark as no longer processing environment variable
	 popf			; Restore

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popa			; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_ENV endp			; End PROC_ENV procedure
	 NPPROC  FIND_LNKENV -- Find QLINK= Environment Variable
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Find QLINK= environment variable

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 mov	 es,PSPSEG	; Address the PSP
	 assume  es:PSPGRP	; Tell the assembler about it

	 mov	 es,PSP_ENVIR_PTR ; Get segment of our environment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> start of environment
	 mov	 cx,8000h	; Maximum size of environment
FIND_LNKENV_NEXT:
	 cmp	 es:[di].LO,0	; Izit the end of the line?
	 je	 short FIND_LNKENV_EXIT ; Jump if so

; Search for QLINK=

	 REGSAVE <cx,di>	; Save for a moment

	 lea	 si,ENVNAME	; Get offset of QLINK=
	 mov	 cx,ENVNAME_LEN ; Get length of ...
    repe cmps	 ENVNAME[si],es:[di].LO ; Izit the same?
	 REGREST <di,cx>	; Restore
	 je	 short FIND_LNKENV_OK ; Jump if so

	 mov	 al,0		; Terminator value
   repne scas	 es:[di].LO	; Search for it
	 jne	 short FIND_LNKENV_EXIT ; Jump if not found

	 jmp	 FIND_LNKENV_NEXT ; Go around again


FIND_LNKENV_OK:
	 add	 di,ENVNAME_LEN ; Skip over QLINK=
	 mov	 LNKENV_VEC.VOFF,di ; Save offset
	 mov	 LNKENV_VEC.VSEG,es ; Save segment
FIND_LNKENV_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_LNKENV endp		; End FIND_LNKENV procedure
	 NPPROC  PROC_CFG -- Process .CFG File
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Process the .CFG file

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 pusha			; Save registers
	 REGSAVE <ds,es>	; ...

; Look for a QLINK.CFG file first in the current directory and,
; if not found there, in the directory from which QLINK.EXE is loaded.

	 mov	 ax,fs		; Get DGROUP segment
	 mov	 ds,ax		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 al,@OPEN_R	; Open as read-only
	 DOSCALL @OPENF2,CFGNAME ; Attempt to open the CFG file in cur dir
	 jnc	 short PROC_CFG_OPEN ; Jump if file found

; Try the directory from which QLINK.EXE was loaded

; Construct the filename to open in the next available segment

	 mov	 ds,PSPSEG	; Address the PSP
	 assume  ds:PSPGRP	; Tell the assembler about it

	 mov	 es,PSP_ENVIR_PTR ; Get segment of our environment
	 assume  es:nothing	; Tell the assembler about it

; Search for the end of environment to find the
; strings section (right next to the woodwinds)

	 xor	 di,di		; Start at offset 0
	 mov	 cx,8000h	; Maximum size of environment
	 mov	 al,0		; Search for this terminator (twice)
@@:
   repne scas	 es:[di].LO	; Search for it
	 jne	 near ptr PROC_CFG_DONE ; Jump if not found (just done)

	 and	 cx,cx		; Is there another byte?
	 jz	 near ptr PROC_CFG_DONE ; Jump if not found (just done)

	 scas	 es:[di].LO	; Izit here twice?
	 jne	 short @B	; Jump if not

; ES:DI  ==>	 end of environment (string count word)

	 lea	 si,es:[di+2]	; Skip over the string count word

	 mov	 ax,es		; Get segment of the environment
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

; DS:SI  ==>	 'd:\path\QLINK.EXE',0

	 mov	 es,NEXTSEG	; Get next available segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> next available segment

; Copy the string to the next available segment

	 xor	 cx,cx		; Mark as no path/drive separator
PROC_CFG_NEXTPATH:
	 lods	 ds:[si].LO	; Get the next byte

	 cmp	 al,'\'         ; Izit path separator
	 jne	 short @F	; Jump if not

	 lea	 cx,es:[di+1]	; Copy address of byte after path/drive sep
@@:
	 cmp	 al,':'         ; Izit drive separator
	 jne	 short @F	; Jump if not

	 lea	 cx,es:[di+1]	; Copy address of byte after path/drive sep
@@:
	 cmp	 al,0		; Izit the end?
	 je	 short @F	; Jump if so

	 stos	 es:[di].LO	; Save in

	 jmp	 PROC_CFG_NEXTPATH ; Go around again

@@:

; If there was a path/drive separator, strip off the
; filename.ext text after that point

	 jcxz	 @F		; Jump if no path/drive separator

	 mov	 di,cx		; Strip off filename.exe text
@@:

; Append the CFGNAME

	 mov	 ax,es		; Get segment of copied CFG filename
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,CFGNAME	; DS:SI ==> .CFG filename
	 mov	 cx,CFGNAME_LEN ; # bytes in CFGNAME
     rep movs	 es:[di].LO,DGROUP:[si].LO ; Copy it, including trailing zero

	 push	 di		; Pass # bytes used
	 call	 U16_CALC_HIGHSEG ; Calculate new HIGHSEG value

; Attempt to open it

	 mov	 al,@OPEN_R	; Open as read-only
	 xor	 dx,dx		; DS:DX ==> copy of CFG filename
	 DOSCALL @OPENF2	; Attempt to open the CFG file in cur dir
	 jc	 near ptr PROC_CFG_DONE ; Jump if file not found (just done)
PROC_CFG_OPEN:
	 mov	 bx,ax		; Copy to handle register

	 mov	 ax,fs		; Get segment of DGROUP
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ds,NEXTSEG	; Get next available segment
	 assume  ds:nothing	; Tell the assembler about it

; Read the .CFG file into memory

	 mov	 cx,-1		; The whole enchilada
	 xor	 dx,dx		; Offset into next available segment
	 DOSCALL @READF2	; Read in the file
	 jc	 short PROC_CFG_READ ; Jump if something went wrong

	 mov	 si,ax		; Copy size of file
	 mov	 ds:[si].LO,EOF ; Mark as End-Of-File
	 inc	 si		; Count in the EOF

	 push	 si		; Pass # bytes used
	 call	 U16_CALC_HIGHSEG ; Calculate new HIGHSEG value

	 DOSCALL @CLOSF2	; Close the .CFG file

	 xor	 si,si		; DS:SI ==> start of command line
	 call	 STR_UPPER	; Convert the string at DS:SI to upper case
	 or	 LCL_FLAG,@LCL_CFG ; Mark as processing .CFG file
PROC_CFG_NEXT:
	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,EOF 	; Izit EOF marker?
	 je	 short PROC_CFG_DONE ; Jump if so (that's all folks)

	 cmp	 al,'#'         ; Izit comment marker?
	 je	 short PROC_CFG_COMMENT ; Jump if so (skip ovr the coment)

	 cmp	 al,';'         ; Izit comment marker?
	 je	 short PROC_CFG_COMMENT ; Jump if so (skip ovr the coment)

	 cmp	 al,CR		; Izit EOL marker?
	 je	 short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	 cmp	 al,LF		; Izit EOL marker?
	 je	 short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	 cmp	 al,'/'         ; Izit switch marker?
	 jne	 short PROC_CFG_ERRSW ; Jump if so

	 push	 dword ptr (offset DGROUP:TAB_CMDSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
	 jc	 short PROC_CFG_ERRCOM ; Jump if error

	 jmp	 PROC_CFG_NEXT	; Go around again


; Skip over a comment

PROC_CFG_COMMENT:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,EOF 	; Izit EOF marker?
	 je	 short PROC_CFG_DONE ; Jump if so (that's all folks)

	 cmp	 al,CR		; Izit EOL marker?
	 je	 short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	 cmp	 al,LF		; Izit EOL marker?
	 je	 short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	 jmp	 PROC_CFG_COMMENT ; Go around again


; Skip over EOL markers

PROC_CFG_OVEREOL:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,EOF 	; Izit EOF marker?
	 je	 short PROC_CFG_DONE ; Jump if so (that's all folks)

	 cmp	 al,CR		; Izit EOL marker?
	 je	 short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	 cmp	 al,LF		; Izit EOL marker?
	 je	 short PROC_CFG_OVEREOL ; Jump if so (skip over EOL markers)

	 dec	 si		; Back off to last valid character

	 jmp	 PROC_CFG_NEXT	; Go around again

PROC_CFG_DONE:
	 clc			; Mark as successful

	 jmp	 short PROC_CFG_EXIT ; Join common exit code

PROC_CFG_ERRSW:
	 push	 fs		; Pass the segment
	 push	 dword ptr (offset DGROUP:ERR_CFGSW) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 jmp	 short PROC_CFG_ERRCOM ; Join common error code

PROC_CFG_READ:
	 push	 fs		; Pass the segment
	 push	 dword ptr (offset DGROUP:ERR_CFG) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
PROC_CFG_ERRCOM:
	 DOSCALL @CLOSF2	; Close the .CFG file

	 stc			; Mark as in error
PROC_CFG_EXIT:
	 pushf			; Save flgs (CF in particular)
	 and	 LCL_FLAG,not @LCL_CFG ; Mark as no longer processing .CFG file
	 popf			; Restore

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popa			; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_CFG endp			; End PROC_CFG procedure
	 NPPROC  CHECK_ARGS_SUB -- Subroutine to CHECK_ARGS
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Subroutine to CHECK_ARGS

On entry:

DS:SI	 ==>	 text to parse

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <eax,si>	; Save registers

	 call	 STR_UPPER	; Convert the string at DS:SI to upper case
CHECK_ARGS_SUB_SRCH:		; Search for arguments
	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,EOF 	; Check for terminator
	 je	 near ptr CHECK_ARGS_SUB_EOF ; That's all folks

	 cmp	 al,';'         ; Check for terminator
	 je	 near ptr CHECK_ARGS_SUB_ENDFLD ; That's all folks

	 cmp	 al,','         ; Check for field separator
	 je	 short CHECK_ARGS_SUB_SEP ; That's all folks

	 test	 LCL_FLAG,@LCL_ARF ; Are we already ARFing?
	 jnz	 short @F	; Jump if so

	 cmp	 al,'@'         ; Check for ARF marker
	 je	 short CHECK_ARGS_SUB_ARF ; That's all folks
@@:
	 cmp	 al,'/'         ; Check for switch marker
	 jne	 near ptr CHECK_ARGS_SUB_XSW ; Jump if not
CHECK_ARGS_SUB_SW:
	 push	 dword ptr (offset DGROUP:TAB_CMDSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
	 jnc	 short CHECK_ARGS_SUB_SRCH ; Jump if found

	 jmp	 CHECK_ARGS_SUB_EXIT ; Jump if not found (note CF=1)

CHECK_ARGS_SUB_ARF:
	 inc	 si		; Skip over the ARF marker

	 call	 CHECK_ARF	; Check it out
	 jc	 near ptr CHECK_ARGS_SUB_EXIT ; Jump if something went wrong (note CF=1)

	 jmp	 CHECK_ARGS_SUB_SRCH ; Go around again

CHECK_ARGS_SUB_SEP:
	 inc	 si		; Skip over the field separator
	 inc	 FIELDNO	; Skip to the next field

	 cmp	 FIELDNO,@NFLDS ; Izit too large?
	 jb	 near ptr CHECK_ARGS_SUB_SRCH ; Jump if not

; If the field is empty, ignore it

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,EOF 	; Izit EOF marker?
	 je	 short CHECK_ARGS_SUB_EOF ; Jump if so

	 cmp	 al,';'         ; Izit comment marker?
	 je	 short CHECK_ARGS_SUB_ENDFLD ; Jump if so

	 cmp	 al,','         ; Check for field separator
	 je	 short CHECK_ARGS_SUB_SEP ; Jump if so

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_FLD) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 stc			; Mark as in error

	 jmp	 short CHECK_ARGS_SUB_EXIT ; Join common exit code

CHECK_ARGS_SUB_XSW:
	 call	 SKIP_WHITE	; Skip over white space

	 mov	 eax,FIELDNO	; Get the field #

; Display the input with the appropriate prompt

	 call	 PDISP[eax*(type PDISP)] ; Display the input
				; Return with DS:SI ==> next char after input
	 jc	 short CHECK_ARGS_SUB_EXIT ; Jump if something went wrong (note CF=1)

	 jmp	 CHECK_ARGS_SUB_SRCH ; Go around again


; EOF encountered:  if we're ARFing, call it an end field marker

CHECK_ARGS_SUB_EOF:
	 test	 LCL_FLAG,@LCL_ARF ; Are we ARFing?
	 jz	 short CHECK_ARGS_SUB_DONE ; Jump if not

; We're done processing arguments

CHECK_ARGS_SUB_ENDFLD:
	 or	 LCL_FLAG,@LCL_ENDFLD ; Mark as ending field marker present
	 or	 ARG_FLAG,@ARG_BATCH ; Mark as running in batch mode
CHECK_ARGS_SUB_DONE:
	 clc			; Mark as successful
CHECK_ARGS_SUB_EXIT:
	 REGREST <si,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS_SUB endp		; End CHECK_ARGS_SUB procedure
	 NPPROC  CHECK_SWITCHES -- Check For Switches
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for switches

On entry:

DS:SI	 ==>	 command line to parse

On exit:

CF	 =	 0 if found
	 =	 1 if not
DS:SI	 ==>	 next character after switch

|

CSW_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
CSW_PTAB dd	 ?		; Offset in DGROUP of switch table

CSW_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; It's a switch command:  find out which one.

	 mov	 edx,[bp].CSW_PTAB ; Get offset in DGROUP of table
	 xor	 ebx,ebx	; Zero index register
	 mov	 ecx,DGROUP:[edx].SWTAB_NARGS ; # arguments to check
CHECK_SWITCHES_NEXT:
	 REGSAVE <cx,si,es>	; Save for a moment

; Get maximum length

	 mov	 edi,DGROUP:[edx].SWTAB_MAX ; Get pointer to maximum length
	 mov	 cx,(type CMDARG_MAX) ptr NGROUP:[edi+ebx*(type CMDARG_MAX)]

; Get location of text

	 mov	 edi,DGROUP:[edx].SWTAB_TAB ; Get pointer to text table
	 les	 di,(type CMDARG_TAB) ptr NGROUP:[edi+ebx*(type CMDARG_TAB)]
	 assume  es:nothing	; Tell the assembler about it

	 push	 di		; Save for a moment

    repe cmps	 ds:[si].LO,es:[di].LO ; Compare 'em
	 je	 short @F	; Jump if it matches

	 dec	 di		; Back off to mismatch
@@:
	 mov	 ax,di		; Get offset of mismatching char

	 pop	 di		; Restore

	 sub	 ax,di		; Subtract to get length

	 REGREST <es,si,cx>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Mark as found only if the next character is a valid separator
; and the length is >= the minimum

	 mov	 edi,DGROUP:[edx].SWTAB_MIN ; Get pointer to minimum length
	 mov	 di,(type CMDARG_MIN) ptr NGROUP:[edi+ebx*(type CMDARG_MIN)]

	 cmp	 ax,di		; Izit at or above the minimum length?
	 jb	 short CHECK_SWITCHES_NEXT1 ; Jump if not

	 mov	 di,si		; Copy starting offset
	 add	 di,ax		; Add actual length into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 cmp	 al,':'         ; Check for valid separator
	 je	 short CHECK_SWITCHES_FOUND ; Jump if valid

	 cmp	 al,','         ; Check for valid separator
	 je	 short CHECK_SWITCHES_FOUND ; Jump if valid

	 cmp	 al,';'         ; Check for valid separator
	 je	 short CHECK_SWITCHES_FOUND ; Jump if valid

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short CHECK_SWITCHES_FOUND ; Jump if valid

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short CHECK_SWITCHES_FOUND ; A match
CHECK_SWITCHES_NEXT1:
	 inc	 ebx		; Skip to next entry

	 loop	 CHECK_SWITCHES_NEXT ; Jump if more entries to check

; Keyword not found

	 lea	 edi,MSG_UNKCFG ; ES:EDI ==> message

	 test	 LCL_FLAG,@LCL_CFG ; Izit in .CFG file?
	 jnz	 short @F	; Jump if so

	 lea	 edi,MSG_UNKENV ; ES:EDI ==> message

	 test	 LCL_FLAG,@LCL_ENV ; Izit in environment variable
	 jnz	 short @F	; Jump if so

	 lea	 edi,MSG_UNK	; ES:EDI ==> message
@@:
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 stc			; Indicate an error occurred

	 jmp	 CHECK_SWITCHES_EXIT ; Join common exit code

CHECK_SWITCHES_FOUND:
	 mov	 LASTKEY,si	; Save starting offset
	 mov	 si,di		; Skip over the keyword

; Take appropriate action

	 mov	 edi,DGROUP:[edx].SWTAB_ACT ; Get pointer to action
	 call	 (type CMDARG_ACT) ptr NGROUP:[edi+ebx*(type CMDARG_ACT)]
				; Return with CF significant
CHECK_SWITCHES_EXIT:
	 REGREST <edi,edx,ecx,ebx,eax> ; Restore

	 pop	 bp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SWITCHES endp		; End CHECK_SWITCHES procedure
	 NPPROC  GET_BUFINP -- Get Buffered Input
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get buffered input

|

GBI_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
GBI_PMT  dd	 ?		; Offset in DGROUP of prompt

GBI_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,dx,ds>	; Save registers

; Display the leading prompt

	 push	 es		; Pass the segment
	 push	 [bp].GBI_PMT	; Pass the offset
	 call	 U16_DISP_MSG	; Display the message

	 lds	 dx,INPBUF_VEC	; DS:DX ==> buffer for input
	 assume  ds:nothing	; Tell the assembler about it

	 DOSCALL @BKEYIN	; Get buffered keyboard input

	 call	 U16_NEWLINE	; Goto a new line

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_BUFINP endp 		; End GET_BUFINP procedure
	 NPPROC  DISPOBJ -- Display .OBJ Files
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .OBJ files

On entry:

DS:SI	 ==>	 input to parse and display

On exit:

DS:SI	 ==>	 next character after parsed input

CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it, one file per line

DISPOBJ_AGAIN:
	 call	 SKIP_WHITE	; Skip over white space

	 push	 @BIT0		; Allow continuation character ('+')
	 call	 FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  prompt for it if so

	 and	 cx,cx		; Izit empty?
	 jne	 short DISPOBJ_SPACE ; Jump if not

; If we already have some .OBJs, use them

	 cmp	 SEGOBJ_1ST,0	; Izit filled in?
	 jne	 short DISPOBJ_END ; Jump if so

	 test	 ARG_FLAG,@ARG_BATCH ; Running in batch mode?
	 jnz	 short DISPOBJ_ERR ; Jump if so

; Get buffered keyboard input

	 push	 dword ptr (offset DGROUP:PMTOBJ) ; Pass the offset
	 call	 GET_BUFINP	; Get buffered input

	 lds	 si,INPBUF_VEC	; DS:SI ==> buffer for input
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[si].BUFINP_BUF ; DS:SI ==> buffer

	 jmp	 DISPOBJ_AGAIN	; Go around again

; Allocate space for the .OBJ filename

DISPOBJ_SPACE:
	 call	 DISPOBJ_ALLOC	; Allocate CX bytes for DS:DX

	 test	 LCL_FLAG,@LCL_ARF ; Running from .ARF?
	 jz	 short DISPOBJ_XDISP ; Jump if not

; Display the .OBJ file with leading prompt

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTOBJ) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 bx		; Save for a moment

	 mov	 bx,@STD_OUT	; Display to standard output
	 DOSCALL @WRITF2	; Write it out

	 pop	 bx		; Restore

	 cmp	 LASTCHAR,'+'   ; Izit a continuation char?
	 jne	 short @F	; Jump if not

	 push	 dx		; Save for a moment

	 mov	 dl,LASTCHAR	; Send to console
	 DOSCALL @CHROUT	; ...

	 pop	 dx		; Restore
@@:
	 call	 U16_NEWLINE	; Goto a new line
DISPOBJ_XDISP:
	 cmp	 LASTCHAR,'+'   ; Are there more FIDs?
	 je	 near ptr DISPOBJ_AGAIN ; Jump if so
DISPOBJ_END:
	 call	 FIND_MAIN	; Find the name of the main file
				; Ignore return code
	 clc			; Mark as successful

	 jmp	 short DISPOBJ_EXIT ; Join common exit code

; No .OBJ files and running in batch mode

DISPOBJ_ERR:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_OBJ) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 stc			; Mark as in error
DISPOBJ_EXIT:
	 REGREST <ds,di,cx,dx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPOBJ  endp			; End DISPOBJ procedure
	 NPPROC  DISPOBJ_ALLOC -- Allocate Space For .OBJ Filename
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .OBJ filename

On entry:

DS:DX	 ==>	 start of FID
CX	 =	 byte length

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 ax,NEXTSEG	; Get next available segment

	 cmp	 SEGOBJ_1ST,0	; Izit initialized?
	 jne	 short @F	; Jump if so

	 mov	 SEGOBJ_1ST,ax	; Save for later use
	 mov	 SEGOBJ_LAST,ax ; ...
;;;;;;;;
;;;;;;;; call	 FIND_MAIN	; Find the name of the main file
;;;;;;;;			; Ignore return code
@@:
	 push	 es		; Save for a moment

	 mov	 si,ax		; Copy segment of new entry
	 xchg	 si,SEGOBJ_LAST ; Mark as new last entry
	 mov	 es,si		; Address the previous last entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].POBJ_NEXT,ax ; Point it to this entry

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].POBJ_NEXT,-1 ; Mark as no next entry
	 lea	 edi,es:[0].POBJ_FID ; ES:EDI ==> start of save area
	 mov	 si,dx		; DS:SI ==> start of FID

	 push	 cx		; Save the byte count

     rep movs	 es:[di].LO,ds:[si].LO ; Copy to save area

	 pop	 cx		; Restore

	 push	 dword ptr (offset DGROUP:EXT_OBJ) ; Pass offset in DGROUP of def ext
	 call	 CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	 mov	 es:[0].POBJ_LEN,cl ; Save as byte length (excluding trailing zero)
	 mov	 al,0		; Get ASCIIZ terminator
	 stos	 es:[di].LO	; Terminate it

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	 add	 di,16-1	; Round up to para boundary
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 NEXTSEG,di	; Protect it

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPOBJ_ALLOC endp		; End DISPOBJ_ALLOC procedure
	 NPPROC  DISPEXE -- Display .EXE File
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .EXE file

On entry:

DS:SI	 ==>	 input to parse and display

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it

DISPEXE_AGAIN:
	 call	 SKIP_WHITE	; Skip over white space

	 push	 0		; Disallow continuation character ('+')
	 call	 FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  use default if so

	 and	 cx,cx		; Izit empty?
	 jnz	 short DISPEXE_SPACE ; Jump if not

; Use the default filename (base)

	 lds	 esi,PFID_FVEC	; DS:SI ==> base filename
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 DISPEXE_AGAIN	; Go around again

; Allocate space for the .EXE/.COM filename

DISPEXE_SPACE:
	 call	 DISPEXE_ALLOC	; Allocate CX bytes for DS:DX

	 test	 LCL_FLAG,@LCL_ARF ; Running from .ARF?
	 jz	 short DISPEXE_XDISP ; Jump if not

; Display the .EXE/.COM file with leading prompt

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTEXE1) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 PFID_LEN	; Pass the length in bytes
	 push	 PFID_FVEC.FSEL ; Pass segment of message
	 push	 PFID_FVEC.FOFF ; ...  offset ...
	 call	 U16_DISP_MSGL	; Display the message

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTEXE2) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 bx		; Save for a moment

	 mov	 bx,@STD_OUT	; Display to standard output
	 DOSCALL @WRITF2	; Write it out

	 pop	 bx		; Restore

	 call	 U16_NEWLINE	; Goto a new line
DISPEXE_XDISP:
	 clc			; Mark as successful

	 REGREST <ds,di,cx,dx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPEXE  endp			; End DISPEXE procedure
	 NPPROC  DISPEXE_ALLOC -- Allocate Space For .EXE Filename
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .EXE filename

On entry:

DS:DX	 ==>	 start of FID
CX	 =	 byte length

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 ax,NEXTSEG	; Get next available segment
	 mov	 PFLDS[@FLD_EXE*(type PFLDS)].VSEG,ax ; Save for later use

	 push	 es		; Save for a moment

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 edi,edi	; ES:EDI ==> start of save area
	 mov	 si,dx		; DS:SI ==> start of FID

	 push	 cx		; Save the byte count

     rep movs	 es:[di].LO,ds:[si].LO ; Copy to save area

	 pop	 cx		; Restore

; Append the default extension if none present

	 test	 ARG_FLAG,@ARG_TINY ; Izit a .COM file?
	 lea	 eax,EXT_COM	; Assume so
	 jnz	 short @F	; Jump if so

	 lea	 eax,EXT_EXE	; It's .EXE
@@:
	 push	 eax		; Pass offset in DGROUP of default extension
	 call	 CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	 mov	 al,0		; Get ASCIIZ terminator
	 stos	 es:[di].LO	; Terminate it

	 mov	 eax,DEFEXT_VEC ; Get offset where default extension appended
				; in case the command line later specifies /TINY
	 mov	 EXEFIL_EXTVEC,eax ; Save for later use

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	 add	 di,16-1	; Round up to para boundary
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 NEXTSEG,di	; Protect it

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPEXE_ALLOC endp		; End DISPEXE_ALLOC procedure
	 NPPROC  DISPMAP -- Display .MAP File
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .MAP file

On entry:

DS:SI	 ==>	 input to parse and display

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it

DISPMAP_AGAIN:
	 call	 SKIP_WHITE	; Skip over white space

	 push	 0		; Disallow continuation character ('+')
	 call	 FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  use default if so

	 and	 cx,cx		; Izit empty?
	 jnz	 short DISPMAP_SPACE ; Jump if not

; Use the default filename (NUL)

	 lds	 esi,PNUL_FVEC	; DS:SI ==> NUL filename
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 DISPMAP_AGAIN	; Go around again

; Allocate space for the .MAP filename

DISPMAP_SPACE:
	 call	 DISPMAP_ALLOC	; Allocate CX bytes for DS:DX

	 test	 LCL_FLAG,@LCL_ARF ; Running from .ARF?
	 jz	 short DISPMAP_XDISP ; Jump if not

; Display the .MAP file with leading prompt

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTMAP1) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 test	 ARG_FLAG,@ARG_MAP ; Izit present?
	 jnz	 short DISPMAP1 ; Jump if so

	 push	 PNUL_LEN	; Pass the length in bytes
	 push	 PNUL_FVEC.FSEL ; Pass segment of message
	 push	 PNUL_FVEC.FOFF ; ...  offset ...
	 call	 U16_DISP_MSGL	; Display the message

	 jmp	 short DISPMAP_COM ; Join common code

DISPMAP1:
	 push	 PFID_LEN	; Pass the length in bytes
	 push	 PFID_FVEC.FSEL ; Pass segment of message
	 push	 PFID_FVEC.FOFF ; ...  offset ...
	 call	 U16_DISP_MSGL	; Display the message
DISPMAP_COM:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTMAP2) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 bx		; Save for a moment

	 mov	 bx,@STD_OUT	; Display to standard output
	 DOSCALL @WRITF2	; Write it out

	 pop	 bx		; Restore

	 call	 U16_NEWLINE	; Goto a new line
DISPMAP_XDISP:
	 clc			; Mark as successful

	 REGREST <ds,di,cx,dx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPMAP  endp			; End DISPMAP procedure
	 NPPROC  DISPMAP_ALLOC -- Allocate Space For .MAP Filename
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .MAP filename

On entry:

DS:DX	 ==>	 start of FID
CX	 =	 byte length

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 ax,NEXTSEG	; Get next available segment
	 mov	 PFLDS[@FLD_MAP*(type PFLDS)].VSEG,ax ; Save for later use

	 push	 es		; Save for a moment

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 edi,edi	; ES:EDI ==> start of save area
	 mov	 si,dx		; DS:SI ==> start of FID

	 push	 cx		; Save the byte count

     rep movs	 es:[di].LO,ds:[si].LO ; Copy to save area

	 pop	 cx		; Restore

	 push	 dword ptr (offset DGROUP:EXT_MAP) ; Pass offset in DGROUP of def ext
	 call	 CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	 mov	 al,0		; Get ASCIIZ terminator
	 stos	 es:[di].LO	; Terminate it

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	 add	 di,16-1	; Round up to para boundary
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 NEXTSEG,di	; Protect it

	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPMAP_ALLOC endp		; End DISPMAP_ALLOC procedure
	 NPPROC  DISPLIB -- Display .LIB Files
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .LIB files

On entry:

DS:SI	 ==>	 input to parse and display

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it, one file per line

DISPLIB_AGAIN:
	 call	 SKIP_WHITE	; Skip over white space

	 push	 @BIT0		; Allow continuation character ('+')
	 call	 FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  ignore it if so

	 and	 cx,cx		; Izit empty?
	 jz	 short DISPLIB_END ; Jump if so

; Allocate space for the .LIB filename

	 call	 DISPLIB_ALLOC	; Allocate CX bytes for DS:DX

	 test	 LCL_FLAG,@LCL_ARF ; Running from .ARF?
	 jz	 short DISPLIB_XDISP ; Jump if not

; Display the .LIB file with leading prompt

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTLIB) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 bx		; Save for a moment

	 mov	 bx,@STD_OUT	; Display to standard output
	 DOSCALL @WRITF2	; Write it out

	 pop	 bx		; Restore

	 cmp	 LASTCHAR,'+'   ; Izit a continuation char?
	 jne	 short @F	; Jump if not

	 push	 dx		; Save for a moment

	 mov	 dl,LASTCHAR	; Send to console
	 DOSCALL @CHROUT	; ...

	 pop	 dx		; Restore
@@:
	 call	 U16_NEWLINE	; Goto a new line
DISPLIB_XDISP:
	 cmp	 LASTCHAR,'+'   ; Are there more FIDs?
	 je	 near ptr DISPLIB_AGAIN ; Jump if so
DISPLIB_END:
	 clc			; Mark as successful
DISPLIB_EXIT:
	 REGREST <ds,di,cx,dx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPLIB  endp			; End DISPLIB procedure
	 NPPROC  DISPLIB_ALLOC -- Allocate Space For .LIB Filename
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .LIB filename

Remember to update LINK_LIBNAM.

On entry:

DS:DX	 ==>	 start of FID
CX	 =	 byte length

|

	 pushad 		; Save registers

	 movzx	 eax,NEXTSEG	; Get next available segment
	 mov	 PFLDS[@FLD_LIB*(type PFLDS)].VSEG,ax ; Save for later use
	 shl	 eax,4-0	; Convert from paras to bytes

	 cmp	 LaLIB_1ST,0	; Izit initialized?
	 jne	 short @F	; Jump if so

	 mov	 LaLIB_1ST,eax	; Save for later use
	 mov	 LaLIB_LAST,eax ; ...
@@:
	 push	 es		; Save for a moment

	 mov	 esi,eax	; Copy LA of new entry
	 xchg	 esi,LaLIB_LAST ; Mark as new last entry
	 shr	 esi,4-0	; Convert from bytes to paras
	 mov	 es,si		; Address the previous last entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].PLIB_NEXT,eax ; Point it to this entry

	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].PLIB_NEXT,-1 ; Mark as no next entry
	 mov	 es:[0].PLIB_HNDL,-1 ; Mark as unopened
	 mov	 es:[0].PLIB_LaXDICT,-1 ; Mark as not present
	 mov	 edi,type PLIB_STR ; ES:EDI ==> start of save area
	 shl	 eax,4-0	; Convert from bytes to paras
	 add	 eax,edi	; Add to get LA
	 mov	 es:[0].PLIB_PNAM,eax ; Save LA of FID

	 mov	 si,dx		; DS:SI ==> start of FID

	 push	 cx		; Save the byte count

	 mov	 bx,di		; Save offset of length byte
	 inc	 di		; Skip over length byte
     rep movs	 es:[di].LO,ds:[si].LO ; Copy to save area

	 pop	 cx		; Restore

	 push	 dword ptr (offset DGROUP:EXT_LIB) ; Pass offset in DGROUP of def ext
	 call	 CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	 mov	 es:[bx].LO,cl	; Precede saved name with length byte

	 mov	 al,0		; Get ASCIIZ terminator
	 stos	 es:[di].LO	; Terminate it

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	 add	 di,16-1	; Round up to para boundary
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 NEXTSEG,di	; Protect it

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPLIB_ALLOC endp		; End DISPLIB_ALLOC procedure
	 NPPROC  FIND_LIBENV -- Find LIB= Environment Variable
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Find LIB= environment variable

|

	 REGSAVE <eax,cx,di,es> ; Save registers

	 mov	 es,PSPSEG	; Address the PSP
	 assume  es:PSPGRP	; Tell the assembler about it

	 mov	 es,PSP_ENVIR_PTR ; Get segment of our environment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> start of environment
	 mov	 cx,8000h	; Maximum size of environment
FIND_LIBENV_NEXT:
	 cmp	 es:[di].LO,0	; Izit the end of the line?
	 je	 short FIND_LIBENV_EXIT ; Jump if so

; Search for LIB=

	 cmp	 es:[di].EDD,'=BIL' ; Izit LIB=?
	 je	 short FIND_LIBENV_OK ; Jump if so

	 mov	 al,0		; Terminator value
   repne scas	 es:[di].LO	; Search for it
	 jne	 short FIND_LIBENV_EXIT ; Jump if not found

	 jmp	 FIND_LIBENV_NEXT ; Go around again


FIND_LIBENV_OK:
	 add	 di,4		; Skip over LIB=
	 mov	 LaLIBENV.ELO,di ; Save offset portion of LA
	 xor	 eax,eax	; Zero to use as dword
	 mov	 ax,es		; Copy segment portion
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 LaLIBENV,eax	; Add in the segment portion
FIND_LIBENV_EXIT:
	 REGREST <es,di,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_LIBENV endp		; End FIND_LIBENV procedure
	 NPPROC  DISPDEF -- Display .DEF File
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Display .DEF file

On entry:

DS:SI	 ==>	 input to parse and display

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,dx,di,ds> ; Save registers

; Parse the input and display it

DISPDEF_AGAIN:
	 call	 SKIP_WHITE	; Skip over white space

	 push	 0		; Disallow continuation character ('+')
	 call	 FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  ignore it if so

	 and	 cx,cx		; Izit empty?
	 jz	 short DISPDEF_END ; Jump if so

; Allocate space for the .DEF filename

	 call	 DISPDEF_ALLOC	; Allocate CX bytes for DS:DX

	 test	 LCL_FLAG,@LCL_ARF ; Running from .ARF?
	 jz	 short DISPDEF_XDISP ; Jump if not

; Display the .DEF file with leading prompt

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:PMTDEF) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 push	 bx		; Save for a moment

	 mov	 bx,@STD_OUT	; Display to standard output
	 DOSCALL @WRITF2	; Write it out

	 pop	 bx		; Restore

	 call	 U16_NEWLINE	; Goto a new line
DISPDEF_XDISP:
DISPDEF_END:
	 clc			; Mark as successful

	 REGREST <ds,di,cx,dx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPDEF  endp			; End DISPDEF procedure
	 NPPROC  DISPDEF_ALLOC -- Allocate Space For .DEF Filename
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Allocate space for .DEF filename

On entry:

DS:DX	 ==>	 start of FID
CX	 =	 byte length

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 ax,NEXTSEG	; Get next available segment
	 mov	 PFLDS[@FLD_DEF*(type PFLDS)].VSEG,ax ; Save for later use

	 push	 es		; Save for a moment

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 edi,edi	; ES:EDI ==> start of save area
	 mov	 si,dx		; DS:SI ==> start of FID

	 push	 cx		; Save the byte count

     rep movs	 es:[di].LO,ds:[si].LO ; Copy to save area

	 pop	 cx		; Restore

; Append the default extension if none present

	 push	 dword ptr (offset DGROUP:EXT_DEF) ; Pass offset in DGROUP of def ext
	 call	 CHECK_DEFEXT	; Append the def ext of DS:DX len CX to ES:DI
				; if none present, CX & DI updated
	 mov	 al,0		; Get ASCIIZ terminator
	 stos	 es:[di].LO	; Terminate it

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Round up to para boundary and protect it

	 add	 di,16-1	; Round up to para boundary
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 NEXTSEG,di	; Protect it

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPDEF_ALLOC endp		; End DISPDEF_ALLOC procedure
	 NPPROC  CHECK_DEFFILE -- Check on .DEF File
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check on .DEF file

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <>		; Save registers



	 clc			; Mark as successful
CHECK_DEFFILE_EXIT:
	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEFFILE endp		; End CHECK_DEFFILE procedure
	 NPPROC  CHECK_ARF -- Check Automatic Response File
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check automatic response file

On entry:

DS:SI	 ==>	 filename.ext of ARF

On exit:

DS:SI	 ==>	 next character after ARF
CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,di,ds> ; Save registers

; Find the end of the FID

	 push	 0		; Disallow continuation character ('+')
	 call	 FIND_FIDEND	; Find the end of the FID
				; Return with DS:DI ==> next char after FID
				;	      DS:SI ==> DS:DI after SKIP_WHITE
				;	      DS:DX ==> starting offset
				;	      CX = # chars in FID
				;	      LASTCHAR saved
; Check for empty input:  error if so

	 jcxz	 CHECK_ARF_ERR1 ; Jump if empty

; Attempt to open the file

	 mov	 cl,0		; ASCIIZ terminator
	 xchg	 cl,ds:[di]	; Terminate it
	 mov	 al,@OPEN_R	; Read-only access
	 DOSCALL @OPENF2	; Open the file
	 xchg	 cl,ds:[di]	; Restore
	 jc	 short CHECK_ARF_ERR1 ; Jump if something went wrong

	 mov	 bx,ax		; Copy to handle register

; Read it into memory

	 xor	 dx,dx		; Start of segment
	 mov	 ds,NEXTSEG	; DS:DX ==> next available segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,-1		; Read it all in
	 DOSCALL @READF2	; ...
	 jc	 short CHECK_ARF_ERR2 ; Jump if something went wrong

	 mov	 di,dx		; Copy start of ARF contents
	 add	 di,ax		; Plus its length
	 mov	 ds:[di].LO,EOF ; Ensure properly terminated
	 inc	 ax		; Count it in

	 add	 ax,16-1	; Round up to para boundary
	 rcr	 ax,1		; In case of overflow
	 shr	 ax,3-0 	; Convert from bytes to para
	 add	 NEXTSEG,ax	; Protect the ARF contents

	 DOSCALL @CLOSF2	; Close 'er up

	 or	 LCL_FLAG,@LCL_ARF ; Mark as ARFing

	 push	 si		; Save for a moment
	 mov	 si,dx		; DS:SI ==> text to parse
	 call	 CONV_ARF	; Convert the .ARF contents to commnd line
	 call	 CHECK_ARGS_SUB ; Handle via subroutine
	 pop	 si		; Restore
	 jc	 short CHECK_ARF_ERRCOM ; Jump if something went wrong

	 and	 LCL_FLAG,not @LCL_ARF ; Mark as no longer ARFing

	 clc			; Mark as successful

	 jmp	 short CHECK_ARF_EXIT ; Join common exit code

CHECK_ARF_ERR1:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:ERR_ARF1) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 jmp	 short CHECK_ARF_ERRCOM ; Join common error code

CHECK_ARF_ERR2:
	 DOSCALL @CLOSF2	; Close 'er up

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:ERR_ARF2) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
CHECK_ARF_ERRCOM:
	 and	 LCL_FLAG,not @LCL_ARF ; Mark as no longer ARFing

	 stc			; Mark as in error
CHECK_ARF_EXIT:
	 REGREST <ds,di,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARF endp			; End CHECK_ARF procedure
	 NPPROC  CONV_ARF -- Convert .ARF Contents
	 assume  ds:nothing,es:DGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Convert .ARF contents to look like a command line

On entry:

DS:SI	 ==>	 .ARF contents

|

	 REGSAVE <ax,ebx,ecx,si,di,es> ; Save registers

	 mov	 ax,ds		; Copy segment
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,0		; Set last character
	 mov	 di,si		; ES:DI ==> .ARF contents
CONV_ARF_NEXT:
	 lods	 ds:[si].LO	; Get the next character

	 cmp	 al,EOF 	; Izit EOF?
	 je	 near ptr CONV_ARF_EOF ; Jump if so

	 cmp	 al,';'         ; Izit EOF?
	 je	 near ptr CONV_ARF_EOF ; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short CONV_ARF_LF ; Jump if so

	 cmp	 al,' '         ; Izit white space?
	 je	 short CONV_ARF_SPC ; Jump if so (force to white space)

	 cmp	 al,CR		; Izit EOL?
	 je	 short CONV_ARF_SPC ; Jump if so (force to white space)

	 cmp	 al,TAB 	; Izit TAB?
	 je	 short CONV_ARF_SPC ; Jump if so (force to white space)

	 cmp	 al,'+'         ; Izit a separator?
	 je	 short CONV_ARF_SEP ; Jump if so

	 cmp	 al,','         ; Izit a separator?
	 je	 short CONV_ARF_SEP ; Jump if so

	 jmp	 short CONV_ARF_FSA ; Handle via FSA


CONV_ARF_SPC:
	 mov	 al,' '         ; Convert to a space
CONV_ARF_SEP:
CONV_ARF_LF:
CONV_ARF_FSA:

; The current char must be processed via the FSA

	 REGSAVE <edi,es>	; Save for a moment

	 mov	 cx,fs		; Copy DGROUP segment
	 mov	 es,cx		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 edi,FSASPEC	; ES:EDI ==> list of special characters
	 mov	 ecx,FSASPEC_LEN ; ECX = # ...
   repne scas	 FSASPEC[edi]	; Search for special characters
	 sub	 edi,offset es:FSASPEC[type FSASPEC] ; Convert to origin-0

; We now compute the address of the word in FSASTM at row CUR_STATE, column EDI

	 imul	 ebx,CUR_STATE,FSASPEC_LEN ; Current state times row length

	 mov	 ebx,FSASTM[ebx+edi*(type FSASTM)] ; New state
	 mov	 CUR_STATE,ebx	; Save for next time
	 mov	 ebx,FSATAB[ebx] ; Get next action

	 REGREST <es,edi>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ebx		; Take appropriate action


; Save LF, start at initial state

CONV_ARF_INIF:
	 mov	 al,','         ; Get general field marker
	 mov	 CUR_STATE,@INI ; Start at initial state

	 jmp	 short CONV_ARF_SAVE ; Join common save code


; Plus, name

CONV_ARF_PNAM:
	 mov	 es:[di].LO,'+' ; Save in .ARF file

	 jmp	 short CONV_ARF_COM ; Join common code


; White space, name

CONV_ARF_WNAM:
	 mov	 es:[di].LO,' ' ; Save in .ARF file
CONV_ARF_COM:
	 inc	 di		; Skip over it
	 mov	 CUR_STATE,@NAM ; Goto name state

;;;;;;;; jmp	 short CONV_ARF_SAVE ; Join common save code

; Initial state, switch
; White space, switch
; Plus, switch
; Plus, LF, switch
; Name, switch
; Name, white space, switch

CONV_ARF_SAVE:
	 stos	 es:[di].LO	; Save in .ARF file

	 jmp	 CONV_ARF_NEXT	; Go around again


CONV_ARF_EOF:
	 stos	 es:[di].LO	; Save in .ARF file

	 REGREST <es,di,si,ecx,ebx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CONV_ARF endp			; End CONV_ARF procedure
	 NPPROC  FIND_FIDBEG -- Find The Start of a FID
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the start of a FID

On entry:

DS:SI	 ==>	 start of text to parse

On exit:

DS:DX	 ==>	 starting offset
CX	 =	 # characters in FID excluding .ext

|

	 REGSAVE <ax,si,di>	; Save registers

	 mov	 dx,si		; Save as starting offset
	 mov	 di,si		; ...
FIND_FIDBEG_NEXT:
	 lods	 ds:[si].LO	; Get the next character

	 cmp	 al,0		; Check for terminator
	 je	 short FIND_FIDBEG_END ; Jump if so

	 cmp	 al,';'         ; Check for terminator
	 je	 short FIND_FIDBEG_END ; Jump if so

	 cmp	 al,EOF 	; Check for terminator
	 je	 short FIND_FIDBEG_END ; Jump if so

	 cmp	 al,','         ; Check for field separator
	 je	 short FIND_FIDBEG_END ; Jump if so

	 cmp	 al,'/'         ; Check for switch marker
	 je	 short FIND_FIDBEG_END ; Jump if so

	 cmp	 al,'+'         ; Check for FID separator
	 je	 short FIND_FIDBEG_END ; Jump if so

	 cmp	 al,':'         ; Check for drive separator
	 je	 short FIND_FIDBEG_SEP ; Jump if so

	 cmp	 al,'\'         ; Check for path separator
	 je	 short FIND_FIDBEG_SEP ; Jump if so

	 cmp	 al,'.'         ; Check for ext separator
	 jne	 short @F	; Jump if not

	 mov	 di,si		; Save offset of '.'+1
@@:
	 cmp	 al,' '         ; Izit end of the name?
	 ja	 short FIND_FIDBEG_NEXT ; Jump if not
FIND_FIDBEG_END:

; If there's an extension separator after the FID start,
; shorten the length to exclude it

	 cmp	 di,dx		; Izit after FID start?
	 jbe	 short @F	; Jump if not

	 mov	 si,di		; Copy as ending offset
@@:
	 mov	 cx,si		; Copy offset
	 dec	 cx		; Back off to last good character
	 sub	 cx,dx		; Subtract to get length

	 jmp	 short FIND_FIDBEG_EXIT ; Join common exit code


FIND_FIDBEG_SEP:
	 mov	 dx,si		; Save as starting offset

	 jmp	 FIND_FIDBEG_NEXT ; Go around again

FIND_FIDBEG_EXIT:
	 REGREST <di,si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_FIDBEG endp		; End FIND_FIDBEG procedure
	 NPPROC  FIND_FIDEND -- Find The End of a FID
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the end of a FID

On entry:

DS:SI	 ==>	 start of text to parse

On exit:

DS:DX	 ==>	 starting offset
DS:DI	 ==>	 next character after FID
DS:SI	 ==>	 DS:SI after SKIP_WHITE
CX	 =	 # characters in FID

|

FINDFID_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
FINDFID_FLAG dw  ?		; Flags:  Bit 0 = allow continuation char ('+')

FINDFID_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax>		; Save register

	 mov	 dx,si		; Save starting offset
FIND_FIDEND_NEXT:
	 lods	 ds:[si].LO	; Get the next character
	 mov	 di,si		; Save next offset

	 cmp	 al,EOF 	; Check for terminator
	 je	 short FIND_FIDEND_END ; Jump if so

	 cmp	 al,';'         ; Check for terminator
	 je	 short FIND_FIDEND_END ; Jump if so

	 cmp	 al,','         ; Check for field separator
	 je	 short FIND_FIDEND_END ; Jump if so

	 cmp	 al,'/'         ; Check for switch marker
	 je	 short FIND_FIDEND_END ; Jump if so

	 test	 [bp].FINDFID_FLAG,@BIT0 ; Allow continuation char?
	 jz	 short @F	; Jump if not

	 cmp	 al,'+'         ; Check for FID separator
	 je	 short FIND_FIDEND_END ; Jump if so
@@:
	 cmp	 al,' '         ; Izit end of the name?
	 ja	 short FIND_FIDEND_NEXT ; Jump if not

	 call	 SKIP_WHITE	; Skip over white space
	 inc	 si		; Reverse the next instruction

; Check for empty input:  re-prompt if so

FIND_FIDEND_END:
	 dec	 si		; Back off to last character
	 mov	 LASTCHAR,al	; Save as last character

	 test	 [bp].FINDFID_FLAG,@BIT0 ; Allow continuation char?
	 jz	 short @F	; Jump if not

	 cmp	 LASTCHAR,'+'   ; Izit continuation char?
	 jne	 short @F	; Jump if not

	 inc	 si		; Skip over it
@@:
	 dec	 di		; Back off to char after FID
	 mov	 cx,di		; Get next offset
	 sub	 cx,dx		; Subtract to get length

	 REGREST <ax>		; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_FIDEND endp		; End FIND_FIDEND procedure
	 NPPROC  FIND_MAIN -- Find The Main File
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the main file which is the first file in the .OBJ list.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds>		; Save segment register

	 cmp	 SEGOBJ_1ST,0	; Izit filled in?
	 je	 near ptr FIND_MAIN_ERR ; Jump if not

	 cmp	 PFID_LEN,0	; Izit already found?
	 jne	 near ptr FIND_MAIN_CLC ; Jump if so

	 mov	 ds,SEGOBJ_1ST	; DS:0 ==> first .OBJ file
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 esi,ds:[0].POBJ_FID ; Copy starting offset
	 mov	 edx,esi	; ...
FIND_MAIN_NEXT:
	 lods	 ds:[si].LO	; Get the next character

	 cmp	 al,0		; Check for terminator
	 je	 short FIND_MAIN_END ; Jump if so

	 cmp	 al,';'         ; Check for terminator
	 je	 short FIND_MAIN_END ; Jump if so

	 cmp	 al,EOF 	; Check for terminator
	 je	 short FIND_MAIN_END ; Jump if so

	 cmp	 al,','         ; Check for terminator
	 je	 short FIND_MAIN_END ; Jump if so

	 cmp	 al,'/'         ; Check for terminator
	 je	 short FIND_MAIN_END ; Jump if so

	 cmp	 al,'+'         ; Check for terminator
	 je	 short FIND_MAIN_END ; Jump if so

	 cmp	 al,':'         ; Izit a drive separator?
	 je	 short FIND_MAIN_SEP ; Jump if so

	 cmp	 al,'\'         ; Izit a path separator?
	 je	 short FIND_MAIN_SEP ; Jump if so

	 cmp	 al,' '         ; Check for separator
	 ja	 short FIND_MAIN_NEXT ; Jump if not
FIND_MAIN_END:
	 mov	 cx,si		; Copy offset
	 dec	 cx		; Back off to last good character
	 sub	 cx,dx		; Subtract to get length

	 mov	 PFID_FVEC.FOFF,edx ; Save for later use
	 mov	 PFID_FVEC.FSEL,ds ; ...
	 mov	 PFID_LEN,cx	; Save the length in bytes

; Get the length in bytes of the filename

	 mov	 si,dx		; Copy starting offset
FIND_MAIN_NEXT2:
	 lods	 ds:[si].LO	; Get the next character

	 cmp	 al,'.'         ; Check for separator
	 loopne  FIND_MAIN_NEXT2 ; Jump if more chars and != sep
	 jne	 short FIND_MAIN_END2 ; Jump if no sep

	 inc	 cx		; Count in the EXT separator
	 sub	 PFID_LEN,cx	; Subtract to get the length in bytes
FIND_MAIN_END2:

; Copy the FID to local storage

	 lds	 esi,PFID_FVEC	; DS:ESI ==> main FID
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,PFID_LEN	; Length in bytes
	 lea	 edi,LCLFID	; ES:EDI ==> local storage

	 mov	 PFID_FVEC.FOFF,edi ; Save for later use
	 mov	 PFID_FVEC.FSEL,es ; ...

     rep movs	 LCLFID[di],ds:[si].LO ; Copy to local storage
	 mov	 al,0		; Terminator
	 stos	 es:[di].LO	; Terminate it
FIND_MAIN_CLC:
	 clc			; Mark as found

	 jmp	 short FIND_MAIN_EXIT ; Join common exit code

FIND_MAIN_SEP:
	 mov	 edx,esi	; Save offset of next char

	 jmp	 FIND_MAIN_NEXT ; Go around again

FIND_MAIN_ERR:
	 stc			; Mark as not found
FIND_MAIN_EXIT:
	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_MAIN endp			; End FIND_MAIN procedure
	 NPPROC  STR_UPPER -- Convert String to Uppercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert ASCIIZ string at DS:SI to uppercase

|

	 REGSAVE <ax,si>	; Save registers
STR_UPPER_NEXT:
	 lods	 ds:[si].LO	; Get next character

	 and	 al,al		; Check for end-of-the-line
	 jz	 short STR_UPPER_EXIT ; Good guess

	 cmp	 al,EOF 	; Check for end-of-the-file
	 je	 short STR_UPPER_EXIT ; Good guess

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short STR_UPPER_NEXT ; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short STR_UPPER_NEXT ; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase

	 mov	 ds:[si-1],al	; Save back in text

	 jmp	 short STR_UPPER_NEXT ; Go around again

STR_UPPER_EXIT:
	 REGREST <si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STR_UPPER endp			; End STR_UPPER procedure
	 NPPROC  DISP_UNK -- Display Message and Unknown Keyword
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display message and unknown keyword.

On entry:

ES:EDI	 ==>	 message to display
DS:SI	 ==>	 unknown keyword

|

	 push	 es		; Pass the segment
	 push	 edi		; Pass address of message
	 call	 U16_DISP_MSG	; Display the message

; Copy unmatched text to local buffer

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,30		; Maximum message length
@@:
	 lods	 ds:[si].LO	; Get next character
S16	 stos	 es:[di].LO	; Save in local buffer

	 cmp	 al,' '         ; Check for terminator
	 jbe	 short @F	; Jump if that's all folks

	 loop	 @B		; Jump if more characters
@@:
	 mov	 ax,LF*256+CR	; Line terminators
S16	 stos	 es:[di].ELO	; Save in message

	 mov	 al,EOS 	; String terminator
S16	 stos	 es:[di].ELO	; Save in message

	 REGREST <di,si,cx,ax>	; Restore

	 push	 es		; Pass the segment
	 push	 edi		; Pass address of unknown keyword
	 call	 U16_DISP_MSG	; Display the message

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_UNK endp			; End DISP_UNK procedure
	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	 ==>	 ASCII text

On exit:

AL	 =	 non-white space character
DS:SI	 ==>	 (updated)

|

@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; izit white space?
	 je	 short @B	; Jump if so

	 dec	 si		; Back off to last non-white space

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	 NPPROC  SKIP_EOL -- Skip Over EOLs and White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over EOLs and white space

On entry:

DS:SI	 ==>	 ASCII text

On exit:

AL	 =	 non-white space character

|

	 push	 si		; Save register
@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,CR		; Izit EOL?
	 je	 short @B	; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short @B	; Jump if so

	 pop	 si		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_EOL endp			; End SKIP_EOL procedure
	 NPPROC  U16_LOWERCASE -- Convert AL To Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convret AL to lowercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Izit below lower limit?
	 jb	 short @F	; Jump if so

	 cmp	 al,'Z'         ; Izit above upper limit?
	 ja	 short @F	; Jump if so

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_LOWERCASE endp		; End U16_LOWERCASE procedure
	 NPPROC  CHECK_BASE -- Check Number Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the number base by looking at the string at DS:SI.
If it looks like a C-constant (0xHHHH), then use base 16;
otherwise use base 10.

On entry:

DS:SI	 ==>	 string to check

On exit:

ECX	 =	 number base to use
DS:SI	 ==>	 (updated)

|

	 REGSAVE <eax>		; Save register

	 mov	 ax,ds:[si]	; Get the next two bytes
	 xchg	 al,ah		; Swap so that the 'X' is in AL, '0' in AH
	 call	 U16_LOWERCASE	; Convert to lowercase

	 mov	 ecx,10 	; Assume base 10

	 cmp	 ax,'0x'        ; Izit hex notation?
	 jne	 short @F	; Jump if not

	 mov	 ecx,16 	; Use base 16
	 add	 si,2		; Skip over the '0x'
@@:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BASE endp 		; End CHECK_BASE procedure
	 NPPROC  BASE2BIN -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:ESI in base ECX to binary.
The converted # is returned in EAX.

On entry:

ECX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
EAX	 =	 converted #

|

	 REGSAVE <ebx,edx,edi>	; Save registers

	 xor	 ebx,ebx	; Zero accumulator
BASE2BIN_NEXT:
	 lods	 ds:[si].LO	; Get next digit
	 call	 U16_LOWERCASE	; Convert to lowercase

	 lea	 edi,NUMBERS_LO ; Get address of number conversion table
	 push	 ecx		; Save number base (and table length)
   repne scas	 NUMBERS_LO[edi] ; Look for the character
	 pop	 ecx		; Restore number base
	 jne	 short BASE2BIN_DONE ; Not one of ours

	 sub	 edi,(type NUMBERS_LO)+offset es:NUMBERS_LO ; Convert to origin 0
	 mov	 eax,ebx	; Copy old to multiply by base

	 mul	 ecx		; Shift over accumulated #
	 jc	 short BASE2BIN_OVF ; Jump if out of range

	 mov	 ebx,eax	; Copy back
	 add	 ebx,edi	; Add in new #
	 jnc	 short BASE2BIN_NEXT ; Jump if in range
BASE2BIN_OVF:
	 stc			; Indicate something went wrong

	 jmp	 short BASE2BIN_EXIT ; Join common exit code

BASE2BIN_DONE:
	 dec	 si		; Back off to previous character
	 mov	 eax,ebx	; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIN_EXIT:
	 REGREST <edi,edx,ebx>	; Restore registers

	 ret			; Return to caller with number in EAX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure
	 NPPROC  U16_DISP_MSG -- Display Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an EOS-terminated message

|

U16_DISP_MSG_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
U16_DISP_MSG_FVEC df ?		; Seg:Off in DGROUP of message

U16_DISP_MSG_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,edx,ds>	; Save registers

	 lds	 edx,[bp].U16_DISP_MSG_FVEC ; DS:EDX ==> message
	 assume  ds:nothing	; Tell the assembler about it

	 DOSCALL @STROUT	; Display the message

	 REGREST <ds,edx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 6		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_DISP_MSG endp		; End U16_DISP_MSG procedure
	 NPPROC  U16_DISP_MSGL -- Display Message by Length
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an length-specified message.

|

U16_DISP_MSGL_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
U16_DISP_MSGL_FVEC df ? 	; Seg:Off in DGROUP of message
U16_DISP_MSGL_LEN dw  ? 	; Length in bytes

U16_DISP_MSGL_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,edx,ds> ; Save registers

	 lds	 edx,[bp].U16_DISP_MSGL_FVEC ; DS:EDX ==> message
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,[bp].U16_DISP_MSGL_LEN ; CX = length in bytes
	 mov	 bx,@STD_OUT	; Send to standard output

	 DOSCALL @WRITF2	; Display the message

	 REGREST <ds,edx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 6+2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_DISP_MSGL endp		; End U16_DISP_MSGL procedure
	 NPPROC  U16_NEWLINE -- Goto A New Line
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Goto a new line

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 dl,CR		; Send to console
	 DOSCALL @CHROUT	; ...

	 mov	 dl,LF		; Send to console
	 DOSCALL @CHROUT	; ...

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_NEWLINE endp		; End U16_NEWLINE procedure
	 NPPROC  U16_CALC_HIGHSEG -- Calculate New HIGHSEG
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate new HIGHSEG

|

U16_CALC_HIGHSEG_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
U16_CALC_HIGHSEG_CNT dw ?	    ; # bytes used in NEXTSEG

U16_CALC_HIGHSEG_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,ds>	; Save registers

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 ax,[bp].U16_CALC_HIGHSEG_CNT ; Get # bytes used in NEXTSEG

	 add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 ax,NEXTSEG	; Add in the base segment

	 cmp	 ax,HIGHSEG	; Izit a new high?
	 jb	 short @F	; Jump if not

	 mov	 HIGHSEG,ax	; Save as new high
@@:
	 REGREST <ds,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U16_CALC_HIGHSEG endp		; End U16_CALC_HIGHSEG procedure
	 NPPROC  CHECK_DEFEXT -- Check On Default Extension
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check on the default extension, VM version

Remember to update PMCHECK_DEFEXT.

On entry:

DS:DX	 ==>	 FID
ES:DI	 ==>	 output area
CX	 =	 byte count

On exit:

ES:EDI	 ==>	 next character after extension (default or not)
CX	 =	 new length if default extension appended

|

CHECK_DEFEXT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
CHECK_DEFEXT_OFF dd ?		; Offset in DGROUP of the default extension

CHECK_DEFEXT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,dx,si>	; Save registers

; Search backwards through DS:DX for the extension marker

	 mov	 si,dx		; Copy to index register
	 add	 si,cx		; Add to get next address
	 mov	 dx,cx		; Save original length
	 mov	 DEFEXT_VEC,0	; Assume no default extension used
CHECK_DEFEXT_NEXT:
	 dec	 si		; Back off to previous byte
	 mov	 al,ds:[si]	; Get the next byte

	 cmp	 al,'.'         ; Izit an extension separator?
	 je	 short CHECK_DEFEXT_EXIT ; Jump if so (no default extension)

	 cmp	 al,'\'         ; Izit a path separator?
	 je	 short CHECK_DEFEXT_COPY ; Jump if so (use default extension)

	 loop	 CHECK_DEFEXT_NEXT ; Jump if more bytes to check
CHECK_DEFEXT_COPY:
	 mov	 DEFEXT_VEC.VSEG,es ; Save for later use
	 mov	 DEFEXT_VEC.VOFF,di ; ...
	 mov	 si,[bp].CHECK_DEFEXT_OFF.ELO ; Get def ext offset in DGROUP

	 mov	 cx,4		; Get length of default extension
	 add	 dx,cx		; Count in the default extension
     rep movs	 es:[di].LO,DGROUP:[si].LO ; Copy default extension
CHECK_DEFEXT_EXIT:
	 mov	 cx,dx		; Return length

	 REGREST <si,dx,ax>	; Restore

	 pop	 bp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEFEXT endp		; End CHECK_DEFEXT procedure

NCODE	 ends			; End NCODE segment


CODE	 segment use32 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 CSEL_DATA:word

	 extrn	 WRITE_OUT:near

	 NPPROC  U32_LOWERCASE -- Convert AL To Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convret AL to lowercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Izit below lower limit?
	 jb	 short @F	; Jump if so

	 cmp	 al,'Z'         ; Izit above upper limit?
	 ja	 short @F	; Jump if so

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_LOWERCASE endp		; End U32_LOWERCASE procedure
	 NPPROC  U32_DISP_MSG -- Display Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an EOS-terminated message

On exit:

CF	 =	 0 if successful
	 =	 1 if not (error writing to .MAP or .ERR file)

|

U32_DISP_MSG_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's return address
U32_DISP_MSG_FVEC df ?		; Seg:Off of message
	 dw	 ?		; Filler

U32_DISP_MSG_STR ends

	 push	 ebp		; Prepare to address stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,ds> ; Save registers

	 lds	 edx,[ebp].U32_DISP_MSG_FVEC ; DS:EDX ==> message
	 assume  ds:nothing	; Tell the assembler about it

; Calculate the EOS-terminated string length

	 mov	 ecx,edx	; Copy start of message
@@:
	 cmp	 ds:[ecx].LO,EOS ; Izit End-Of-String?
	 je	 short @F	; Jump if so

	 inc	 ecx		; Skip to the next char

	 jmp	 @B		; Go around again

@@:
	 sub	 ecx,edx	; Subtract to get length
	 call	 WRITE_OUT	; Write DS:EDX for ECX bytes to output file
				; Return with CF significant
	 REGREST <ds,edx,ecx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 8		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_DISP_MSG endp		; End U32_DISP_MSG procedure
	 NPPROC  U32_DISP_MSGL -- Display Message by Length
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an length-specified message.

On exit:

CF	 =	 0 if successful
	 =	 1 if not (error writing to .MAP or .ERR file)

|

U32_DISP_MSGL_STR struc

	 dd	 ?		; Caller's BP
	 dd	 ?		; Caller's return address
U32_DISP_MSGL_FVEC df ? 	; Seg:Off of message
	 dw	 ?		; Filler
U32_DISP_MSGL_LEN dd  ? 	; Length in bytes

U32_DISP_MSGL_STR ends

	 push	 ebp		; Prepare to address stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,edx,ds> ; Save registers

	 lds	 edx,[ebp].U32_DISP_MSGL_FVEC ; DS:EDX ==> message
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ecx,[ebp].U32_DISP_MSGL_LEN ; ECX = length in bytes
	 call	 WRITE_OUT	; Write DS:EDX for ECX bytes to output file
				; Return with CF significant
	 REGREST <ds,edx,ecx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 8+4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_DISP_MSGL endp		; End U32_DISP_MSGL procedure
	 NPPROC  U32_NEWLINE -- Goto A New Line
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Goto a new line

On exit:

CF	 =	 0 if successful
	 =	 1 if not (error writing to .MAP or .ERR file)

|

	 push	 CSEL_DATA.EDD	; Pass DGROUP segment (as dword)
	 push	 dword ptr (offset DGROUP:MSG_CRLF) ; Pass offset of message
	 call	 U32_DISP_MSG	; Display the message
				; Return with CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_NEWLINE endp		; End U32_NEWLINE procedure
	 NPPROC  U32_SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:ESI	 ==>	 ASCII text

On exit:

AL	 =	 non-white space character
DS:ESI	 ==>	 (updated)

|

@@:
	 lods	 ds:[esi].LO	; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; izit white space?
	 je	 short @B	; Jump if so

	 dec	 esi		; Back off to last non-white space

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_SKIP_WHITE endp		; End U32_SKIP_WHITE procedure
	 NPPROC  U32_CALC_HIGHSEG -- Calculate New HIGHSEG
	 assume  ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Calculate new HIGHSEG

|

U32_CALC_HIGHSEG_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
U32_CALC_HIGHSEG_CNT dd ?	    ; # bytes used in NEXTSEG

U32_CALC_HIGHSEG_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax>		; Save register

	 mov	 eax,[ebp].U32_CALC_HIGHSEG_CNT ; Get # bytes used in NEXTSEG

	 add	 eax,16-1	; Round up to para boundary
	 shr	 eax,4-0	; Convert from bytes to paras
	 add	 ax,NEXTSEG	; Add in the base segment

	 cmp	 ax,HIGHSEG	; Izit a new high?
	 jb	 short @F	; Jump if not

	 mov	 HIGHSEG,ax	; Save as new high
@@:
	 REGREST <eax>		; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

U32_CALC_HIGHSEG endp		; End U32_CALC_HIGHSEG procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_ARG module
