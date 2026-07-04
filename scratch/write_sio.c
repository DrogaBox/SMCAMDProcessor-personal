#include <stdio.h>
#include <stdlib.h>
#include <IOKit/IOKitLib.h>

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: write_sio <reg_hex> <val_hex>\n");
        printf("Example: write_sio 13 00\n");
        return 1;
    }

    uint64_t reg = strtoul(argv[1], NULL, 16);
    uint64_t val = strtoul(argv[2], NULL, 16);

    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AMDRyzenCPUPowerManagement"));
    if (!service) {
        printf("Failed to find AMDRyzenCPUPowerManagement service.\n");
        return 1;
    }

    io_connect_t connect;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
    IOObjectRelease(service);
    if (kr != KERN_SUCCESS) {
        printf("Failed to open connection to driver: 0x%08x\n", kr);
        return 1;
    }

    uint64_t input[2] = {reg, val};
    kr = IOConnectCallMethod(connect, 99, input, 2, NULL, 0, NULL, NULL, NULL, NULL);
    if (kr == KERN_SUCCESS) {
        printf("Successfully wrote 0x%02X to register 0x%02X.\n", (uint8_t)val, (uint8_t)reg);
    } else {
        printf("Failed to write to register: 0x%08x (make sure to run as sudo or with privilege!)\n", kr);
    }

    IOServiceClose(connect);
    return 0;
}
