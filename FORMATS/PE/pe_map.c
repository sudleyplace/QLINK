
/* 
 * pe_map.c, dumps a PE file
 * made with Watcom C32 version 11.0b on NT 4.0
 * (f) by B. Luevelsmeyer 1997, 1998, 1999
 */

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <io.h>
#include <fcntl.h>


/* 
 *      $Header: D:/c_kram/nt_info/RCS/pe_map.c,v 1.26 1999/03/20 23:59:47 LUEVELSMEYER Exp $
 *
 *      checked in by $Author: LUEVELSMEYER $
 *      checked in at $Date: 1999/03/20 23:59:47 $
 *
 *      History:
 *      $Log: pe_map.c,v $
 *      Revision 1.26  1999/03/20 23:59:47  LUEVELSMEYER
 *      fixed messed-up comment
 *
 *      Revision 1.25  1999/03/18 20:29:56  LUEVELSMEYER
 *      changed ordinal<->hint
 *
 *      Revision 1.24  1999/03/14 04:47:19  LUEVELSMEYER
 *      cosmetical stuff (indentation, comments)
 *
 *      Revision 1.23  1999/03/14 02:48:41  LUEVELSMEYER
 *      corrected major fuckup in export directory dump
 *
 *      Revision 1.22  1998/07/20 12:02:54  LUEVELSMEYER
 *      merged with DEC alpha port
 *
 *      Revision 1.21  1998/07/03 18:03:02  LUEVELSMEYER
 *      added share to file opening
 *
 *      Revision 1.20  1998/04/26 00:03:07  LUEVELSMEYER
 *      corrected typo in comment
 *
 *      Revision 1.19  1998/04/16 13:22:12  LUEVELSMEYER
 *      added output of import table addresses
 *
 *      Revision 1.18  1998/04/14 15:41:46  LUEVELSMEYER
 *      added comments
 *
 *      Revision 1.17  1998/04/04 16:07:08  LUEVELSMEYER
 *      added command line options & base relocation output
 *
 *      Revision 1.16  1998/04/02 21:37:24  LUEVELSMEYER
 *      supported output of resource-language
 *
 *      Revision 1.15  1998/04/02 16:34:03  LUEVELSMEYER
 *      changed output strings of bound imports
 *
 *      Revision 1.14  1998/04/02 15:56:53  LUEVELSMEYER
 *      added support for new-style-binding of imports
 *
 *      Revision 1.13  1998/04/02 01:18:02  LUEVELSMEYER
 *      beautified indentation
 *
 *      Revision 1.12  1998/04/02 01:07:13  LUEVELSMEYER
 *      linted
 *      (mostly bad printf-conversions)
 *
 *      Revision 1.11  1998/02/18 00:53:50  LUEVELSMEYER
 *      corrected typo
 *
 *      Revision 1.10  1998/01/16 02:51:35  LUEVELSMEYER
 *      changed wording of header output
 *
 *      Revision 1.9  1998/01/16 02:36:25  LUEVELSMEYER
 *      added meaningful exit-codes
 *
 *      Revision 1.8  1997/12/24 22:14:07  LUEVELSMEYER
 *      changed filename output
 *
 *      Revision 1.8  1997/12/24 22:10:53  LUEVELSMEYER
 *      dropped filename on output
 *
 *      Revision 1.7  1997/11/23 00:14:07  LUEVELSMEYER
 *      corrected spelling in output
 *
 *      Revision 1.6  1997/08/10 03:39:09  LUEVELSMEYER
 *      (minor correction in output)
 *
 *      Revision 1.5  1997/08/10 03:33:19  LUEVELSMEYER
 *      added following forwarders
 *
 *      Revision 1.4  1997/08/07 16:54:49  LUEVELSMEYER
 *      added remark on "ForwarderChain"
 *
 *      Revision 1.3  1997/08/06 20:51:13  LUEVELSMEYER
 *      changed one output string
 *
 *      Revision 1.2  1997/06/06 22:26:31  LUEVELSMEYER
 *      added support for bound import; changed to bind for old style
 *
 *      Revision 1.1  1997/06/05 11:23:42  LUEVELSMEYER
 *      Initial revision
 *
 *
 */

#pragma off(unreferenced)
static const char RCSHeader[] = "$Id: pe_map.c,v 1.26 1999/03/20 23:59:47 LUEVELSMEYER Exp $";
#pragma on(unreferenced)



#include "versinfo.h"


/* is an address in the range start up to start+length? */
#define isin(address,start,length) ((char*)(address)>=(char*)(start) && (char*)(address)<(char*)(start)+(length))


static do_the_relocs;           /* controls whether base relocation table is desired */


static void dump_export_directory(const void *const section_base, const DWORD section_base_virtual, const IMAGE_EXPORT_DIRECTORY * const exp, const size_t section_length)
    /* output of an export directory */
{
      #define indent "      "
      #define adr(rva) ((const void*)((char*)section_base+((DWORD)(rva))-section_base_virtual))

    /* prepare for bad linkers */
    if (IsBadReadPtr(exp, sizeof(*exp)))
      {
          puts(indent "!! data inaccessible!!");
          return;
      }

    printf(indent "module name: \"%s\"\n", (char *)adr(exp->Name));
    printf(indent "created (GMT): %s", asctime(gmtime((const time_t *)&exp->TimeDateStamp)));
    printf(indent "version: %d.%d\n", exp->MajorVersion, exp->MinorVersion);
    printf(indent "%lu exported functions, list at %lx\n", exp->NumberOfFunctions, exp->AddressOfFunctions);
    if (exp->NumberOfNames && exp->AddressOfNames)
        printf(indent "%lu exported names, list at %lx\n", exp->NumberOfNames, exp->AddressOfNames);
    else
        puts(indent "(no name table provided)");
    printf(indent "Ordinal base: %lu\n", exp->Base);

    {
        const WORD *ordinal_table = adr(exp->AddressOfNameOrdinals);
        const DWORD *function_table = adr(exp->AddressOfFunctions);
        const DWORD *name_table = exp->AddressOfNames ? adr(exp->AddressOfNames) : 0;
        size_t i;
        unsigned unused_slots = 0;  /* functions with an RVA of 0 seem to be unused */

        printf(indent "%4s %4s %-30s %6s\n", "Ord.", "Hint", "Name", "RVA");
        printf(indent "%4s %4s %-30s %6s\n", "----", "----", "----", "---");

        for (i = 0; i < exp->NumberOfFunctions; i++)
          {
              const DWORD addr = function_table[i];
              if (!addr)        /* skip unused slots */
                {
                    ++unused_slots;
                    continue;
                }

              /* ordinal */
              printf(indent "%4u ", i + exp->Base);

              /* if names provided, list all names of this
               * export ordinal
               */
              if (name_table)
                {
                    size_t n;
                    int found = 0;
                    for (n = 0; n < exp->NumberOfNames; n++)
                      {
                          /* according to the spec, you should
                           * compare to the ordinal 'i+exp->Base'
                           * rather than to 'i', but I've found
                           * this to work and the ordinal not to
                           * work.
                           */
                          if (ordinal_table[n] == i)
                            {
                                /* begin new line for
                                 * additional names
                                 */
                                if (found)
                                    fputs("\n" indent "     ", stdout);

                                printf("%4lu %-30s", (unsigned long)n,adr(name_table[n]));
                                ++found;
                            }
                      }
                    if (!found)
                        /* no names */
                        printf("%4s %-30s", "","(nameless)");
                    else if (found > 1)
                        /* several names, put address in new line */
                        fputs("\n" indent indent, stdout);

                    putchar(' ');
                }

              /* entry point */
              if (addr >= section_base_virtual && addr < section_base_virtual + section_length)
                  /* forwarder */
                  puts(adr(addr));
              else
                  /* normal export */
                  printf("%6lx\n", addr);
          }

        if (unused_slots)
            printf(indent "-- there are %u unused slots --\n", unused_slots);
    }

      #undef adr
      #undef indent
}


static void dump_import_directory(const void *const section_base, const DWORD section_base_virtual, const IMAGE_IMPORT_DESCRIPTOR * imp)
    /* dump of import directory.
     * quite a challenge because of broken linkers, unbound/old-bound and new-bound directories
     */
{
      #define indent "      "
      #define adr(rva) ((const void*)((char*)section_base+((DWORD)(rva))-section_base_virtual))

    for (; !IsBadReadPtr(imp, sizeof(*imp)) && imp->Name; imp++)
      {
          const IMAGE_THUNK_DATA *import_entry, *mapped_entry;
          enum
            {
                bound_none, bound_old, bound_new
            }
          bound;

          printf("\n" indent "from \"%s\":\n", (char *)adr(imp->Name));

          if (imp->TimeDateStamp == ~0UL)
            {
                puts(indent "bound, new style");
                bound = bound_new;
            }
          else if (imp->TimeDateStamp)
            {
                printf(indent "bound (old style) to %s", asctime(gmtime((const time_t *)&imp->TimeDateStamp)));
                bound = bound_old;
            }
          else
            {
                puts(indent "not bound");
                bound = bound_none;
            }

          printf(indent "name table at %#lx, address table at %#lx\n", imp->OriginalFirstThunk, imp->FirstThunk);

          if (imp->OriginalFirstThunk)
            {
                import_entry = adr(imp->OriginalFirstThunk);
                mapped_entry = adr(imp->FirstThunk);
            }
          else
            {
                puts(indent "(hint table missing, probably Borland bug)");
                import_entry = adr(imp->FirstThunk);
                mapped_entry = 0;
                bound = bound_none;
            }

          printf(indent "%6s %s\n", "hint", "name");
          printf(indent "%6s %s\n", "----", "----");

          {
              int count, nextforwarder = bound==bound_old ? imp->ForwarderChain : -1;
              for (count = 0; import_entry->u1.Ordinal; count++, import_entry++, bound ? mapped_entry++ : 0)
                {
                    if (IMAGE_SNAP_BY_ORDINAL(import_entry->u1.Ordinal))
                        printf(indent "%6lu %-20s", IMAGE_ORDINAL(import_entry->u1.Ordinal),"<ordinal>");
                    else
                      {
                          const IMAGE_IMPORT_BY_NAME *name_import = adr(import_entry->u1.AddressOfData);
                          printf(indent "%6u %-20.50s", name_import->Hint, name_import->Name);
                      }
                    if (bound)
                        if (count != nextforwarder)
                            printf("%#12lx\n", (unsigned long)mapped_entry->u1.Function);
                        else
                          {
                              printf("%12s\n", "    --> forward");
                              nextforwarder = (int)mapped_entry->u1.ForwarderString;
                          }
                    else
                        puts("");
                }
          }
      }
    if (IsBadReadPtr(imp, sizeof(*imp)))
        puts(indent "!! data inaccessible!!");

      #undef adr
      #undef indent
}


static void dump_bound_import_directory(const void *const section_base, const DWORD section_base_virtual, const void *const import_base)
    /* for forward-table of new-style bound import directories
     * often found in the header, not in a section!
     */
{
      #define indent "   "

    const IMAGE_BOUND_IMPORT_DESCRIPTOR *bd = import_base;

    while (bd->TimeDateStamp)
      {
          unsigned i;
          const IMAGE_BOUND_FORWARDER_REF *forw;
          printf(indent "%u forwarder-DLLs from %s of %s", bd->NumberOfModuleForwarderRefs, (char *)import_base + bd->OffsetModuleName, asctime(gmtime((const time_t *)&bd->TimeDateStamp)));
          forw = (void *)(bd + 1);
          for (i = bd->NumberOfModuleForwarderRefs; i; i--, forw++)
              printf(indent indent "%s of %s", (char *)import_base + forw->OffsetModuleName, asctime(gmtime((const time_t *)&forw->TimeDateStamp)));
          bd = (void *)forw;
      }

      #undef indent
}


/* resources are recursive stuff! * directories contain enries which
 * may point to other directories. */

static void dump_resource_directory(const int indent, const IMAGE_RESOURCE_DIRECTORY * const res_start, const IMAGE_RESOURCE_DIRECTORY * const dir, const BOOL output_types);

static void dump_resource_directory_entry(const int indent, const IMAGE_RESOURCE_DIRECTORY * const res_start, const IMAGE_RESOURCE_DIRECTORY_ENTRY * const entry, const BOOL output_types)
    /* a directory entry is either a type (menu etc.) or an ID (name or number) or
     * a language identifier
     */
{
    if (entry->NameIsString)
      {
          /* it's a UNICODE string without a 0-termination - cautious! */
          IMAGE_RESOURCE_DIR_STRING_U *uni_name = (void *)((char *)res_start + entry->NameOffset);
          printf("%*sname: \"%.*ls\"", indent, "", (int)uni_name->Length, uni_name->NameString);
      }
    else if (output_types)
        switch (entry->Id)
          {
              case 1:
                  printf("%*scursor", indent, "");
                  break;
              case 2:
                  printf("%*sbitmap", indent, "");
                  break;
              case 3:
                  printf("%*sicon", indent, "");
                  break;
              case 4:
                  printf("%*smenu", indent, "");
                  break;
              case 5:
                  printf("%*sdialog", indent, "");
                  break;
              case 6:
                  printf("%*sstring", indent, "");
                  break;
              case 7:
                  printf("%*sfontdir", indent, "");
                  break;
              case 8:
                  printf("%*sfont", indent, "");
                  break;
              case 9:
                  printf("%*saccelerators", indent, "");
                  break;
              case 10:
                  printf("%*sRCdata", indent, "");
                  break;
              case 11:
                  printf("%*smessage table", indent, "");
                  break;
              case 12:
                  printf("%*sgroup cursor", indent, "");
                  break;
              case 14:
                  printf("%*sgroup icon", indent, "");
                  break;
              case 16:
                  printf("%*sversion info", indent, "");
                  break;
              default:
                  printf("%*sunknown resource type %#4x", indent, "", entry->Id);
                  break;
          }
    else
        printf("%*sid: %#x", indent, "", entry->Id);
    fputs(", ", stdout);
    if (entry->DataIsDirectory)
        dump_resource_directory(indent + 4, res_start, (void *)((char *)res_start + entry->OffsetToDirectory), FALSE);
    else
      {
          IMAGE_RESOURCE_DATA_ENTRY *data = (void *)((char *)res_start + entry->OffsetToData);
          char lang_buffer[50]; /* buffer for language name */
          char country_buffer[50];  /* buffer for country name */
          if (PRIMARYLANGID(entry->Id) == LANG_NEUTRAL)
            {
                strcpy(lang_buffer, "neutral");
                switch (SUBLANGID(entry->Id))
                  {
                      case SUBLANG_NEUTRAL:
                          strcpy(country_buffer, "neutral");
                          break;
                      case SUBLANG_SYS_DEFAULT:
                          strcpy(country_buffer, "system default");
                          break;
                      case SUBLANG_DEFAULT:
                          strcpy(country_buffer, "user default");
                          break;
                      default:
                          strcpy(country_buffer, "unknown default");
                          break;
                  }
            }
          else
            {
                DWORD lcid = MAKELCID(entry->Id, SORT_DEFAULT);  /* build locale for language (indicated by id) */
                if (!GetLocaleInfo(lcid, LOCALE_SENGLANGUAGE, lang_buffer, sizeof lang_buffer))  /* get abbreviated language identifier */
                    strcpy(lang_buffer, "???");
                if (!GetLocaleInfo(lcid, LOCALE_SENGCOUNTRY, country_buffer, sizeof country_buffer))  /* get abbreviated language identifier */
                    strcpy(lang_buffer, "???");
            }
          printf("%s (%s), %ld bytes from %#lx, codepage 0x%04lx\n", lang_buffer, country_buffer, data->Size, data->OffsetToData, data->CodePage);
      }
}


static void dump_resource_directory(const int indent, const IMAGE_RESOURCE_DIRECTORY * const res_start, const IMAGE_RESOURCE_DIRECTORY * const dir, const BOOL output_types)
    /* a directory contains many resource types or many resources or many languages */
{
    if (IsBadReadPtr(dir, sizeof(*dir)))
      {
          puts("!! data inaccessible!!");
          return;
      }
    printf("version: %d.%d, created (GMT): %s", dir->MajorVersion, dir->MinorVersion, asctime(gmtime((const time_t *)&dir->TimeDateStamp)));
    {
        IMAGE_RESOURCE_DIRECTORY_ENTRY *single_resource = (void *)(dir + 1);
        int i;
        for (i = 0; i < dir->NumberOfNamedEntries + dir->NumberOfIdEntries; i++, single_resource++)
            dump_resource_directory_entry(indent, res_start, single_resource, output_types);
    }
}


static void dump_reloc_directory(const void *const section_base, const DWORD section_base_virtual, const IMAGE_BASE_RELOCATION * rel)
    /* relocations - boring to read, but they are there :-)
     */
{
      #define indent "    "

    if (!do_the_relocs)
      {
          puts(indent "(relocations skipped)");
          return;
      }

    while (rel->VirtualAddress)
      {
          const unsigned long reloc_num = (rel->SizeOfBlock - sizeof(*rel)) / sizeof(WORD);
          printf("\n" indent indent "%lu relocations starting at 0x%04lx\n", reloc_num, rel->VirtualAddress);
          {
              unsigned i;
              const WORD *ad = (void *)(rel + 1);
              for (i = 0; i < reloc_num; i++, ad++)
                {
                    const char *type;
                    switch (*ad >> 12)
                      {
                          case IMAGE_REL_BASED_ABSOLUTE:
                              type = "nop";
                              break;
                          case IMAGE_REL_BASED_HIGH:
                              type = "fix high";
                              break;
                          case IMAGE_REL_BASED_LOW:
                              type = "fix low";
                              break;
                          case IMAGE_REL_BASED_HIGHLOW:
                              type = "fix hilo";
                              break;
                          case IMAGE_REL_BASED_HIGHADJ:
                              type = "fix highadj";
                              break;
                          case IMAGE_REL_BASED_MIPS_JMPADDR:
                              type = "jmpaddr";
                              break;
                          case IMAGE_REL_BASED_SECTION:
                              type = "section";
                              break;
                          case IMAGE_REL_BASED_REL32:
                              type = "fix rel32";
                              break;
                          default:
                              type = "???";
                              break;
                      }
                    printf(indent indent indent "offset 0x%03x (%s)\n", *ad & 0xfffU, type);
                }
              rel = (void *)ad;
          }
      }


      #undef indent
}


static void look_for_directories(const void *const section_data,
                                 const DWORD section_start_virtual,
                                 const size_t section_length,
                                 const IMAGE_DATA_DIRECTORY * const directories,
                                 const int indentation)
    /* find directories in the given range
     * section_data: current address of section start (raw data)
     * section_start_virtual: RVA of section (raw data)
     * section_length: number of bytes in section
     * look for directory in section or in section-like part of the header (bound import!)
     * if found, dump interesting stuff
     */
{
    int directory;
    for (directory = 0; directory < IMAGE_NUMBEROF_DIRECTORY_ENTRIES; directory++)
        if (directories[directory].VirtualAddress && isin(directories[directory].VirtualAddress, section_start_virtual, section_length))
          {
              const void *const stuff_start = (char *)section_data + (directories[directory].VirtualAddress - section_start_virtual);
              /* (virtual address of stuff - virtual address of section) = offset of stuff in section */
              const unsigned stuff_length = directories[directory].Size;
              printf("\n%*sat offset %#x (%u bytes): ", indentation, "", (char *)stuff_start - (char *)section_data, stuff_length);
              switch (directory)
                {
                    case IMAGE_DIRECTORY_ENTRY_EXPORT:
                        puts("Export Directory");
                        dump_export_directory(section_data, section_start_virtual, stuff_start, section_length);
                        break;
                    case IMAGE_DIRECTORY_ENTRY_IMPORT:
                        puts("Import Directory");
                        dump_import_directory(section_data, section_start_virtual, stuff_start);
                        break;
                    case IMAGE_DIRECTORY_ENTRY_RESOURCE:
                        printf("Resource Directory\n%*s", 2 * indentation, "");
                        dump_resource_directory(2 * indentation, stuff_start, stuff_start, TRUE);
                        break;
                    case IMAGE_DIRECTORY_ENTRY_EXCEPTION:
                        puts("Exception Directory");
                        break;
                    case IMAGE_DIRECTORY_ENTRY_SECURITY:
                        puts("Security Directory");
                        break;
                    case IMAGE_DIRECTORY_ENTRY_BASERELOC:
                        puts("Base Relocation Table");
                        dump_reloc_directory(section_data, section_start_virtual, stuff_start);
                        break;
                    case IMAGE_DIRECTORY_ENTRY_DEBUG:
                        puts("Debug Directory");
                        break;
                    case IMAGE_DIRECTORY_ENTRY_COPYRIGHT:
                        printf("Description String \"%.*s\"\n", stuff_length, (char *)stuff_start);
                        break;
                    case IMAGE_DIRECTORY_ENTRY_GLOBALPTR:
                        puts("Machine Value (MIPS GP)");
                        break;
                    case IMAGE_DIRECTORY_ENTRY_TLS:
                        puts("TLS Directory");
                        break;
                    case IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG:
                        puts("Load Configuration Directory");
                        break;
                    case IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT:
                        puts("Bound Import Directory");
                        dump_bound_import_directory(section_data, section_start_virtual, stuff_start);
                        break;
                    case IMAGE_DIRECTORY_ENTRY_IAT:
                        puts("Import Address Table");
                        break;
                    default:
                        puts("unknown directory");
                        break;
                }
          }
}


static void map_exe(const void *base)
    /* dump headers, then walk through sections */
{
    const IMAGE_DOS_HEADER *dos_head = base;

      #include <pshpack1.h>     /* sorry, but I really do need this struct without padding */
    const struct
      {
          DWORD signature;
          IMAGE_FILE_HEADER _head;
          IMAGE_OPTIONAL_HEADER opt_head;
          IMAGE_SECTION_HEADER section_header[];  /* actual number in NumberOfSections */
      }
          *header;
      #include <poppack.h>

    if (dos_head->e_magic != IMAGE_DOS_SIGNATURE)
      {
          puts("unknown type of file");
          return;
      }                         /* verify DOS-EXE-Header */
    header = (const void *)((char *)dos_head + dos_head->e_lfanew);  /* after end of DOS-EXE-Header: offset to PE-Header */

    if (IsBadReadPtr(header, sizeof(*header)))  /* start of PE-Header */
      {
          puts("(no PE header, probably DOS executable)");
          return;
      }
    printf("DOS-stub: %ld bytes\n", (long)((char *)header - (char *)dos_head));
    {
        if (header->signature != IMAGE_NT_SIGNATURE)  /* verify PE format */
          {
              switch ((unsigned short)header->signature)
                {
                    case IMAGE_DOS_SIGNATURE:
                        puts("(MS-DOS signature)");
                        return;
                    case IMAGE_OS2_SIGNATURE:
                        puts("(Win16 or OS/2 signature)");
                        return;
                    case IMAGE_OS2_SIGNATURE_LE:
                        puts("(Win16, OS/2 or VxD signature)");
                        return;
                    default:
                        puts("(unknown signature, probably MS-DOS)");
                        return;
                }
          }
    }

    /* finally, we have the PE image header */

    fputs("built for machine: ", stdout);
    switch (header->_head.Machine)
      {
          case IMAGE_FILE_MACHINE_I386:
              puts("Intel 80386 processor");
              break;
          case 0x014d:
              puts("Intel 80486 processor");
              break;
          case 0x014e:
              puts("Intel Pentium processor");
              break;
          case 0x0160:
              puts("R3000 (MIPS) processor, big endian");
              break;
          case IMAGE_FILE_MACHINE_R3000:
              puts("R3000 (MIPS) processor, little endian");
              break;
          case IMAGE_FILE_MACHINE_R4000:
              puts("R4000 (MIPS) processor, little endian");
              break;
          case IMAGE_FILE_MACHINE_R10000:
              puts("R10000 (MIPS) processor, little endian");
              break;
          case IMAGE_FILE_MACHINE_ALPHA:
              puts("DEC Alpha_AXP processor");
              break;
          case IMAGE_FILE_MACHINE_POWERPC:
              puts("Power PC, little endian");
              break;
          default:
              printf("unknown processor: %04x\n", header->_head.Machine);
              break;
      }

    printf("  (%s32-bit-word machine)\n", header->_head.Characteristics & IMAGE_FILE_32BIT_MACHINE ? "" : "non-");
    printf("Bytes of machine word are %s\n", header->_head.Characteristics & IMAGE_FILE_BYTES_REVERSED_LO ? "reversed" : "not reversed");

    printf("Relocation info %s\n", header->_head.Characteristics & IMAGE_FILE_RELOCS_STRIPPED ? "stripped" : "not stripped");
    printf("Line nunbers %s\n", header->_head.Characteristics & IMAGE_FILE_LINE_NUMS_STRIPPED ? "stripped" : "not stripped");
    printf("Local symbols %s\n", header->_head.Characteristics & IMAGE_FILE_LOCAL_SYMS_STRIPPED ? "stripped" : "not stripped");
    printf("Debugging info %s\n", header->_head.Characteristics & IMAGE_FILE_DEBUG_STRIPPED ? "stripped" : "not stripped");

    printf("%s copy to swapfile if run from removable media\n", header->_head.Characteristics & IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP ? "must" : "need not");
    printf("%s copy to swapfile if run from network\n", header->_head.Characteristics & IMAGE_FILE_NET_RUN_FROM_SWAP ? "must" : "need not");
    printf("runs on %s\n", header->_head.Characteristics & IMAGE_FILE_UP_SYSTEM_ONLY ? "UP machine only" : "MP or UP machine");
    printf("working set trimmed %s\n", header->_head.Characteristics & IMAGE_FILE_AGGRESIVE_WS_TRIM ? "aggressively" : "normaly");

    puts(header->_head.Characteristics & IMAGE_FILE_EXECUTABLE_IMAGE ? "executable file" : "object/library file");
    puts(header->_head.Characteristics & IMAGE_FILE_SYSTEM ? "system file" : "not a system file");
    if (header->_head.Characteristics & IMAGE_FILE_DLL)
      {
          puts("File is a DLL");
          printf("  %snotify on ProcAttach\n", header->opt_head.DllCharacteristics & 0x1 ? "" : "do not ");
          printf("  %snotify on ThreadAttach\n", header->opt_head.DllCharacteristics & 0x4 ? "" : "do not ");
          printf("  %snotify on ProcDetach\n", header->opt_head.DllCharacteristics & 0x8 ? "" : "do not ");
          printf("  %snotify on ThreadDetach\n", header->opt_head.DllCharacteristics & 0x2 ? "" : "do not ");
      }
    else
        puts("not a DLL");

    printf("%ld entries in symbol table\n", header->_head.NumberOfSymbols);
    printf("%d sections\n", header->_head.NumberOfSections);
    printf("created (GMT): %s", asctime(gmtime((const time_t *)&header->_head.TimeDateStamp)));

    printf("Linker version: %d.%d\n", header->opt_head.MajorLinkerVersion, header->opt_head.MinorLinkerVersion);
    printf(".text start: %#8lx, length: %6lu bytes\n", header->opt_head.BaseOfCode, header->opt_head.SizeOfCode);
    printf(".data start: %#8lx, length: %6lu bytes\n", header->opt_head.BaseOfData, header->opt_head.SizeOfInitializedData);
    printf(".bss  start:      -/-, length: %6lu bytes\n", header->opt_head.SizeOfUninitializedData);
    printf("execution starts at    %#8lx\n", header->opt_head.AddressOfEntryPoint);
    printf("Preferred load base is %#8lx\n", header->opt_head.ImageBase);
    printf("Image size in RAM: %lu KB\n", header->opt_head.SizeOfImage / 1024);
    printf("Sections aligned to %lu bytes in RAM, %lu bytes in file\n", header->opt_head.SectionAlignment, header->opt_head.FileAlignment);
    printf("Versions: NT %d.%d, Win32 %d.%d, App %d.%d\n", header->opt_head.MajorOperatingSystemVersion, header->opt_head.MinorOperatingSystemVersion, header->opt_head.MajorSubsystemVersion, header->opt_head.MinorSubsystemVersion, header->opt_head.MajorImageVersion, header->opt_head.MinorImageVersion);
    printf("Checksum: 0x%08lx\n", header->opt_head.CheckSum);
    switch (header->opt_head.Subsystem)
      {
          case IMAGE_SUBSYSTEM_NATIVE:
              puts("uses no subsystem");
              break;
          case IMAGE_SUBSYSTEM_WINDOWS_GUI:
              puts("uses Win32 graphical subsystem");
              break;
          case IMAGE_SUBSYSTEM_WINDOWS_CUI:
              puts("uses Win32 console subsystem");
              break;
          case IMAGE_SUBSYSTEM_OS2_CUI:
              puts("uses OS/2 console subsystem");
              break;
          case IMAGE_SUBSYSTEM_POSIX_CUI:
              puts("uses Posix console subsystem");
              break;
          default:
              puts("uses unknown subsystem");
              break;
      }
    printf("Stack: %3lu KB reserved, %3lu KB committed\n", header->opt_head.SizeOfStackReserve / 1024, header->opt_head.SizeOfStackCommit / 1024);
    printf("Heap:  %3lu KB reserved, %3lu KB committed\n", header->opt_head.SizeOfHeapReserve / 1024, header->opt_head.SizeOfHeapCommit / 1024);
    printf("Size of headers / offset to sections in file: %#lx\n", header->opt_head.SizeOfHeaders);

    /* look for directories in the headers
     * yes, this happens...
     */
    look_for_directories(base, 0, header->opt_head.SizeOfHeaders, header->opt_head.DataDirectory, 0);

    /* walk through sections */
    {
        int sect;
        const IMAGE_SECTION_HEADER *section_header;
        for (sect = 0, section_header = header->section_header; sect < header->_head.NumberOfSections; sect++, section_header++)
          {                     /* first, dump header */
                          #define indent "    "
              printf("\n\"%.*s\" (virt. Size/Address: %#lx)\n", IMAGE_SIZEOF_SHORT_NAME, section_header->Name, section_header->Misc.VirtualSize);
              printf("  %6lu bytes at offset %#8lx in RAM, %#8lx in file\n", section_header->SizeOfRawData, section_header->VirtualAddress, section_header->PointerToRawData);

              if (section_header->Characteristics & IMAGE_SCN_CNT_CODE)
                  puts(indent "contains code");
              if (section_header->Characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA)
                  puts(indent "contains initialized data");
              if (section_header->Characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA)
                  puts(indent "contains uninitialized data");

              if (section_header->Characteristics & IMAGE_SCN_LNK_INFO)
                  puts(indent "contains comments / information");
              if (section_header->Characteristics & IMAGE_SCN_LNK_REMOVE)
                  puts(indent "contents will not become part of image");
              if (section_header->Characteristics & IMAGE_SCN_LNK_COMDAT)
                  puts(indent "contents is COMDAT (common block data, packaged functions)");
              if (section_header->Characteristics & IMAGE_SCN_MEM_FARDATA)
                  puts(indent "? far data ?");
              if (section_header->Characteristics & IMAGE_SCN_MEM_PURGEABLE)
                  puts(indent "purgeable");
              if (section_header->Characteristics & IMAGE_SCN_MEM_16BIT)
                  puts(indent "? 16-bit-section ?");
              if (section_header->Characteristics & IMAGE_SCN_MEM_LOCKED)
                  puts(indent "locked in memory");
              if (section_header->Characteristics & IMAGE_SCN_MEM_PRELOAD)
                  puts(indent "preload");

              if (!(section_header->Characteristics & IMAGE_SCN_ALIGN_64BYTES))
                  puts(indent "default alignment (16 bytes)");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_1BYTES)
                  puts(indent "1-byte-alignment");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_2BYTES)
                  puts(indent "2-byte-alignment");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_4BYTES)
                  puts(indent "4-byte-alignment");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_8BYTES)
                  puts(indent "8-byte-alignment");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_16BYTES)
                  puts(indent "16-byte-alignment");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_32BYTES)
                  puts(indent "32-byte-alignment");
              else if (section_header->Characteristics & IMAGE_SCN_ALIGN_64BYTES)
                  puts(indent "64-byte-alignment");
              else
                  puts(indent "unknown alignment");

              if (section_header->Characteristics & IMAGE_SCN_LNK_NRELOC_OVFL)
                  puts(indent "contains extended relocations");
              if (section_header->Characteristics & IMAGE_SCN_MEM_DISCARDABLE)
                  puts(indent "can be discarded");
              if (section_header->Characteristics & IMAGE_SCN_MEM_NOT_CACHED)
                  puts(indent "is not cachable");
              if (section_header->Characteristics & IMAGE_SCN_MEM_NOT_PAGED)
                  puts(indent "is not pageable");
              if (section_header->Characteristics & IMAGE_SCN_MEM_SHARED)
                  puts(indent "is shareable");
              if (section_header->Characteristics & IMAGE_SCN_MEM_EXECUTE)
                  puts(indent "is executable");
              if (section_header->Characteristics & IMAGE_SCN_MEM_READ)
                  puts(indent "is readable");
              if (section_header->Characteristics & IMAGE_SCN_MEM_WRITE)
                  puts(indent "is writeable");

              if (isin(header->opt_head.AddressOfEntryPoint, section_header->VirtualAddress, section_header->SizeOfRawData))
                  printf(indent "at offset %#lx: execution start\n", header->opt_head.AddressOfEntryPoint - section_header->VirtualAddress);

              look_for_directories((char *)base + section_header->PointerToRawData,
                                   section_header->VirtualAddress,
                                   section_header->SizeOfRawData,
                                   header->opt_head.DataDirectory,
                                   sizeof(indent) - 1);
                          #undef indent
          }
    }
}


int main(int argc, char **argv)
{
    while (*++argv)
        if (!strcmp(*argv, "-r"))
            do_the_relocs = 1;
        else if (!strcmp(*argv, "-?"))
          {
              fputs("usage: pe_map [-r] file ...\n", stderr);
              return EXIT_FAILURE;
          }
        else
          {
              HANDLE hFile, hMapping;
              void *basepointer;
              printf("filename: %s\n", *argv);
              if ((hFile = CreateFile(*argv, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0)) == INVALID_HANDLE_VALUE)
                {
                    puts("(could not open)");
                    return EXIT_FAILURE;
                }
              if (!(hMapping = CreateFileMapping(hFile, 0, PAGE_READONLY | SEC_COMMIT, 0, 0, 0)))
                {
                    puts("(mapping failed)");
                    CloseHandle(hFile);
                    return EXIT_FAILURE;
                }
              if (!(basepointer = MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0)))
                {
                    puts("(view failed)");
                    CloseHandle(hMapping);
                    CloseHandle(hFile);
                    return EXIT_FAILURE;
                }
              map_exe(basepointer);
              UnmapViewOfFile(basepointer);
              CloseHandle(hMapping);
              CloseHandle(hFile);
              puts("\nVersion Info:");
              print_version_info(*argv);
          }
    return EXIT_SUCCESS;
}
