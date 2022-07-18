#include <stdio.h>
#include <math.h>
#include "pulp_nn_utils.h"


// TODO: review argument order
uint8_t * __attribute__((noinline)) xpulp_nn_matmul_ternary_4x1(
                        uint8_t  *pIn,
                        int8_t   *pBias,
                        uint32_t *pThr,
                        uint8_t  *pOut,
                        uint8_t  *pWeight,
                        uint16_t num_col_im2col,
                        uint16_t ch_out,
                        uint32_t *thrc_res)
{
  uint16_t ch_out_r = PACK_INT2_SIZE(ch_out);

  uint16_t num_col_im2col_w = PACK_INT2_SIZE(num_col_im2col);
  uint16_t num_col_im2col_a = PACK_INT2_SIZE(num_col_im2col);

  uint8_t *pA = pWeight;
  uint32_t *currThr = pThr;

  int res, incr_val;
  res = *thrc_res;
  incr_val = 0;

  for(int i=0; i < CHANS_DECOMPR(ch_out) >> 2; i++)
  {
    uint8_t *pB = pIn;

    uint32_t *ptrB  = (uint32_t *) pB;

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

    int sum = 0;
    int sum2 = 0;
    int sum3 = 0;
    int sum4 = 0;

    if (pBias != NULL)
    {
      sum = ((int) (*pBias++));
      sum2 = ((int) (*pBias++));
      sum3 = ((int) (*pBias++));
      sum4 = ((int) (*pBias++));
    }

    for (int j=0; j<(num_col_im2col >> 4); j++)
    {
      InitNNRF(ptrB, GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  ptrA,  GetConfig(1, 0, 0, 0));
      CompressedMAC(sum2, ptrA2, GetConfig(1, 0, 1, 0));
      CompressedMAC(sum3, ptrA3, GetConfig(1, 0, 2, 0));
      CompressedMAC(sum4, ptrA4, GetConfig(1, 0, 3, 0));
    }

    int col_cnt_im2col = num_col_im2col & 0xf;

    if (col_cnt_im2col)
    {
      uint16_t loop_cnt_im2col_w = (num_col_im2col >> 4) << 2;
      pA+=loop_cnt_im2col_w;
      pA2+=loop_cnt_im2col_w;
      pA3+=loop_cnt_im2col_w;
      pA4+=loop_cnt_im2col_w;

      uint16_t loop_cnt_im2col_a = (num_col_im2col >> 4) << 2;
      pB+=loop_cnt_im2col_a;

      volatile uint32_t valA, valA2, valA3, valA4, valB;
      // pack the remaining weights and activations into 32-bit vectors
      // padding with 0xd9 because ternary_decoder(0xd9) = 0000000000
      if (col_cnt_im2col == 4)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA2;
        valA3 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA3;
        valA4 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA4;

        valB = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pB;
      }
      else if (col_cnt_im2col == 8)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | *(pA2 + 1) << 8 | *pA2;
        valA3 = 0xd9 << 24 | 0xd9 << 16 | *(pA3 + 1) << 8 | *pA3;
        valA4 = 0xd9 << 24 | 0xd9 << 16 | *(pA4 + 1) << 8 | *pA4;

        valB = 0xd9 << 24 | 0xd9 << 16 | *(pB + 1) << 8 | *pB;
      }
      else // col_cnt_im2col == 12
      {
        valA = 0xd9 << 24 | *(pA + 2) << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA2 + 1) << 8 | *pA2;
        valA3 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA3 + 1) << 8 | *pA3;
        valA4 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA4 + 1) << 8 | *pA4;

        valB = 0xd9 << 24 | *(pA + 2) << 16 | *(pB + 1) << 8 | *pB;
      }
      pA += PACK_INT2_SIZE(col_cnt_im2col);

      uint32_t *pA_p = &valA;
      uint32_t *pA2_p = &valA2;
      uint32_t *pA3_p = &valA3;
      uint32_t *pA4_p = &valA4;

      uint32_t *pB_p = &valB;

      InitNNRF(pA_p,  GetConfig(1, 0, 0, 0));
      InitNNRF(pA2_p, GetConfig(1, 0, 1, 0));
      InitNNRF(pA3_p, GetConfig(1, 0, 2, 0));
      InitNNRF(pA4_p, GetConfig(1, 0, 3, 0));

      InitNNRF(pB_p,  GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  pA_p,  GetConfig(0, 0, 0, 0));
      CompressedMAC(sum2, pA2_p, GetConfig(0, 0, 1, 0));
      CompressedMAC(sum3, pA3_p, GetConfig(0, 0, 2, 0));
      CompressedMAC(sum4, pA4_p, GetConfig(0, 0, 3, 0));
    }

    ThresholdCompress(res, sum, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    ThresholdCompress(res, sum2, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    ThresholdCompress(res, sum3, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    ThresholdCompress(res, sum4, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    if (!col_cnt_im2col)
    {
      pA+=(4*num_col_im2col_w);
    }
    else
    {
      pA+=(3*num_col_im2col_w);
    }
  }

  // leftover part : the hotloop above produces 4N output channels. If out_ch not divisible
  // by 4, the remaining output channels are computed below
  int out_ch_left = CHANS_DECOMPR(ch_out) & 0x3;

  if (out_ch_left == 1)
  {
    uint8_t *pB = pIn;

    uint32_t *ptrB  = (uint32_t *) pB;

    uint32_t *ptrA  = (uint32_t *) pA ;

    InitNNRF(ptrA,  GetConfig(1, 0, 0, 0));

    int sum = 0;

    if (pBias != NULL)
    {
      sum = ((int) (*pBias++));
    }

    for (int j=0; j<(num_col_im2col >> 4); j++)
    {
      InitNNRF(ptrB, GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  ptrA,  GetConfig(1, 0, 0, 0));
    }

    int col_cnt_im2col = num_col_im2col & 0xf;

    if (col_cnt_im2col)
    {
      uint16_t loop_cnt_im2col_w = (num_col_im2col >> 4) << 2;
      pA+=loop_cnt_im2col_w;

      uint16_t loop_cnt_im2col_a = (num_col_im2col >> 4) << 2;
      pB+=loop_cnt_im2col_a;

      volatile uint32_t valA, valB;
      // pack the remaining weights and activations into 32-bit vectors
      // padding with 0xd9 because ternary_decoder(0xd9) = 0000000000
      if (col_cnt_im2col == 4)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA;

        valB = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pB;
      }
      else if (col_cnt_im2col == 8)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | *(pA + 1) << 8 | *pA;

        valB = 0xd9 << 24 | 0xd9 << 16 | *(pB + 1) << 8 | *pB;
      }
      else // col_cnt_im2col == 12
      {
        valA = 0xd9 << 24 | *(pA + 2) << 16 | *(pA + 1) << 8 | *pA;

        valB = 0xd9 << 24 | *(pA + 2) << 16 | *(pB + 1) << 8 | *pB;
      }
      pA += PACK_INT2_SIZE(col_cnt_im2col);

      uint32_t *pA_p = &valA;

      uint32_t *pB_p = &valB;

      InitNNRF(pA_p,  GetConfig(1, 0, 0, 0));

      InitNNRF(pB_p,  GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  pA_p,  GetConfig(0, 0, 0, 0));
    }

    ThresholdCompress(res, sum, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    if (!col_cnt_im2col)
    {
      pA+=num_col_im2col_w;
    }
  }
  else if (out_ch_left == 2)
  {
    uint8_t *pB = pIn;

    uint32_t *ptrB  = (uint32_t *) pB;

    uint8_t *pA2 = (pA + num_col_im2col_w);

    uint32_t *ptrA  = (uint32_t *) pA ;
    uint32_t *ptrA2 = (uint32_t *) pA2;

    InitNNRF(ptrA,  GetConfig(1, 0, 0, 0));
    InitNNRF(ptrA2, GetConfig(1, 0, 1, 0));

    int sum = 0;
    int sum2 = 0;

    if (pBias != NULL)
    {
      sum = ((int) (*pBias++));
      sum2 = ((int) (*pBias++));
    }

    for (int j=0; j<(num_col_im2col >> 4); j++)
    {
      InitNNRF(ptrB, GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  ptrA,  GetConfig(1, 0, 0, 0));
      CompressedMAC(sum2, ptrA2, GetConfig(1, 0, 1, 0));
    }

    int col_cnt_im2col = num_col_im2col & 0xf;

    if (col_cnt_im2col)
    {
      uint16_t loop_cnt_im2col_w = (num_col_im2col >> 4) << 2;
      pA+=loop_cnt_im2col_w;
      pA2+=loop_cnt_im2col_w;

      uint16_t loop_cnt_im2col_a = (num_col_im2col >> 4) << 2;
      pB+=loop_cnt_im2col_a;

      volatile uint32_t valA, valA2, valB;
      // pack the remaining weights and activations into 32-bit vectors
      // padding with 0xd9 because ternary_decoder(0xd9) = 0000000000
      if (col_cnt_im2col == 4)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA2;

        valB = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pB;
      }
      else if (col_cnt_im2col == 8)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | *(pA2 + 1) << 8 | *pA2;

        valB = 0xd9 << 24 | 0xd9 << 16 | *(pB + 1) << 8 | *pB;
      }
      else // col_cnt_im2col == 12
      {
        valA = 0xd9 << 24 | *(pA + 2) << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA2 + 1) << 8 | *pA2;

        valB = 0xd9 << 24 | *(pA + 2) << 16 | *(pB + 1) << 8 | *pB;
      }
      pA += PACK_INT2_SIZE(col_cnt_im2col);

      uint32_t *pA_p = &valA;
      uint32_t *pA2_p = &valA2;

      uint32_t *pB_p = &valB;

      InitNNRF(pA_p,  GetConfig(1, 0, 0, 0));
      InitNNRF(pA2_p, GetConfig(1, 0, 1, 0));

      InitNNRF(pB_p,  GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  pA_p,  GetConfig(0, 0, 0, 0));
      CompressedMAC(sum2, pA2_p, GetConfig(0, 0, 1, 0));
    }

    ThresholdCompress(res, sum, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    ThresholdCompress(res, sum2, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    if (!col_cnt_im2col)
    {
      pA+=(2*num_col_im2col_w);
    }
    else
    {
      pA+=num_col_im2col_w;
    }
  }
  else if (out_ch_left == 3)
  {
    uint8_t *pB = pIn;

    uint32_t *ptrB  = (uint32_t *) pB;

    uint8_t *pA2 = (pA + num_col_im2col_w);
    uint8_t *pA3 = (pA2 + num_col_im2col_w);

    uint32_t *ptrA  = (uint32_t *) pA ;
    uint32_t *ptrA2 = (uint32_t *) pA2;
    uint32_t *ptrA3 = (uint32_t *) pA3;

    InitNNRF(ptrA,  GetConfig(1, 0, 0, 0));
    InitNNRF(ptrA2, GetConfig(1, 0, 1, 0));
    InitNNRF(ptrA3, GetConfig(1, 0, 2, 0));

    int sum = 0;
    int sum2 = 0;
    int sum3 = 0;

    if (pBias != NULL)
    {
      sum = ((int) (*pBias++));
      sum2 = ((int) (*pBias++));
      sum3 = ((int) (*pBias++));
    }

    for (int j=0; j<(num_col_im2col >> 4); j++)
    {
      InitNNRF(ptrB, GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  ptrA,  GetConfig(1, 0, 0, 0));
      CompressedMAC(sum2, ptrA2, GetConfig(1, 0, 1, 0));
      CompressedMAC(sum3, ptrA3, GetConfig(1, 0, 2, 0));
    }

    int col_cnt_im2col = num_col_im2col & 0xf;

    if (col_cnt_im2col)
    {
      uint16_t loop_cnt_im2col_w = (num_col_im2col >> 4) << 2;
      pA+=loop_cnt_im2col_w;
      pA2+=loop_cnt_im2col_w;
      pA3+=loop_cnt_im2col_w;

      uint16_t loop_cnt_im2col_a = (num_col_im2col >> 4) << 2;
      pB+=loop_cnt_im2col_a;

      volatile uint32_t valA, valA2, valA3, valB;
      // pack the remaining weights and activations into 32-bit vectors
      // padding with 0xd9 because ternary_decoder(0xd9) = 0000000000
      if (col_cnt_im2col == 4)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA2;
        valA3 = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pA3;

        valB = 0xd9 << 24 | 0xd9 << 16 | 0xd9 << 8 | *pB;
      }
      else if (col_cnt_im2col == 8)
      {
        valA = 0xd9 << 24 | 0xd9 << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | 0xd9 << 16 | *(pA2 + 1) << 8 | *pA2;
        valA3 = 0xd9 << 24 | 0xd9 << 16 | *(pA3 + 1) << 8 | *pA3;

        valB = 0xd9 << 24 | 0xd9 << 16 | *(pB + 1) << 8 | *pB;
      }
      else // col_cnt_im2col == 12
      {
        valA = 0xd9 << 24 | *(pA + 2) << 16 | *(pA + 1) << 8 | *pA;
        valA2 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA2 + 1) << 8 | *pA2;
        valA3 = 0xd9 << 24 | *(pA + 2) << 16 | *(pA3 + 1) << 8 | *pA3;

        valB = 0xd9 << 24 | *(pA + 2) << 16 | *(pB + 1) << 8 | *pB;
      }
      pA += PACK_INT2_SIZE(col_cnt_im2col);

      uint32_t *pA_p = &valA;
      uint32_t *pA2_p = &valA2;
      uint32_t *pA3_p = &valA3;

      uint32_t *pB_p = &valB;

      InitNNRF(pA_p,  GetConfig(1, 0, 0, 0));
      InitNNRF(pA2_p, GetConfig(1, 0, 1, 0));
      InitNNRF(pA3_p, GetConfig(1, 0, 2, 0));

      InitNNRF(pB_p,  GetConfig(0, 1, 0, 0));

      CompressedMAC(sum,  pA_p,  GetConfig(0, 0, 0, 0));
      CompressedMAC(sum2, pA2_p, GetConfig(0, 0, 1, 0));
      CompressedMAC(sum3, pA3_p, GetConfig(0, 0, 2, 0));
    }

    ThresholdCompress(res, sum, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    ThresholdCompress(res, sum2, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    ThresholdCompress(res, sum3, *currThr++);
    check_store(res, pOut);
    reset_currThr();

    if (!col_cnt_im2col)
    {
      pA+=(3*num_col_im2col_w);
    }
    else
    {
      pA+=(2*num_col_im2col_w);
    }
  }

  *thrc_res = res;

  pOut+=incr_val; // ch_out_r if a store was performed, else 0
  return pOut;
}


