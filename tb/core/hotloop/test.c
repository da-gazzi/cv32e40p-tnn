#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define PACK_INT2_SIZE(x)                                    ((x) >> 2)

#define CompressedMAC(sum, ptr, config) asm volatile(                \
    "pv.smlsdotp.t %[shum], %[phtr], %[chonfig];"                    \
    : [shum] "+r" (sum), [phtr] "+r" (ptr): [chonfig] "I" (config))

#define InitNNRF(ptr, config) asm volatile(        \
    "pv.smlsdotp.t x0, %[phtr], %[chonfig];"       \
    : [phtr] "+r" (ptr) : [chonfig] "I" (config))

#define ThresholdCompress(res, val, thrs) asm volatile(                                                \
    "pv.thrc %[rhes], %[vhal], %[thhrs];" : [rhes] "+r" (res) : [vhal] "r" (val), [thhrs] "r" (thrs))

#define GetConfig(a_update, b_update, a_reg, b_reg) a_update << 4 | b_update << 3 | a_reg << 1 | b_reg

#define check_store(res, pOut)            \
  if ((res & 0xe0000000) == 0x00000000) { \
    *pOut = res & 0xff;                   \
    pOut++; }

#define N_INPUTS 20

//uint32_t inp_c [N_INPUTS] = {
//  0x00, // 00000000 -> 0100010101
//  0x7f, // 01111111 -> 0111111111
//  0x01, // 00000001 -> 0101000001
//  0x80, // 10000000 -> 1100010101
//  0x02, // 00000010 -> 0101000000
//  0x81, // 10000001 -> 1101000001
//  0x03, // 00000011 -> 0101010100
//  0x82, // 10000010 -> 1101000000
//  0x4,  // 00000100 -> 0101000101
//  0x83, // 10000011 -> 1101010100
//  0x5,  // 00000101 -> 0101010001
//  0x84, // 10000100 -> 1101000101
//  0x6,  // 00000110 -> 0101010000
//  0x85, // 10000101 -> 1101010001
//  0x7,  // 00000111 -> 0101010101
//  0x86, // 10000110 -> 1101010000
//  0x8,  // 00001000 -> 0001010101
//  0x87, // 10000111 -> 1101010101
//  0x9,  // 00001001 -> 0001000000
//  0x19  // 00011001 -> 0001000000
//};

uint32_t act_c[] = {
  0x007f0180,
  0x02810382,
  0x04830584,
  0x06850786,
  0x8870919,
  0x7f0180,
  0x2810382,
  0x4830584
};

uint32_t wgt_c [] = {
  0x7f0180,
  0x2810382,
  0x4830584,
  0x6850786,
  0x8870919,
  0x7f0180,
  0x2810382,
  0x4830584,
  0x6850786,
  0x8870919,
  0x7f0180,
  0x2810382,
  0x4830584,
  0x6850786,
  0x8870919,
  0x7f0180
};

uint32_t thrs_packed [] = {
  0xa0014,
  0xb0012,
  0x110016,
  0x8000d
};

// input tensor
// original:   2 x 4 x 20 activations = 2 x 4 x 40bits
// compressed: 2 x 4 x 32bits

// weight tensor
// original:   4 x 20 x 2 x 2 activations = 4 x 40bits x 2 x 2
// compressed: 4 x 32 x 2 x 2

int main(int argc, char *argv[])
{
  int ch_in, dim_kernel_x, dim_kernel_y, ch_out, dim_in_x, dim_in_y; // uncompressed!
  dim_in_x = 2;
  dim_in_y = 2;
  ch_in = 20; // must be multiple of 5

  dim_kernel_x = 2;
  dim_kernel_y = 2;
  ch_out = 4; // is this okay? should it also be a multiple of 5?

  uint32_t num_col_im2col = ch_in * dim_kernel_x * dim_kernel_y * 0.8; // the weights and acts are compressed
  uint16_t num_col_im2col_w = PACK_INT2_SIZE(num_col_im2col); // in how many bytes do the activations fit?
  uint16_t num_col_im2col_a = PACK_INT2_SIZE(num_col_im2col);
  int32_t *pBias = NULL;
  uint8_t *pOut;

  int8_t *pA = wgt_c; //pWeight;
  int8_t *pB = act_c; //pIn;
  int8_t *pB2 = (pB + num_col_im2col_a);

  int32_t *ptrB  = (int32_t *) pB;
  int32_t *ptrB2 = (int32_t *) pB2;

  int8_t *pA2 = (pA + num_col_im2col_w);
  int8_t *pA3 = (pA2 + num_col_im2col_w);
  int8_t *pA4 = (pA3 + num_col_im2col_w);

  int32_t *ptrA  = (int32_t *) pA ;
  int32_t *ptrA2 = (int32_t *) pA2;
  int32_t *ptrA3 = (int32_t *) pA3;
  int32_t *ptrA4 = (int32_t *) pA4;

  int sum = 0;
  int sum2 = 0;
  int sum3 = 0;
  int sum4 = 0;
  int sum5 = 0;
  int sum6 = 0;
  int sum7 = 0;
  int sum8 = 0;
  int res;

  if (pBias != NULL)
  {
    sum = ((int) (*pBias++));
    sum2 = ((int) (*pBias++));
    sum3 = ((int) (*pBias++));
    sum4 = ((int) (*pBias++));

    sum5 = sum;
    sum6 = sum2;
    sum7 = sum3;
    sum8 = sum4;
  }
  InitNNRF(ptrA, GetConfig(1, 0, 0, 0));
  InitNNRF(ptrA2, GetConfig(1, 0, 1, 0));
  InitNNRF(ptrA3, GetConfig(1, 0, 2, 0));
  InitNNRF(ptrA4, GetConfig(1, 0, 3, 0));
  InitNNRF(ptrB, GetConfig(0, 1, 0, 0));

  for (int j=0; j<(num_col_im2col >> 4); j++)
  {
    InitNNRF(ptrB2, GetConfig(0, 1, 0, 1));
    CompressedMAC(sum,  ptrA,  GetConfig(0, 0, 0, 0));
    CompressedMAC(sum2, ptrA2, GetConfig(0, 0, 1, 0));
    CompressedMAC(sum3, ptrA3, GetConfig(0, 0, 2, 0));
    CompressedMAC(sum4, ptrB,  GetConfig(0, 1, 3, 0));

    CompressedMAC(sum5, ptrA,  GetConfig(1, 0, 0, 1));
    CompressedMAC(sum6, ptrA2, GetConfig(1, 0, 1, 1));
    CompressedMAC(sum7, ptrA3, GetConfig(1, 0, 2, 1));
    CompressedMAC(sum8, ptrA4, GetConfig(1, 0, 3, 1));
  }

  printf("sum = %d\n", sum);
  printf("sum2 = %d\n", sum2);
  printf("sum3 = %d\n", sum3);
  printf("sum4 = %d\n", sum4);
  printf("sum5 = %d\n", sum5);
  printf("sum6 = %d\n", sum6);
  printf("sum7 = %d\n", sum7);
  printf("sum8 = %d\n", sum8);

  ThresholdCompress(res, sum, thrs_packed[0]);
  check_store(res, pOut);

  ThresholdCompress(res, sum2, thrs_packed[1]);
  check_store(res, pOut);

  ThresholdCompress(res, sum3, thrs_packed[2]);
  check_store(res, pOut);

  ThresholdCompress(res, sum4, thrs_packed[3]);
  check_store(res, pOut);

  ThresholdCompress(res, sum5, thrs_packed[0]);
  check_store(res, pOut);

  ThresholdCompress(res, sum6, thrs_packed[1]);
  check_store(res, pOut);

  ThresholdCompress(res, sum7, thrs_packed[2]);
  check_store(res, pOut);

  ThresholdCompress(res, sum8, thrs_packed[3]);
  check_store(res, pOut);

  return EXIT_SUCCESS;
}
