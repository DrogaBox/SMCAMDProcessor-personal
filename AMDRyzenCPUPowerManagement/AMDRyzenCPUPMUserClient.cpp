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
    
    proc_t proc = (proc_t)get_bsdtask_info(owningTask);
    proc_name(proc_pid(proc), taskProcessBinaryName, 32);
    clientAuthorizedByUser = false;
    

    
    return true;

}

bool AMDRyzenCPUPMUserClient::start(IOService *provider){
    
    IOLog("AMDCPUSupportUserClient::start\n");
    
    bool success = IOService::start(provider);
    
    if(success){
        fProvider = OSDynamicCast(AMDRyzenCPUPowerManagement, provider);
    }
    
    return success;
}

void AMDRyzenCPUPMUserClient::stop(IOService *provider){
    IOLog("AMDCPUSupportUserClient::stop\n");
    
    fProvider = nullptr;
    IOService::stop(provider);
}

//this is a meme, not getting the joke? nvm.
uint64_t multiply_two_numbers(uint64_t number_one, uint64_t number_two){
    uint64_t number_three = 0;
    for(uint32_t i = 0; i < number_two; i++){
        number_three = number_three + number_one;
    }
    return number_three;
}

bool AMDRyzenCPUPMUserClient::hasPrivilege(){
    if(fProvider->disablePrivilegeCheck) return true;
    if(clientHasPrivilege(token, kIOClientPrivilegeAdministrator) == kIOReturnSuccess) return true;
    if(clientAuthorizedByUser) return true;
    
    char buf[128];
    snprintf(buf, 128,
             "A process is trying to make changes to your system.\nAffected process name: %s\n\nAuthorize?",
             taskProcessBinaryName);
    
    unsigned int rf;
    (*(fProvider->kunc_alert))(0, 0, NULL, NULL, NULL,
                  "AMDRyzenCPUPowerManagement", buf, "Deny", "Until Process Terminate", "Once", &rf);
    
    
    if(rf == 1){
        clientAuthorizedByUser = true;
        return true;
    }
    
    if(rf == 2){
        return true;
    }
    
    return false;
}

IOReturn AMDRyzenCPUPMUserClient::externalMethod(uint32_t selector, IOExternalMethodArguments *arguments,
                                                 IOExternalMethodDispatch *dispatch,
                                                   OSObject *target, void *reference){
    
    if (fProvider->kextloadAlerts) {
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
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            fProvider->PStateCtl = (uint8_t)arguments->scalarInput[0];
            fProvider->applyPowerControl();
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
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            
            for(uint32_t i = 0; i < requiredSize && i < maxLen; i++){
                if (i < 64) {
                    dataOut[i] = fProvider->boardVender[i];
                } else {
                    dataOut[i] = fProvider->boardName[i-64];
                }
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
            
            uint32_t requiredSize = (uint32_t)strlen(str) + 1;
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize - 1; // standard behaviour returns size without null terminator
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            if (maxLen > 0) {
                strlcpy(dataOut, str, maxLen);
            }
            
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
            
            fProvider->superIO->updateFanRPMS();
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < numFans) ? (maxLen / sizeof(uint64_t)) : numFans;
            
            for (uint32_t i = 0; i < copyCount; i++) {
                dataOut[i] = fProvider->superIO->getRPMForFan(i);
            }
            
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
            
            fProvider->superIO->updateFanControl();
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < numFans) ? (maxLen / sizeof(uint64_t)) : numFans;
            
            for (uint32_t i = 0; i < copyCount; i++) {
                dataOut[i] = fProvider->superIO->getFanThrottle(i) << 8 | (fProvider->superIO->getFanAutoControlMode(i) ? 1 : 0);
            }
            
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
            
            fProvider->superIO->overrideFanControl(fanSel, pwm);
            
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
            
            fProvider->superIO->setDefaultFanControl(fanSel);
            
            break;
        }
        
        //SMC Secret Undocumented feature (⁎⁍̴̛ᴗ⁍̴̛⁎)
        case 97: {
            if(!fProvider->superIO)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege())
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            int numFan = fProvider->superIO->getNumberOfFans();
            for (int i = 0; i < numFan; i++) {
                if(arguments->scalarInput[0])
                    fProvider->superIO->overrideFanControl(i, 0xff);
                else
                    fProvider->superIO->setDefaultFanControl(i);
            }
            
            break;
        }
        
        default: {
            IOLog("AMDCPUSupportUserClient::externalMethod: invalid method.\n");
            break;
        }
    }
    
    return kIOReturnSuccess;
}
