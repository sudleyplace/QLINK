/*****************************************************************************
Filename:  UM.H

                  C++ Demangler Source Code

      Copyright (c) 1987, 1993 Borland International, Inc.
                       All Rights Reserved


LICENSE
-------
Your use of the Source Code is subject to the terms of the
License Statement contained in the No Nonsense License Statement
attached hereto, and the following additional terms.

You acknowledge that Borland may reserve the right to modify the
Source Code, and Borland shall have no responsibility to you in
this regard.

You have no right to receive any support, service, upgrades or
technical or other assistance from Borland, and you shall have no
right to contact Borland for such services or assistance.

"AS IS" DISCLAIMER OF WARRANTIES
--------------------------------
THE SOURCE CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
INCLUDING BUT NOT LIMITED TO ANY IMPLIED WARRANTY OF
MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

You agree that Borland shall not be liable for any direct,
indirect, consequential or incidential damages relating to use of
the Source Code, even if Borland has been specifically advised of
the possibility of such damages. In no event will Borland's
liability for any damages to you or any other person exceed $50,
regardless of any form of the claim.  Some states do not allow
the exclusion of incidental or consequential damages, so some of
the above may not apply to you.

Send any questions/problems in writing to Developer Relations,
Borland International, 1800 Green Hills Road, Scotts Valley, CA
95066-0001, USA.

*****************************************************************************/




/*****************************************************************************/

typedef enum
{
    UM_NOT_MANGLED = 0,
    UM_MEMBER_FN   = 1,
    UM_CONSTRUCTOR = 2,
    UM_DESTRUCTOR  = 3,
    UM_OPERATOR    = 4,
    UM_CONVERSION  = 5,
    UM_STATIC_DM   = 6,
    UM_THUNK       = 7,

    UM_OTHER       = 127,
}
    umKind;

/*****************************************************************************/

#ifdef  IN_MOJO
#define DoArgsArguments     0x01
#define DoArgsNoClassPrefix 0x02
#define DoArgsExcludeMangled    0x04
#endif

/*****************************************************************************/

#ifdef __cplusplus
extern  "C"
#endif

umKind  unmangle(char   *   src,    /* source (mangled) name */
         char   *   dest,   /* destination buffer addr or 0 */
         unsigned   maxlen, /* destination buffer size */
         char   *   classP, /* class name buffer (or 0) */
         char   *   nameP,  /* base  name buffer (or 0) */
         int        doArgs);/* include argument type info */

/*****************************************************************************/
