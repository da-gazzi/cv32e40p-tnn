#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "data_statstest.h"
#include "matmul_ternary.h"
#include "matmul_ternary_4x1.h"
#include "conv_ternary.h"

int main(int argc, char *argv[])
{
  //uint8_t *pIn; -> in data_statstest.h
  uint8_t *pIm2ColBuffer;
  int8_t *pBias;
  uint8_t *pOut;
  //int8_t *pWeight; -> in data_statstest.h
  //uint32_t *pThr; -> in data_statstest.h
  uint16_t dim_in_x;
  uint16_t dim_in_y;
  uint16_t ch_in;
  uint16_t dim_out_x;
  uint16_t dim_out_y;
  uint16_t ch_out;
  uint16_t dim_kernel_x;
  uint16_t dim_kernel_y;
  uint16_t padding_y_top;
  uint16_t padding_y_bottom;
  uint16_t padding_x_left;
  uint16_t padding_x_right;
  uint16_t stride_x;
  uint16_t stride_y;

  uint8_t outputs[N_OUTPUTS] = {0};
  uint8_t im2col[IM2COL_DIM] = {0};

  pOut = outputs;
  pIm2ColBuffer = im2col;


  /****** TEST 0 ******/
  pBias = NULL;
  dim_in_x = 8;
  dim_in_y = 8;
  ch_in = 16;
  dim_out_x = 8;
  dim_out_y = 8;
  ch_out = 16;
  dim_kernel_x = 3;
  dim_kernel_y = 3;
  padding_y_top = 1;
  padding_y_bottom = 1;
  padding_x_left = 1;
  padding_x_right = 1;
  stride_x = 1;
  stride_y = 1;

  printf("===> TEST 0: Running xpulp_nn_conv_ternary...\n");
  printf("  dim_in_x     = [%d]\n", dim_in_x);
  printf("  dim_in_y     = [%d]\n", dim_in_y);
  printf("  ch_in        = [%d]\n", ch_in);
  printf("  ch_out       = [%d]\n", ch_out);
  printf("  dim_kernel_x = [%d]\n", dim_kernel_x);
  printf("  dim_kernel_y = [%d]\n", dim_kernel_y);
  printf("  padding_y_top    = [%d]\n", padding_y_top);
  printf("  padding_y_bottom = [%d]\n", padding_y_bottom);
  printf("  padding_x_left   = [%d]\n", padding_x_left);
  printf("  padding_x_right  = [%d]\n", padding_x_right);
  printf("  stride_x         = [%d]\n", stride_x);
  printf("  stride_y         = [%d]\n", stride_y);

  xpulp_nn_conv_ternary(
    pIn_c,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight_c,
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
  printf("===> TEST 0: Finished running xpulp_nn_conv_ternary\n");




  /****** TEST 1 ******/
  pBias = NULL;
  dim_in_x = 16;
  dim_in_y = 16;
  ch_in = 16;
  dim_out_x = 16;
  dim_out_y = 16;
  ch_out = 16;
  dim_kernel_x = 3;
  dim_kernel_y = 3;
  padding_y_top = 1;
  padding_y_bottom = 1;
  padding_x_left = 1;
  padding_x_right = 1;
  stride_x = 1;
  stride_y = 1;

  printf("===> TEST 1: Running xpulp_nn_conv_ternary...\n");
  printf("  dim_in_x     = [%d]\n", dim_in_x);
  printf("  dim_in_y     = [%d]\n", dim_in_y);
  printf("  ch_in        = [%d]\n", ch_in);
  printf("  ch_out       = [%d]\n", ch_out);
  printf("  dim_kernel_x = [%d]\n", dim_kernel_x);
  printf("  dim_kernel_y = [%d]\n", dim_kernel_y);
  printf("  padding_y_top    = [%d]\n", padding_y_top);
  printf("  padding_y_bottom = [%d]\n", padding_y_bottom);
  printf("  padding_x_left   = [%d]\n", padding_x_left);
  printf("  padding_x_right  = [%d]\n", padding_x_right);
  printf("  stride_x         = [%d]\n", stride_x);
  printf("  stride_y         = [%d]\n", stride_y);

  xpulp_nn_conv_ternary(
    pIn_c,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight_c,
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
  printf("===> TEST 1: Finished running xpulp_nn_conv_ternary\n");




  /****** TEST 2 ******/
  pBias = NULL;
  dim_in_x = 32;
  dim_in_y = 32;
  ch_in = 16;
  dim_out_x = 32;
  dim_out_y = 32;
  ch_out = 16;
  dim_kernel_x = 3;
  dim_kernel_y = 3;
  padding_y_top = 1;
  padding_y_bottom = 1;
  padding_x_left = 1;
  padding_x_right = 1;
  stride_x = 1;
  stride_y = 1;

  printf("===> TEST 2: Running xpulp_nn_conv_ternary...\n");
  printf("  dim_in_x     = [%d]\n", dim_in_x);
  printf("  dim_in_y     = [%d]\n", dim_in_y);
  printf("  ch_in        = [%d]\n", ch_in);
  printf("  ch_out       = [%d]\n", ch_out);
  printf("  dim_kernel_x = [%d]\n", dim_kernel_x);
  printf("  dim_kernel_y = [%d]\n", dim_kernel_y);
  printf("  padding_y_top    = [%d]\n", padding_y_top);
  printf("  padding_y_bottom = [%d]\n", padding_y_bottom);
  printf("  padding_x_left   = [%d]\n", padding_x_left);
  printf("  padding_x_right  = [%d]\n", padding_x_right);
  printf("  stride_x         = [%d]\n", stride_x);
  printf("  stride_y         = [%d]\n", stride_y);

  xpulp_nn_conv_ternary(
    pIn_c,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight_c,
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
  printf("===> TEST 2: Finished running xpulp_nn_conv_ternary\n");



  return EXIT_SUCCESS;
}
