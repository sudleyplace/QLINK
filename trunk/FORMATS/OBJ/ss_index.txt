======================================================================
    Microsoft Product Support Services Application Note (Text File)
               SS0288: RELOCATABLE OBJECT MODULE FORMAT
======================================================================
   
This application note is divided into six text files, SS0288_1.TXT
through SS0288_6.TXT. The following provides a reference to the
text file location (section) of the contents.
   
                           TABLE OF CONTENTS
                          ==================
                                   
                                                               Section
                                                               -------
Introduction                                                         1
The Object Record Format                                             1
Frequent Object Record Subfields                                     1
Order of Records                                                     1
Record Specifics                                                     1
80H THEADR--Translator Header Record                                 1
82H LHEADR--Library Module Header Record                             2
88H COMENT--Comment Record                                           2
88H IMPDEF--Import Definition Record (Comment Class A0, Subtype 01)  2
88H EXPDEF--Export Definition Record (Comment Class A0, Subtype 02)  2
88H INCDEF--Incremental Compilation Record (Cmnt Class A0, Sub 03)   2
88H LNKDIR--C++ Directives Record (Comment Class A0, Subtype 05)     2
88H LIBMOD--Library Module Name Record (Comment Class A3)            2
88H EXESTR--Executable String Record (Comment Class A4)              2
88H INCERR--Incremental Compilation Error (Comment Class A6)         2
88H NOPAD--No Segment Padding (Comment Class A7)                     2
88H WKEXT--Weak Extern Record (Comment Class A8)                     2
88H LZEXT--Lazy Extern Record (Comment Class A9)                     3
88H PharLap Format Record (Comment Class AA)                         3
8AH or 8BH MODEND--Module End Record                                 3
8CH EXTDEF--External Names Definition Record                         3
8EH TYPDEF--Type Definition Record                                   3
90H or 91H PUBDEF--Public Names Definition Record                    3
94H or 95H LINNUM--Line Numbers Record                               3
96H LNAMES--List of Names Record                                     4
98H or 99H SEGDEF--Segment Definition Record                         4
9AH GRPDEF--Group Definition Record                                  4
9CH or 9DH FIXUPP--Fixup Record                                      4
A0H or A1H LEDATA--Logical Enumerated Data Record                    5
A2H or A3H LIDATA--Logical Iterated Data Record                      5
B0H COMDEF--Communal Names Definition Record                         5
B2H or B3H BAKPAT--Backpatch Record                                  5
B4H or B5H LEXTDEF--Local External Names Definition Record           5
B6H or B7H LPUBDEF--Local Public Names Definition Record             5
B8H LCOMDEF--Local Communal Names Definition Record                  5
BCH CEXTDEF--COMDAT External Names Definition Record                 5
C2H or C3H COMDAT--Initialized Communal Data Record                  5
C4H or C5H LINSYM--Symbol Line Numbers Record                        6
C6H ALIAS--Alias Definition Record                                   6
C8H or C9H NBKPAT--Named Backpatch Record                            6
CAH LLNAMES--Local Logical Names Definition Record                   6
Appendix 1: CodeView Extensions                                      6
Appendix 2: Microsoft MS-DOS Library Format                          6
