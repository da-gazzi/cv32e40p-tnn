#include <stdio.h>

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

// TODO: review argument order
uint8_t * __attribute__((noinline)) xpulp_nn_matmul_ternary(
                        uint8_t  *pIn,
                        int8_t   *pBias,
                        uint32_t *pThr,
                        uint8_t  *pOut,
                        uint8_t  *pOut2,
                        uint8_t  *pWeight,
                        uint16_t num_col_im2col,
                        uint16_t ch_out,
                        uint32_t *thrc_res1,
                        uint32_t *thrc_res2)
{
  uint16_t ch_out_r = PACK_INT2_SIZE(ch_out);

  uint16_t num_col_im2col_w = PACK_INT2_SIZE(num_col_im2col); // in how many bytes do the activations fit?
  uint16_t num_col_im2col_a = PACK_INT2_SIZE(num_col_im2col);

  uint8_t *pA = pWeight;

  int res1, res2;

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

    InitNNRF(ptrA,  GetConfig(1, 0, 0, 0));
    InitNNRF(ptrA2, GetConfig(1, 0, 1, 0));
    InitNNRF(ptrA3, GetConfig(1, 0, 2, 0));
    InitNNRF(ptrA4, GetConfig(1, 0, 3, 0));

    InitNNRF(ptrB,  GetConfig(0, 1, 0, 0));

    int sum = 0;
    int sum2 = 0;
    int sum3 = 0;
    int sum4 = 0;
    int sum5 = 0;
    int sum6 = 0;
    int sum7 = 0;
    int sum8 = 0;

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

      volatile uint32_t valA, valA2, valA3, valA4, valB, valB2; // volatile somehow solves the problem with XX
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
      pA += PACK_INT2_SIZE(col_cnt_im2col);

      uint32_t *pA_p = &valA;
      uint32_t *pA2_p = &valA2;
      uint32_t *pA3_p = &valA3;
      uint32_t *pA4_p = &valA4;
      uint32_t *pB_p = &valB;
      uint32_t *pB2_p = &valB2;

      InitNNRF(pA_p,  GetConfig(1, 0, 0, 0));
      InitNNRF(pA2_p, GetConfig(1, 0, 1, 0));
      InitNNRF(pA3_p, GetConfig(1, 0, 2, 0));
      InitNNRF(pA4_p, GetConfig(1, 0, 3, 0));

      InitNNRF(pB_p,  GetConfig(0, 1, 0, 0));
      InitNNRF(pB2_p, GetConfig(0, 1, 0, 1));

      CompressedMAC(sum,  pA_p,  GetConfig(0, 0, 0, 0));
      CompressedMAC(sum2, pA2_p, GetConfig(0, 0, 1, 0));
      CompressedMAC(sum3, pA3_p, GetConfig(0, 0, 2, 0));
      CompressedMAC(sum4, ptrB,  GetConfig(0, 0, 3, 0));

      CompressedMAC(sum5, ptrA,  GetConfig(0, 0, 0, 1));
      CompressedMAC(sum6, ptrA2, GetConfig(0, 0, 1, 1));
      CompressedMAC(sum7, ptrA3, GetConfig(0, 0, 2, 1));
      CompressedMAC(sum8, ptrA4, GetConfig(0, 0, 3, 1));
    }

    //printf("sum = %d\n", sum);
    //printf("sum2 = %d\n", sum2);
    //printf("sum3 = %d\n", sum3);
    //printf("sum4 = %d\n", sum4);
    //printf("sum5 = %d\n", sum5);
    //printf("sum6 = %d\n", sum6);
    //printf("sum7 = %d\n", sum7);
    //printf("sum8 = %d\n", sum8);

    ThresholdCompress(res1, sum, pThr[0]);
    check_store(res1, pOut);

    ThresholdCompress(res1, sum2, pThr[1]);
    check_store(res1, pOut);

    ThresholdCompress(res1, sum3, pThr[2]);
    check_store(res1, pOut);

    ThresholdCompress(res1, sum4, pThr[3]);
    check_store(res1, pOut);

    ThresholdCompress(res2, sum5, pThr[0]);
    check_store(res2, pOut2);

    ThresholdCompress(res2, sum6, pThr[1]);
    check_store(res2, pOut2);

    ThresholdCompress(res2, sum7, pThr[2]);
    check_store(res2, pOut2);

    ThresholdCompress(res2, sum8, pThr[3]);
    check_store(res2, pOut2);
  }
  *thrc_res1 = res1;
  *thrc_res2 = res2;
}
