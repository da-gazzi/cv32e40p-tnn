#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "data.h"

int main(int argc, char *argv[])
{
    int n_mismatches=0;
    int32_t res, *aw, *ax;
    aw = compr_w;
    ax = compr_x;
    for (int i=0; i<N_STIMULI; i++){
      //printf("aw = %x, &compr_w[i] = %x\n", aw, &compr_w[i]);
      //printf("ax = %x, &compr_x[i] = %x\n", ax, &compr_x[i]);
      asm volatile(
        "add %[res], x0, x0;"
        "pv.smlsdotsp.t x0, %[aw], 0b10000;"
        "pv.smlsdotsp.t x0, %[ax], 0b01000;"
        "nop;"
        "pv.smlsdotsp.t %[res], x0, 0b00000;"
                : [aw] "+r" (aw), [ax] "+r" (ax), [res] "=r" (res));
      if (res != exp_responses[i]){
        printf("***Mismatch found at iteration %d: Expected: %d, got: %d\n", i, exp_responses[i], res);
        n_mismatches++;
      }
    }
    if (n_mismatches == 0)
      printf("All %d tests passed successfully! :)\n", N_STIMULI);
    else
      printf("******Test FAILED with %d mismatches out of %d******\n", n_mismatches, N_STIMULI);

    return EXIT_SUCCESS;
}
