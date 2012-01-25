#include <windows.h>

#include <malloc.h>
#include <stdio.h>


/* 
 * $Header: D:/c_kram/nt_info/RCS/versinfo.c,v 1.3 1998/11/18 00:00:59 LUEVELSMEYER Exp $
 *
 * checked in by $Author: LUEVELSMEYER $
 * checked in at $Date: 1998/11/18 00:00:59 $
 *
 * History:
 * $Log: versinfo.c,v $
 * Revision 1.3  1998/11/18 00:00:59  LUEVELSMEYER
 * run through indent
 *
 * Revision 1.2  1998/04/14 15:41:46  LUEVELSMEYER
 * added comments
 *
 * Revision 1.1  1997/06/05 11:23:42  LUEVELSMEYER
 * Initial revision
 *
 *
 */

#pragma off(unreferenced)
static const char RCSHeader[] = "$Id: versinfo.c,v 1.3 1998/11/18 00:00:59 LUEVELSMEYER Exp $";
#pragma on(unreferenced)



#include "versinfo.h"

static void ShowStrings(void *const info, const DWORD lang)
{
#define ARRAY_LEN(Array)	(sizeof(Array) / sizeof(Array[0]))
    char *stringnames[] =
    {"Comments",
     "CompanyName",
     "FileDescription",
     "FileVersion",
     "InternalName",
     "LegalCopyright",
     "LegalTrademarks",
     "OriginalFilename",
     "PrivateBuild",
     "ProductName",
     "ProductVersion",
     "SpecialBuild"
    };

    int i;

    for (i = 0; i < ARRAY_LEN(stringnames); i++)
      {
          char query[500];
          LPSTR value;
          UINT len;

          sprintf(query, "\\StringFileInfo\\%04x%04x\\%s", LOWORD(lang), HIWORD(lang), stringnames[i]);
          if (!VerQueryValue(info, query, &value, &len) || !len)
              continue;
          CharToOem(value, value);
          printf("  %-16s: %s\n", stringnames[i], value);
      }

#undef ARRAY_LEN
}


void print_version_info(char *progname)
{
    DWORD dummy, infosize;

    if (!(infosize = GetFileVersionInfoSize(progname, &dummy)))
      {
          puts("(no version info)");
          return;
      }
    else
      {
          void *info = malloc(infosize);
          VS_FIXEDFILEINFO *fixed_info;
          UINT fixed_len;

          if (!info)
            {
                puts("(error on malloc");
                return;
            }

          GetFileVersionInfo(progname, 0, infosize, info);
          VerQueryValue(info, "\\", &fixed_info, &fixed_len);

          /* File Version */
          printf("File Version:    %d.%d.%d.%d\n",
                 HIWORD(fixed_info->dwFileVersionMS),
                 LOWORD(fixed_info->dwFileVersionMS),
                 HIWORD(fixed_info->dwFileVersionLS),
                 LOWORD(fixed_info->dwFileVersionLS));

          /* Product Version */
          printf("Product Version: %d.%d.%d.%d\n",
                 HIWORD(fixed_info->dwProductVersionMS),
                 LOWORD(fixed_info->dwProductVersionMS),
                 HIWORD(fixed_info->dwProductVersionLS),
                 LOWORD(fixed_info->dwProductVersionLS));

          {                     /* File Flags */
              DWORD flags = fixed_info->dwFileFlags & fixed_info->dwFileFlagsMask;
              fputs("Flags:           ", stdout);
              if (!flags)
                  fputs("(none)", stdout);
              if (flags & VS_FF_DEBUG)
                  fputs("Debug ", stdout);
              if (flags & VS_FF_PRERELEASE)
                  fputs("Prerelease ", stdout);
              if (flags & VS_FF_PATCHED)
                  fputs("Patched ", stdout);
              if (flags & VS_FF_PRIVATEBUILD)
                  fputs("PrivateBuild ", stdout);
              if (flags & VS_FF_INFOINFERRED)
                  fputs("InfoInferred ", stdout);
              if (flags & VS_FF_SPECIALBUILD)
                  fputs("SpecialBuild ", stdout);
              putchar('\n');
          }

          {                     /* File OS. */
              fputs("OS:              ", stdout);
              switch (LOWORD(fixed_info->dwFileOS))
                {
                    case VOS__WINDOWS16:
                        fputs("16-Bit Windows", stdout);
                        break;
                    case VOS__PM16:
                        fputs("16-Bit Presentation Manager", stdout);
                        break;
                    case VOS__PM32:
                        fputs("32-Bit Presentation Manager", stdout);
                        break;
                    case VOS__WINDOWS32:
                        fputs("Win32", stdout);
                        break;
                    default:
                        fputs("(unknown)", stdout);
                        break;
                }
              fputs(" on ", stdout);
              switch (MAKELONG(0, HIWORD(fixed_info->dwFileOS)))
                {
                    case VOS_DOS:
                        puts("MS-DOS");
                        break;
                    case VOS_OS216:
                        puts("16-Bit OS/2");
                        break;
                    case VOS_OS232:
                        puts("32-Bit OS/2");
                        break;
                    case VOS_NT:
                        puts("NT");
                        break;
                    default:
                        puts("(unknown)");
                        break;
                }
          }

          /* file type */
          fputs("Type:            ", stdout);
          switch (fixed_info->dwFileType)
            {
                case VFT_APP:
                    puts("Exe");
                    break;
                case VFT_DLL:
                    puts("DLL");
                    break;
                case VFT_DRV:
                    switch (fixed_info->dwFileSubtype)
                      {
                          case VFT2_DRV_COMM:
                              puts("driver (serial)");
                              break;
                          case VFT2_DRV_PRINTER:
                              puts("driver (printer)");
                              break;
                          case VFT2_DRV_KEYBOARD:
                              puts("driver (keyboard)");
                              break;
                          case VFT2_DRV_LANGUAGE:
                              puts("driver (language)");
                              break;
                          case VFT2_DRV_DISPLAY:
                              puts("driver (screen)");
                              break;
                          case VFT2_DRV_MOUSE:
                              puts("driver (mouse)");
                              break;
                          case VFT2_DRV_NETWORK:
                              puts("driver (network)");
                              break;
                          case VFT2_DRV_SYSTEM:
                              puts("driver (system)");
                              break;
                          case VFT2_DRV_INSTALLABLE:
                              puts("driver (installable)");
                              break;
                          case VFT2_DRV_SOUND:
                              puts("driver (sound)");
                              break;
                          case VFT2_UNKNOWN:
                          default:
                              puts("driver (unknown)");
                              break;
                      }

                    break;
                case VFT_FONT:
                    switch (fixed_info->dwFileSubtype)
                      {
                          case VFT2_FONT_RASTER:
                              puts("font (raster)");
                              break;
                          case VFT2_FONT_VECTOR:
                              puts("font (vector)");
                              break;
                          case VFT2_FONT_TRUETYPE:
                              puts("font (truetype)");
                              break;
                          case VFT2_UNKNOWN:
                          default:
                              puts("font (unknown)");
                              break;
                      }

                    break;

                case VFT_VXD:
                    printf("virtual device (VxD), device id == %ld\n", fixed_info->dwFileSubtype);
                    break;
                case VFT_STATIC_LIB:
                    puts("static Lib");
                    break;
                case VFT_UNKNOWN:
                default:
                    puts("(unknown)");
                    break;
            }


          /* languages and strings */
          {
              LPDWORD langs;
              UINT len, i;
              char buffer[MAX_PATH];

              VerQueryValue(info, "\\VarFileInfo\\Translation", &langs, &len);

              for (i = 0; i < len; i += sizeof(*langs), langs++)
                {               /* Get the string name for the language number. */
                    VerLanguageName(LOWORD(*langs), buffer, sizeof(buffer));
                    fputs("- ", stdout);
                    puts(buffer);
                    ShowStrings(info, *langs);
                }
          }

          free(info);

      }
}
