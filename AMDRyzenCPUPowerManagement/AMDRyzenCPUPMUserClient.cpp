//
//  AMDRyzenCPUPowerManagementUserClient.cpp
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 2/4/20.
//

#include "AMDRyzenCPUPMUserClient.hpp"

OSDefineMetaClassAndStructors(AMDRyzenCPUPMUserClient, IOUserClient);


bool AMDRyzenCPUPMUserClient::initWithTask(task_t owningTask,
                                             void *securityToken,
                                             UInt32 type,
                                             OSDictionary *properties){
    
    if(!IOUserClient::initWithTask(owningTask, securityToken, type, properties)){
        return false;
    }
    
    token = securityToken;
    clientAuthorizedByUser = false;
    
    proc_t proc = (proc_t)get_bsdtask_info(owningTask);
    if (!proc) return false;
    
    proc_name(proc_pid(proc), taskProcessBinaryName, sizeof(taskProcessBinaryName));
    taskProcessBinaryName[sizeof(taskProcessBinaryName) - 1] = '\0';
    
    bool isRoot = (proc_suser(proc) == 0 || kauth_cred_getuid(proc_ucred(proc)) == 0);
    bool isKnownApp = (strncmp(taskProcessBinaryName, "AMD Power Gadget", 16) == 0 ||
                       strncmp(taskProcessBinaryName, "SMCAMDProcessor", 15) == 0);
                       
    if (isRoot || isKnownApp) {
        clientAuthorizedByUser = true;
    } else {
        IOLog("AMDRyzenCPUPMUserClient: Connection attempt from unauthorized process: %s\n", taskProcessBinaryName);
    }
    
    return true;
}

bool AMDRyzenCPUPMUserClient::start(IOService *provider){
    IOLog("AMDRyzenCPUPMUserClient::start\n");
    bool success = IOService::start(provider);
    if(success){
        fProvider = OSDynamicCast(AMDRyzenCPUPowerManagement, provider);
    }
    return success;
}

void AMDRyzenCPUPMUserClient::stop(IOService *provider){
    IOLog("AMDRyzenCPUPMUserClient::stop\n");
    fProvider = nullptr;
    IOService::stop(provider);
}

bool AMDRyzenCPUPMUserClient::hasPrivilege(){
    if (clientAuthorizedByUser) return true;
    if (fProvider && fProvider->disablePrivilegeCheck) return true; // -amdpnopchk
    proc_t proc = (proc_t)get_bsdtask_info(current_task());
    if (proc && (proc_suser(proc) == 0 || kauth_cred_getuid(proc_ucred(proc)) == 0)) return true;
    return false;
}

IOReturn AMDRyzenCPUPMUserClient::externalMethod(uint32_t selector, IOExternalMethodArguments *arguments,
                                                 IOExternalMethodDispatch *dispatch,
                                                   OSObject *target, void *reference){
    
    if (!fProvider) return kIOReturnNotReady;
    
    if (fProvider->kextloadAlerts && fProvider->kunc_alert) {
        unsigned int rf;
        
        char buf[128];
        snprintf(buf, 128,
                 "Kext alert detected: %d",
                 fProvider->kextloadAlerts);
        
        (*(fProvider->kunc_alert))(0, 0, NULL, NULL, NULL,
                      "AMDRyzenCPUPowerManagement", buf, "Ok", "Ok and Clear Alert", "WTF?", &rf);
        if(rf == 1){
            fProvider->kextloadAlerts = 0;
        }
    }
    
    fProvider->registerRequest();
    
    switch (selector) {
            
        //Get PStateDef raw values for core 0
        case 0: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (fProvider->kMSR_PSTATE_LEN) * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < fProvider->kMSR_PSTATE_LEN) ? (maxLen / sizeof(uint64_t)) : fProvider->kMSR_PSTATE_LEN;
            
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = fProvider->PStateDef_perCore[i];
            }
            
            break;
        }
            
            
        //Get PStateDef floating point clock values for core 0
        case 1: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (fProvider->kMSR_PSTATE_LEN) * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(float) < fProvider->kMSR_PSTATE_LEN) ? (maxLen / sizeof(float)) : fProvider->kMSR_PSTATE_LEN;
            
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = fProvider->PStateDefClock_perCore[i];
            }
            
            break;
        }
            
        case 2: {
            uint32_t numPhyCores = fProvider->totalNumberOfPhysicalCores;

            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = numPhyCores;
            
            uint32_t requiredSize = numPhyCores * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(float) < numPhyCores) ? (maxLen / sizeof(float)) : numPhyCores;

            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = fProvider->effFreq_perCore[i];
            }
            
            break;
        }
        
        case 3: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 1 * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            float *dataOut = (float*) arguments->structureOutput;
            if (maxLen >= sizeof(float)) {
                dataOut[0] = fProvider->PACKAGE_TEMPERATURE_perPackage[0];
            }
            break;
        }
        
        //Get all data like this: [power, temp, pstateCur, clock_core_1, 2, 3 .....]
        //Yes, i am too lazy to write a struct
        case 4: {
            uint32_t numPhyCores = fProvider->totalNumberOfPhysicalCores;
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = numPhyCores;
            
            uint32_t requiredSize = (numPhyCores + 3) * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            
            if (maxLen >= sizeof(float)) {
                dataOut[0] = (float)fProvider->uniPackageEnergy;
            }
            if (maxLen >= 2 * sizeof(float)) {
                dataOut[1] = fProvider->PACKAGE_TEMPERATURE_perPackage[0];
            }
            if (maxLen >= 3 * sizeof(float)) {
                dataOut[2] = fProvider->PStateCtl;
            }
            
            uint32_t copyCount = 0;
            if (maxLen > 3 * sizeof(float)) {
                copyCount = (maxLen - 3 * sizeof(float)) / sizeof(float);
            }
            if (copyCount > numPhyCores) {
                copyCount = numPhyCores;
            }
            
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i + 3] = fProvider->effFreq_perCore[i];
            }
            
            break;
        }
            
        //Get per core raw load index
        case 5: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = 0;
                uint32_t numLogCores = fProvider->totalNumberOfLogicalCores;
                if (numLogCores > CPUInfo::MaxCpus) {
                    numLogCores = CPUInfo::MaxCpus;
                }
                for(uint32_t i = 0; i < numLogCores; i++){
                    dataOut[0] += fProvider->instructionDelta_perCore[i];
                }
            }
            
            break;
        }
            
        //Get per core load index
        case 6: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (fProvider->totalNumberOfPhysicalCores) * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            
            int lcpu_percore = 1;
            if (fProvider->totalNumberOfPhysicalCores > 0) {
                lcpu_percore = fProvider->totalNumberOfLogicalCores / fProvider->totalNumberOfPhysicalCores;
            }
            if (lcpu_percore <= 0) {
                lcpu_percore = 1;
            }
            
            uint32_t copyCount = (maxLen / sizeof(float) < fProvider->totalNumberOfPhysicalCores) ? (maxLen / sizeof(float)) : fProvider->totalNumberOfPhysicalCores;
            
            for(uint32_t i = 0; i < copyCount; i++){
                float l = pmRyzen_avgload_pcpu(i * lcpu_percore);
                dataOut[i] = l;
            }
            
            break;
        }
            
        //Get basic CPUID
        //[Family, Model, Physical, Logical, L1_perCore, L2_perCore, L3]
        case 7: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (8) * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < 8) ? (maxLen / sizeof(uint64_t)) : 8;
            
            if (copyCount > 0) dataOut[0] = (uint64_t)fProvider->cpuFamily;
            if (copyCount > 1) dataOut[1] = (uint64_t)fProvider->cpuModel;
            if (copyCount > 2) dataOut[2] = (uint64_t)fProvider->totalNumberOfPhysicalCores;
            if (copyCount > 3) dataOut[3] = (uint64_t)fProvider->totalNumberOfLogicalCores;
            if (copyCount > 4) dataOut[4] = (uint64_t)fProvider->cpuCacheL1_perCore;
            if (copyCount > 5) dataOut[5] = (uint64_t)fProvider->cpuCacheL2_perCore;
            if (copyCount > 6) dataOut[6] = (uint64_t)fProvider->cpuCacheL3;
            if (copyCount > 7) dataOut[7] = (uint64_t)fProvider->cpuSupportedByCurrentVersion;
            
            break;
        }
        
        //Get AMDRyzenCPUPowerManagement Version String
        case 8: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = sizeof(xStringify(MODULE_VERSION));
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            uint32_t copyLen = (maxLen < requiredSize) ? maxLen : requiredSize;
            for (uint32_t i = 0; i < copyLen; i++) {
                dataOut[i] = xStringify(MODULE_VERSION)[i];
            }
            
            break;
        }
        
        //Get PState
        case 9: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = fProvider->PStateCtl;
            }
            
            break;
        }
        
        //Set PState
        case 10: {
            if(!hasPrivilege()) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            fProvider->PStateCtl = (uint8_t)arguments->scalarInput[0];
            fProvider->applyPowerControl();
            break;
        }

        // Zero-copy streaming structured telemetry packet (Task 1.2)
        case 100: {
            arguments->scalarOutputCount = 0;
            uint32_t requiredSize = sizeof(AMDRyzenCPUPowerManagement::CPUSensorPacket);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput || maxLen < requiredSize) {
                return kIOReturnBadArgument;
            }
            
            AMDRyzenCPUPowerManagement::CPUSensorPacket *packet = (AMDRyzenCPUPowerManagement::CPUSensorPacket*) arguments->structureOutput;
            packet->packagePowerW = (float)fProvider->uniPackageEnergy;
            packet->packageTempC = fProvider->PACKAGE_TEMPERATURE_perPackage[0];
            packet->numLogicalCores = fProvider->totalNumberOfLogicalCores;
            packet->ccdCount = fProvider->ccdCount;
            for (uint32_t i = 0; i < 8; i++) {
                packet->ccdTemperatures[i] = (i < fProvider->ccdCount) ? fProvider->ccdTemperatures[i] : 0.0f;
            }
            for (uint32_t i = 0; i < 64 && i < fProvider->totalNumberOfLogicalCores; i++) {
                uint32_t phys = (fProvider->totalNumberOfPhysicalCores > 0)
                    ? (i % fProvider->totalNumberOfPhysicalCores) : i;
                packet->coreFrequenciesMHz[i] = fProvider->effFreq_perCore[phys];
            }
            break;
        }
            
        //Get CPB
        case 11: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 2 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)fProvider->cpbSupported;
            }
            if (maxLen >= 2 * sizeof(uint64_t)) {
                dataOut[1] = (uint64_t)fProvider->getCPBState();
            }
            break;
        }
        
        //Set CPB
        case 12: {
            if(!hasPrivilege()) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            if(!fProvider->cpbSupported)
                return kIOReturnNoDevice;
            
            fProvider->setCPBState(arguments->scalarInput[0]==1?true:false);
            
            break;
        }
            
        //Get PPM
        case 13: {
            arguments->scalarOutputCount = 0;
                
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
                
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(fProvider->getPMPStateLimit() == 0 ? 0 : 1);
            }
            break;
        }
            
        //Set PPM
        case 14: {
            if(!hasPrivilege()) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
                
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            boolean_t enabled = arguments->scalarInput[0]==1?true:false;
            
            fProvider->setPMPStateLimit(enabled ? 1 : 0);
            
            break;
        }
            
        //Set PStateDef
        case 15: {
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 8)
                return kIOReturnBadArgument;
            
            
            fProvider->writePstate(arguments->scalarInput);
            
            break;
        }
            
        //get board info
        case 16: {
            //Let's give that one more try :)
            if(!fProvider->boardInfoValid)
                fProvider->fetchOEMBaseBoardInfo();
            
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = fProvider->boardInfoValid ? 1 : 0;
            
            uint32_t requiredSize = 128;
            uint32_t maxLen = arguments->structureOutputSize;
            uint32_t copyLen = maxLen < requiredSize ? maxLen : requiredSize;
            arguments->structureOutputSize = copyLen;
            
            if (!arguments->structureOutput || maxLen == 0) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            memset(dataOut, 0, maxLen);
            
            if (copyLen > 0) {
                size_t vendorCopy = copyLen < 64 ? copyLen : 64;
                strlcpy(dataOut, fProvider->boardVendor, vendorCopy);
            }
            if (copyLen > 64) {
                size_t nameCopy = (copyLen - 64) < 64 ? (copyLen - 64) : 64;
                strlcpy(dataOut + 64, fProvider->boardName, nameCopy);
            }
            
            break;
        }
            
        case 17: {
            arguments->scalarOutputCount = 0;
                
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
                
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(fProvider->getHPcpus());
            }
            break;
        }
        
        //Get LPM
        case 18: {
            arguments->scalarOutputCount = 0;
                
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
                
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(fProvider->getPMPStateLimit() == 2 ? 1 : 0);
            }
            break;
        }
            
        //Set LPM
        case 19: {
            if(!hasPrivilege()) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
                
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            boolean_t enabled = arguments->scalarInput[0]==1?true:false;
            
            fProvider->setPMPStateLimit(enabled ? 2 : 1);
            
            break;
        }
            
        //Get CCD temperatures
        case 20: {
            uint32_t ccdCount = fProvider->ccdCount;
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = ccdCount;
            
            uint32_t requiredSize = ccdCount * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(float) < ccdCount) ? (maxLen / sizeof(float)) : ccdCount;
            
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = fProvider->ccdTemperatures[i];
            }
            
            break;
        }
        
        // Get CPPC Highest Performance values per logical core
        case 21: {
            uint32_t numLogicalCores = fProvider->totalNumberOfLogicalCores;

            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = fProvider->cppcSupported ? 1 : 0;
            
            uint32_t requiredSize = numLogicalCores * sizeof(uint8_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint8_t *dataOut = (uint8_t*) arguments->structureOutput;
            uint32_t copyLen = (maxLen < requiredSize) ? maxLen : requiredSize;
            
            for(uint32_t i = 0; i < copyLen; i++) {
                dataOut[i] = fProvider->cppcHighestPerf_perCore[i];
            }
            break;
        }

        // Get C-State address configuration
        case 22: {
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = fProvider->cstateAddrConfig;
            
            break;
        }
        
        // Get CPPC Active Mode status and current EPP value
        case 23: {
            arguments->scalarOutputCount = 2;
            arguments->scalarOutput[0] = fProvider->cppcActiveMode ? 1 : 0;
            arguments->scalarOutput[1] = fProvider->cppcEPPValue;
            
            break;
        }
        
        // Set CPPC Active Mode status
        case 24: {
            if (!hasPrivilege())
                return kIOReturnNotPrivileged;
                
            if (arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            fProvider->cppcActiveMode = (arguments->scalarInput[0] == 1);
            if (fProvider->cppcActiveMode) {
                fProvider->applyEPPControl();
            }
            
            break;
        }
        
        // Set CPPC EPP Value
        case 25: {
            if (!hasPrivilege())
                return kIOReturnNotPrivileged;
                
            if (arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            fProvider->cppcEPPValue = (uint8_t)arguments->scalarInput[0];
            if (fProvider->cppcActiveMode) {
                fProvider->applyEPPControl();
            }
            
            break;
        }
        
        //Try load SMC driver
        case 90: {
            arguments->scalarOutputCount = 0;
            uint32_t requiredSize = 2 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            if(fProvider->superIO != nullptr){
                if (maxLen >= sizeof(uint64_t)) {
                    dataOut[0] = (uint64_t)(1);
                }
                if (maxLen >= 2 * sizeof(uint64_t)) {
                    dataOut[1] = (uint64_t)(fProvider->savedSMCChipIntel);
                }
                break;
            }
            
            uint16_t ci = 0;
            bool found = fProvider->initSuperIO(&ci);
            
            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(found ? 1 : 0);
            }
            if (maxLen >= 2 * sizeof(uint64_t)) {
                dataOut[1] = (uint64_t)(ci);
            }
            
            break;
        }
        
        //SMC load number of fans
        case 91: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;

            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(fProvider->superIO->getNumberOfFans());
            }
            break;
        }
        
        //SMC load readable desc for fan
        case 92: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;

            arguments->scalarOutputCount = 0;
                
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            const char *str = fProvider->superIO->getReadableStringForFan((int)arguments->scalarInput[0]);
            if (!str) {
                str = "";
            }
            
            uint32_t maxLen = arguments->structureOutputSize;
            if (!arguments->structureOutput || maxLen == 0) {
                arguments->structureOutputSize = 0;
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            strlcpy(dataOut, str, maxLen);
            arguments->structureOutputSize = (uint32_t)strlen(dataOut);
            
            break;
        }
            
        //SMC fan rpms
        case 93: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;
            
            uint32_t numFans = fProvider->superIO->getNumberOfFans();
            uint32_t requiredSize = numFans * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            UInt32 currentCount = OSIncrementAtomic(&fProvider->fanUpdateCounter);
            if ((currentCount % 4) == 0) {
                IOLockLock(fProvider->superIOLock);
                fProvider->superIO->updateFanRPMS();
                IOLockUnlock(fProvider->superIOLock);
            }
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < numFans) ? (maxLen / sizeof(uint64_t)) : numFans;
            
            IOLockLock(fProvider->superIOLock);
            for (uint32_t i = 0; i < copyCount; i++) {
                dataOut[i] = fProvider->superIO->getRPMForFan(i);
            }
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        //SMC fan throttles and control mode
        case 94: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;
            
            uint32_t numFans = fProvider->superIO->getNumberOfFans();
            uint32_t requiredSize = numFans * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            UInt32 snap94 = (UInt32)OSAddAtomic(0, (SInt32*)&fProvider->fanUpdateCounter);
            if ((snap94 % 4) == 0) {
                IOLockLock(fProvider->superIOLock);
                fProvider->superIO->updateFanControl();
                IOLockUnlock(fProvider->superIOLock);
            }
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < numFans) ? (maxLen / sizeof(uint64_t)) : numFans;
            
            IOLockLock(fProvider->superIOLock);
            for (uint32_t i = 0; i < copyCount; i++) {
                dataOut[i] = fProvider->superIO->getFanThrottle(i) << 8 | (fProvider->superIO->getFanAutoControlMode(i) ? 1 : 0);
            }
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        //SMC fan override control
        case 95: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 2)
                return kIOReturnBadArgument;
            
            int fanSel = (int)arguments->scalarInput[0];
            uint8_t pwm = (uint8_t)arguments->scalarInput[1];
            
            IOLockLock(fProvider->superIOLock);
            fProvider->superIO->overrideFanControl(fanSel, pwm);
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        //SMC fan default control
        case 96: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            int fanSel = (int)arguments->scalarInput[0];
            
            IOLockLock(fProvider->superIOLock);
            fProvider->superIO->setDefaultFanControl(fanSel);
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        //SMC Secret Undocumented feature (⁎⁍̴̛ᴗ⁍̴̛⁎) - Capped at 80% PWM (0xC8) for hardware safety
        case 97: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            int numFan = fProvider->superIO->getNumberOfFans();
            IOLockLock(fProvider->superIOLock);
            for (int i = 0; i < numFan; i++) {
                if(arguments->scalarInput[0])
                    fProvider->superIO->overrideFanControl(i, 0xC8);
                else
                    fProvider->superIO->setDefaultFanControl(i);
            }
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        // Read raw SuperIO register
        case 98: {
            if(!fProvider || !fProvider->superIO)
                return kIOReturnNoDevice;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            uint16_t reg = (uint16_t)arguments->scalarInput[0];
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t maxLen = arguments->structureOutputSize;
            
            if (!arguments->structureOutput || maxLen < sizeof(uint64_t))
                return kIOReturnBadArgument;
            
            IOLockLock(fProvider->superIOLock);
            uint8_t val = fProvider->superIO->readReg(reg);
            IOLockUnlock(fProvider->superIOLock);
            
            dataOut[0] = val;
            arguments->structureOutputSize = sizeof(uint64_t);
            break;
        }
        
        // Write raw SuperIO register
        case 99: {
            if(!fProvider || !fProvider->superIO)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 2)
                return kIOReturnBadArgument;
            
            uint16_t reg = (uint16_t)arguments->scalarInput[0];
            uint8_t val = (uint8_t)arguments->scalarInput[1];
            
            IOLockLock(fProvider->superIOLock);
            fProvider->superIO->writeReg(reg, val);
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        // Update fan curve LUT and parameters
        case 101: {
            if(!fProvider)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
                
            if (!arguments->structureInput || arguments->structureInputSize < 272) {
                return kIOReturnBadArgument;
            }
            
            struct FanCurveInput {
                uint32_t curveIndex;
                uint32_t sourceSensor;
                uint32_t hysteresis;
                uint32_t rampRate;
                uint8_t lut[256];
            };
            
            const FanCurveInput *input = (const FanCurveInput*) arguments->structureInput;
            uint32_t idx = input->curveIndex;
            if (idx >= MAX_FAN_CURVES) {
                return kIOReturnBadArgument;
            }
            
            IOLockLock(fProvider->superIOLock);
            fProvider->fanCurves[idx].sourceSensor = (uint8_t)input->sourceSensor;
            fProvider->fanCurves[idx].hysteresis   = (uint8_t)input->hysteresis;
            fProvider->fanCurves[idx].rampRate     = (uint8_t)input->rampRate;
            memcpy(fProvider->fanCurves[idx].lut, input->lut, 256);
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        // Map physical fan to curve
        case 102: {
            if(!fProvider)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
                
            if (arguments->scalarInputCount != 2) {
                return kIOReturnBadArgument;
            }
            
            int fanIdx = (int)arguments->scalarInput[0];
            int curveIdx = (int)arguments->scalarInput[1];
            
            if (fanIdx < 0 || fanIdx >= 16 || curveIdx < -1 || curveIdx >= MAX_FAN_CURVES) {
                return kIOReturnBadArgument;
            }
            
            IOLockLock(fProvider->superIOLock);
            fProvider->fanToCurveMap[fanIdx] = (int8_t)curveIdx;
            // If mapping to Auto, restore default fan control
            if (curveIdx == -1 && fProvider->superIO) {
                fProvider->superIO->setDefaultFanControl(fanIdx);
            }
            IOLockUnlock(fProvider->superIOLock);
            
            break;
        }
        
        // Set GPU temperature
        case 103: {
            if(!fProvider)
                return kIOReturnNoDevice;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            fProvider->gpuTempC = (float)arguments->scalarInput[0];
            
            break;
        }
        
        default: {
            IOLog("AMDRyzenCPUPMUserClient::externalMethod: invalid method.\n");
            break;
        }
    }
    
    return kIOReturnSuccess;
}
