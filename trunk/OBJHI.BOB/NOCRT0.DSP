DISPOBJ   -- Version 1.74 -- An Object Module Displayer
   (C) Copyright 1985-2000 Qualitas, Inc.  All rights reserved.
ðð Object module listing of R:\MAX\LIB\NOCRT0.OBJ (895 bytes) ðð
THEADR:  Type 80, Offset 0000
         Name crt0.asm
COMENT:  Type 88, Offset 000D
         No purge, comment type 9E ==> DOSSEG
LNAMES:  Type 96, Offset 0013
            1: Name 
            2: Name NULL
            3: Name _BSS
            4: Name CDATA
            5: Name _DATA
            6: Name DGROUP
            7: Name _TEXT
            8: Name CONST
            9: Name BSS
           10: Name CONST
           11: Name DATA
           12: Name BEGDATA
           13: Name CODE
SEGDEF:  Type 98, Offset 005D
         Reloc word-aligned, combine type public, length 0068
         Segment name _TEXT, class CODE
SEGDEF:  Type 98, Offset 0067
         Reloc para-aligned, combine type public, length 0010
         Segment name NULL, class BEGDATA
SEGDEF:  Type 98, Offset 0071
         Reloc word-aligned, combine type public, length 0014
         Segment name _DATA, class DATA
SEGDEF:  Type 98, Offset 007B
         Reloc word-aligned, combine type common, length 0000
         Segment name CDATA, class DATA
SEGDEF:  Type 98, Offset 0085
         Reloc word-aligned, combine type public, length 0000
         Segment name CONST, class CONST
SEGDEF:  Type 98, Offset 008F
         Reloc word-aligned, combine type public, length 0000
         Segment name _BSS, class BSS
GRPDEF:  Type 9A, Offset 0099
         Group DGROUP is Seg NULL+Seg _DATA+Seg CDATA+Seg CONST+Seg _BSS
EXTDEF:  Type 8C, Offset 00A8
            1: Name __WINFLAGS
            2: Name INITTASK
            3: Name WINMAIN
            4: Name WAITEVENT
            5: Name INITAPP
PUBDEF:  Type 90, Offset 00DF
         Segment _TEXT
         Name _EXIT, offset 0002
PUBDEF:  Type 90, Offset 00EE
         Frame 0000
         Name __ACRTUSED, offset 9876
PUBDEF:  Type 90, Offset 0104
         Segment _TEXT
         Name __ASTART, offset 000E
PUBDEF:  Type 90, Offset 0116
         Group DGROUP, Segment _DATA
         Name _STKHQQ, offset 0000
PUBDEF:  Type 90, Offset 0127
         Group DGROUP, Segment NULL
         Name RSRVPTRS, offset 0004
PUBDEF:  Type 90, Offset 0139
         Group DGROUP, Segment _DATA
         Name __CMDSHOW, offset 000A
         Name __HPREVINSTANCE, offset 0002
PUBDEF:  Type 90, Offset 015F
         Frame 0000
         Name __FPTASKDATA, offset 9876
PUBDEF:  Type 90, Offset 0177
         Segment _TEXT
         Name __EXIT, offset 0002
PUBDEF:  Type 90, Offset 0187
         Frame 0000
         Name __SIZEC, offset 0000
PUBDEF:  Type 90, Offset 019A
         Group DGROUP, Segment _DATA
         Name __HINSTANCE, offset 0004
PUBDEF:  Type 90, Offset 01AF
         Frame 0000
         Name __SIZED, offset 0000
PUBDEF:  Type 90, Offset 01C2
         Group DGROUP, Segment _DATA
         Name _ASEGHI, offset 000E
         Name ___ADBSWPFLG, offset 0010
         Name ___ADBRTERR, offset 0012
PUBDEF:  Type 90, Offset 01F2
         Frame 0000
         Name __ADBDOSWP, offset D6D6
         Name __ADBUSED, offset D6D6
PUBDEF:  Type 90, Offset 0215
         Group DGROUP, Segment _DATA
         Name __LPSZCMDLINE, offset 0006
PUBDEF:  Type 90, Offset 022C
         Segment _TEXT
         Name __WFLAGS, offset 0000
PUBDEF:  Type 90, Offset 023E
         Group DGROUP, Segment _DATA
         Name _ASEGLO, offset 000C
ALIAS:  Type C6, Offset 024F
         Alias name:  __error_exit
         Substitute name:  _exit
LEDATA:  Type A0, Offset 0266
         Segment NULL, offset 0000, length 0006
    0000:00 00 00 00 05 00                               ð ......
LIDATA:  Type A2, Offset 0273
         Segment NULL, offset 0006
         0005 dup (00 00)
LEDATA:  Type A0, Offset 0281
         Segment _DATA, offset 0000, length 0014
    0000:00 00 00 00 00 00 00 00-00 00 00 00 01 00 FF FF ð ..............ÿÿ
    0010:00 00 00 00                                     ð ....
LEDATA:  Type A0, Offset 029C
         Segment _TEXT, offset 0000, length 0068
    0000:00 00 58 58 B4 4C CD 21-B0 FF 50 E8 F4 FF 33 ED ð ..XX´LÍ!°ÿPèôÿ3í
    0010:55 9A 00 00 00 00 0B C0-74 EE 81 C1 00 01 72 E8 ð U......Àtî.Á..rè
    0020:89 0E 00 00 89 36 00 00-89 3E 00 00 89 1E 00 00 ð .....6...>......
    0030:8C 06 02 00 89 16 00 00-33 C0 50 9A 00 00 00 00 ð ........3ÀP.....
    0040:FF 36 00 00 9A 00 00 00-00 0B C0 74 BB FF 36 00 ð ÿ6........Àt»ÿ6.
    0050:00 FF 36 00 00 FF 36 02-00 FF 36 00 00 FF 36 00 ð .ÿ6..ÿ6..ÿ6..ÿ6.
    0060:00 E8 00 00 50 E8 9A FF-                        ð .è..Pè.ÿ
FIXUPP:  Type 9C, Offset 030B
         Segment-relative word offset location 000 (000), 
         Frame external __WINFLAGS,
           Target external __WINFLAGS
         Segment-relative ptr16:16 location 012 (012), 
           Frame & Target external INITTASK
         Segment-relative word offset location 022 (022), Frame group DGROUP,
           Target segment _DATA
         Segment-relative word offset location 026 (026), Frame group DGROUP,
           Target segment _DATA, offset 0002
         Segment-relative word offset location 02A (02A), Frame group DGROUP,
           Target segment _DATA, offset 0004
         Segment-relative word offset location 02E (02E), Frame group DGROUP,
           Target segment _DATA, offset 0006
         Segment-relative word offset location 032 (032), Frame group DGROUP,
           Target segment _DATA, offset 0006
         Segment-relative word offset location 036 (036), Frame group DGROUP,
           Target segment _DATA, offset 000A
         Segment-relative ptr16:16 location 03C (03C), 
           Frame & Target external WAITEVENT
         Segment-relative word offset location 042 (042), Frame group DGROUP,
           Target segment _DATA, offset 0004
         Segment-relative ptr16:16 location 045 (045), 
           Frame & Target external INITAPP
         Segment-relative word offset location 04F (04F), Frame group DGROUP,
           Target segment _DATA, offset 0004
         Segment-relative word offset location 053 (053), Frame group DGROUP,
           Target segment _DATA, offset 0002
         Segment-relative word offset location 057 (057), Frame group DGROUP,
           Target segment _DATA, offset 0006
         Segment-relative word offset location 05B (05B), Frame group DGROUP,
           Target segment _DATA, offset 0006
         Segment-relative word offset location 05F (05F), Frame group DGROUP,
           Target segment _DATA, offset 000A
         Self-relative word offset location 062 (062), 
           Frame & Target external WINMAIN
MODEND:  Type 8A, Offset 0376
         Main module, start address is 
           Frame & Target segment _TEXT, offset 000E
