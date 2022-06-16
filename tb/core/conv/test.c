#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "data.h"
#include "matmul_ternary.h"


int main(int argc, char *argv[])
{
  int ch_out;
  ch_out = 4;
  int8_t *pBias = NULL;
  uint32_t num_col_im2col = NUM_COL_IM2COL; // the weights and acts are compressed
  uint32_t thrc_res1, thrc_res2;

  uint8_t outputs[20] = {0};

  int n_outputs = ceil((ch_out >> 2)*1.6); // should be floor instead?

  uint8_t *pOut1 = &outputs[0];
  uint8_t *pOut2 = &outputs[n_outputs/2];

  pOut1 = xpulp_nn_matmul_ternary(
    pIn,
    pBias,
    pThr,
    pOut1,
    pOut2,
    pWeight,
    num_col_im2col,
    ch_out,
    &thrc_res1,
    &thrc_res2
  );

  int n_mismatches = 0;
  for(int i=0; i < n_outputs; i++) {
    if (outputs[i] != pOut_exp[i]){
        printf("***Mismatch found at iteration %d: Expected: %x, got: %x\n", i, pOut_exp[i], outputs[i]);
        n_mismatches++;
    }
  }
  if (n_mismatches == 0)
    printf("All %d tests passed successfully! :)\n", n_outputs);
  else
    printf("******Test FAILED with %d mismatches out of %d******\n", n_mismatches, n_outputs);

  return EXIT_SUCCESS;
}
