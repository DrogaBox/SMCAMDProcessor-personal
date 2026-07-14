//
//  pmAMDRyzen.c
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 3/27/20.
//

#include "pmAMDRyzen.h"



x86_lcpu_t *pmRyzen_cpunum_to_lcpu[XNU_MAX_CPU];

void *pmRyzen_io_service_handle;

pmProcessor_t pmRyzen_cpus[XNU_MAX_CPU];
uint64_t pmRyzen_tsc_freq;
uint64_t pmRyzen_effective_timetsc;

uint32_t pmRyzen_num_phys;
uint32_t pmRyzen_num_logi;

uint64_t pmRyzen_exit_idle_c;
uint64_t pmRyzen_exit_idle_ipi_c;
uint64_t pmRyzen_exit_idle_false_c;

uint64_t pmRyzen_p_sdtsc;
uint64_t pmRyzen_p_sutsc;

uint32_t pmRyzen_hpcpus = 0;
volatile uint32_t pmRyzen_pstatelimit;

void(*pmRyzen_pmUnRegister)(pmDispatch_t*) = 0;
void(*pmRyzen_cpu_NMI)(int) = 0;
void(*pmRyzen_NMI_enabled)(boolean_t) = 0;
void(*pmRyzen_cpu_IPI)(int) = 0;



pmDispatch_t pmRyzen_cpuFuncs = {
    .pmCPUStateInit = 0,
    .cstateInit = 0,
    .MachineIdle = &pmRyzen_machine_idle,
    .GetDeadline = 0,
    .SetDeadline = 0,
    .Deadline = 0,
#ifdef PMRYZEN_IDLE_MWAIT
    .exitIdle = &pmRyzen_exit_idle,
#else
    .exitIdle = 0,
#endif
    .markCPURunning = 0,
    .pmCPUControl = 0,
    .pmCPUHalt = 0,
    .getMaxSnoop = 0,
    .setMaxBusDelay = 0,
    .getMaxBusDelay = 0,
    .setMaxIntDelay = 0,
    .getMaxIntDelay = 0,
    .pmCPUSafeMode = 0,
    .pmTimerStateSave = 0,
    .pmTimerStateRestore = 0,
    .exitHalt = 0,
    .exitHaltToOff = 0,
    .markAllCPUsOff = 0,
    .pmSetRunCount = 0,
    .pmIsCPUUnAvailable = 0,
    .pmChooseCPU = &pmRyzen_choose_cpu,
    .pmIPIHandler = 0,
    .pmThreadTellUrgency = 0,
    .pmActiveRTThreads = 0,
    .pmInterruptPrewakeApplicable = 0,
    .pmThreadGoingOffCore = 0,
};

void pmRyzen_init_PState(void){
    uint64_t p0 = pmRyzen_rdmsr_safe(pmRyzen_io_service_handle, MSR_PSTATE_0);
    if (!(p0 & (1ULL << 63))) return;
    
    uint64_t p0dfsid = (p0 >> 8) & 0x3f;
    if (p0dfsid == 0) return;
    
    float p0spd = ((float)(p0 & 0xff) / (float)p0dfsid) * 200.0f;
    
    uint64_t p1 = pmRyzen_rdmsr_safe(pmRyzen_io_service_handle, MSR_PSTATE_0 + 1);
    uint32_t fid_raw = (uint32_t)((p0spd * 0.80f) / 200.0f * (float)((p1 >> 8) & 0x3f));
    if (fid_raw > 0xFF) fid_raw = 0xFF;
    uint64_t p1fid = (uint64_t)fid_raw;
    
    pmRyzen_wrmsr_safe(pmRyzen_io_service_handle, MSR_PSTATE_0 + 1, (p1 & ~0xFFULL) | p1fid | (1ULL << 63));
}

inline void set_PState(pmProcessor_t *cpu, uint8_t state){
    if(pmRyzen_pstatelimit == 0) return;
    if (state >= 8) state = 7;
    state = min((uint8_t)pmRyzen_pstatelimit, state);
    if(cpu->PState == state) return;
    
    boolean_t from_hpstate = !cpu->PState;
    
    pmRyzen_wrmsr_safe(pmRyzen_io_service_handle, MSR_PSTATE_CTL, state);
    cpu->PState = state;
    
    if(!state){
        __asm__ volatile("lock incq (%0)"::"r"(&pmRyzen_hpcpus):"memory");
    } else if(from_hpstate) {
        __asm__ volatile("lock decq (%0)"::"r"(&pmRyzen_hpcpus):"memory");
    }
}

void pmRyzen_doPState_reset(void *arg){
    uint32_t cn = cpu_number();
    pmProcessor_t *self = &pmRyzen_cpus[cn];
    self->PState = 8;
    set_PState(self, 0);
}

void pmRyzen_PState_reset(void){
    pmRyzen_hpcpus = 0;
    if(pmRyzen_pstatelimit == 0) pmRyzen_pstatelimit = 1;
    mp_rendezvous_no_intrs(&pmRyzen_doPState_reset, NULL);
}

void pmRyzen_init(void *handle, int allowDispatch){
    
    pmRyzen_io_service_handle = handle;
    IOLog("AMDRyzenCPUPowerManagement::pmRyzen_init sizeof(pmProcessor_t) = %lu bytes (cacheline aligned)\n", (unsigned long)sizeof(pmProcessor_t));
    
    
    if (!pmRyzen_symtable._pmDispatch || !pmRyzen_symtable._pmUnRegister ||
        !pmRyzen_symtable._tscFreq) {
        IOLog("pmRyzen_init: critical symbols not resolved, aborting\n");
        return;
    }
    
    void **kernelDisp = pmRyzen_symtable._pmDispatch;
    pmRyzen_pmUnRegister = (void(*)(pmDispatch_t*))pmRyzen_symtable._pmUnRegister;
    pmRyzen_cpu_NMI = pmRyzen_symtable._cpu_NMI_interrupt
        ? (void(*)(int))pmRyzen_symtable._cpu_NMI_interrupt : NULL;
    pmRyzen_NMI_enabled = pmRyzen_symtable._NMIPI_enable
        ? (void(*)(boolean_t))pmRyzen_symtable._NMIPI_enable : NULL;
    pmRyzen_cpu_IPI = pmRyzen_symtable._i386_cpu_IPI
        ? (void(*)(int))pmRyzen_symtable._i386_cpu_IPI : NULL;
    pmRyzen_tsc_freq = *((uint64_t*)pmRyzen_symtable._tscFreq);
    
    
    
    pmCallBacks_t cb;
    if (allowDispatch) {
        if(*kernelDisp)(*pmRyzen_pmUnRegister)(*kernelDisp);
        pmKextRegister(PM_DISPATCH_VERSION, &pmRyzen_cpuFuncs, &cb);
    } else {
        pmKextRegister(PM_DISPATCH_VERSION, NULL, &cb);
    }
    
    x86_pkg_t * pkg = cb.GetPkgRoot();
    int pkgCount = 0;
    
    pmRyzen_num_phys = 0;
    pmRyzen_num_logi = 0;
    pmRyzen_hpcpus = 0;
    pmRyzen_pstatelimit = PSTATE_LIMIT;
    
    while(pkg){
        pkgCount++;
        x86_core_t *core = pkg->cores;
        
        while (core) {
            pmRyzen_num_phys++;
            x86_lcpu_t *lcpu = core->lcpus;
            
            while (lcpu) {
                pmRyzen_num_logi++;
                if (lcpu->cpu_num >= XNU_MAX_CPU) {
                    static boolean_t loggedMaxCpu = FALSE;
                    if (!loggedMaxCpu) {
                        loggedMaxCpu = TRUE;
                        IOLog("AMDRyzenCPUPowerManagement ERR: System has CPU %u beyond limit %u. Cores beyond limit will not be managed.\n", lcpu->cpu_num, XNU_MAX_CPU);
                    }
                    lcpu = lcpu->next_in_core;
                    continue;
                }
                
                pmRyzen_cpunum_to_lcpu[lcpu->cpu_num] = lcpu;
                
                pmProcessor_t *cpu = &pmRyzen_cpus[lcpu->cpu_num];
                cpu->lcpu = lcpu;
                cpu->stat_exit_idle = 0;
                cpu->arm_flag = 0;
                cpu->cpu_awake = 1;
                
                lcpu = lcpu->next_in_core;
            }
            
            core = core->next_in_pkg;
        }
        
        pkg = pkg->next;
    }
//    IOLog("pkg c %d\n", pkgCount);

    
    pmRyzen_effective_timetsc = ((double)pmRyzen_tsc_freq * EFF_INTERVAL);
    pmRyzen_p_sdtsc = (uint64_t)((double)pmRyzen_effective_timetsc * PSTATE_STEPDOWN_THRE);
    pmRyzen_p_sutsc = (uint64_t)((double)pmRyzen_effective_timetsc * PSTATE_STEPUP_THRE);
    
    pmRyzen_init_PState();
    pmRyzen_PState_reset();
    
    cb.initComplete();
}

void pmRyzen_stop(void){
    
    if (pmRyzen_pmUnRegister) {
        (*pmRyzen_pmUnRegister)(&pmRyzen_cpuFuncs);
    }
    
    //Make sure all managed cores exited idle thread.
    for (int i = 0; i < pmRyzen_num_logi && i < XNU_MAX_CPU; i++) {
        if (!pmRyzen_cpunum_to_lcpu[i]) continue;
        int retries = 0;
        while(pmRyzen_exit_idle(pmRyzen_cpunum_to_lcpu[i])){
            if (pmRyzen_cpu_IPI) {
                (*pmRyzen_cpu_IPI)(i);
            }
            if (++retries > 1000) {
                IOLog("pmRyzen_stop: CPU %d failed to exit idle after 1000 retries\n", i);
                break;
            }
        }
    }
}



float pmRyzen_avgload_pcpu(uint32_t cpu){
    if (cpu >= XNU_MAX_CPU || !pmRyzen_cpunum_to_lcpu[cpu]) return 0.0f;
    float loadacc = 0;
    int num_lcpus = 0;
    
    x86_lcpu_t *lcpu = pmRyzen_cpunum_to_lcpu[cpu]->core->lcpus;
    while (lcpu) {
        if (lcpu->cpu_num < XNU_MAX_CPU) {
            float idle_ratio = (pmRyzen_cpus[lcpu->cpu_num].eff_timeaccd > 0)
                ? (float)pmRyzen_cpus[lcpu->cpu_num].eff_idleaccd / (float)pmRyzen_cpus[lcpu->cpu_num].eff_timeaccd
                : 0.0f;
            loadacc += 1.0f - idle_ratio;
            num_lcpus++;
        }
        lcpu = lcpu->next_in_core;
    }
    
    if (num_lcpus == 0) return 0.0f;
    return loadacc / (float)num_lcpus;
}


volatile uint32_t pmRyzen_last_woken_cpu=0;
//uint32_t pmRyzen_last_idle_cpu=0;
uint64_t pmRyzen_machine_idle(uint64_t maxDur){

    __asm__ volatile("cli;");
    
    uint32_t cn = cpu_number();
    if (cn >= XNU_MAX_CPU) {
        __asm__ volatile("sti;hlt;");
        return 0;
    }
    pmProcessor_t *self = &pmRyzen_cpus[cn];
    
    
    self->cpu_awake = 0;
    self->arm_flag = 0;
    
    uint64_t tscnow = rdtsc64();

    self->last_idle_tsc = tscnow;
//    self->last_running_time = self->last_idle_tsc - self->last_start_tsc;
    
#ifdef PMRYZEN_IDLE_MWAIT

    void* addr = &self->arm_flag;
    uint32_t ps_hint = 0x50;
    __asm__ volatile("wbinvd":::"memory");
    __asm__ volatile("mfence":::"memory");
    __asm__ volatile("clflushopt %0" : "+m" (*(volatile char *)&self->arm_flag));

    __asm__ volatile("mfence;"
                     "movq %0, %%rax;"
                     "xor %%edx, %%edx;"
                     "xor %%ecx, %%ecx;"
                     "monitor;"
                     "xorq %%rax, %%rax;"
                     "movl %1, %%eax;"
                     "movl $0x1, %%ecx;"
                     "mwait;"
                     :
                     : "r"(addr), "r"(ps_hint)
                     : "%ecx", "%edx", "%rax"
                     );
    
#elif defined(PMRYZEN_IDLE_SIMPLE)
    
    __asm__ volatile("sti;hlt;");
    
#elif defined(PMRYZEN_IDLE_IO_CSTATE)
    
    __asm__ volatile("sti;"
                     "inw $0xf2, %%ax;"
                     "cli;"
                     :::"%eax");
    
#endif

    
    self->cpu_awake = 1;
    if(!self->arm_flag)
        pmRyzen_exit_idle_false_c++;
    
    
    tscnow = rdtsc64();

    uint64_t tscela = tscnow - self->last_idle_tsc;
    self->eff_timeacc += tscnow - self->last_start_tsc;
    self->eff_idleacc += tscela;

    if(self->eff_timeacc > pmRyzen_effective_timetsc){
//        self->eff_load = 1 - (float)self->eff_idleacc / (float)self->eff_timeacc;
        uint64_t rt = self->eff_timeacc - self->eff_idleacc;
        
        //Avoid using xmm registers shared within same core.
        if(rt > pmRyzen_p_sutsc){
            set_PState(self, 0);
            self->ll_count = 0;
        } else if(rt < pmRyzen_p_sdtsc){
            self->ll_count++;
            if(self->ll_count > PSTATE_STEPDOWN_TIME + pmRyzen_hpcpus * PSTATE_STEPDOWN_MP_GAIN){
                self->ll_count = 0;
                set_PState(self, self->PState+1);
            }
        }
        
//        self->eff_load = 1 - (float)self->eff_idleacc / (float)self->eff_timeacc;
        self->eff_idleaccd = self->eff_idleacc;
        self->eff_timeaccd = self->eff_timeacc;
        self->eff_timeacc = 0;
        self->eff_idleacc = 0;

        
//        if(self->eff_load > PSTATE_STEPUP_THRE){
//            set_PState(self, 0);
//            self->ll_count = 0;
//        } else if(self->eff_load < PSTATE_STEPDOWN_THRE){
//            self->ll_count++;
//            if(self->ll_count > PSTATE_STEPDOWN_TIME){
//                set_PState(self, self->PState+1);
//            }
//        }

    }

    self->last_start_tsc = tscnow;
    self->last_idle_length = tscela;
    
    pmRyzen_last_woken_cpu = cn;
    return 0;
}

boolean_t pmRyzen_exit_idle(x86_lcpu_t *lcpu){
    if (!lcpu || lcpu->cpu_num >= XNU_MAX_CPU) return false;
    pmProcessor_t *target = &pmRyzen_cpus[lcpu->cpu_num];

#ifdef PMRYZEN_IDLE_MWAIT
    uint64_t start_tsc = rdtsc64();
    do {
        target->arm_flag = 1;
        __asm__ volatile("pause;");

        if(rdtsc64() - start_tsc > 0x6000){
            //If we still unable to wake up the processor, send an IPI.
            pmRyzen_exit_idle_ipi_c++;
            return true;
        }
    } while(!target->cpu_awake);
    
    return false;
    
#else
    target->arm_flag = 1;
    return false;
#endif
}

int pmRyzen_choose_cpu(int startCPU, int endCPU, int preferredCPU){
    if (preferredCPU >= 0 && preferredCPU < XNU_MAX_CPU && pmRyzen_cpus[preferredCPU].cpu_awake)
        return preferredCPU;

    if (pmRyzen_last_woken_cpu < XNU_MAX_CPU && pmRyzen_cpus[pmRyzen_last_woken_cpu].cpu_awake)
        return pmRyzen_last_woken_cpu;
        
    return preferredCPU;
}

pmProcessor_t* pmRyzen_get_processor(uint32_t cpu){
    if (cpu >= XNU_MAX_CPU) return NULL;
    return &pmRyzen_cpus[cpu];
}
