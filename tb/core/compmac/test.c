#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "data.h"

int main(int argc, char *argv[])
{
    uint32_t op1, op2, res;

    for (int i=0; i<N_STIMULI; i++){
      asm volatile(
        "lw %[op1], 0x(%[data1_addr]);"
        "lw %[op2], 0x(%[data2_addr]);"
        "pv.mlsdotusp.t.0 %[res], %[op1], %[op2];"
                : [op1] "+r" (op1), [op2] "+r" (op2), [res] "=r" (res)
                : [data1_addr] "r" (&data1[0]), [data2_addr] "r" (&data2[0]));
      printf("x=0x%x (@0x%x)\ty=0x%x (@0x%x)\t res=0x%x\n", data1[i], &data1[i], data2[i], &data2[i], res);
    }

    return EXIT_SUCCESS;
}
