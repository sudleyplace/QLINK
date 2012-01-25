.386p
	include MASM.INC
	include PTR.INC
	include VMM.INC
	include WINDEVID.INC

W95DPMI_Init_Order equ	Undefined_Init_Order
W95DPMI_VERS_H	   equ	1
W95DPMI_VERS_T	   equ	0

Declare_Virtual_Device	W95DPMI,		\
			W95DPMI_VERS_H, 	\
			W95DPMI_VERS_T, 	\
			W95DPMI_CONTROL,	\
			W95DPMI_Device_ID,	\
			W95DPMI_Init_Order,	\
			,			\
			W95DPMI_PM_Call
			

VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	public	ActionTable
ActionTable label dword
	dd	offset32 Sys_Critical_In ; 00 Sys_Critical_Init
	dd	offset32 W95_Device_Init ; 01 Device_Init
;;;;;;; dd	offset32 NoAction	 ; 02
;;;;;;; dd	offset32 NoAction	 ; 03
;;;;;;; dd	offset32 NoAction	 ; 04
;;;;;;; dd	offset32 NoAction	 ; 05
;;;;;;; dd	offset32 NoAction	 ; 06
;;;;;;; dd	offset32 NoAction	 ; 07
;;;;;;; dd	offset32 NoAction	 ; 08
;;;;;;; dd	offset32 NoAction	 ; 09
;;;;;;; dd	offset32 NoAction	 ; 0A
;;;;;;; dd	offset32 loc_28F	 ; 0B: VM_Not_Executeable
;;;;;;; dd	offset32 NoAction	 ; 0C
;;;;;;; dd	offset32 NoAction	 ; 0D
;;;;;;; dd	offset32 NoAction	 ; 0E
;;;;;;; dd	offset32 NoAction	 ; 0F
;;;;;;; dd	offset32 NoAction	 ; 10
;;;;;;; dd	offset32 NoAction	 ; 11
;;;;;;; dd	offset32 NoAction	 ; 12
;;;;;;; dd	offset32 NoAction	 ; 13
;;;;;;; dd	offset32 NoAction	 ; 14
;;;;;;; dd	offset32 Begin_PM_App	 ; 15:	Begin_PM_App
;;;;;;; dd	offset32 loc_28F	 ; 16:	End_PM_App
@ActionTable equ ($-ActionTable)/(type ActionTable)

	public	PM_Action
PM_Action label dword
	dd	offset32 PM_Version	  ; 00
	dd	offset32 PM_Beg_Crst	  ; 01
	dd	offset32 PM_End_Crst	  ; 02
	dd	offset32 PM_Page_Reserve  ; 03
	dd	offset32 PM_Page_Commit   ; 04
	dd	offset32 PM_Page_Free	  ; 05
@PM_Action equ	($-PM_Action)/(type PM_Action)

	public OldGPF
OldGPF	dd	0		; Old GPF handler

VxD_LOCKED_DATA_ENDS		; End _LDATA segment


VxD_LOCKED_CODE_SEG			; Begin _LCODE segment
	assume	ds:FLAT,es:FLAT,fs:nothing,gs:nothing,ss:FLAT

BeginProc W95DPMI_PM_Call
COMMENT|

PM Call-in

On entry:

EBX	=	Current VM handle
EBP	==>	Client_Reg_Struc

|

	movzx	eax,[ebp].Client_EAX.ELO.HI ; Get the function #
		
	cmp	eax,@PM_Action	; Izit too big?
	jae	short @F	; Jump if so
		
	jmp	cs:PM_Action[eax*4] ; Take appropriate action
		
@@:
	ret			; Return to caller
		
PM_Version:    
	mov	[ebp].Client_EAX.ELO,0100h ; Save version #
		
	ret			; Return to caller

PM_Beg_Crst:
	VMMcall Begin_Critical_Section ; Call function

	ret			; Return to caller
		
PM_End_Crst:
	VMMcall End_Critical_Section ; Call function
		
	ret			; Return to caller

PM_Page_Reserve:
COMMENT|

Call to _PageReserve (pages, npages, flags)

On entry:

page	=	linear address or PR_xxx
npages	=	# pages
flags	=	PR_xxx

|

	Client_Ptr_Flat eax, SS, ESP ; Return with EAX = la of SS:ESP

	cmp	eax,-1		; Izit valid?
	je	short PM_Page_Err ; Jump if so
       
	VMMcall _PageReserve, <[eax+00h].EDD, \
			       [eax+04h].EDD, \
			       [eax+08h].EDD> ; Reserve some pages
	jmp	short PM_Page_Exit ; Join common exit code
		
PM_Page_Commit:
COMMENT|

Call to _PageCommit (page, npages, hpd, pagerdata, flags)

On entry:

page	=	linear page # (Client_xxx)
npages	=	# pages       (Client_ECX)
hpd	=	handle of registered pager (or PD_xxx)
pagerdata =	pager data (zero if hpd is PD_xxx)
flags	=	PC_xxx

|

	Client_Ptr_Flat eax, SS, ESP ; Return with EAX = la of SS:ESP
	
	cmp	eax,-1		; Izit valid?
	je	short PM_Page_Err ; Jump if so

	VMMcall _PageCommit, <[eax+00h].EDD, \
			      [eax+04h].EDD, \
			      [eax+08h].EDD, \
			      [eax+0Ch].EDD, \
			      [eax+10h].EDD> ; Commit some pages
	jmp	short PM_Page_Exit ; Join common exit code
		
PM_Page_Free:
COMMENT|

Call to _PageFree (hMem, flags)

On entry:

hMem	=	Client_ESI
flags	=	Client_EDX

|

	Client_Ptr_Flat eax, SS, ESP ; Return with EAX = la of SS:ESP
		
	cmp	eax,-1		; Izit valid?
	je	short PM_Page_Err ; Jump if so
	
	VMMcall _PageFree, <[eax+00h].EDD, \
			    [eax+04h].EDD> ; Free some pages
PM_Page_Exit:	
	mov	[ebp].Client_EAX,eax ; Save return value
	
	mov	eax,[ebp].Client_ECX ; Get size of pushed parms
	add	[ebp].Client_ESP,eax ; Strip from the stack
	
	ret			; Return to caller

PM_Page_Err:
	xor	eax,eax 	; Indicate an error
		
	jmp	short PM_Page_Exit ; Join common exit code


EndProc W95DPMI_PM_Call


BeginProc W95DPMI_CONTROL

; All VxD functions come through here

	cmp	eax,@ActionTable ; Izit a function we handle?
	jae	short NoAction	; Jump if not

	jmp	cs:ActionTable[eax*(type ActionTable)] ; Take appropriate action

NoAction:
	clc

	ret

W95DPMI_CONTROL endp

; ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФ

GPF:
	REGSAVE <eax,ecx>	; Save registers

	Client_Ptr_Flat eax, CS, EIP ; Return with EAX = la of CS:EIP

	cmp	eax, -1 	; Did it work?
	jz	short GPFNotFound

	cmp	word ptr [eax], 200Fh
	jz	short MovBtwn_Reg_CRn

;;;;;;; cmp	word ptr [eax], 220Fh
;;;;;;; jz	short MovBtwn_Reg_CRn
GPFNotFound:
	REGREST <ecx,eax>	; Restore

	cmp	OldGPF,0	; Izit valid?
	je	short GPFExit	; Jump if not

	jmp	OldGPF		; Continue with next handler
; ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФ

GPFExit:
	ret
; ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФ

MovBtwn_Reg_CRn:
	cmp	[eax+2].LO,0D0h 
	jb	short GPFNotFound

	cmp	[eax+2].LO,0D8h
	jnb	short GPFNotFound

	push	ebx
	xor	ebx, ebx
	mov	bl, [eax+2]
	and	ebx, 7
	shl	ebx, 2
	lea	ecx, [ebp].Client_EAX
	sub	ecx, ebx
	pop	ebx
	mov	eax, cr2
	mov	[ecx], eax
	add	[ebp].Client_EIP, 3

	pop	ecx
	pop	eax

	ret

VxD_LOCKED_CODE_ENDS		; End LOCKED_CODE segment


VxD_IDATA_SEG			; Begin _IDATA segment
VxD_IDATA_ENDS			; End _IDATA segment


VxD_ICODE_SEG			; Begin _ICODE segment

Sys_Critical_In:
;;;;;;; call	HookTS_CR0

	clc

	ret
; ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФ

W95_Device_Init:
;;;;;;; xor	eax, eax
;;;;;;; mov	ds:pList, eax
;;;;;;; mov	ds:BlockHandle, eax
;;;;;;; mov	ds:LockFlag, al
;;;;;;; mov	ds:HeapLinAddr, eax
;;;;;;; mov	ds:dword_26AC, eax
;;;;;;; mov	ds:dword_26B0, eax
;;;;;;; mov	ds:byte_26FB, al
;;;;;;; push	0
;;;;;;; VMMcall _PageGetAllocInfo
;;;;;;; add	esp, 4
;;;;;;; shr	edx, 3
;;;;;;; cmp	edx, 10h
;;;;;;; ja	short DeviceInit1
;;;;;;; mov	edx, 10h

;;;DeviceInit1:
;;;;;;; mov	ds:nPageLocked, edx
;;;;;;; call	CR3ToLinear
;;;;;;; jb	short DeviceInitExit
;;;;;;; call	AllocPDE
;;;;;;; jb	short DeviceInitExit
;;;;;;; call	Hook_IPF
;;;;;;; jb	short DeviceInitExit
	call	Hook_GP_Fault
;;;;;;; call	Hook_TS_SaveCR0
;;;;;;; call	Create_SP
;;;;;;; jb	short DeviceInitExit
;;;;;;; call	Alloc_PMCB
;;;;;;; jb	short DeviceInitExit
;;;;;;; call	HookInts

	clc
DeviceInitExit:
	ret

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

;		S u b r o u t i n e

BeginProc Hook_GP_Fault
COMMENT|

Hook the GP Fault handler

|

	REGSAVE <eax,esi>	; Save for a moment

	mov	esi,offset32 GPF ; Get offset of replacement routine
	mov	eax,0Dh 	; Intercept this one
	VMMcall Hook_PM_Fault	; Hook it, returning ESI = old address
	mov	OldGPF,esi	; Save the old address

	REGREST <eax,esi>	; Restore

	clc			; Mark as successful

	ret			; Return to caller

EndProc Hook_GP_Fault


;;; ; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;;;
;;; ;		    S u b r o u t i n e
;;;
;;; Hook_IPF	    proc near		    ; CODE XREF: _ITEXT:00003058p
;;;		    push    esi
;;;		    mov     esi, offset32 IPF
;;;		    VMMcall Hook_Invalid_Page_Fault
;;;		    pop     esi
;;;		    clc
;;;		    retn
;;; Hook_IPF	    endp
;;;
;;;
;;; ; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;;;
;;; ;		    S u b r o u t i n e
;;;
;;; Alloc_PMCB	    proc near		    ; CODE XREF: _ITEXT:00003070p
;;;		    mov     esi, offset32 PMCB_2F
;;;		    VMMcall Allocate_PM_Call_Back
;;;		    mov     ds:PMCB_2F_VEC, eax
;;;		    mov     esi, offset32 PMCB_31
;;;		    VMMcall Allocate_PM_Call_Back
;;;		    mov     ds:PMCB_31_VEC, eax
;;;		    retn
;;; Alloc_PMCB	    endp
;;;
;;;
;;; ; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;;;
;;; ;		    S u b r o u t i n e
;;;
;;; HookInts	    proc near		    ; CODE XREF: _ITEXT:00003077p
;;;		    mov     eax, 31h ; '1'
;;;		    VMMcall Get_PM_Int_Vector
;;;		    mov     ds:OldPM_INT31_OFF, edx
;;;		    mov     ds:OldPM_INT31_SEL, cx
;;;		    mov     eax, 2Fh ; '/'
;;;		    VMMcall Get_PM_Int_Vector
;;;		    mov     ds:OldPM_INT2F_OFF, edx
;;;		    mov     ds:OldPM_INT2F_SEL, cx
;;;		    mov     eax, 2Fh ; '/'
;;;		    mov     esi, offset32 VM2F
;;;		    VMMcall Hook_V86_Int_Chain
;;;		    retn
;;; HookInts	    endp

VxD_ICODE_ENDS			; End _ICODE segment


VxD_CODE_SEG			; Begin _LCODE segment

; Other non-INIT control procedures go here

VxD_CODE_ENDS			; End _LCODE segment


VxD_REAL_INIT_SEG

BeginProc W95DPMI_RMI
	assume	ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

W95DPMI real mode init

On entry:
	
AX	= VMM version (AH=Major #, AL=Minor #)
BX	= Flags:
		Duplicate_Device_ID	; duplicate device ID already loaded
		Duplicate_From_INT2F	; duplicate device ID already loaded
		Loading_From_INT2F	; this device was loaded via 1605
EDX	= Reference data specified by INT 2Fh load
		(V86 far pointer ==> our INT_67)
SI	= Segment of WIN386 environment strings
ECX	= Segment:offset of assistance API (3.10 only)

On exit:

BX	= pointer to excluded pages list (0 if none)
SI	= pointer to instance data list (0 if none)
EDX	= Reference data to pass to protected mode portion of VxD
AX	= Real mode return value, one of:
		Device_Load_Ok		real mode init was successful
		Abort_Device_Load	real mode init failed, do not load VxD
		Abort_Win386_Load	real mode init failed, fail Windows
		No_Fail_Message 	indicates no message should be displayed

|

	cmp	ax,0400h	; Izit Win95 or later?
	jb	short W95DPMI_RMI_ERR ; Jump if so

	test	bx,Duplicate_Device_ID ; Check for duplicates
	jnz	short W95DPMI_RMI_ERR ; Jump if so

	xor	bx,bx		; No excluded pages
	xor	si,si		; No instance data
	xor	edx,edx 	; No reference data for Sys_Critical_Init
	mov	ax,Device_Load_Ok ; Mark as successful

	ret			; Return to caller

W95DPMI_RMI_ERR:
	mov	ax,Abort_Device_Load or No_Fail_Message ; Don't load us,
				; don't print message, but load other VxDs
	ret			; Return to caller

; ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФ

EndProc W95DPMI_RMI

VxD_REAL_INIT_ENDS			; End _RCODE segment

	end	W95DPMI_RMI
