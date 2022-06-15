#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "data.h"
#include "matmul_ternary.h"
#include "conv_ternary.h"


int main(int argc, char *argv[])
{
  //uint8_t *pIn; -> in data.h
  uint8_t *pIm2ColBuffer;
  int8_t *pBias = NULL;
  uint8_t *pOut;
  //int8_t *pWeight; -> in data.h
  //uint32_t *pThr; -> in data.h
  uint16_t dim_in_x = DIM_IN_X;
  uint16_t dim_in_y = DIM_IN_Y;
  uint16_t ch_in = CH_IN;
  uint16_t dim_out_x = DIM_OUT_X;
  uint16_t dim_out_y = DIM_OUT_Y;
  uint16_t ch_out = CH_OUT;
  uint16_t dim_kernel_x = DIM_KERNEL_X;
  uint16_t dim_kernel_y = DIM_KERNEL_Y;
  uint16_t padding_y_top = PADDING_Y;
  uint16_t padding_y_bottom = PADDING_Y;
  uint16_t padding_x_left = PADDING_X;
  uint16_t padding_x_right = PADDING_X;
  uint16_t stride_x = STRIDE_X;
  uint16_t stride_y = STRIDE_Y;

  uint8_t outputs[N_COMPRESSED_OUTPUTS] = {0};
  uint8_t im2col[IM2COL_DIM] = {0};

  pOut = outputs;
  pIm2ColBuffer = im2col;

  xpulp_nn_conv_ternary(
    pIn,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight,
    pThr,
    dim_in_x,
    dim_in_y,
    ch_in,
    dim_out_x,
    dim_out_y,
    ch_out,
    dim_kernel_x,
    dim_kernel_y,
    padding_y_top,
    padding_y_bottom,
    padding_x_left,
    padding_x_right,
    stride_x,
    stride_y
  );

  int n_mismatches = 0;
  for(int i=0; i < N_COMPRESSED_OUTPUTS; i++) {
    if (outputs[i] != pOut_exp[i]){
        printf("***Mismatch found at iteration %d: Expected: %x, got: %x\n", i, pOut_exp[i], outputs[i]);
        n_mismatches++;
    }
  }
  if (n_mismatches == 0)
    printf("All %d tests passed successfully! :)\n", N_COMPRESSED_OUTPUTS);
  else
    printf("******Test FAILED with %d mismatches out of %d******\n", n_mismatches, N_COMPRESSED_OUTPUTS);

  return EXIT_SUCCESS;
}
