;' $Header:   P:/PVCS/MISC/QLINK/QLNK_FCN.ASV   1.2   07 Aug 1998 16:00:08   BOB  $
	title	QLNK_FCN -- QLINK Argument Function Routines
	page	58,122
	name	QLNK_FCN

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
	include ASCII.INC
	include PTR.INC
	include DIR.INC
	include XMS.INC
	include BIOSDATA.INC
	include DPMI.INC

	include QLNK_COM.INC
	include QLNK_LIN.INC
	include QLNK_SEG.INC
.list


RCODE	segment 		; Start RCODE segment
	assume	cs:PGROUP,ds:PGROUP

	public	OLDINT2F_VEC
OLDINT2F_VEC dd ?		; Save area for old INT 2Fh handler

	public	RESNAME_LEN
RESNAME_LEN dw	?		; Length of TXT_RESNAME (including trailing zero)

	public	TXT_RESNAME,TXT_PRJNAME
TXT_RESNAME db	'QLINK:'        ; Resident name
TXT_PRJNAME db	32 dup (0)	; Project name
	db	0		; Trailing zero

	FPPROC	LCL_INT2F -- Local INT 2Fh Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 2Fh handler

On entry:

AX	=	function code

On exit:

If it's a match,

AL	=	0
ES:DI	==>	our entry point

Otherwise, we pass it on to the next handler in sequence.

|

	cmp	ax,@DPMI_API2F	; Izit our function?
	jne	short LCL_INT2F_ORIG ; Jump if not

	REGSAVE <cx,si,di,es>	; Save registers

	cld			; String ops forwardly

	mov	cx,seg PGROUP	; Get segment of TXT_RESNAME
	mov	es,cx		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	mov	cx,RESNAME_LEN	; Get # bytes in our name
	lea	di,TXT_RESNAME	; ES:DI ==> our local name
   repe cmps	ds:[si].LO,TXT_RESNAME[di] ; Compare 'em
	REGREST <es,di,si,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it
	jne	short LCL_INT2F_ORIG ; Jump if no match

	mov	ax,seg PGROUP	; Get segment of our entry point
	mov	es,ax		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	lea	di,LCL_ENTRY	; ES:DI ==> our entry point

	mov	al,0		; Mark as us

	ret			; Return to caller

	assume	es:nothing	; Tell the assembler about it

LCL_INT2F_ORIG:
	jmp	OLDINT2F_VEC	; Continue with original handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT2F endp			; End LCL_INT2F procedure
	 FPPROC  LCL_ENTRY -- Local Entry Point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local entry point

On entry:

AX	 =	 function

On exit:

Depends upon the function

|

	 REGSAVE <>		; Save registers



	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_ENTRY endp			; End LCL_ENTRY procedure

RCODE	ends			; End RCODE segment


DATA	segment 		; Start DATA segment
	assume	ds:DGROUP

	extrn	ARG_FLAG:dword
	include QLNK_ARG.INC

	extrn	MSG_SEP:byte
	extrn	MSG_OVF:byte
	extrn	MSG_UNF:byte
	extrn	MSG_NSERR:byte
	extrn	LASTKEY:word
	extrn	PMTEXE2:byte
	extrn	EXEFIL_MAXMEM:word
	extrn	MINSTACK:dword
	extrn	EXEFIL_EXTVEC:dword
	extrn	NEXTSEG:word
	extrn	NS_HEAD:dword
	extrn	SEQOBJ:word
	
	public	IWF_FLAG,IW2_FLAG,IW3_FLAG
	include QLNK_IWF.INC
IWF_FLAG label	dword		; Ignore/Warn/Fail flags
	IWF_REC <>
	align	4
IW2_FLAG label	dword		; Ignore/Warn/Fail flags #2
	IW2_REC <>
	align	4
IW3_FLAG label	dword		; Ignore/Warn/Fail flags #3
	IW3_REC <>
	align	4

	public	ALIGN_SIZE,PACKCODE_LIM
ALIGN_SIZE dd	512		; Default alignment size
PACKCODE_LIM dd 65500		; ...	  pack code limit

	public	RESFCN_VEC
RESFCN_VEC dd	?		; Seg:Off of resident services

	public	IWFSW
IWFSW	dd	?		; @IWF_IGN, @IWF_WRN, @IWF_FAL

	public	NS_LSTVEC
NS_LSTVEC dd	-1		; Name Sub last ptr (-1 = none)

	public	MSG_ERRPRJ
MSG_ERRPRJ db	'Project name in /R: statement too long.  The limit is 32 characters.',CR,LF,EOS

	public	MSG_HELP
MSG_HELP db	'QLINK    -- Qualitas Linker,',CR,LF
	db	EOS

	public	MSG_QUICKHELP
MSG_QUICKHELP db 'Summary of command line options',CR,LF
	db	'Usage:',CR,LF
	db	CR,LF
	db	'LINK',CR,LF
	db	'LINK @<response file>',CR,LF
	db	'LINK <objs>,<exefile>,<mapfile>,<libs>,<deffile>',CR,LF
	db	CR,LF
	db	'Valid options are',CR,LF
MSG_OPTS label	byte
	db	'/?                                  '
MSG_OPTLEN equ	$-MSG_OPTS     ; Length of ...
;;;;;;; db	'/ALIGNMENT                          '
	db	'/BATCH                              '
;;;;;;; db	'/CODEVIEW                           '
	db	'/CPARMAXALLOC                       '
	db	'/DOSSEG                             '
;;;;;;; db	'/DSALLOCATE                         '
;;;;;;; db	'/DYNAMIC                            '
;;;;;;; db	'/EXEPACK                            '
	db	'/F:option (fail this option)        '
	db	'/FARCALLTRANSLATION                 '
;;;;;;; db	'/HELP                               '
;;;;;;; db	'/HIGH                               '
	db	'/I:option (ignore this option)      '
	db	'/INFORMATION                        '
	db	'/LINENUMBERS                        '
	db	'/MAP                                '
	db	'/NODEFAULTLIBRARYSEARCH             '
	db	'/NOEXTDICTIONARY                    '
	db	'/NOFARCALLTRANSLATION               '
;;;;;;; db	'/NOGROUPASSOCIATION                 '
	db	'/NOIGNORECASE                       '
	db	'/NOLOGO                             '
	db	'/NONULLSDOSSEG                      '
	db	'/NOPACKCODE                         '
	db	'/NOPACKFUNCTIONS                    '
	db	'/NOSWAP                             '
	db	'/NS:Name1-Name2[:Name3-Name4]       '
;;;;;;; db	'/OLDOVERLAY                         '
	db	'/ONERROR                            '
;;;;;;; db	'/OVERLAYINTERRUPT                   '
	db	'/PACKCODE                           '
	db	'/PACKDATA                           '
	db	'/PACKFUNCTIONS                      '
;;;;;;; db	'/PAUSE                              '
;;;;;;; db	'/PCODE                              '
;;;;;;; db	'/PMTYPE                             '
;;;;;;; db	'/QUICKLIBRARY                       '
;;;;;;; db	'/R:projname (resident w/project)    '
	db	'/SEGMENTS                           '
	db	'/STACK                              '
	db	'/TINY                               '
	db	'/W:option (warn this option)        '
;;;;;;; db	'/WARNFIXUP                          '
NOPTS	equ	($-MSG_OPTS)/MSG_OPTLEN ; # options
	org	$-2
	db	CR,LF
	db	' For /F: /I: /W: options, see ',@PRODNAME,'.CFG'
	db	CR,LF,EOS
MSG_OPTZ label	 byte


CNT	=	2		; Initialize counter

	rept	NOPTS/2

	org	MSG_OPTS + CNT*MSG_OPTLEN - 2
	db	CR,LF
CNT	=	CNT + 2

	endm			; REPT NOPTS/2

	org	MSG_OPTZ	; Back to where we started (or ended)



MSGNO_MAC macro  NAM

MSGNO_&NAM db BEL,'ออ> WARN:  ','&NAM&',' option ignored.',CR,LF,EOS

	 endm			; MSGNO_MAC

	 MSGNO_MAC ALIGN
	 MSGNO_MAC CODEVIEW
	 MSGNO_MAC DSALLOCATE
	 MSGNO_MAC DYNAMIC
	 MSGNO_MAC EXEPACK
	 MSGNO_MAC HIGH
	 MSGNO_MAC NOGROUPASSOCIATION
	 MSGNO_MAC OLDOVERLAY
	 MSGNO_MAC OVERLAYINTERRUPT
	 MSGNO_MAC PACKCODE
	 MSGNO_MAC PACKDATA
	 MSGNO_MAC PACKFUNCTIONS
	 MSGNO_MAC PAUSE
	 MSGNO_MAC PCODE
	 MSGNO_MAC PMTYPE
	 MSGNO_MAC QUICKLIBRARY

DATA	 ends			; End DATA segment


	 INISEG_MAC MAP

; All keywords in this table *MUST* be in uppercase

	 LINARG_MAC 'ADDRESS',  'A',  FCN_MAPADDRESS,   LCL
	 LINARG_MAC 'FULL',     'F',  FCN_MAPFULL,      LCL

	 ENDSEG_MAC MAP


	 INISEG_MAC DBG

; All keywords in this table *MUST* be in uppercase

	 LINARG_MAC 'ERROR',    'ERR',  FCN_DBGERROR,     LCL
	 LINARG_MAC 'STATS',    'STA',  FCN_DBGSTATS,     LCL
	 LINARG_MAC 'MSGS',     'MSG',  FCN_DBGMSGS,      LCL
	 LINARG_MAC 'FIXUP',    'FIX',  FCN_DBGFIXUP,     LCL

	 ENDSEG_MAC DBG


	 INISEG_MAC ONERR

; All keywords in this table *MUST* be in uppercase

	 LINARG_MAC 'NOEXE',    'N',    FCN_ONERR_N,      LCL

	 ENDSEG_MAC ONERR


	 INISEG_MAC IWF

; All keywords in this table *MUST* be in uppercase

	 LINARG_MAC 'OMFIGN',   'OMFIGN',  FCN_IWFOMFIGN,  LCL
	 LINARG_MAC 'OMFUNK',   'OMFUNK',  FCN_IWFOMFUNK,  LCL
	 LINARG_MAC 'CSUMINV',  'CSUMINV', FCN_IWFCSUMINV, LCL
	 LINARG_MAC 'CTYPINV',  'CTYPINV', FCN_IWFCTYPINV, LCL
	 LINARG_MAC 'ALININV',  'ALININV', FCN_IWFALININV, LCL
	 LINARG_MAC 'ALINDIF',  'ALINDIF', FCN_IWFALINDIF, LCL
	 LINARG_MAC 'USEDIF',   'USEDIF',  FCN_IWFUSEDIF,  LCL
	 LINARG_MAC 'GRPINV',   'GRPINV',  FCN_IWFGRPINV,  LCL
	 LINARG_MAC 'GRPDIF',   'GRPDIF',  FCN_IWFGRPDIF,  LCL
	 LINARG_MAC 'SEGBIG',   'SEGBIG',  FCN_IWFSEGBIG,  LCL
	 LINARG_MAC 'GRPBIG',   'GRPBIG',  FCN_IWFGRPBIG,  LCL
	 LINARG_MAC 'GRPMIX',   'GRPMIX',  FCN_IWFGRPMIX,  LCL
	 LINARG_MAC 'FIXOVF',   'FIXOVF',  FCN_IWFFIXOVF,  LCL
	 LINARG_MAC 'ABSOVF',   'ABSOVF',  FCN_IWFABSOVF,  LCL
	 LINARG_MAC 'ABSDIF',   'ABSDIF',  FCN_IWFABSDIF,  LCL
	 LINARG_MAC 'TYPDIF',   'TYPDIF',  FCN_IWFTYPDIF,  LCL
	 LINARG_MAC 'EXTMAT',   'EXTMAT',  FCN_IWFEXTMAT,  LCL
	 LINARG_MAC 'SEGEXT',   'SEGEXT',  FCN_IWFSEGEXT,  LCL
	 LINARG_MAC 'SEGEXT0',  'SEGEXT0', FCN_IWFSEGEXT0, LCL
	 LINARG_MAC 'GRPEXT',   'GRPEXT',  FCN_IWFGRPEXT,  LCL
	 LINARG_MAC 'GRPEXT0',  'GRPEXT0', FCN_IWFGRPEXT0, LCL
	 LINARG_MAC 'RELSEG',   'RELSEG',  FCN_IWFRELSEG,  LCL
	 LINARG_MAC 'RELTGT',   'RELTGT',  FCN_IWFRELTGT,  LCL
	 LINARG_MAC 'RELGRP',   'RELGRP',  FCN_IWFRELGRP,  LCL
	 LINARG_MAC 'RELSEGX',  'RELSEGX', FCN_IWFRELSEGX, LCL
	 LINARG_MAC 'RELGRPX',  'RELGRPX', FCN_IWFRELGRPX, LCL
	 LINARG_MAC 'PUBDIF',   'PUBDIF',  FCN_IWFPUBDIF,  LCL
	 LINARG_MAC 'LINDIF',   'LINDIF',  FCN_IWFLINDIF,  LCL
	 LINARG_MAC 'FIXDIF',   'FIXDIF',  FCN_IWFFIXDIF,  LCL
	 LINARG_MAC 'FIXDIFX',  'FIXDIFX', FCN_IWFFIXDIFX, LCL
	 LINARG_MAC 'FRMSEG',   'FRMSEG',  FCN_IWFFRMSEG,  LCL
	 LINARG_MAC 'THRINV',   'THRINV',  FCN_IWFTHRINV,  LCL
	 LINARG_MAC 'BAKPAT',   'BAKPAT',  FCN_IWFBAKPAT,  LCL
	 LINARG_MAC 'FRMSEG0',  'FRMSEG0', FCN_IWFFRMSEG0, LCL
	 LINARG_MAC 'FRMSEG$',  'FRMSEG$', FCN_IWFFRMSEG$, LCL
	 LINARG_MAC 'BLKDEF',   'BLKDEF',  FCN_IWFBLKDEF,  LCL
	 LINARG_MAC 'BLKEND',   'BLKEND',  FCN_IWFBLKEND,  LCL
	 LINARG_MAC 'TYPDEF',   'TYPDEF',  FCN_IWFTYPDEF,  LCL
	 LINARG_MAC 'ALL',      'ALL',     FCN_IWFALL,     LCL

; Remember to create a function for this with IWF_FCNMAC

	 ENDSEG_MAC IWF



NCODE	segment 		; Start NCODE segment
	assume	cs:NGROUP

	extrn	SKIP_WHITE:near
	extrn	U16_DISP_MSG:near
	extrn	DISP_UNK:near
	extrn	CHECK_BASE:near
	extrn	BASE2BIN:near
	extrn	CHECK_SWITCHES:near
	extrn	U16_CALC_HIGHSEG:near

	NPPROC	FCN_ALIGN -- ALIGN Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/A:nnn
/ALIGN:nnn

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_ALIGN_SEP ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 CHECK_BASE	; Check the number base at DS:SI
				; Return with ECX = number base, DS:SI updated
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_ALIGN_OVF ; Jump if too large

; Round up to power-of-two boundary

	 bsr	 ecx,eax	; Get index of high-order bit
	 jz	 short FCN_ALIGN_UNF ; Jump if too small (zero)

	 bsf	 eax,eax	; Get index of low-order bit
	 cmp	 eax,ecx	; If not the same, CF=1
	 adc	 ecx,0		; Add one to round up to next boundary

	 xor	 eax,eax	; Zero to set bit
	 bts	 eax,ecx	; Set the high-order bit

	 mov	 ALIGN_SIZE,eax ; Save for later use

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_ALIGN) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 jmp	 short FCN_ALIGN_EXIT ; Join common exit code

FCN_ALIGN_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_ALIGN_ERR ; Join common error code

FCN_ALIGN_UNF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_UNF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_ALIGN_ERR ; Join common error code

FCN_ALIGN_SEP:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
FCN_ALIGN_ERR:
	 stc			; Indicate there was a problem
FCN_ALIGN_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ALIGN endp			; End FCN_ALIGN procedure
	 NPPROC  FCN_BATCH -- BATCH Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/A
/BATCH

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_BATCH ; Mark as running in batch mode

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_BATCH endp			; End FCN_BATCH procedure
	 NPPROC  FCN_CODEVIEW -- CODEVIEW Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/CO
/CODEVIEW

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_CODEVIEW) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_CODEVIEW endp		; End FCN_CODEVIEW procedure
	 NPPROC  FCN_CPARMAXALLOC -- CPARMAXALLOC Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/CP:nnn
/CPARMAXALLOC:nnn

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_CPARMAXALLOC_SEP ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 CHECK_BASE	; Check the number base at DS:SI
				; Return with ECX = number base, DS:SI updated
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_CPARMAXALLOC_OVF ; Jump if too large

	 cmp	 eax,@CON64KB	; Izit too large?
	 jae	 short FCN_CPARMAXALLOC_OVF ; Jump if so

	 mov	 EXEFIL_MAXMEM,ax ; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_CPARMAXALLOC_EXIT ; Join common exit code

FCN_CPARMAXALLOC_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_CPARMAXALLOC_ERR ; Join common error code

FCN_CPARMAXALLOC_SEP:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
FCN_CPARMAXALLOC_ERR:
	 stc			; Indicate there was a problem
FCN_CPARMAXALLOC_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_CPARMAXALLOC endp		; End FCN_CPARMAXALLOC procedure
	 NPPROC  FCN_DEBUG -- DEBUG Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DEBUG
/DEBUG:ERROR
/DEBUG:STATS
/DEBUG:MSGS

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax>		; Save register

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Izit present?
	 jne	 short FCN_DEBUG_ORIG ; Jump if not

	 inc	 si		; Skip over it

	 call	 SKIP_WHITE	; Skip over more white space

	 push	 dword ptr (offset DGROUP:TAB_DBGSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
				; Return with CF significant
	 jmp	 short FCN_DEBUG_EXIT ; Join common exit code


FCN_DEBUG_ORIG:
	 or	 ARG_FLAG,@ARG_DBGERR or @ARG_DBGSTA ; Mark as in a debuggin' moood

	 clc			; Indicate all went well
FCN_DEBUG_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DEBUG endp			; End FCN_DEBUG procedure
	NPPROC	FCN_DBGERROR -- /DEBUG:ERROR Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DEBUG:ERROR

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	ARG_FLAG,@ARG_DBGERR ; Mark as sending errors to .ERR file

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGERROR endp		; End FCN_DBGERROR procedure
	NPPROC	FCN_DBGFIXUP -- /DEBUG:FIXUP Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DEBUG:FIXUP

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	ARG_FLAG,@ARG_DBGFIX ; Mark as displaying debugging fixups

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGFIXUP endp		; End FCN_DBGFIXUP procedure
	NPPROC	FCN_DBGMSGS -- /DEBUG:MSGS Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DEBUG:MSGS

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	ARG_FLAG,@ARG_DBGMSG ; Mark as displaying debugging messages

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGMSGS endp		; End FCN_DBGMSGS procedure
	NPPROC	FCN_DBGSTATS -- /DEBUG:STATS Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DEBUG:STATS

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	ARG_FLAG,@ARG_DBGSTA ; Mark as sending statistics to .ERR file

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGSTATS endp		; End FCN_DBGSTATS procedure
	NPPROC	FCN_DOSSEG -- DOSSEG Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DOSS
/DOSSEG

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	ARG_FLAG,@ARG_DOSSEG ; Mark as using DOS seg ordering

	clc			; Indicate all went well

	ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DOSSEG endp 		; End FCN_DOSSEG procedure
	NPPROC	FCN_DSALLOCATE -- DSALLOCATE Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DS
/DSALLOCATE

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:MSGNO_DSALLOCATE) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DSALLOCATE endp		; End FCN_DSALLOCATE procedure
	 NPPROC  FCN_DYNAMIC -- DYNAMIC Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/DY:nnn
/DYNAMIC:nnn

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_DYNAMIC_SEP ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 CHECK_BASE	; Check the number base at DS:SI
				; Return with ECX = number base, DS:SI updated
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_DYNAMIC_OVF ; Jump if too large

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_DYNAMIC) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 jmp	 short FCN_DYNAMIC_EXIT ; Join common exit code

FCN_DYNAMIC_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_DYNAMIC_ERR ; Join common error code

FCN_DYNAMIC_SEP:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
FCN_DYNAMIC_ERR:
	 stc			; Indicate there was a problem
FCN_DYNAMIC_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DYNAMIC endp		; End FCN_DYNAMIC procedure
	 NPPROC  FCN_EXEPACK -- EXEPACK Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/E
/EXEPACK

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_EXEPACK) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EXEPACK endp		; End FCN_EXEPACK procedure
	 NPPROC  FCN_FARCALLTRANSLATION -- FARCALLTRANSLATION Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/F
/FARCALLTRANSLATION
/F:type 	 Use this syntax to fail certain events

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax>		; Save register

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Izit present?
	 jne	 short FCN_FAIL_ORIG ; Jump if not

	 inc	 si		; Skip over it

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 IWFSW,@IWF_FAL ; Mark as failing this event

	 push	 dword ptr (offset DGROUP:TAB_IWFSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
				; Return with CF significant
	 jmp	 short FCN_FAIL_EXIT ; Join common exit code

FCN_FAIL_ORIG:
	 or	 ARG_FLAG,@ARG_FCT ; Mark as doing Far Call Translation

	 clc			; Indicate all went well
FCN_FAIL_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FARCALLTRANSLATION endp	; End FCN_FARCALLTRANSLATION procedure
;;;	     NPPROC  FCN_HELP -- HELP Function
;;;	     assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; /HE
;;; /HELP
;;;
;;; On entry:
;;;
;;; DS:SI    ==>     command line following keyword
;;;
;;; On exit:
;;;
;;; DS:SI    ==>     next character to scan
;;; CF	     =	     0 if successful
;;;	     =	     1 if not
;;;
;;; |
;;;
;;;	     push    es 	    ; Pass the segment
;;;	     push    dword ptr (offset DGROUP:MSG_HELP) ; Pass offset of message
;;;	     call    U16_DISP_MSG   ; Display the message
;;;
;;;	     clc		    ; Indicate all went well
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; FCN_HELP endp		    ; End FCN_HELP procedure
	 NPPROC  FCN_HIGH -- HIGH Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/HI
/HIGH

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_HIGH) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_HIGH endp			; End FCN_HIGH procedure
	 NPPROC  FCN_INFORMATION -- INFORMATION Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/I
/INFORMATION
/I:type 	 Use this syntax to ignore certain events

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax>		; Save register

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Izit present?
	 jne	 short FCN_INFO_ORIG ; Jump if not

	 inc	 si		; Skip over it

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 IWFSW,@IWF_IGN ; Mark as ignoring this event

	 push	 dword ptr (offset DGROUP:TAB_IWFSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
				; Return with CF significant
	 jmp	 short FCN_INFO_EXIT ; Join common exit code

FCN_INFO_ORIG:
	or	ARG_FLAG,@ARG_INFO ; Mark as present

	 clc			; Indicate all went well
FCN_INFO_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_INFORMATION endp		; End FCN_INFORMATION procedure
	 NPPROC  FCN_LINENUMBERS -- LINENUMBERS Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/L
/LINENUMBERS

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_LINE ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LINENUMBERS endp		    ; End FCN_LINENUMBERS procedure
	 NPPROC  FCN_MAP -- MAP Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/M[:type]
/MAP[:type]

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_MAP ; Mark as present

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Izit present?
	 jne	 short FCN_MAP_CLC ; Jump if not

	 inc	 si		; Skip over it

	 call	 SKIP_WHITE	; Skip over more white space

	 push	 dword ptr (offset DGROUP:TAB_MAPSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
				; Return with CF significant
	 jmp	 short FCN_MAP_EXIT ; Join common exit code

FCN_MAP_CLC:
	 clc			; Indicate all went well
FCN_MAP_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MAP  endp			; End FCN_MAP procedure
	 NPPROC  FCN_MAPADDRESS -- MAP Address Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/MAP:A
/MAP:ADDRESS

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_MAPADDR ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MAPADDRESS endp		; End FCN_MAPADDRESS procedure
	 NPPROC  FCN_MAPFULL -- MAP Full Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/MAP:F
/MAP:FULL

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_MAPFULL ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MAPFULL endp		; End FCN_MAPFULL procedure
	 NPPROC  FCN_NODEFAULTLIBRARYSEARCH -- NODEFAULTLIBRARYSEARCH Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOD
/NODEFAULTLIBRARYSEARCH

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_NODLS ; Mark as no default library search

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NODEFAULTLIBRARYSEARCH endp ; End FCN_NODEFAULTLIBRARYSEARCH procedure
	 NPPROC  FCN_NOEXTDICTIONARY -- NOEXTDICTIONARY Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOE
/NOEXTDICTIONARY

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_NOEXT ; Mark as no extended dictionaries

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOEXTDICTIONARY endp   ; End FCN_NOEXTDICTIONARY procedure
	NPPROC	FCN_NOFARCALLTRANSLATION -- NOFARCALLTRANSLATION Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOF
/NOFARCALLTRANSLATION

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	and	ARG_FLAG,not @ARG_FCT ; Mark as not translating far calls
	or	ARG_FLAG,@ARG_XFCT ; ...

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOFARCALLTRANSLATION endp	; End FCN_NOFARCALLTRANSLATION procedure
	 NPPROC  FCN_NOIGNORECASE -- NOIGNORECASE Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOI
/NOIGNORECASE

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_NOI ; Mark as NOIGNORECASE

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOIGNORECASE endp		; End FCN_NOIGNORECASE procedure
	 NPPROC  FCN_NOLOGO -- NOLOGO Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOL
/NOLOGO

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

;;;;;;;; push	 es		; Pass the segment
;;;;;;;; push	 dword ptr (offset DGROUP:MSGNO_NOLOGO) ; Pass offset of message
;;;;;;;; call	 U16_DISP_MSG	; Display the message
;;;;;;;;
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOLOGO endp 		; End FCN_NOLOGO procedure
	 NPPROC  FCN_NONULLSDOSSEG -- NONULLSDOSSEG Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NON
/NONULLSDOSSEG

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_NONULLS or @ARG_DOSSEG ; Mark as present and
				; using DOS seg ordering
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NONULLSDOSSEG endp		; End FCN_NONULLSDOSSEG procedure
	 NPPROC  FCN_NOPACKCODE -- NOPACKCODE Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOPACKC
/NOPACKCODE

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 and	 ARG_FLAG,not @ARG_PACKC ; Mark as not packing code

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPACKCODE endp		; End FCN_NOPACKCODE procedure
	 NPPROC  FCN_NOPACKDATA -- NOPACKDATA Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOPACKD
/NOPACKDATA

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 and	 ARG_FLAG,not @ARG_PACKD ; Mark as not packing data

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPACKDATA endp		; End FCN_NOPACKDATA procedure
	 NPPROC  FCN_NOPACKFUNCTIONS -- NOPACKFUNCTIONS Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOPACKF
/NOPACKFUNCTIONS

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 and	 ARG_FLAG,not @ARG_PACKF ; Mark as not packing functions

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPACKFUNCTIONS endp	; End FCN_NOPACKFUNCTIONS procedure
	 NPPROC  FCN_NOSWAP -- NOSWAP Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NOS
/NOSWAP

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_NOSWAP ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSWAP endp 		; End FCN_NOSWAP procedure
	NPPROC	FCN_NS -- NS Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/NS:name->name[:name->name[: ...]]
/NS:name
/NS

Name1->Name2	means substitute Name2 for Name1
Name1		...   stop substituting for Name1

No arguments at all means stop all substitutions.

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax,ebx,di,bp,fs,gs> ; Save registers

	mov	fs,NEXTSEG	; Get next available segment
	assume	fs:nothing	; Tell the assembler about it
	xor	ebx,ebx 	; FS:BX ==> current segment

; Initialize the last segment if necessary

	cmp	NS_LSTVEC.VSEG,-1 ; Izit none so far?
	jne	short @F	; Jump if not

	mov	NS_LSTVEC.VSEG,fs ; Save as new segment
	mov	NS_LSTVEC.VOFF,bx ; ...
	mov	fs:[bx].NS_NEXT,-1 ; Mark as end-of-the-line

	xor	eax,eax 	; Zero to use as dword
	mov	ax,fs		; Get segment
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,ebx 	; Add to get LA
	mov	NS_HEAD,eax	; Save as start of linked list
@@:
	call	SKIP_WHITE	; Skip over more white space

	cmp	al,':'          ; Izit present?
	jne	near ptr FCN_NS_HALT ; Jump if not (halt all substitutions)
FCN_NS_NEXT:
	inc	si		; Skip over it
	call	SKIP_WHITE	; Skip over more white space

; Parse the names

	lea	di,fs:[bx].NS_NAME1 ; FS:DI ==> Name1 save area
	mov	bp,di		; Save start of name for later use
FCN_NS_NEXTCHAR1:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	jbe	short FCN_NS_WS1 ; Jump if so

	cmp	al,'-'          ; Izit name separator?
	je	short FCN_NS_PTR ; Jump if so

	mov	fs:[di],al	; Save as part of Name1
	inc	di		; Skip over it

	jmp	FCN_NS_NEXTCHAR1 ; Go around again


FCN_NS_WS1:
	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'-'          ; Izit name separator
	jne	near ptr FCN_NS_SYNTERR ; Jump if not (syntax error)
	
	inc	si		; Skip over it
FCN_NS_PTR:
	mov	ax,di		; Copy offset of next char
	sub	ax,bp		; Less start of name
	mov	fs:[bp-1],al	; Save as Name1 length

	call	SKIP_WHITE	; Skip over more white space

	inc	di		; Skip over the length byte
	mov	bp,di		; Save start of name for later use
FCN_NS_NEXTCHAR2:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	jbe	short FCN_NS_WS2 ; Jump if so
	
	cmp	al,';'          ; Izit EOL?
	jbe	short FCN_NS_WS2 ; Jump if so

	cmp	al,','          ; Izit field separator?
	jbe	short FCN_NS_WS2 ; Jump if so

	cmp	al,':'          ; Izit list separator?
	je	short FCN_NS_WS2 ; Jump if so

	mov	fs:[di],al	; Save as part of Name2
	inc	di		; Skip over it

	jmp	FCN_NS_NEXTCHAR2 ; Go around again


FCN_NS_WS2:
	mov	ax,di		; Copy offset of next char
	sub	ax,bp		; Less start of name
	mov	fs:[bp-1],al	; Save as Name1 length

	dec	si		; Back off to last char

	mov	fs:[bx].NS_FLAG,0 ; Mark as clean
	mov	ax,SEQOBJ	; Get current .OBJ sequence #
	mov	fs:[bx].NS_OBJSEQ,ax ; Save in record

; Link in this segment to the last
; FS:BX ==>	current entry

	push	si		; Save for a moment

	lgs	si,NS_LSTVEC	; GS:SI ==> last entry
	assume	gs:nothing	; Tell the assembler about it

	xor	eax,eax 	; Zero to use as word
	mov	ax,fs		; Get the current segment
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,ebx 	; Add offset to get LA
	mov	gs:[si].NS_NEXT,eax ; Save as ptr to this entry

	pop	si		; Restore

	mov	NS_LSTVEC.VSEG,fs ; Save as ptr to last entry
	mov	NS_LSTVEC.VOFF,bx ; ...


	call	SKIP_WHITE	; Skip over more white space
	
	cmp	al,':'          ; Izit list separator?
	jne	short FCN_NS_DONE ; Jump if not

	mov	bx,di		; FS:BX ==> next entry

	jmp	FCN_NS_NEXT	; Go around again


; Spit out a Halt All Substitutions record

FCN_NS_HALT:
	mov	fs:[bx].NS_FLAG,@NS_HALT ; Mark as halted
	lea	di,fs:[bx].NS_LEN1 ; Use minimum length

	mov	ax,SEQOBJ	; Get current .OBJ sequence #
	mov	fs:[bx].NS_OBJSEQ,ax ; Save in record

; Link in this segment to the last
; FS:BX ==>	current entry

	push	si		; Save for a moment

	lgs	si,NS_LSTVEC	; GS:SI ==> last entry
	assume	gs:nothing	; Tell the assembler about it

	xor	eax,eax 	; Zero to use as word
	mov	ax,fs		; Get the current segment
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,ebx 	; Add offset to get LA
	mov	gs:[si].NS_NEXT,eax ; Save as ptr to this entry

	pop	si		; Restore

	mov	NS_LSTVEC.VSEG,fs ; Save as ptr to next available entry
	mov	NS_LSTVEC.VOFF,bx ; ...

; Processing is over
; FS:DI ==>	next entry

FCN_NS_DONE:
	push	di		; Pass # bytes used
	call	U16_CALC_HIGHSEG ; Calculate new HIGHSEG value

	add	di,16-1 	; Round up to next para boundary
	shr	di,4-0		; Convert from bytes to paras
	add	NEXTSEG,di	; Save as next available segment

	mov	fs:[bx].NS_NEXT,-1 ; Mark as last in sequence

	clc			; Mark as successful

	jmp	short FCN_NS_EXIT ; Join common exit code


FCN_NS_SYNTERR:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:MSG_NSERR) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message
FCN_NS_ERR:
	stc			; Indicate there was a problem
FCN_NS_EXIT:
	REGREST <gs,fs,bp,di,ebx,eax> ; Restore
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NS	endp			; End FCN_NS procedure
	NPPROC	FCN_ONERROR -- ONERROR Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/ON[ERROR]:N[OEXE]

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,':'          ; Izit present?
	jne	short FCN_ONERROR_SEP ; Jump if not

	inc	si		; Skip over it

	call	SKIP_WHITE	; Skip over more white space

	push	dword ptr (offset DGROUP:TAB_ONERRSW) ; Pass offset of table
	call	CHECK_SWITCHES	; See if it matches our list of switches
				; Return with CF significant
	jmp	short FCN_ONERROR_EXIT ; Join common exit code

FCN_ONERROR_SEP:
	push	es		; Pass the segment
	push	dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	call	U16_DISP_MSG	; Display the message
FCN_ONERROR_ERR:
	stc			; Indicate there was a problem
FCN_ONERROR_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ONERROR endp		; End FCN_ONERROR procedure
	 NPPROC  FCN_ONERR_N -- /ONERROR:NOEXE Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/ONERROR:NOEXE

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_NOEXE ; Mark as not creating EXE on error

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ONERR_N endp		; End FCN_ONERR_N procedure
	NPPROC	FCN_OPTHEADER -- OPTHEADER Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/OP
/OPTHEADER

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	or	ARG_FLAG,@ARG_OPTHDR ; Mark as present

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_OPTHEADER endp		; End FCN_OPTHEADER procedure
	 NPPROC  FCN_PACKCODE -- PACKCODE Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/PACKC[:nnn]
/PACKCODE[:nnn]

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Is optional arg present?
	 jne	 short FCN_PACKCODE_CLC ; Jump if not

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 CHECK_BASE	; Check the number base at DS:SI
				; Return with ECX = number base, DS:SI updated
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_PACKCODE_OVF ; Jump if too large

	 mov	 PACKCODE_LIM,eax ; Save for later use
FCN_PACKCODE_CLC:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_PACKCODE) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 or	 ARG_FLAG,@ARG_PACKC ; Mark as packing code

	 clc			; Indicate all went well

	 jmp	 short FCN_PACKCODE_EXIT ; Join common exit code

FCN_PACKCODE_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

;;;;;;;; jmp	 short FCN_PACKCODE_ERR ; Join common error code

FCN_PACKCODE_ERR:
	 stc			; Indicate there was a problem
FCN_PACKCODE_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PACKCODE endp		; End FCN_PACKCODE procedure
	 NPPROC  FCN_PACKDATA -- PACKDATA Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/PACKD
/PACKDATA

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_PACKD ; Mark as packing data

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_PACKDATA) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PACKDATA endp		; End FCN_PACKDATA procedure
	 NPPROC  FCN_PACKFUNCTIONS -- PACKFUNCTIONS Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/PACKF
/PACKFUNCTIONS

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_PACKF ; Mark as packing functions

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSGNO_PACKFUNCTIONS) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PACKFUNCTIONS endp		; End FCN_PACKFUNCTIONS procedure
	 NPPROC  FCN_R -- R (RESIDENT) Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/R:projname

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <ax,cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_R_SEP ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

; Append the project name to the resident name

	 push	 es		; Save for a moment

	 mov	 ax,seg PGROUP	; Get segment of TXT_RESNAME
	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,TXT_PRJNAME ; ES:DI ==> save area for project name
	 mov	 cx,length TXT_PRJNAME ; Get # bytes in save area
@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Izit end-of-name?
	 jbe	 short @F	; Jump if so

	 cmp	 al,'/'         ; Izit a switch character?
	 je	 short @F	; Jump if so

	 cmp	 al,';'         ; Izit an endline character?
	 je	 short @F	; Jump if so

	 stos	 TXT_PRJNAME[di] ; Save in project name

	 loop	 @B		; Jump if more characters in save area

	 pop	 es		; Retore
	 assume  es:DGROUP	; Tell the assembler about it

	 jmp	 short FCN_R_PRJ ; Join common error code

	 assume  es:PGROUP	; Tell the assembler about it
@@:
	 sub	 di,offset PGROUP:TXT_RESNAME ; Less starting point to get length
	 inc	 di		; Count in trailing zero
	 mov	 RESNAME_LEN,di ; Save for later use

	 pop	 es		; Retore
	 assume  es:DGROUP	; Tell the assembler about it

	 dec	 si		; Back up to previous character

	 REGSAVE <si,ds,es>	; Save for a moment

	 mov	 ax,seg PGROUP	; Get segment of TXT_RESNAME
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,TXT_RESNAME ; DS:SI ==> resident name
	 mov	 ax,@DPMI_API2F ; Get function for API
	 int	 2Fh		; Request resident status check
				; Return ES:DI ==> entry point if resident
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,es		; Copy entry point segment is resident

	 REGREST <es,ds,si>	; Restore
	 assume  ds:nothing,es:DGROUP ; Tell the assembler about it

	 cmp	 al,0		; Are we already resident for this project?
	 jne	 short @F	; Jump if not

	 mov	 RESFCN_VEC.VOFF,di ; Save for later use
	 mov	 RESFCN_VEC.VSEG,cx ; ...

	 jmp	 short FCN_R_DONE ; Join common done code




@@:





FCN_R_DONE:
	 clc			; Indicate all went well

	 jmp	 short FCN_R_EXIT ; Join common exit code

FCN_R_PRJ:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_ERRPRJ) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 jmp	 short FCN_R_ERR ; Join common error code

FCN_R_SEP:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
FCN_R_ERR:
	 stc			; Indicate there was a problem
FCN_R_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_R	 endp			; End FCN_R procedure
	 NPPROC  FCN_SEGMENTS -- SEGMENTS Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/SEG:nnn
/SEGMENTS:nnn

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_SEGMENTS_SEP ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 CHECK_BASE	; Check the number base at DS:SI
				; Return with ECX = number base, DS:SI updated
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_SEGMENTS_OVF ; Jump if too large

; Ignore this one quietly:  we have nowhere near the segment limit
; other linkers have.

	 clc			; Indicate all went well

	 jmp	 short FCN_SEGMENTS_EXIT ; Join common exit code

FCN_SEGMENTS_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_SEGMENTS_ERR ; Join common error code

FCN_SEGMENTS_SEP:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
FCN_SEGMENTS_ERR:
	 stc			; Indicate there was a problem
FCN_SEGMENTS_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SEGMENTS endp		; End FCN_SEGMENTS procedure
	 NPPROC  FCN_STACK -- STACK Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/ST:nnn
/STACK:nnn

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_STACK_SEP ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 CHECK_BASE	; Check the number base at DS:SI
				; Return with ECX = number base, DS:SI updated
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_STACK_OVF ; Jump if too large

	 cmp	 eax,@CON64KB	; Izit too large?
	 ja	 short FCN_STACK_OVF ; Jump if so

	 mov	 MINSTACK,eax	; Save as minimum stack

	 clc			; Indicate all went well

	 jmp	 short FCN_STACK_EXIT ; Join common exit code

FCN_STACK_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_STACK_ERR ; Join common error code

FCN_STACK_SEP:
	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_SEP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message
FCN_STACK_ERR:
	 stc			; Indicate there was a problem
FCN_STACK_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_STACK endp			; End FCN_STACK procedure
	 NPPROC  FCN_QUICKHELP -- QUICKHELP Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/?

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 push	 es		; Pass the segment
	 push	 dword ptr (offset DGROUP:MSG_QUICKHELP) ; Pass offset of message
	 call	 U16_DISP_MSG	; Display the message

	 stc			; Indicate we should quit

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_QUICKHELP endp		; End FCN_QUICKHELP procedure
	 NPPROC  FCN_TINY -- TINY Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/T
/TINY

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 or	 ARG_FLAG,@ARG_TINY ; Mark as creating .COM file

	 mov	 PMTEXE2[0].EDD,'MOC.' ; Change default to .COM

	 cmp	 EXEFIL_EXTVEC,0 ; Has there been a default extension used?
	 je	 short @F	; Jump if not

	 REGSAVE <si,ds>	; Save for a moment

	 lds	 si,EXEFIL_EXTVEC ; DS:SI ==> default extension
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds:[si].EDD,'MOC.' ; Change default to .COM

	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TINY endp			; End FCN_TINY procedure
	 NPPROC  FCN_WARNFIXUP -- WARNFIXUP Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/W
/WARNFIXUP
/W:type 	 Use this syntax to warn about certain events

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax>		; Save register

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,':'         ; Izit present?
	 jne	 short FCN_WARN_ORIG ; Jump if not

	 inc	 si		; Skip over it

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 IWFSW,@IWF_WRN ; Mark as warning this event

	 push	 dword ptr (offset DGROUP:TAB_IWFSW) ; Pass offset of table
	 call	 CHECK_SWITCHES ; See if it matches our list of switches
				; Return with CF significant
	 jmp	 short FCN_WARN_EXIT ; Join common exit code

FCN_WARN_ORIG:

; Ignore this one quietly:  we already do more than any other linker
; to warn about fixup problems.

	 clc			; Indicate all went well
FCN_WARN_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WARNFIXUP endp		; End FCN_WARNFIXUP procedure
	 NPPROC  FCN_IWFALL -- IWF:ALL Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/I:ALL
/W:ALL
/F:ALL

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax>		; Save register

	 imul	 eax,IWFSW,01010101010101010101010101010101b ; Set 'em all to this
	 mov	 IWF_FLAG,eax	; Save as the new setting
	 mov	 IW2_FLAG,eax	; ...

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_IWFALL endp 		; End FCN_IWFALL procedure


IWF_FCNMAC macro NAM,SUF

	NPPROC	FCN_IWF&NAM -- IWF:&NAM Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

/I:&NAM&
/W:&NAM&
/F:&NAM&

On entry:

DS:SI	==>	command line following keyword

On exit:

DS:SI	==>	next character to scan
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax>		; Save register

	mov	eax,IWFSW	; Get the new setting
	shl	eax,$IW&SUF&_&NAM& ; Shift into position
	and	IW&SUF&_FLAG,not @IW&SUF&_&NAM& ; Clear the old setting
	or	IW&SUF&_FLAG,eax ; Include the new setting

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_IWF&NAM& endp		; End FCN_IWF&NAM& procedure

	endm			; IWF_FCNMAC

	IWF_FCNMAC OMFIGN,  F
	IWF_FCNMAC OMFUNK,  F
	IWF_FCNMAC CSUMINV, F
	IWF_FCNMAC CTYPINV, F
	IWF_FCNMAC ALININV, F
	IWF_FCNMAC ALINDIF, F
	IWF_FCNMAC USEDIF,  F
	IWF_FCNMAC GRPINV,  F
	IWF_FCNMAC GRPDIF,  F
	IWF_FCNMAC SEGBIG,  F
	IWF_FCNMAC GRPBIG,  F
	IWF_FCNMAC GRPMIX,  F
	IWF_FCNMAC FIXOVF,  F
	IWF_FCNMAC ABSOVF,  F
	IWF_FCNMAC ABSDIF,  F
	IWF_FCNMAC TYPDIF,  F
	IWF_FCNMAC EXTMAT,  2
	IWF_FCNMAC SEGEXT,  2
	IWF_FCNMAC SEGEXT0, 2
	IWF_FCNMAC GRPEXT,  2
	IWF_FCNMAC GRPEXT0, 2
	IWF_FCNMAC RELSEG,  2
	IWF_FCNMAC RELTGT,  3
	IWF_FCNMAC RELGRP,  2
	IWF_FCNMAC RELSEGX, 2
	IWF_FCNMAC RELGRPX, 2
	IWF_FCNMAC PUBDIF,  2
	IWF_FCNMAC LINDIF,  2
	IWF_FCNMAC FIXDIF,  2
	IWF_FCNMAC FIXDIFX, 2
	IWF_FCNMAC FRMSEG,  2
	IWF_FCNMAC THRINV,  2
	IWF_FCNMAC BAKPAT,  2
	IWF_FCNMAC FRMSEG0, 3
	IWF_FCNMAC FRMSEG$, 3
	IWF_FCNMAC BLKDEF,  3
	IWF_FCNMAC BLKEND,  3
	IWF_FCNMAC TYPDEF,  3

; Remember to create a command line entry for this with LINARG_MAC

NCODE	ends			; End NCODE segment

	MEND			; End QLNK_FCN module
