#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "data.h"

int main(int argc, char *argv[])
{
    int n_mismatches=0;
    int32_t res, res_masked, *addr_preact;

    for (int i=0; i<N_STIMULI; i++){
      addr_preact = &preactivations[5*i];
      asm volatile(
        "li t0, 5;"
        "lw t1, 0x(%[addr_thresh]);"
        "loop: lw t2, 0x(%[addr_preact]);"
        "pv.thrc %[res], t2, t1;"
        "addi t0, t0, -1;"
        "addi %[addr_preact], %[addr_preact], 4;"
        "bnez t0, loop;"
                : [res] "=r" (res), [addr_preact] "+r" (addr_preact)
                : [addr_thresh] "r" (&thresholds[i]) );
      res_masked = res & 0xFF;
      if (res_masked != exp_responses[i]){
        printf("***Mismatch found at iteration %d: Expected: %x, got: %x\n", i, exp_responses[i], res_masked);
        n_mismatches++;
      }
    }
    if (n_mismatches == 0)
      printf("All %d tests passed successfully! :)\n", N_STIMULI);
    else
      printf("******Test FAILED with %d mismatches out of %d******\n", n_mismatches, N_STIMULI);

    return EXIT_SUCCESS;
}
