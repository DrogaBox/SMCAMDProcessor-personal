#include <stdio.h>
#include <stdlib.h>
#include <IOKit/IOKitLib.h>

int main() {
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

    printf("Successfully connected to driver. Dumping raw ITE SuperIO registers (0x00 - 0xFF):\n\n");
    printf("     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n");
    printf("----------------------------------------------------\n");

    for (int row = 0; row < 16; row++) {
        printf("%02X:  ", row * 16);
        for (int col = 0; col < 16; col++) {
            uint64_t reg = row * 16 + col;
            uint64_t val = 0;
            size_t outSize = sizeof(val);
            
            kr = IOConnectCallMethod(connect, 98, &reg, 1, NULL, 0, NULL, NULL, &val, &outSize);
            if (kr == KERN_SUCCESS) {
                printf("%02X ", (uint8_t)val);
            } else {
                printf("?? ");
            }
        }
        printf("\n");
    }

    IOServiceClose(connect);
    return 0;
}
