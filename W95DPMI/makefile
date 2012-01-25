
O=RET\					# OEM directory
BIN=$(SRCROOT)LIB\		# Output directory
PROJ=W95DPMI

ALL:		$(BIN)$(PROJ).386

$(BIN)$(PROJ).386:	$(O)$(PROJ).386
	xc /r %s $@

$(O)$(PROJ).386:	$(O)W95DPMI.OBJ MAKEFILE
	link386 $(O)$(PROJ).OBJ,$(O)$(PROJ).386,$(O)$(PROJ)/map,,$(PROJ).DEF
	addhdr /v:300 $(O)$(PROJ).386

$(O)$(PROJ).OBJ:	$(PROJ).ASM
	masm %s,$(O)$(PROJ) /I. /II:\;

