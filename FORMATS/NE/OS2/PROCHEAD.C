/*
 PROCHEAD.C - process EXE file header
 Creation Date: 24-Jan-1991
 Author: Igor Semenyuk
 Version: 1.00

 History:

	1.00	24-Jan-1991	Created from RESOURCE.C version 0.15
	1.01	24-Jan-1991	Incorporate NEWEXE.H header
	1.02	01-Mar-1991	Add extra check for legal image
*/

#include <stdio.h>
#include <malloc.h>
#include <process.h>
#include <stdlib.h>
#include "resource.h"
#include "newexe.h"

extern FILE *in, *rc;
extern BOOL bWindows3;
extern BOOL bDumpHeader;
extern struct ResourceTable *pResourceEntry;

void
process_header()
{
	struct exe_hdr	oefh;
	struct new_exe	nshib;
	DWORD           lNewOffset;
	WORD		iResTabSize;
	BYTE            bDscLength;
	char		tmp[256];

	if (fread(&oefh, 1, sizeof oefh, in) != sizeof oefh) error_mess(EM_CANTREADOEFH);
	if (E_MAGIC(oefh)!=EMAGIC) error_mess(EM_BADOEFH);

	lNewOffset = E_LFANEW(oefh);

	fseek(in, lNewOffset, SEEK_SET);

	if (fread(&nshib, 1, sizeof nshib, in) != sizeof nshib) error_mess(EM_CANTREADNEFH);

	if (NE_MAGIC(nshib)!=NEMAGIC) error_mess(EM_NOTWINIMAGE);
	if ((NE_EXETYP(nshib) == NE_UNKNOWN) ||
	    (NE_EXETYP(nshib) == NE_WINDOWS) ||
	    (NE_EXETYP(nshib) == NE_WIN386)) {
		bWindows3 = (NE_SDKVER(nshib) >= 3);
	} else {
		error_mess(EM_NOTWINIMAGE);
	}

	if (bDumpHeader) {
		fseek(in, NE_NRESTAB(nshib), SEEK_SET);
		fread(&bDscLength, 1, 1, in);
		if ((BYTE)fread(tmp, 1, bDscLength, in) != bDscLength) error_mess(EM_CANTREADDESC);
		tmp[bDscLength]=0;
		printf("Description              : %s\n", tmp);
		printf("Operating system         : ");
		switch (NE_EXETYP(nshib)) {
		case NE_UNKNOWN:
			printf("UNKNOWN");
			break;
		case NE_OS2:
			printf("OS/2");
			break;
		case NE_WINDOWS:
			printf("Windows");
			break;
		case NE_DOS4:
			printf("DOS 4.x");
			break;
		case NE_WIN386:
			printf("Windows 386");
			break;
		default:
			printf("*unknown* - %d", NE_EXETYP(nshib));
		}
		putchar('\n');
		printf("Entry Point              : seg %d offset 0x%04X\n",
		       HIWORD(NE_CSIP(nshib)), LOWORD(NE_CSIP(nshib)));
		printf("Initial SS:SP            : seg %d offset 0x%04X\n",
		       HIWORD(NE_SSSP(nshib)), LOWORD(NE_SSSP(nshib)));
		printf("Initial Stack allocation : %d\n", NE_STACK(nshib));
		printf("DGROUP                   : seg %d\n", NE_AUTODATA(nshib));
		printf("Linker Version           : %d.%02d\n",
		       NE_VER(nshib), NE_REV(nshib));
		printf("32-bit Checksum          : 0x%08lX\n", NE_CRC(nshib));
		printf("Segment Table            : 0x%08lX size 0x%04X\n",
		       NE_SEGTAB(nshib)	+ lNewOffset,
		       NE_RSRCTAB(nshib) - NE_SEGTAB(nshib));
		printf("Resource Table           : 0x%08lX size 0x%04X\n",
		       NE_RSRCTAB(nshib) + lNewOffset,
		       NE_RESTAB(nshib) - NE_RSRCTAB(nshib));
		printf("Resident Names Table     : 0x%08lX size 0x%04X\n",
		       NE_RESTAB(nshib)	+ lNewOffset,
		       NE_MODTAB(nshib)	- NE_RESTAB(nshib));
		printf("Module Reference Table   : 0x%08lX size 0x%04X\n",
		       NE_MODTAB(nshib)	+ lNewOffset,
		       NE_IMPTAB(nshib)	- NE_MODTAB(nshib));
		printf("Imported Names Table     : 0x%08lX size 0x%04X\n",
		       NE_IMPTAB(nshib)	+ lNewOffset,
		       NE_ENTTAB(nshib)	- NE_IMPTAB(nshib));
		printf("Entry Table              : 0x%08lX size 0x%04lX\n",
		       NE_ENTTAB(nshib)	+ lNewOffset,
		       NE_NRESTAB(nshib)	- NE_ENTTAB(nshib) - lNewOffset);
		printf("Non-Resident Names Table : 0x%08lX size 0x%04X\n",
		       NE_NRESTAB(nshib), NE_CBNRESTAB(nshib));
		printf("Movable entry points     : %d\n", NE_CMOVENT(nshib));
		printf("Sector size              : %d\n", 1 << NE_ALIGN(nshib));
		printf("Heap Size                : %d\n", NE_HEAP(nshib));

		printf("Module Flags             : 0x%04X\n", NE_FLAGS(nshib));
		printf("Segment Entries          : %d\n", NE_CSEG(nshib));
		printf("External Modules         : %d\n", NE_CMOD(nshib));
		printf("Reserved Segments        : %d\n", NE_CRES(nshib));
		printf("Other Flags              : %02X\n", NE_ADDFLAGS(nshib));
		printf("Reserved2                : %04X\n", nshib.ne_res[0]);
		printf("Reserved3                : %04X\n", nshib.ne_res[1]);
		printf("Reserved4                : %04X\n", nshib.ne_res[2]);
		printf("SDK Version              : %d.%02d\n",
		       NE_SDKVER(nshib), NE_SDKREV(nshib));
		fclose(in);
		exit(0);
	}

	if (bWindows3)
	    error_mess(IM_WINDOWS3);
	else
	    error_mess(IM_WINDOWS2);

	if(NE_VER(nshib)<=4) printf("Warning - 1.xx image (???).\n");
	if(bWindows3 && (NE_FLAGS(nshib)&0xFF)!=0x02)
	    printf("Warning - Unusual module flags.\n");
	if((NE_RSRCTAB(nshib) - NE_SEGTAB(nshib))%8!=0)
	    printf("Warning - Extra 4 bytes in segment table.\n");
	if(nshib.ne_res[2]) printf("Warning - Reserved4 != 0.\n");

	lNewOffset += NE_RSRCTAB(nshib);
	fseek(in, lNewOffset, SEEK_SET);
	iResTabSize = NE_RESTAB(nshib) - NE_RSRCTAB(nshib);
	if (!iResTabSize) {
		fprintf(rc, "/* No Resource */\n");
		error_mess(WM_NORESOURCES);
		exit(WM_NORESOURCES>>4);
	}
	if ((pResourceEntry = malloc(iResTabSize)) == NULL) error_mess(EM_NOMEMFORRT);
	if (fread(pResourceEntry, 1, iResTabSize, in) != iResTabSize) error_mess(EM_CANTREADRT);
}
