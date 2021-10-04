#ifndef STAGE2_PCI_H
#define STAGE2_PCI_H

#include <stage2/typedefs.h>

uint16_t pcicfg_reg(uint8_t bus, uint8_t device, uint8_t func, uint8_t offset);



#endif 
