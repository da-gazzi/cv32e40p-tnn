#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "data.h"

#define PACK_INT2_SIZE(x)                                    ((x) >> 2)

// does not work somehow
//#define CompressedMAC(sum, ptr, config) asm volatile(             \
//    "pv.smlsdotp.t %[sum], %[ptr], %[config];"                    \
//    : [sum] "+r" (sum) : [ptr] "r" (ptr), [config] "I" (config))

struct MyStruct {
  int32_t sum;
  uint32_t ptr;
};

inline struct MyStruct CompressedMAC(int32_t sum, uint32_t ptr, char config) {
  struct MyStruct x;
  asm volatile(
    "pv.smlsdotp.t %[sum], %[ptr], %[config];"
    : [sum] "+r" (sum), [ptr] "+r" (ptr) : [config] "I" (config)
  );
  x.sum = sum;
  x.ptr = ptr;
  return x;
};

inline uint32_t InitNNRF(uint32_t ptr, char config) {
  asm volatile(
    "pv.smlsdotp.t x0, %[ptr], %[config];"
    : [ptr] "+r" (ptr) : [config] "I" (config)
  );
  return ptr;
};

inline uint32_t ThresholdCompress(uint32_t res, int32_t val, uint32_t thrs) {
  asm volatile(
    "pv.thrc %[res], %[val], %[thrs];" : [res] "+r" (res) : [val] "r" (val), [thrs] "r" (thrs)
  );
  return res;
};

static inline uint8_t * check_store(uint32_t res, uint8_t *pOut) {
  // if counter value equals 0 (i.e. 5 computations are finished), store the compressed output to the output pointer
  if ((res & 0xe0000000) == 0x00000000) {
    *pOut = res & 0xff;
    pOut++;
  }
  return pOut;
}

#define GetConfig(a_update, b_update, a_reg, b_reg) a_update << 4 | b_update << 3 | a_reg << 1 | b_reg

int main(int argc, char *argv[])
{
  int ch_out;
  ch_out = 4;
  int8_t *pBias = NULL;
  uint32_t num_col_im2col = NUM_COL_IM2COL; // the weights and acts are compressed
  /* ---------------------- */

  struct MyStruct x;
  uint16_t ch_out_r = PACK_INT2_SIZE(ch_out);

  uint16_t num_col_im2col_w = PACK_INT2_SIZE(num_col_im2col); // in how many bytes do the activations fit?
  uint16_t num_col_im2col_a = PACK_INT2_SIZE(num_col_im2col);
  uint8_t outputs[10] = {0};
  uint8_t *pOut = outputs;

  uint8_t *pA = pWeight;

  for(int i=0; i < (ch_out >> 2); i++)
  {
    uint8_t *pB = pIn;
    uint8_t *pB2 = (pB + num_col_im2col_a);

    uint32_t *ptrB  = (uint32_t *) pB;
    uint32_t *ptrB2 = (uint32_t *) pB2;

    uint8_t *pA2 = (pA + num_col_im2col_w);
    uint8_t *pA3 = (pA2 + num_col_im2col_w);
    uint8_t *pA4 = (pA3 + num_col_im2col_w);

    uint32_t *ptrA  = (uint32_t *) pA ;
    uint32_t *ptrA2 = (uint32_t *) pA2;
    uint32_t *ptrA3 = (uint32_t *) pA3;
    uint32_t *ptrA4 = (uint32_t *) pA4;

    ptrA  = InitNNRF(ptrA,  GetConfig(1, 0, 0, 0));
    ptrA2 = InitNNRF(ptrA2, GetConfig(1, 0, 1, 0));
    ptrA3 = InitNNRF(ptrA3, GetConfig(1, 0, 2, 0));
    ptrA4 = InitNNRF(ptrA4, GetConfig(1, 0, 3, 0));

    ptrB  = InitNNRF(ptrB,  GetConfig(0, 1, 0, 0));

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

    for (int j=0; j<(num_col_im2col >> 4); j++)
    {
      ptrB2 = InitNNRF(ptrB2, GetConfig(0, 1, 0, 1));

      x = CompressedMAC(sum,  ptrA,  GetConfig(0, 0, 0, 0));
      sum = x.sum;

      x = CompressedMAC(sum2, ptrA2, GetConfig(0, 0, 1, 0));
      sum2 = x.sum;

      x = CompressedMAC(sum3, ptrA3, GetConfig(0, 0, 2, 0));
      sum3 = x.sum;

      x = CompressedMAC(sum4, ptrB,  GetConfig(0, 1, 3, 0));
      sum4 = x.sum;
      ptrB = x.ptr;

      x = CompressedMAC(sum5, ptrA,  GetConfig(1, 0, 0, 1));
      sum5 = x.sum;
      ptrA = x.ptr;

      x = CompressedMAC(sum6, ptrA2, GetConfig(1, 0, 1, 1));
      sum6 = x.sum;
      ptrA2 = x.ptr;

      x = CompressedMAC(sum7, ptrA3, GetConfig(1, 0, 2, 1));
      sum7 = x.sum;
      ptrA3 = x.ptr;

      x = CompressedMAC(sum8, ptrA4, GetConfig(1, 0, 3, 1));
      sum8 = x.sum;
      ptrA4 = x.ptr;
    }

    int col_cnt_im2col = num_col_im2col & 0xf;

    if(col_cnt_im2col)
    {
      uint16_t loop_cnt_im2col_w = (num_col_im2col >> 4) << 2;
      pA+=loop_cnt_im2col_w;
      pA2+=loop_cnt_im2col_w;
      pA3+=loop_cnt_im2col_w;
      pA4+=loop_cnt_im2col_w;

      uint16_t loop_cnt_im2col_a = (num_col_im2col >> 4) << 2;
      pB+=loop_cnt_im2col_a;
      pB2+=loop_cnt_im2col_a;

      uint32_t valA, valA2, valA3, valA4, valB, valB2;
      // pack the remaining weights and activations into 32-bit vectors
      // padding with 0xd9 because ternary_decoder(0xd9) = 0000000000
      if (col_cnt_im2col == 4)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA2;
        valA3 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA3;
        valA4 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA4;

        valB = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pB;
        valB2 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pB2;
      }
      else if (col_cnt_im2col == 8)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | *(pA2 + 1) << 8 | *pA2;
        valA3 = 0xd9 << 24 | 0xd9 << 16 | *(pA3 + 1) << 8 | *pA3;
        valA4 = 0xd9 << 24 | 0xd9 << 16 | *(pA4 + 1) << 8 | *pA4;

        valB = 0xd9 << 24 | 0xd9 << 16 | *(pB + 1) << 8 | *pB;
        valB2 = 0xd9 << 24 | 0xd9 << 16 | *(pB2 + 1) << 8 | *pB2;
      }
      else // col_cnt_im2col == 12
      {
        valA = 0xd9 << 24 | *(pA + 2) << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA2 + 1) << 8 | *pA2;
        valA3 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA3 + 1) << 8 | *pA3;
        valA4 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA4 + 1) << 8 | *pA4;

        valB = 0xd9 << 24 | *(pA + 2) << 16 | *(pB + 1) << 8 | *pB;
        valB2 = 0xd9 << 24 | *(pA + 2) << 16 | *(pB2 + 1) << 8 | *pB2;
      }

      uint32_t *pA_p = &valA;
      uint32_t *pA2_p = &valA2;
      uint32_t *pA3_p = &valA3;
      uint32_t *pA4_p = &valA4;
      uint32_t *pB_p = &valB;
      uint32_t *pB2_p = &valB2;

      pA_p  = InitNNRF(pA_p,  GetConfig(1, 0, 0, 0));
      pA2_p = InitNNRF(pA2_p, GetConfig(1, 0, 1, 0));
      pA3_p = InitNNRF(pA3_p, GetConfig(1, 0, 2, 0));
      pA4_p = InitNNRF(pA4_p, GetConfig(1, 0, 3, 0));

      pB_p  = InitNNRF(pB_p,  GetConfig(0, 1, 0, 0));
      pB2_p = InitNNRF(pB2_p, GetConfig(0, 1, 0, 1));

      x = CompressedMAC(sum,  pA_p,  GetConfig(0, 0, 0, 0));
      sum = x.sum;

      x = CompressedMAC(sum2, pA2_p, GetConfig(0, 0, 1, 0));
      sum2 = x.sum;

      x = CompressedMAC(sum3, pA3_p, GetConfig(0, 0, 2, 0));
      sum3 = x.sum;

      x = CompressedMAC(sum4, ptrB,  GetConfig(0, 0, 3, 0));
      sum4 = x.sum;

      x = CompressedMAC(sum5, ptrA,  GetConfig(0, 0, 0, 1));
      sum5 = x.sum;

      x = CompressedMAC(sum6, ptrA2, GetConfig(0, 0, 1, 1));
      sum6 = x.sum;

      x = CompressedMAC(sum7, ptrA3, GetConfig(0, 0, 2, 1));
      sum7 = x.sum;

      x = CompressedMAC(sum8, ptrA4, GetConfig(0, 0, 3, 1));
      sum8 = x.sum;
    }

    //printf("sum = %d\n", sum);
    //printf("sum2 = %d\n", sum2);
    //printf("sum3 = %d\n", sum3);
    //printf("sum4 = %d\n", sum4);
    //printf("sum5 = %d\n", sum5);
    //printf("sum6 = %d\n", sum6);
    //printf("sum7 = %d\n", sum7);
    //printf("sum8 = %d\n", sum8);

    res = ThresholdCompress(res, sum, pThr[0]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum2, pThr[1]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum3, pThr[2]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum4, pThr[3]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum5, pThr[0]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum6, pThr[1]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum7, pThr[2]);
    pOut = check_store(res, pOut);

    res = ThresholdCompress(res, sum8, pThr[3]);
    pOut = check_store(res, pOut);
  }

  int n_mismatches = 0;
  int n_outputs = ceil((ch_out >> 2)*1.6);
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
