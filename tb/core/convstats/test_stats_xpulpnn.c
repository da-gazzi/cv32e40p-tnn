#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "data_statstest.h"
#include "xpulp_nn_matmul_u2_u2_i2.h"
#include "xpulp_nn_conv_u2_u2_i2.h"

int main(int argc, char *argv[])
{
  //uint8_t *pIn; -> in data_statstest.h
  uint8_t *pIm2ColBuffer;
  int8_t *pBias;
  uint8_t *pOut;
  //int8_t *pWeight; -> in data_statstest.h
  //int32_t *pKappa; -> in data_statstest.h
  //int32_t *pLambda; -> in data_statstest.h
  uint16_t out_mult;
  uint16_t out_shift;
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
  uint8_t flag_relu = 1;
  uint8_t flag_batch_norm = 1;

  uint8_t im2col[IM2COL_DIM] = {0};
  pIm2ColBuffer = im2col;

    
  /****** TEST 0 ******/
  pBias = NULL;
  out_mult = 1;
  out_shift = 1;
  dim_in_x = 8;
  dim_in_y = 8;
  ch_in = 20;
  dim_out_x = 8;
  dim_out_y = 8;
  ch_out = 20;
  dim_kernel_x = 3;
  dim_kernel_y = 3;
  padding_y_top = 1;
  padding_y_bottom = 1;
  padding_x_left = 1;
  padding_x_right = 1;
  stride_x = 1;
  stride_y = 1;

  uint8_t outputs_0[256] = {0};
  pOut = outputs_0;

  printf("===> TEST 0: Running xpulp_nn_conv_ternary...\n");
  printf("  dims_in     = [%d, %d]\n", dim_in_x, dim_in_y);
  printf("  ch_in/out   = [%d, %d]\n", ch_in, ch_out);
  printf("  dims_kernel = [%d, %d]\n", dim_kernel_x, dim_kernel_y);
  //printf("  padding_y_top    = [%d]\n", padding_y_top);
  //printf("  padding_y_bottom = [%d]\n", padding_y_bottom);
  //printf("  padding_x_left   = [%d]\n", padding_x_left);
  //printf("  padding_x_right  = [%d]\n", padding_x_right);
  //printf("  stride_x         = [%d]\n", stride_x);
  //printf("  stride_y         = [%d]\n", stride_y);

  xpulp_nn_conv_u2_u2_i2(
    pIn,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight,
    pKappa,
    pLambda,
    out_mult,
    out_shift,
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
    stride_y,
    flag_relu,
    flag_batch_norm
  );
  printf("===> TEST 0: Finished running xpulp_nn_conv_u2_u2_i2\n");



    
  /****** TEST 1 ******/
  pBias = NULL;
  out_mult = 1;
  out_shift = 1;
  dim_in_x = 16;
  dim_in_y = 16;
  ch_in = 20;
  dim_out_x = 16;
  dim_out_y = 16;
  ch_out = 20;
  dim_kernel_x = 3;
  dim_kernel_y = 3;
  padding_y_top = 1;
  padding_y_bottom = 1;
  padding_x_left = 1;
  padding_x_right = 1;
  stride_x = 1;
  stride_y = 1;

  uint8_t outputs_1[1024] = {0};
  pOut = outputs_1;

  printf("===> TEST 1: Running xpulp_nn_conv_ternary...\n");
  printf("  dims_in     = [%d, %d]\n", dim_in_x, dim_in_y);
  printf("  ch_in/out   = [%d, %d]\n", ch_in, ch_out);
  printf("  dims_kernel = [%d, %d]\n", dim_kernel_x, dim_kernel_y);
  //printf("  padding_y_top    = [%d]\n", padding_y_top);
  //printf("  padding_y_bottom = [%d]\n", padding_y_bottom);
  //printf("  padding_x_left   = [%d]\n", padding_x_left);
  //printf("  padding_x_right  = [%d]\n", padding_x_right);
  //printf("  stride_x         = [%d]\n", stride_x);
  //printf("  stride_y         = [%d]\n", stride_y);

  xpulp_nn_conv_u2_u2_i2(
    pIn,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight,
    pKappa,
    pLambda,
    out_mult,
    out_shift,
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
    stride_y,
    flag_relu,
    flag_batch_norm
  );
  printf("===> TEST 1: Finished running xpulp_nn_conv_u2_u2_i2\n");



    
  /****** TEST 2 ******/
  pBias = NULL;
  out_mult = 1;
  out_shift = 1;
  dim_in_x = 32;
  dim_in_y = 32;
  ch_in = 20;
  dim_out_x = 32;
  dim_out_y = 32;
  ch_out = 20;
  dim_kernel_x = 3;
  dim_kernel_y = 3;
  padding_y_top = 1;
  padding_y_bottom = 1;
  padding_x_left = 1;
  padding_x_right = 1;
  stride_x = 1;
  stride_y = 1;

  uint8_t outputs_2[4096] = {0};
  pOut = outputs_2;

  printf("===> TEST 2: Running xpulp_nn_conv_ternary...\n");
  printf("  dims_in     = [%d, %d]\n", dim_in_x, dim_in_y);
  printf("  ch_in/out   = [%d, %d]\n", ch_in, ch_out);
  printf("  dims_kernel = [%d, %d]\n", dim_kernel_x, dim_kernel_y);
  //printf("  padding_y_top    = [%d]\n", padding_y_top);
  //printf("  padding_y_bottom = [%d]\n", padding_y_bottom);
  //printf("  padding_x_left   = [%d]\n", padding_x_left);
  //printf("  padding_x_right  = [%d]\n", padding_x_right);
  //printf("  stride_x         = [%d]\n", stride_x);
  //printf("  stride_y         = [%d]\n", stride_y);

  xpulp_nn_conv_u2_u2_i2(
    pIn,
    pIm2ColBuffer,
    pBias,
    pOut,
    pWeight,
    pKappa,
    pLambda,
    out_mult,
    out_shift,
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
    stride_y,
    flag_relu,
    flag_batch_norm
  );
  printf("===> TEST 2: Finished running xpulp_nn_conv_u2_u2_i2\n");



  return 0;
}

