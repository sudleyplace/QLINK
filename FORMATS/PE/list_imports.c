

    /* list_imports -- list imports of PE files in command line
     *
     * usage:
     *        list_imports [-d] [-q] file1 file2 ...
     *
     * sorry for the lot of casting - it's ugly but it helps :-)
     * (it's necessary because you have to calculate in byte offsets but C pointers
     * increment in pointed-to sizes, and you must change between RVAs and addresses)
     */


#define STRICT
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <getopts.h>


static debugmode;
    /* decide whether to dump debug-output */



    /* dump of import directory */
    /* section begins at pointer 'section base'
     * section RVA is 'section_rva'
     * import directory begins at pointer 'imp'
     * I left out all the bound/unbound stuff, and left out support for broken Borland linkers
     * (see 'pe_map.c' for complete version)
     */
static int dump_import_directory(const void *const section_base, const DWORD section_rva, const IMAGE_IMPORT_DESCRIPTOR * imp)
{
    /* get memory address given the RVA */
    #define adr(rva) ((const void*)((char*)section_base+((DWORD)(rva))-section_rva))

    /* continue until address inaccessible or there's no DLL name */
    for (; !IsBadReadPtr(imp, sizeof(*imp)) && imp->Name; imp++)
      {
          const IMAGE_THUNK_DATA *import_entry;

            /* output DLL's name */
          printf("\nfrom \"%s\":\n", (char *)adr(imp->Name));

          if(debugmode)
            printf("name table at %#lx, address table at %#lx\n",(unsigned long)imp->OriginalFirstThunk,(unsigned long)imp->FirstThunk);

          import_entry = adr(imp->OriginalFirstThunk);

            /* listing header */
          printf("%6s %s\n", "hint", "name");
          printf("%6s %s\n", "----", "----");

            /* loop to enumerate imported functions
             * ends when 0-bytes in name/ordinal found
             */
          for (; import_entry->u1.Ordinal; import_entry++)
            {
                    /* nameless import */
                if (IMAGE_SNAP_BY_ORDINAL(import_entry->u1.Ordinal))
                    printf("%6lu <ordinal>\n", IMAGE_ORDINAL(import_entry->u1.Ordinal));
                else
                  {     /* import with name */
                      const IMAGE_IMPORT_BY_NAME *name_import = adr(import_entry->u1.AddressOfData);
                        /* careful string output - some DLLs have horrible names */
                      printf("%6u %-20.50s\n", name_import->Hint, name_import->Name);
                  }
            }
      }


      /* was the loop ended because memory was not readable? */
    if (IsBadReadPtr(imp, sizeof(*imp)))
        {
            puts("!! import directory ended unexpectedly !!");
            return 1;
        }

    #undef adr

    return 0;
}


    /* load a file in RAM (memory-mapped)
     * return pointrer to loaded file
     * 0 if no success
     */
static void *get_mapped_file(const char *filename)
{
    HANDLE hFile, hMapping;
    void *basepointer;
    if ((hFile = CreateFile(filename, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0)) == INVALID_HANDLE_VALUE)
      {
          if(debugmode) puts("(could not open)");
          return 0;
      }
    if (!(hMapping = CreateFileMapping(hFile, 0, PAGE_READONLY | SEC_COMMIT, 0, 0, 0)))
      {
          if(debugmode) puts("(mapping failed)");
          CloseHandle(hFile);
          return 0;
      }
    if (!(basepointer = MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0)))
      {
          if(debugmode) puts("(view failed)");
          CloseHandle(hMapping);
          CloseHandle(hFile);
          return 0;
      }
    
    CloseHandle(hMapping);
    CloseHandle(hFile);

    return basepointer;
}


    /* this will return a pointer immediatly behind the DOS-header
     * 0 if error
     */
static void * skip_dos_stub(const IMAGE_DOS_HEADER * dos_ptr)
{
    /* look there's enough space for a DOS-header */
    if (IsBadReadPtr(dos_ptr, sizeof(*dos_ptr)))
        {
            puts("not enough space for DOS-header");
            return 0;
        }

     /* validate MZ */
     if (dos_ptr->e_magic != IMAGE_DOS_SIGNATURE)
        {
            puts("not a DOS-stub");
            return 0;
        }

    /* ok, then, go get it */
    return (char*)dos_ptr + dos_ptr->e_lfanew;
}


    /* find the directory's section index given the RVA
     * Returns -1 if impossible
     */
static int get_directory_index(const unsigned dir_rva, const unsigned dir_length, const int number_of_sections, const IMAGE_SECTION_HEADER *sections)
{
    int sect;
    int index = -1;
    
    for(sect=0;sect<number_of_sections;sect++)
    {
        /* output section data */
        if(debugmode)
            printf("section \"%.*s\": RVA %#lx, offset %#lx, length %#lx\n",
                    (int)IMAGE_SIZEOF_SHORT_NAME,
                    sections[sect].Name,
                    (unsigned long)sections[sect].PointerToRawData,
                    (unsigned long)sections[sect].VirtualAddress,
                    (unsigned long)sections[sect].SizeOfRawData
                   );

        /* compare directory RVA to section RVA */
        if(sections[sect].VirtualAddress<=dir_rva && dir_rva<sections[sect].VirtualAddress+sections[sect].SizeOfRawData)
            {
                if(debugmode)
                {
                    puts("  (taken this one)");
                    index = sect;
                }
                else
                    return sect;
            }
    }

    return index;
}


    /* dump imports of a single file
     * Returns 0 if successful, !=0 else
     * *** action starts here ***
     */
static int process_file(const char *filename)
{
    const void *basepointer;    /* Points to loaded PE file
                                 * This is memory mapped stuff
                                 */
    int number_of_sections;
    DWORD import_rva;           /* RVA of import directory */
    DWORD import_length;        /* length of import directory */
    int import_index;           /* index of section with import directory */

        /* ensure byte-alignment for struct tag_header
         * sorry, but it's necessary
         */
    #include <pshpack1.h>

    const struct tag_header
      {
          DWORD signature;
          IMAGE_FILE_HEADER file_head;
          IMAGE_OPTIONAL_HEADER opt_head;
          IMAGE_SECTION_HEADER section_header[];  /* this is an array of unknown length
                                                   * actual number in file_head.NumberOfSections
                                                   * if your compiler objects to it length 1 should work
                                                   */
      } *header;

      /* revert to regular alignment */
    #include <poppack.h>

      
    if (debugmode)
        printf("starting to process \"%s\"\n", filename);
    else
        puts(filename);

    /* first, load file */
    basepointer = get_mapped_file(filename);
    if (!basepointer)
        {
            puts("cannot load file");
            return 1;
        }

    /* get header pointer; validate a little bit */
    header = skip_dos_stub(basepointer);
    if (!header)
        {
            puts("cannot skip DOS stub");
            UnmapViewOfFile(basepointer);
            return 2;
        }

    /* look there's enough space for PE headers */
    if(IsBadReadPtr(header, sizeof(*header)))
        {
            puts("not enough space for PE headers");
            UnmapViewOfFile(basepointer);
            return 3;
        }

    /* validate PE signature */
    if(header->signature!=IMAGE_NT_SIGNATURE)
        {
            puts("not a PE file");
            UnmapViewOfFile(basepointer);
            return 4;
        }
    

    /* some debug output */
    if (debugmode)
        printf("file header at %#lx\n"
               "optional header at %#lx\n"
               "data directories at %#lx\n"
               "section headers at %#lx\n",
               (unsigned long)(long)((char*)header - (char*)basepointer + offsetof(struct tag_header,file_head)),
               (unsigned long)(long)((char*)header - (char*)basepointer + offsetof(struct tag_header,opt_head)),
               (unsigned long)(long)((char*)header - (char*)basepointer + offsetof(struct tag_header,opt_head) + offsetof(IMAGE_OPTIONAL_HEADER,DataDirectory)),
               (unsigned long)(long)((char*)header - (char*)basepointer + offsetof(struct tag_header,section_header))
              );

    /* get number of sections */
    number_of_sections = header->file_head.NumberOfSections;
    if(debugmode)
        printf("%d sections\n",number_of_sections);

    /* check there are sections... */
    if(number_of_sections<1)
        {
            puts("no sections???");
            UnmapViewOfFile(basepointer);
            return 5;
        }

    /* validate there's enough space for section headers */
    if(IsBadReadPtr(header->section_header, number_of_sections*sizeof(IMAGE_SECTION_HEADER)))
        {
            puts("not enough space for section headers");
            UnmapViewOfFile(basepointer);
            return 6;
        }

    /* get RVA and length of import directory */
    import_rva = header->opt_head.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
    import_length = header->opt_head.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size;

    if(debugmode)
            printf("import directory at offset %#lx, length %#lx\n",(unsigned long)import_rva,(unsigned long)import_length);

    /* check there's stuff to care about */
    if(!import_rva || !import_length)
        {
            puts("no imports");
            UnmapViewOfFile(basepointer);
            return 0;       /* success! */
        }

    /* get import directory pointer */
    import_index = get_directory_index(import_rva,import_length,number_of_sections,header->section_header);

    /* check directory was found */
    if(import_index <0)
        {
            puts("couldn't find import directory in sections");
            UnmapViewOfFile(basepointer);
            return 7;
        }

    /* ok, we've found the import directory... action! */
    {
        /* The pointer to the start of the import directory's section */
      const void * section_address = (char*)basepointer + header->section_header[import_index].PointerToRawData;
      if(dump_import_directory(section_address,
                               header->section_header[import_index].VirtualAddress,
                                        /* the last parameter is the pointer to the import directory:
                                         * section address + (import RVA - section RVA)
                                         * The difference is the offset of the import directory in the section
                                         */
                               (void*)((char*)section_address+import_rva-header->section_header[import_index].VirtualAddress)))
        {
            UnmapViewOfFile(basepointer);
            return 8;
        }
    }
    
    UnmapViewOfFile(basepointer);
    return 0;
}



int main(int argc, char **argv)
{
    /* handle command line switches and filenames */
    for (;;)
        switch (getopt(argc, argv, "dq"))
          {
              case 0:
                  if (process_file(optarg))
                    {
                        puts("no happy - aborting");
                        return EXIT_FAILURE;
                    }
                  else
                      break;
              case '?':
                  fputs("usage: list_imports {[-d|-q|-?|file}\n", stderr);
                  return EXIT_FAILURE;
              case 'd':
                  debugmode = 1;
                  break;
              case 'q':
                  debugmode = 0;
                  break;
              case EOF:
                  return EXIT_SUCCESS;  /* done */
          }
}
