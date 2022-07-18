/*
 * pulp_nn_utils.h
 * Nazareno   Bruschi  <nazareno.bruschi@unibo.it>
 * Alessandro Nadalini <alessandro.nadalini3@unibo.it>
 * Georg Rutishauser   <georgr@iis.ee.ethz.ch>
 *
 * Copyright (C) 2019-2020 ETH Zurich & University of Bologna
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __PULPNN_UTILS__
#define __PULPNN_UTILS__


#define min(a,b)                                             ((a)<(b)?(a):(b))
#define PACK_INT2_SIZE(x)                                    ((x) >> 2)

#define MemoryFence()                                        asm volatile("":::"memory")

#define CHANS_DECOMPR(x)                                     (5*x >> 2) // equivalent to division by 0.8

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
    pOut++;                               \
    incr_val=ch_out_r; }

#define reset_currThr()                           \
  if (currThr == pThr + CHANS_DECOMPR(ch_out)) {  \
    currThr = pThr;                               \
  }

typedef unsigned char  v4u __attribute__((vector_size (4)));
typedef   signed char  v4s __attribute__((vector_size (4)));

static void __attribute__((noinline)) xpulp_nn_im2col_u2_to_u2(uint8_t * pInput, uint8_t * pOutput, unsigned int blockSize)
{
  unsigned int blkCnt = blockSize >> 4u;
  int lfover = blockSize & 0x0f;
  for (int i = 0; i<blkCnt; i++)
  {
    *((v4u*)pOutput) = *((v4u*)pInput);
    pInput+=4;
    pOutput+=4;
  }
  while (lfover)
  {
    uint8_t extr;
    *((uint8_t*)pOutput) = *((uint8_t*)pInput);
    pOutput++;
    pInput++;
    lfover -= 4;
  }
}


static void __attribute__((noinline)) xpulp_nn_im2col_i2_to_i2(int8_t * pInput, int8_t * pOutput, unsigned int blockSize)
{
  unsigned int blkCnt = blockSize >> 4u;
  int lfover = blockSize & 0x0f;
  for (int i = 0; i<blkCnt; i++)
  {
    *((v4s*)pOutput) = *((v4s*)pInput);
    pInput+=4;
    pOutput+=4;
  }
  while (lfover)
  {
    int8_t extr;
    *((int8_t*)pOutput) = *((int8_t*)pInput);
    pOutput++;
    pInput++;
    lfover -= 4;
  }
}


static void __attribute__((noinline)) xpulp_nn_zero_mem_u2(uint8_t * pBuffer, unsigned int size)
{
  int lfover = size &0xf;
  for (int i=0; i<(size>>4); i++)
  {
    *((v4u *)pBuffer) = (v4u){0,0,0,0};
    MemoryFence();
    pBuffer+=4;
  }
  while(lfover)
  {
    *pBuffer++=0;
    lfover-=4;
  }
}


static void __attribute__((noinline)) xpulp_nn_zero_mem_ternary(uint8_t * pBuffer, unsigned int size)
{
  int lfover = size &0xf;
  for (int i=0; i<(size>>4); i++)
  {
    *((v4u *)pBuffer) = (v4u){0xd9,0xd9,0xd9,0xd9};
    MemoryFence();
    pBuffer+=4;
  }
  while(lfover)
  {
    *pBuffer++=0xd9;
    lfover-=4;
  }
}

#define start_cycle_counter()                                   asm volatile("csrw 0xCC0, 0x01;")
#define stop_cycle_counter()                                    asm volatile("csrw 0xCC0, 0x00;")
#define read_cycle_counter(x)                                   asm volatile("csrr %0, 0x780;" : "=r" (x))
#define reset_cycle_counter()                                   asm volatile("csrw 0x780, 0x0;")

#endif
