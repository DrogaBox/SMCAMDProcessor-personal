#ifndef kernel_resolver_h
#define kernel_resolver_h

//
// kernel_resolver — fragile dynamic symbol resolution for private kernel APIs.
//
// K-01: This module uses heuristic-based kernel base address discovery
// (walking Mach-O headers, _mh_execute_header / _version anchors, KASLR
// slide calculation) to resolve symbols that Apple does not export.
//
// RISK: The internal kernel ABI — struct offsets, function signatures,
// symbol presence — changes across macOS minor versions without notice.
// A future kernel update can silently break:
//   - Mach-O header iteration (MH_MAGIC_64 mismatch)
//   - Symbol table parsing (nlist_64 format change)
//   - KASLR slide calculation (new kernel layout)
//   - Required symbol removal or renaming
//
// This is an accepted architectural tradeoff: there is no public API for
// SMU mailbox access, CPPC MSR read/write, or CCD temperature reporting.
// Without this resolver, those features cannot exist. The resolver must be
// validated against every new macOS release before shipping an update.
//

#include <IOKit/IOLib.h>
#include <mach/mach_types.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <sys/systm.h>
#include <sys/types.h>
#include <vm/vm_kern.h>
#include <sys/sysctl.h>



typedef struct mach_header_64 mach_header_64_t;
typedef struct load_command load_command_t;
typedef struct segment_command_64 seg_command_64_t;
typedef struct nlist_64 nlist_64_t;
typedef struct symtab_command symtab_command_t;

#ifdef __cplusplus
extern "C" {
#endif
void find_mach_header_addr(uint8_t kc);
void *lookup_symbol(const char *symbol);
void print_pointer(void *ptr);
    
#ifdef __cplusplus
}
#endif

#endif /* kernel_resolver_h */

