/*++

Copyright (c) 2003, Qualitas, Inc.

Module Name:

	wntvdd.c

Abstract:

	Virtual Device Driver for DOSIOCTL sample

Environment:

	NT-MVDM (User Mode VDD)

Notes:

	This VDD presents a private interface for the DOSDRVR component
	of the DOSIOCTL sample. The three functions (OPEN, CLOSE, INFO)
	correspond to calls that the DOSAPP in the sample makes. To show
	how nicely symetrical a VDD can be architected, this VDD simply
	converts each of these calls made by the DOS device driver into
	NT-kernel device driver calls using WIN32 functions.

	Thus, when the DOS application of the sample issues a DOS OPEN,
	the DOS driver gets the request and calls our entry point with
	the VDD's VDDOPEN call. The VDD then calls the Win32 function
	CreateFile() to get a handle to the NT driver in the sample.

	When the DOS application does an IOCTL read, the DOS driver
	calls VDDINFO, which issues a Win32 DeviceIOControl() to the
	NT driver, after getting a flat address for the application's
	buffer.

	Finally, the DOSAPP's CLOSE is translated similarly to a WIN32
	CloseHandle().

	Note that the functions VDDOPEN, VDDCLOSE and VDDINFO are not
	architected in the NT VDD interface, and were invented just for
	this sample. The interface between the DOS driver and the VDD
	could have been defined completely differently. This VDD was
	coded only to show one possibility for designing a VDD interface.


--*/


#include <qualitas.h>
#include "windows.h"
#include <vddsvc.h>
//#include "ioctlvdd.h"
#include "devioctl.h"

// The followintg equates *MUST* match the @VDD_xxx equates in WNTDPMI.INC
#define VDD_GETLMB		1		// Allocate Linear Memory Block
#define VDD_RELLMB		2		// Release	Linear Memory Block
#define VDD_GETLL		99		// Get linked list count


typedef struct tagLL
{
	struct tagLL *lpNext,		// Ptr to next entry (NULL if none)
				 *lpPrev;		// ...	  previous ...
	LPVOID		  lpAddr;		// Linear address of LMB
	DWORD		  dwSize;		// Size of LMB
} LL, *LPLL;

LPLL lpLLBase = NULL;


//****************************************************************************
//	WNTDPMI_Initialize ()
//
//	   The entry point for the Vdd which handles intialization and termination.
//
//	Arguments:
//
//		hVdd   - The handle to the VDD
//
//		Reason - flag word that indicates why Dll Entry Point was invoked
//
//		lpReserved - Unused
//
//	Return Value:
//		BOOL bRet - if (dwReason == DLL_PROCESS_ATTACH)
//					   TRUE    - Dll Intialization successful
//					   FALSE   - Dll Intialization failed
//					else
//					   always returns TRUE
//
//
//****************************************************************************

BOOL WINAPI
WNTDPMI_Initialize
   (HANDLE hVdd,
	DWORD dwReason,
	LPVOID lpReserved)

{
////HANDLE hDriver;

	switch (dwReason)
	{
////	case DLL_PROCESS_ATTACH:
////		//
////		// The following call is here only to test the existence of
////		// the KRNLDRVR component. If it isn't there, then there is
////		// no reason to load.
////		//
////
////		hDriver = CreateFile("\\\\.\\krnldrvr",    /* open KRNLDRVR      */
////						GENERIC_READ | GENERIC_WRITE,  /* open for r/w	 */
////						0,						   /* can't share        */
////						(LPSECURITY_ATTRIBUTES) NULL, /* no security	 */
////						OPEN_EXISTING,			   /* existing file only */
////						FILE_FLAG_OVERLAPPED,	   /* overlapped I/O	 */
////						(HANDLE) NULL); 		   /* no attr template	 */
////
////		if (hDriver == INVALID_HANDLE_VALUE) {
////			MessageBox (NULL, "Unable to locate Kernel driver",
////					"Sample VDD", MB_OK | MB_ICONEXCLAMATION);
////			return FALSE;							/* Abort load		*/
////			}
////
////		//
////		// The call to CreateFile succeeded, close the handle again
////		//
////
////		CloseHandle (hDriver);
////
////		MessageBox (NULL, "WNTDPMI_Initialize -- Process Attach", "WNTDPMI", MB_OK);
////
////		break;
////
		case DLL_PROCESS_DETACH:
			MessageBox (NULL, "WNTDPMI_Initialize -- Process Detach", "WNTDPMI", MB_OK);

			break;

////	case DLL_THREAD_ATTACH:
////		MessageBox (NULL, "WNTDPMI_Initialize -- Thread Attach", "WNTDPMI", MB_OK);
////
////		break;
////
////	case DLL_THREAD_DETACH:
////		MessageBox (NULL, "WNTDPMI_Initialize -- Thread Detach", "WNTDPMI", MB_OK);
////
////		break;
////
////	default:
////		MessageBox (NULL, "WNTDPMI_Initialize -- Default", "WNTDPMI", MB_OK);
////
////		break;
	} // End SWITCH

	return TRUE;
} // End WNTDPMI_Initialize ()


//****************************************************************************
//	WNTDPMI_Init ()
//
//	Arguments:	None
//
//	Return value:
//
//	SUCCESS - Client Carry Clear
//	FAILURE - Client Carry Set
//****************************************************************************

void WNTDPMI_Init (void)

{
	// This routine is called when the DOSDRVR issues
	// the RegisterModule call.
////MessageBox (NULL, "WNTDPMI_Init", "WNTDPMI", MB_OK);

	setCF (0);

	return;
} // End WNTDPMI_Init ()


//****************************************************************************
//	AppendToLL ()
//
//	Append data to a linked list whose head is at lpLLBase;
//****************************************************************************

BOOL AppendToLL (LPVOID lpAddr, DWORD dwSize)

{
	LPVOID lpNew;
	LPLL   lpLock;

	// Allocate space for the new entry
	lpNew = GlobalAlloc (GHND, sizeof (LL));

	// If it failed, go home
	if (lpNew EQ NULL)
		return FALSE;

	// Lock the block
	lpLock = GlobalLock (lpNew);

	// Save information in the block
	lpLock->lpNext = NULL;
	lpLock->lpPrev = lpLLBase;
	lpLock->lpAddr = lpAddr;
	lpLock->dwSize = dwSize;

	// We no longer need this ptr
	GlobalUnlock (lpNew); lpLock = NULL;

	// If the previous ptr is valid, point its next to us
	if (lpLLBase NE NULL)
	{
		// Lock the block
		lpLock = GlobalLock (lpLLBase);

		// Point its next to us
		lpLock->lpNext = lpNew;

		// We no longer need this ptr
		GlobalUnlock (lpLLBase); lpLock = NULL;
	} // End IF

	// Save as new head of LL
	lpLLBase = lpNew;

	return TRUE;
} // End AppendToLL ()


//****************************************************************************
//	LookupLL ()
//
//	Lookup an address in our linked list
//****************************************************************************

LPLL LookupLL (LPVOID lpAddr)

{
	LPLL lpNew, lpLock, lpPrev, lpRet = NULL;

	for (lpNew = lpLLBase;
		 lpNew NE NULL && lpRet EQ NULL;
		 lpNew = lpPrev)
	{
		// Lock the block
		lpLock = GlobalLock (lpNew);

		if (lpLock->lpAddr EQ lpAddr)
			lpRet = lpNew;
		else
			lpPrev = lpLock->lpPrev;

		// We no longer need this ptr
		GlobalUnlock (lpNew); lpLock = NULL;
	} // End FOR

	return lpRet;
} // End LookupLL ()


//****************************************************************************
//	FreeLL ()
//
//	Release a LL
//****************************************************************************

void FreeLL (LPLL lpLL)

{
	LPLL lpLock, lpLock2;

	// Lock the block
	lpLock = GlobalLock (lpLL);

	// If the previous ptr is valid, point its next to our next
	if (lpLock->lpPrev NE NULL)
	{
		// Lock the previous block
		lpLock2 = GlobalLock (lpLock->lpPrev);

		// Point its next to our next
		lpLock2->lpNext = lpLock->lpNext;

		// We no longer need this ptr
		GlobalUnlock (lpLock->lpPrev); lpLock2 = NULL;
	} // End IF

	// If the next ptr is valid, point its previous to our previous
	if (lpLock->lpNext NE NULL)
	{
		// Lock the next block
		lpLock2 = GlobalLock (lpLock->lpNext);

		// Point its previous to our previous
		lpLock2->lpPrev = lpLock->lpPrev;

		// We no longer need this ptr
		GlobalUnlock (lpLock->lpNext); lpLock2 = NULL;
	} // End IF

	// Check for lpLLBase being freed
	if (lpLL EQ lpLLBase)
		lpLLBase = lpLock->lpPrev;

	// We no longer need this ptr
	GlobalUnlock (lpLL); lpLock = NULL;

	// We no longer need this storage
	GlobalFree (lpLL); lpLL = NULL;
} // End FreeLL ()


//****************************************************************************
//	CountLL ()
//
//	Count the LLs
//****************************************************************************

int CountLL (void)

{
	LPLL lpNew, lpLock, lpPrev;
	int iCnt;

	for (iCnt = 0, lpNew = lpLLBase;
		 lpNew NE NULL;
		 iCnt++, lpNew = lpPrev)
	{
		char szTemp[256];

		// Lock the block
		lpLock = GlobalLock (lpNew);

		wsprintf (szTemp,
				  "New = %08X, "
				  "Lock = %08X, "
				  "Next = %08X, "
				  "Prev = %08X, "
				  "Addr = %08X, "
				  "Size = %08X",
				  lpNew,
				  lpLock,
				  lpLock->lpNext,
				  lpLock->lpPrev,
				  lpLock->lpAddr,
				  lpLock->dwSize);
		MessageBox (NULL, szTemp, "WNTDPMI", MB_OK);

		lpPrev = lpLock->lpPrev;

		// We no longer need this ptr
		GlobalUnlock (lpNew); lpLock = NULL;
	} // End FOR

	return iCnt;
} // End CountLL ()


//****************************************************************************
//	WNTDPMI_Dispatch ()
//
//	   This subroutine implements the funcionality of the VDD. It handles
//	   client VDM calls from the DOS driver. The operation is as follows:
//
//	   VDD_GETLMB  -- Allocate Linear Memory Block
//	   VDD_RELLMB  -- Release  Linear Memory Block
//
// Arguments:
//
// For VDD_GETLMB:
//
// EBX	   =	   desired linear address (page aligned)
// ECX	   =	   size of block (bytes, must be non-zero)
// EDX	   =	   flags bit 0 = 1 means committed, else uncommitted
//
// For VDD_RELLMB:
//
// EBX	   =	   linear address to free
//
// Return Value:
//
// For VDD_GETLMB:
//
// CF	   =	   0 if successful
// EBX	   =	   linear address of allocated block
// ESI	   =	   memory block handle
//
// CF	   =	   1 if not successful
//
// For VDD_RELLMB:
//
// CF	   =	   0 if successful
//		   =	   1 if not successful
//****************************************************************************

void WNTDPMI_Dispatch (void)

{
////MessageBox (NULL, "WNTDPMI_Dispatch", "WNTDPMI", MB_OK);

	// Split cases depending upon the function code
	switch (getEAX () >> 16)
	{
		case VDD_GETLMB:	
		{
			LPVOID lpAddr;
			DWORD  dwSize;
			BOOL   bCommit;

			// Get and check the size
			dwSize = getECX ();

			if (dwSize)
			{
				// Get the committed status of the pages
				bCommit = getEDX () & 1;

				lpAddr = 
				VirtualAlloc ((LPVOID) getEBX (),
							  dwSize,
							  bCommit ? MEM_COMMIT
									  : (MEM_COMMIT | MEM_RESERVE),
							  PAGE_EXECUTE_READWRITE);
////						  bCommit ? PAGE_READWRITE
////								  : 0); // 0, PAGE_GUARD, PAGE_NOACCESS
				// If successful, append this page (and its size)
				// to a linked list.
				if (lpAddr NE NULL)
				{
					// Append the new entry
					if (AppendToLL (lpAddr, dwSize) EQ FALSE)
					{
						// The append failed:  free the address
						VirtualFree (lpAddr, dwSize, MEM_DECOMMIT);
						VirtualFree (lpAddr, 0, 	 MEM_RELEASE);
						lpAddr = NULL;
					} // End IF
				} else
				{
					setAX (0x8012); 	// Mark as Linear Memory unavailable
				} // End IF/ELSE

				// Return information to the caller
				setEBX ((DWORD) lpAddr);	// Return the address
				setESI ((DWORD) lpAddr);	// Return as handle, too
				setCF (lpAddr EQ NULL); 	// Mark as successful or not,
											// depending upon the return address
			} else
			{
				setEAX (0x8021);		// Mark as invalid value
				setEBX (0); 			// ...
				setCF(1);				// ...
			} // End IF/ELSE

			break;
		} // End VDD_GETLMB

		case VDD_RELLMB:
		{
			LPVOID lpAddr, lpLL;
			LPLL   lpLock;
			DWORD  dwSize;

			// Get the address
			lpAddr = (LPVOID) getEBX ();

			// Lookup this address in our LL
			lpLL = LookupLL (lpAddr);

			if (lpLL NE NULL)
			{
				// Lock the block
				lpLock = GlobalLock (lpLL);

				// First, decommit the memory so the subsequent VirtualFree
				// is done on all the same memory type (otherwise, it fails).
				VirtualFree (lpAddr, lpLock->dwSize, MEM_DECOMMIT);

				// Next, release the memory
				if (VirtualFree (lpAddr, 0, MEM_RELEASE))
					setCF (0);
				else
				{
					setAX (0x8012); 	// Linear Memory Unavailable
					setCF (1);
				} // End IF/ELSE

				// We no longer need this ptr
				GlobalUnlock (lpLL); lpLock = NULL;

				// Release the LL
				FreeLL (lpLL); lpLL = NULL;
			} else
			{
				setAX (0x8025); 		// Invalid linear address
				setCF (1);
			} // End IF/ELSE

			break;
		} // End VDD_GETLMB

		case VDD_GETLL: 		// Count the LLs
		{
			setEAX (CountLL ());
			setCF (0);

			break;
		} // End VDD_GETLL

		default:
			setCF (1);

			break;
	} // End SWITCH

	return;

////LPVOID	Buffer;
////ULONG	VDMAddress;
////DWORD	dwCount;
////BOOL	Success = TRUE;
////DWORD	BytesReturned;
////static HANDLE hDriver = INVALID_HANDLE_VALUE;
////
////switch (getDX()) {
////
////	case VDDOPEN:
////
////		hDriver = CreateFile("\\\\.\\krnldrvr",    /* open KRNLDRVR      */
////						GENERIC_READ | GENERIC_WRITE,  /* open for r/w	 */
////						0,						   /* can't share        */
////						(LPSECURITY_ATTRIBUTES) NULL, /* no security	 */
////						OPEN_EXISTING,			   /* existing file only */
////						0,						   /* flags 			 */
////						(HANDLE) NULL); 		   /* no attr template	 */
////
////		if (hDriver == INVALID_HANDLE_VALUE) {
////			setCF(1);
////		} else
////			setCF(0);
////
////		break;
////
////	case VDDCLOSE:
////
////		if (hDriver != INVALID_HANDLE_VALUE) {
////			CloseHandle (hDriver);
////			hDriver = INVALID_HANDLE_VALUE;
////		}
////
////		break;
////
////	case VDDINFO:
////
////		dwCount = (DWORD) getCX();
////
////		VDMAddress = (ULONG) (getES()<<16 | getDI());
////
////		Buffer = (LPVOID) GetVDMPointer (VDMAddress, dwCount, FALSE);
////
////		Success = DeviceIoControl (hDriver,
////			(DWORD) IOCTL_KRNLDRVR_GET_INFORMATION,
////			(LPVOID) NULL, 0,
////			Buffer, dwCount,
////			&BytesReturned, (LPVOID) NULL);
////
////		if (Success) {
////			setCF(0);
////			setCX((WORD)BytesReturned);
////		} else
////			setCF(1);
////
////		FreeVDMPointer (VDMAddress, dwCount, Buffer, FALSE);
////
////		break;
////
////	default:
////		setCF(1);
////}
} // End WNTDPMI_Dispatch ()

