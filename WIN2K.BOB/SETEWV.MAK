#' $Header$
# MAKEFILE for SETEWV.EXE


# Add our includes to include search path
INCLUDE = $(MAXROOT)include;$(MAXROOT)inc;$(INCLUDE)

# Get product names
!include <maxnames.mak>

L=$(MAXROOT)TEXT\	# Directory for non-built .OBJs, .LIBs, etc.
O=EWV\			# ...		.OBJs, etc.
R=			# ...		source
I=$(MAXROOT)inc\	# .INC directory
H=$(MAXROOT)include\	# .H   ...

ASM=masm
AFLAGS=/Mu

ALL: $(O)SETEWV.EXE


$(O)SETEWV.OBJ: 	$(R)SETEWV.ASM
	$(ASM) $(AFLAGS) $(@B) /I. /I$(I) /DDEBUG=$(DEBUG), $(O)$(@B);

LIBS=libw ver

$(O)SETEWV.EXE: 	$(O)SETEWV.OBJ
	@Set LIB=$(LIB)
	LINK /NOLOGO /NOD /PACKC:61440 /ALIGN:16 /ONERROR:NOEXE @<<$(O)SETEWV.LRF
$(O2)nocrt0+
$*
$*
$* /map:full
$(LIBS: =+^
)
setewv.def
<<KEEP

