#' $Header$
PROJ=WNTDPMI		# Project name
STUB=WNTSTUB		# Stub internal name
STUB31=WNTST31		# INT 31h stub internal name
STUBARG=WNTSTARG	# Arg stub internal name
VDD=WNTVDD		# VDD internal name
O=RET\			# .exe's, .obj's and temporary files
R=.\			# Current directory
S=R:\MAX\STATUTIL\	# Statutil directory

# Linker names
LD16=$(MSVC16)BIN\link
LD32=$(MSVC32)BIN\link
LD32=N:\WINDDK\3790\BIN\X86\link

# Assembler names
ASMOMF=C:\BIN\masm	# Name of OMF assembler
ASMCOFF=ml		# Name of COFF assembler
ASMML=ml		# Name of ML assembler

# Default options for $(ASMOMF) & $(ASMCOFF)
OPTOMF=/Ml /p /r /t /w1 /Zd /dW$(WID) /II:\		# MASM options
OPTCOFF=/c /coff /Zm /I$(MSVC32)DDK\INC32 /II:\ /Cp
OPTML=/c /Zm /I$(MSVC32)DDK\INC32 /II:\ /Cp

LFLAGS_EXE=
LFLAGS_VDD=

###LIBPATH=$(MSVC32)LIB\
LIBPATH=N:\WINDDK\3790\LIB\WNET\I386\	# Path to DDK LIB files

LIBS_VDD=USER32.LIB KERNEL32.LIB MSVCRT4.LIB

.SUFFIXES : .cof

{$(R)}.asm{$(O)}.obj:
	set INCLUDE=$(ALLINC);$(INCLUDE)
	$(ASMOMF) %s $(OPTOMF),$(O);


{$(S)}.asm{$(O)}.obj:
	set INCLUDE=$(ALLINC);$(INCLUDE)
	$(ASMOMF) %s $(OPTOMF),$(O) /DW16 /DDALIGN=para /DEXTDATASEG;


{$(R)}.asm{$(O)}.cof:
	set INCLUDE=$(ALLINC);$(INCLUDE)
	$(ASMCOFF) $(OPTCOFF) /Fo$@ %s


{$(S)}.asm{$(O)}.cof:
	set INCLUDE=$(ALLINC);$(INCLUDE)
	$(ASMCOFF) $(OPTCOFF) /Fo$@ /DW32 /DWIN /DCOFF /DDALIGN=para /DEXTDATASEG %s


ALL:	$(O)$(PROJ).EXE 	\
###	$(O)$(PROJ).VDD 	\
	$(BINDIR)$(PROJ).EXE	\
###	$(BINDIR)$(PROJ).VDD


OBJSTUB=$(O)$(STUB).OBJ 	\
	$(O)$(STUB31).OBJ	\
	$(O)$(STUBARG).OBJ	\
	$(O)PRINTF.OBJ

$(O)$(STUB).OBJ:	$(STUB).ASM

$(O)$(STUB31).OBJ:	$(STUB31).ASM

$(O)$(STUBARG).OBJ:	$(STUBARG).ASM

$(O)PRINTF.OBJ: 	$(S)PRINTF.ASM

$(O)$(PROJ).EXE:	$(OBJSTUB) makefile
	$(LD16) @<<$(O)$(STUB).arf
$(OBJSTUB: =+^
)	$(LFLAGS_EXE)
$@
$(O)$(STUB).MAP/map;
<<KEEP


OBJVDD=$(O)$(VDD).COF

$(O)$(VDD).COF: 	$(VDD).ASM

$(O)$(VDD).OBJ: 	$(VDD).ASM
	$(ASMML) $(OPTML) /Fo$@ %s

$(O)$(PROJ).VDD:	$(OBJVDD)	\
			$(VDD).DEF	\
			makefile
####	$(LD16) @<<$(O)$(VDD).ARF
#### $(OBJVDD: =+^
#### )	     $(LFLAGS_VDD)
#### $@
#### $(O)$(VDD).MAP/map
####	     $(LIBS_VDD)
#### $(VDD).DEF
#### <<KEEP
####### Set LIB=$(MSVC32)LIB
	Set LIB=$(LIBPATH)
	$(LD32) @<<$(O)$(VDD).arf
$(OBJVDD)
/OUT:$@
/MAP:$(O)$(VDD).MAP
$(LIBS_VDD)
/DEF:$(VDD).DEF
/DLL
/ENTRY:WNTDPMI_Initialize
/LIBPATH:$(LIBPATH)
/NOLOGO
<<KEEP


$(BINDIR)$(PROJ).EXE:	$(O)$(PROJ).EXE
	xc /r %s $@

$(BINDIR)$(PROJ).VDD:	$(O)$(PROJ).VDD
	xc /r %s $@


