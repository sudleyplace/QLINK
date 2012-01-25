;' $Header:   P:/PVCS/MISC/QLINK/QLNK_DMP.ASV   1.1   17 Jul 1997 12:36:44   BOB  $
	title	QLNK_DMP -- QLINK Dump Routines
	page	58,122
	name	QLNK_DMP

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
	 include DOSCALL.INC
	 include ASCII.INC
	 include ALLMEM.INC

	 include QLNK_COM.INC
	 include QLNK_SEG.INC
	 include QLNK_SYM.INC
.list

DISP_MAC macro	 TTL,NAM,VAL,NAM2

ifnb <VAL>
	 mov	 eax,AGROUP:[esi].&TTL&_&VAL ; Get offset
else
	 mov	 eax,AGROUP:[esi].&TTL&_&NAM ; Get offset
endif
ifnb <NAM2>
	 lea	 edi,TXT_&TTL&_&NAM2&1 ; ES:EDI ==> format area
else
	 lea	 edi,TXT_&TTL&_&NAM&1 ; ES:EDI ==> format area
endif
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 push	 eax		; Save for a moment
ifnb <NAM2>
	 DOSCALL @STROUT,TXT_&TTL&_&NAM2 ; Display header message
else
	 DOSCALL @STROUT,TXT_&TTL&_&NAM ; Display header message
endif
	 pop	 eax		; Restore

	 endm			; DISP_MAC

DATA	 segment		; Start DATA segment
	 assume  ds:DGROUP

;;;;;;; extrn	LMB_TXTSTR:tbyte
	 extrn	 LMB_PEROBJ:tbyte
	 extrn	 LMB_PERSEG:tbyte
	 extrn	 LMB_PERGRP:tbyte
	 extrn	 LMB_LNAMES:tbyte
	 extrn	 LMB_SYMBOL:tbyte
;;;;;;; extrn	LMB_SYMHSH:tbyte
;;;;;;; extrn	LMB_EXTDEF:tbyte
;;;;;;; extrn	LMB_PUBDEF:tbyte

	 public  DMPSTAT
DMPSTAT   db	 0		; 1 = enabled, 0 = disabled

	 public  HDR_PEROBJ
HDR_PEROBJ db	      '様> PEROBJ Header Record at '
HDR_PEROBJ1 db	 '________',CR,LF,EOS
TXT_PEROBJ_PFID     db '    PFID    = '
TXT_PEROBJ_PFID1    db '________ - ',EOS
TXT_PEROBJ_PTHEADR  db '    PTHEADR = '
TXT_PEROBJ_PTHEADR1 db '________ - ',EOS

	 public  HDR_LNAMES
HDR_LNAMES db	      '様> LNAMES Header Record at '
HDR_LNAMES1 db	 '________',CR,LF,EOS
TXT_LNAMES_PTXT     db '    PTXT    = '
TXT_LNAMES_PTXT1    db '________ - ',EOS

	 public  HDR_PERSEG
HDR_PERSEG db	      '様> PERSEG Header Record at '
HDR_PERSEG1 db	 '________',CR,LF,EOS
TXT_PERSEG_LEN	    db '    LMB_LEN = '
TXT_PERSEG_LEN1     db '________',EOS
TXT_PERSEG_HNDL     db '    LMB_HNDL= '
TXT_PERSEG_HNDL1    db '________',EOS
TXT_PERSEG_BEG	    db '    LMB_BEG = '
TXT_PERSEG_BEG1     db '________',EOS
TXT_PERSEG_NXT	    db '    LMB_NXT = '
TXT_PERSEG_NXT1     db '________',EOS
TXT_PERSEG_END	    db '    LMB_END = '
TXT_PERSEG_END1     db '________',EOS
TXT_PERSEG_SEGSYM   db '    SEGSYM  = '
TXT_PERSEG_SEGSYM1  db '________ - ',EOS
TXT_PERSEG_GRPSYM   db '    GRPSYM  = '
TXT_PERSEG_GRPSYM1  db '________ - ',EOS
TXT_PERSEG_GRPLNK   db '    GRPLNK  = '
TXT_PERSEG_GRPLNK1  db '________',EOS
TXT_PERSEG_START    db '    START   = '
TXT_PERSEG_START1   db '________',EOS
TXT_PERSEG_NEWLEN   db '    NEWLEN  = '
TXT_PERSEG_NEWLEN1  db '________',EOS
TXT_PERSEG_OLDLEN   db '    OLDLEN  = '
TXT_PERSEG_OLDLEN1  db '________',EOS

	 public  HDR_PERGRP
HDR_PERGRP db	      '様> PERGRP Header Record at '
HDR_PERGRP1 db	 '________',CR,LF,EOS
TXT_PERGRP_GRPSYM   db '    GRPSYM  = '
TXT_PERGRP_GRPSYM1  db '________ - ',EOS
TXT_PERGRP_BEG	    db '    START   = '
TXT_PERGRP_BEG1     db '________',EOS
TXT_PERGRP_NXT	    db '    NEXT    = '
TXT_PERGRP_NXT1     db '________',EOS
TXT_PERGRP_GRPLNK   db '    GRPLNK  = '
TXT_PERGRP_GRPLNK1  db '________',EOS

	 public  TXT_CRLF,TXT_SEP
TXT_CRLF db	 CR,LF,EOS
TXT_SEP  db	 ' - ',EOS

DATA	 ends			; End DATA segment


CODE	 segment		; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 CSEL_4GB:word
	 extrn	 CSEL_DATA:word

	 extrn	 DD2HEX:near
	 extrn	 DISP_CNTCHR:near

	 NPPROC  DUMPIT -- Dump All The Tables
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Dump all the tables.

|

	 pushad 		; Save registers
	 REGSAVE <ds,es,fs,gs>	; ...

	 mov	 ds,CSEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,CSEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 fs,CSEL_DATA	; Get DGROUP data selector
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 gs,CSEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 cmp	 DMPSTAT,1	; Izit still enabled?
	 jne	 short DUMPIT_EXIT ; Jump if not

	 call	 DUMP_TXTSTR	; Dump the small text strings table
	 call	 DUMP_PEROBJ	; ...	   per .OBJ file table
	 call	 DUMP_PERSEG	; ...	   per segment table
	 call	 DUMP_PERGRP	; ...	   per group table
;;;;;;;; call	 DUMP_LNAMES	; ...	   List of Names table
	 call	 DUMP_SYMBOL	; ...	   symbol table
;;;;;;;; call	 DUMP_SYMHSH	; ...	   symbol name hash table
;;;;;;;; call	 DUMP_SEGDEF	; ...	   segment definitions table
;;;;;;;; call	 DUMP_GRPDEF	; ...	   group ...
;;;;;;;; call	 DUMP_EXTDEF	; ...	   external ...
;;;;;;;; call	 DUMP_PUBDEF	; ...	   public ...
;;;;;;;; call	 DUMP_FUXUPP	; ...	   fixup table
DUMPIT_EXIT:
	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it
	 popad			; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMPIT	 endp			; End DUMPIT procedure
	 NPPROC  DUMP_TXTSTR -- Dump Small Text Strings Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump small text strings table

|





	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_TXTSTR endp		; End DUMP_TXTSTR procedure
	 NPPROC  DUMP_PEROBJ -- Dump Per .OBJ File Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per .OBJ file table

|

	 mov	 esi,LMB_PEROBJ.LMB_CURB.BOUND_BEG ; Get starting address
DUMP_PEROBJ_NEXT:
	 cmp	 esi,LMB_PEROBJ.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 near ptr DUMP_PEROBJ_EXIT ; Jump if so

	 mov	 eax,esi	; Copy offset
	 lea	 edi,HDR_PEROBJ1 ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 DOSCALL @STROUT,HDR_PEROBJ ; Display header message

	 DISP_MAC PEROBJ,PFID
	 push	 eax		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display the FID
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PEROBJ,PTHEADR
	 push	 eax		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display the FID
	 DOSCALL @STROUT,TXT_CRLF

	 add	 esi,type PEROBJ_STR ; Skip to next entry

	 jmp	 DUMP_PEROBJ_NEXT ; Go around again

DUMP_PEROBJ_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PEROBJ endp		; End DUMP_PEROBJ procedure
	 NPPROC  DUMP_PERSEG -- Dump Per Segment Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per segment table

|

	 mov	 esi,LMB_PERSEG.LMB_CURB.BOUND_BEG ; Get starting address

	 cmp	 esi,0		; Izit initialized?
	 je	 near ptr DUMP_PERSEG_EXIT ; Jump if not

	 cmp	 esi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 near ptr DUMP_PERSEG_EXIT ; Jump if so

	 mov	 eax,esi	; Copy offset
	 lea	 edi,HDR_PERSEG1 ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 DOSCALL @STROUT,HDR_PERSEG ; Display header message
DUMP_PERSEG_NEXT:
	 cmp	 esi,LMB_PERSEG.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 near ptr DUMP_PERSEG_EXIT ; Jump if so

	 DISP_MAC PERSEG,SEGSYM

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display the FID

	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,GRPSYM

	 and	 eax,eax	; Izit valid?
	 jz	 short @F	; Jump if not

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display the FID
@@:
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,GRPLNK
	 call	 DUMP_GRPLNK	; Dump the GRPLNK chain by segment name
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,LMB,LMB.LMB_LEN ,LEN
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,LMB,LMB.LMB_HNDL,HNDL
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,LMB,LMB.LMB_CURB.BOUND_BEG,BEG
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,LMB,LMB.LMB_CURB.BOUND_NXT,NXT
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,LMB,LMB.LMB_OVRB.BOUND_NXT,END
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,ADRB,ADRB.BOUND_BEG,BEG
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,ADRB,ADRB.BOUND_NXT,NXT
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,NEWLEN
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERSEG,OLDLEN
	 DOSCALL @STROUT,TXT_CRLF

	 add	 esi,type PERSEG_STR ; Skip to next entry

	 jmp	 DUMP_PERSEG_NEXT ; Go around again

DUMP_PERSEG_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERSEG endp		; End DUMP_PERSEG procedure
	 NPPROC  DUMP_PERGRP -- Dump Per Group Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump per group table

|

	 mov	 esi,LMB_PERGRP.LMB_CURB.BOUND_BEG ; Get starting address

	 cmp	 esi,0		; Izit initialized?
	 je	 near ptr DUMP_PERGRP_EXIT ; Jump if not

	 cmp	 esi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 near ptr DUMP_PERGRP_EXIT ; Jump if so

	 mov	 eax,esi	; Copy offset
	 lea	 edi,HDR_PERGRP1 ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 DOSCALL @STROUT,HDR_PERGRP ; Display header message
DUMP_PERGRP_NEXT:
	 cmp	 esi,LMB_PERGRP.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 near ptr DUMP_PERGRP_EXIT ; Jump if so

	 DISP_MAC PERGRP,GRPSYM

	 and	 eax,eax	; Izit valid?
	 jz	 short @F	; Jump if not

	 UNCURB  eax,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[eax].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display the FID
@@:
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERGRP,GRPLNK
	 call	 DUMP_GRPLNK	; Dump the GRPLNK chain by segment name
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERGRP,ADRB,ADRB.BOUND_BEG,BEG
	 DOSCALL @STROUT,TXT_CRLF

	 DISP_MAC PERGRP,ADRB,ADRB.BOUND_NXT,NXT
	 DOSCALL @STROUT,TXT_CRLF

	 add	 esi,type PERGRP_STR ; Skip to next entry

	 jmp	 DUMP_PERGRP_NEXT ; Go around again

DUMP_PERGRP_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PERGRP endp		; End DUMP_PERGRP procedure
	 NPPROC  DUMP_LNAMES -- Dump List of Names Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump list of names table

|

	 mov	 esi,LMB_LNAMES.LMB_CURB.BOUND_BEG ; Get starting address

	 cmp	 esi,0		; Izit initialized?
	 je	 short DUMP_LNAMES_EXIT ; Jump if not

	 cmp	 esi,LMB_LNAMES.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 short DUMP_LNAMES_EXIT ; Jump if so

	 mov	 eax,esi	; Copy offset
	 lea	 edi,HDR_LNAMES1 ; ES:EDI ==> format area
	 call	 DD2HEX 	; Convert EAX to hex at ES:EDI

	 DOSCALL @STROUT,HDR_LNAMES ; Display header message
DUMP_LNAMES_NEXT:
	 cmp	 esi,LMB_LNAMES.LMB_CURB.BOUND_NXT ; Izit at the end?
	 je	 short DUMP_LNAMES_EXIT ; Jump if so

	 DISP_MAC LNAMES,PTXT
	 push	 eax		; Pass the offset in AGROUP
	 call	 DISP_CNTCHR	; Display the FID
	 DOSCALL @STROUT,TXT_CRLF

	 add	 esi,type LNAMES_STR ; Skip to next entry

	 jmp	 DUMP_LNAMES_NEXT ; Go around again

DUMP_LNAMES_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_LNAMES endp		; End DUMP_LNAMES procedure
	 NPPROC  DUMP_SYMBOL -- Dump Symbol Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump symbol table

|





	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_SYMBOL endp		; End DUMP_SYMBOL procedure
	 NPPROC  DUMP_SYMHSH -- Dump Symbol Name Hash Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump symbol name hash table

|





	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_SYMHSH endp		; End DUMP_SYMHSH procedure
	 NPPROC  DUMP_EXTDEF -- Dump External Definitions Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump external definitions table

|





	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_EXTDEF endp		; End DUMP_EXTDEF procedure
	 NPPROC  DUMP_PUBDEF -- Dump Public Definitions Table
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the public definitions table

|





	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_PUBDEF endp		; End DUMP_PUBDEF procedure
	 NPPROC  DUMP_GRPLNK -- Dump The GRPLNK Chain
	 assume  ds:DGROUP,es:DGROUP,fs:DGROUP,gs:AGROUP,ss:nothing
COMMENT|

Dump the GRPLNK chain by segment name.

On entry:

EAX	 =	 LA of PERSEG_STR

|

	 pushad 		; Save registers
DUMP_GRPLNK_NEXT:
	 and	 eax,eax	; Izit valid?
	 jz	 short DUMP_GRPLNK_EXIT ; Jump if not

	 push	 eax		; Save for a moment
	 DOSCALL @STROUT,TXT_SEP ; Display a separator
	 pop	 eax		; Restore

	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 ebx,AGROUP:[eax].PERSEG_SEGSYM ; Get LA of SYM_STR
	 UNCURB  ebx,SYMBOL	; Ensure within current bounds
	 push	 AGROUP:[ebx].SYM_PNAM ; Pass LA of symbol (Count, Char[])
	 call	 DISP_CNTCHR	; Display the FID

	 UNCURB  eax,PERSEG	; Ensure within current bounds
	 mov	 eax,AGROUP:[eax].PERSEG_GRPLNK ; Get LA of next PERSEG_STR

	 jmp	 DUMP_GRPLNK_NEXT ; Go around again

DUMP_GRPLNK_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMP_GRPLNK endp		; End DUMP_GRPLNK procedure

CODE	 ends			; End CODE segment

	 MEND			; End QLNK_DMP module
