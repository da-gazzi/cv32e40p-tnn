#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

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

inline void check_store(uint32_t res, uint8_t *pOut) {
  // if counter value equals 0 (i.e. 5 computations are finished), store the compressed output to the output pointer
  if (res & 0xe0000000 == 0x0) {
    *pOut = res & 0xff;
    pOut++;
  }
}

#define GetConfig(a_update, b_update, a_reg, b_reg) a_update << 4 | b_update << 3 | a_reg << 1 | b_reg

uint8_t pIn[] = {
  0x0,  0x1,  0x2,  0x3,  0x4,  0x5,  0x6,  0x7,  0x8,  0x9,
  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
  0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
  0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
  0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
  0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
  0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79
};

uint8_t pWeight [] = {
  0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9,
  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
  0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
  0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
  0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
  0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
  0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
  0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
  0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99,
  0x100, 0x101, 0x102, 0x103, 0x104, 0x105, 0x106, 0x107, 0x108, 0x109,
  0x110, 0x111, 0x112, 0x113, 0x114, 0x115, 0x116, 0x117, 0x118, 0x119,
  0x120, 0x121, 0x122, 0x123, 0x124, 0x125, 0x126, 0x127, 0x128, 0x129,
  0x130, 0x131, 0x132, 0x133, 0x134, 0x135, 0x136, 0x137, 0x138, 0x139,
  0x140, 0x141, 0x142, 0x143, 0x144, 0x145, 0x146, 0x147, 0x148, 0x149,
  0x150, 0x151, 0x152, 0x153, 0x154, 0x155, 0x156, 0x157, 0x158, 0x159,
  0x160, 0x161, 0x162, 0x163, 0x164, 0x165, 0x166, 0x167, 0x168, 0x169,
  0x170, 0x171, 0x172, 0x173, 0x174, 0x175, 0x176, 0x177, 0x178, 0x179
};

uint32_t thrs_packed [] = {
  0xa0014,
  0xb0012,
  0x110016,
  0x8000d
};

// input tensor
// original:   4 x 4 x 25 activations = 4 x 4 x 50bits
// compressed: 4 x 4 x 40bits

// weight tensor
// original:   4 x 25 x 3 x 3 activations = 4 x 50bits x 3 x 3
// compressed: 4 x 40 x 3 x 3

int main(int argc, char *argv[])
{
  /* kernel input arguments */
  int ch_in, dim_kernel_x, dim_kernel_y, ch_out, dim_in_x, dim_in_y; // uncompressed!
  dim_in_x = 4;
  dim_in_y = 4;
  ch_in = 25; // must be multiple of 5

  dim_kernel_x = 3;
  dim_kernel_y = 3;
  ch_out = 4; // is this okay? should it also be a multiple of 5?
  int8_t *pBias = NULL;
  uint32_t num_col_im2col = ch_in * dim_kernel_x * dim_kernel_y * 0.8; // the weights and acts are compressed
  /* ---------------------- */

  struct MyStruct x;
  uint16_t ch_out_r = PACK_INT2_SIZE(ch_out);

  uint16_t num_col_im2col_w = PACK_INT2_SIZE(num_col_im2col); // in how many bytes do the activations fit?
  uint16_t num_col_im2col_a = PACK_INT2_SIZE(num_col_im2col);
  uint8_t *pOut;

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

    res = ThresholdCompress(res, sum, thrs_packed[0]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum2, thrs_packed[1]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum3, thrs_packed[2]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum4, thrs_packed[3]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum5, thrs_packed[0]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum6, thrs_packed[1]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum7, thrs_packed[2]);
    check_store(res, pOut);

    res = ThresholdCompress(res, sum8, thrs_packed[3]);
    check_store(res, pOut);
  }
  return EXIT_SUCCESS;
}
