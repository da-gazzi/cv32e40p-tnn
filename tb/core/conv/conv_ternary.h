#include <stdio.h>
#include "pulp_nn_utils.h"


// TODO: review argument order
void __attribute__((noinline)) xpulp_nn_conv_ternary(
                        uint8_t  *pIn,
                        uint8_t  *pIm2ColBuffer,
                        int8_t   *pBias,
                        uint8_t  *pOut,
                        uint8_t  *pWeight,
                        uint32_t *pThr,
                        uint16_t  dim_in_x,
                        uint16_t  dim_in_y,
                        uint16_t  ch_in,
                        uint16_t  dim_out_x,
                        uint16_t  dim_out_y,
                        uint16_t  ch_out,
                        uint16_t  dim_kernel_x,
                        uint16_t  dim_kernel_y,
                        uint16_t  padding_y_top,
                        uint16_t  padding_y_bottom,
                        uint16_t  padding_x_left,
                        uint16_t  padding_x_right,
                        uint16_t  stride_x,
                        uint16_t  stride_y)
{
  uint16_t ch_in_r = PACK_INT2_SIZE(ch_in);
  uint16_t ch_out_r = PACK_INT2_SIZE(ch_out);
  int core_id = 0;
  //int core_id = pi_core_id();
  uint8_t * pIm2ColBase = pIm2ColBuffer + (2 * core_id * PACK_INT2_SIZE(ch_in) * dim_kernel_x * dim_kernel_y);
  int i_out_y, i_out_x, i_ker_y, i_ker_x;
  int Log2Core;

  uint8_t extra_chunk = ((dim_out_y & (NUM_CORES-1)) != 0);
  uint8_t extra_chunk_r;
  uint16_t dim_out_x_r;
  uint8_t section;
  int core_id_r;

  if(extra_chunk && dim_out_x > 1)
  {
    Log2Core = log2(NUM_CORES >> 1);
    core_id_r = (core_id >> 1);
    dim_out_x_r = (dim_out_x >> 1);
    section = (core_id & 0x1);
    extra_chunk_r = ((dim_out_y & ((NUM_CORES >> 1) - 1)) != 0);
  }
  else
  {
    Log2Core = log2(NUM_CORES);
    core_id_r = core_id;
    dim_out_x_r = dim_out_x;
    section = 0;
    extra_chunk_r = extra_chunk;
    extra_chunk = 0;
  }

  uint8_t flag_dim_out_x_odd = dim_out_x & 0x01;

  int chunk = (dim_out_y >> Log2Core) + extra_chunk_r;

  int start_pixel = min((chunk * core_id_r), dim_out_y);
  int stop_pixel = min(start_pixel + chunk, dim_out_y);

  uint8_t *pIm2Col = pIm2ColBase;
  uint8_t *pOutBuffer = pOut + (start_pixel * ch_out_r * dim_out_x) + (section * ch_out_r * dim_out_x_r);

  int thrc_res1, thrc_res2;

  for (i_out_y = start_pixel; i_out_y < stop_pixel; i_out_y++)
  {
    for(i_out_x=(section * dim_out_x_r); i_out_x<(dim_out_x_r + (section * (dim_out_x_r + flag_dim_out_x_odd))); i_out_x++)
    {
      if(i_out_y < padding_y_top)
      {
        for(i_ker_y=((i_out_y * stride_y) - padding_y_top); i_ker_y<((i_out_y * stride_y) - padding_y_top + dim_kernel_y); i_ker_y++)
        {
          for(i_ker_x=((i_out_x * stride_x) - padding_x_left); i_ker_x<((i_out_x * stride_x) - padding_x_left + dim_kernel_x); i_ker_x++)
          {
            if((i_ker_y < 0) || (i_ker_y >= dim_in_y) || (i_ker_x < 0) || (i_ker_x >= dim_in_x))
            {
              xpulp_nn_zero_mem_u2(pIm2Col, ch_in);
            }
            else
            {
              xpulp_nn_im2col_u2_to_u2((uint8_t*) (pIn + ((i_ker_y * dim_in_x + i_ker_x) * ch_in_r)), pIm2Col, ch_in);
            }
            pIm2Col+=PACK_INT2_SIZE(ch_in);
          }
        }
      }
      else if(i_out_y < dim_out_y - padding_y_bottom)
      {
        if(i_out_x < padding_x_left)
        {
          for(i_ker_y=((i_out_y * stride_y) - padding_y_top); i_ker_y<((i_out_y * stride_y) - padding_y_top + dim_kernel_y); i_ker_y++)
          {
            for(i_ker_x=((i_out_x * stride_x) - padding_x_left); i_ker_x<((i_out_x * stride_x) - padding_x_left + dim_kernel_x); i_ker_x++)
            {
              if((i_ker_x < 0) || (i_ker_x >= dim_in_x))
              {
                xpulp_nn_zero_mem_u2(pIm2Col, ch_in);
              }
              else
              {
                xpulp_nn_im2col_u2_to_u2((uint8_t*) (pIn + ((i_ker_y * dim_in_x + i_ker_x) * ch_in_r)), pIm2Col, ch_in);
              }
              pIm2Col+=PACK_INT2_SIZE(ch_in);
            }
          }
        }
        else if(i_out_x < (dim_out_x - padding_x_right))
        {
          for(i_ker_y=((i_out_y * stride_y) - padding_y_top); i_ker_y<((i_out_y * stride_y) - padding_y_top + dim_kernel_y); i_ker_y++)
          {
            xpulp_nn_im2col_u2_to_u2((uint8_t*) pIn + (i_ker_y * dim_in_x + i_out_x * stride_x - padding_x_left)*ch_in_r,pIm2Col,ch_in * dim_kernel_x);
            pIm2Col+=PACK_INT2_SIZE(ch_in * dim_kernel_x);
          }
        }
        else
        {
          for(i_ker_y=((i_out_y * stride_y) - padding_y_top); i_ker_y<((i_out_y * stride_y) - padding_y_top + dim_kernel_y); i_ker_y++)
          {
            for(i_ker_x = i_out_x * stride_x - padding_x_left; i_ker_x < i_out_x * stride_x - padding_x_left + dim_kernel_x; i_ker_x++)
            {
              if((i_ker_x < 0) || (i_ker_x >= dim_in_x))
              {
                xpulp_nn_zero_mem_u2(pIm2Col, ch_in);
              }
              else
              {
                xpulp_nn_im2col_u2_to_u2((uint8_t *)pIn + (i_ker_y*dim_in_x+i_ker_x)* ch_in_r, pIm2Col, ch_in);
              }
              pIm2Col+=PACK_INT2_SIZE(ch_in);
            }
          }
        }
      }
      else
      {
        for(i_ker_y=((i_out_y * stride_y) - padding_y_top); i_ker_y<((i_out_y * stride_y) - padding_y_top + dim_kernel_y); i_ker_y++)
        {
          for(i_ker_x = i_out_x * stride_x - padding_x_left; i_ker_x < i_out_x * stride_x - padding_x_left + dim_kernel_x; i_ker_x++)
          {
            if(i_ker_y < 0 || (i_ker_y >= dim_in_y) || i_ker_x < 0 || i_ker_x >= dim_in_x)
            {
              xpulp_nn_zero_mem_u2(pIm2Col, ch_in);
            }
            else
            {
              xpulp_nn_im2col_u2_to_u2((uint8_t *) pIn + (i_ker_y * dim_in_x + i_ker_x) * ch_in_r, pIm2Col, ch_in);
            }
            pIm2Col+=PACK_INT2_SIZE(ch_in);
          }
        }
      }
      if(pIm2Col == (pIm2ColBase + ((PACK_INT2_SIZE(ch_in) * dim_kernel_x * dim_kernel_y) << 1)))
      {
        pOutBuffer = xpulp_nn_matmul_ternary(
          pIm2ColBase,
          pBias,
          pThr,
          pOutBuffer,
          pOutBuffer + ch_out_r,
          pWeight,
          (ch_in * dim_kernel_x * dim_kernel_y),
          ch_out,
          &thrc_res1,
          &thrc_res2
        );

        pIm2Col = pIm2ColBase;
      }
    }

  // TODO: Rewrite the whole next part that takes care of the remaining SDOTPs
  }
  //pi_cl_team_barrier(0);
}
