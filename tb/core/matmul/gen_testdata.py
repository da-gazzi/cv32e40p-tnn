import torch
import torch.nn as nn
from random import randint
from mako.template import Template
import numpy as np


def getbinary(x, n):
    x = x.item()
    # get n-bit binary representation of x
    if x >= 0:
        return format(x, 'b').zfill(n)
    else:
        return format(2**n+x, 'b')


class TernaryConversion:
    def __init__(self, enc_stimuli_path, enc_exp_responses_path, dec_stimuli_path, dec_exp_responses_path):
        with open(enc_stimuli_path, 'r') as enc_stimuli_file:
            enc_stimuli = enc_stimuli_file.readlines()

        with open(enc_exp_responses_path, 'r') as enc_exp_responses_file:
            enc_exp_responses = enc_exp_responses_file.readlines()

        with open(dec_stimuli_path, 'r') as dec_stimuli_file:
            dec_stimuli = dec_stimuli_file.readlines()

        with open(dec_exp_responses_path, 'r') as dec_exp_responses_file:
            dec_exp_responses = dec_exp_responses_file.readlines()

        self.encoding_map = {key.strip(): value.strip() for key, value in zip(enc_stimuli, enc_exp_responses)}
        self.decoding_map = {key.strip(): value.strip() for key, value in zip(dec_stimuli, dec_exp_responses)}

    def compress_tensor(self, t):
        tmp = t.reshape(-1)
        # append zeros at the end of the tensor to make its number of elements divisible by 5
        if tmp.numel()%5 != 0:
            tmp = torch.cat((tmp, torch.zeros(5-tmp.numel()%5)))
        tmp = tmp.reshape(-1, 5).type(torch.int8)
        compressed_t = []
        for x in tmp:
            x_bin = ''.join([getbinary(y, 2) for y in x])
            x_compressed_bin = self.encoding_map[x_bin]
            # replace 'don't cares' with '0' or '1' randomly
            if 'X' in x_compressed_bin:
                x_compressed_bin = x_compressed_bin.replace('X', str(randint(0, 1)))
            compressed_t.append(int(x_compressed_bin, 2))

        return torch.Tensor(compressed_t).type(torch.uint8)

    def decompress_tensor(self, t):
        decompressed_t = []
        for i, x in enumerate(t):
            x_bin = getbinary(x, 8)
            x_decompressed_bin = self.decoding_map[x_bin]
            x_decompressed = [int(x_decompressed_bin[2*i:2*i+2], 2) for i in range(0, 5)] # split the binary string in 5 ternary integers
            assert 2 not in x_decompressed, '10 found in decompressed vector - not permitted'
            x_decompressed = [-1 if n==3 else n for n in x_decompressed] # 11s are converted to 3s - convert these to -1s
            decompressed_t = decompressed_t + x_decompressed

        return torch.Tensor(decompressed_t).type(torch.int8)


if __name__=='__main__':
    MATMUL_A = 4
    MATMUL_B = 2
    k_x = 3
    k_y = 3
    ch_in = 10
    #ch_out = 8 # needs to be a multiple of 5 as well? Atm, must be a multiple of 4
    assert ch_in % 5 == 0, 'Number of input channels must be a multiple of 5'

    num_col_im2col = k_x * k_y * ch_in
    num_col_im2col_compressed = int(num_col_im2col * 0.8)

    weights = torch.randint(-1, 2, (MATMUL_A, num_col_im2col)).type(torch.float32)
    acts = torch.randint(-1, 2, (num_col_im2col, MATMUL_B)).type(torch.float32)

    thr_max = k_x * k_y
    thr_min = -thr_max
    thresh_lo = torch.randint(thr_min, thr_max // 2, (MATMUL_A, 1))
    thresh_hi = thresh_lo + torch.randint(thr_max//2, thr_max, (MATMUL_A, 1))

    out_preact = torch.matmul(weights, acts)

    tc = TernaryConversion(
        enc_stimuli_path='./testdata_gen_files/encoder_stimuli.txt',
        enc_exp_responses_path='./testdata_gen_files/encoder_exp_responses.txt',
        dec_stimuli_path='./testdata_gen_files/decoder_stimuli.txt',
        dec_exp_responses_path='./testdata_gen_files/decoder_exp_responses.txt'
    )

    acts_compressed = tc.compress_tensor(acts)
    weights_compressed = tc.compress_tensor(weights)

    tmp1 = -1*(out_preact < thresh_lo)
    tmp2 = out_preact >= thresh_hi
    outp = (tmp1 + tmp2).to(torch.float32)

    outp_compressed = tc.compress_tensor(outp)

    # pack the thresholds
    thresh_lo = torch.where(thresh_lo < 0, 2**16+thresh_lo, thresh_lo)
    thresh_hi = torch.where(thresh_hi < 0, 2**16+thresh_hi, thresh_hi)
    thr_packed = (thresh_lo << 16 | thresh_hi).squeeze().numpy()

    # write data.h
    tk = {
      'data_h_incguard': 'DATA_H',
      'weight_varname': 'pWeight',
      'inp_varname': 'pIn',
      'thr_varname': 'pThr',
      'weights': weights_compressed,
      'acts': acts_compressed,
      'thr': thr_packed,
      'exp_outp_varname': 'pOut_exp',
      'exp_outp': outp_compressed,
      'num_col_im2col': num_col_im2col_compressed
    }
    tmpl = Template(filename="./testdata_gen_files/data.h.template")
    s = tmpl.render(**tk)
    with open('./data.h', "w") as f:
        f.write(s)

