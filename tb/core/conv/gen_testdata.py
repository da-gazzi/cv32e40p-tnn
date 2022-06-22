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


class TernaryConv2dWithThreshold(nn.Conv2d):
    def __init__(
        self,
        in_channels,
        out_channels,
        kernel_size,
        ternary_conversion,
        **kwargs
    ):
        super(TernaryConv2dWithThreshold, self).__init__(in_channels, out_channels, kernel_size, bias=False, **kwargs) # atm, no biases implemented
        self.weight.data.random_(-1, 2) # generate random ternary weights

        # threshold bounds are set arbitrarily
        thr_max = self.kernel_size[0]*self.kernel_size[1]
        thr_min = -thr_max
        # generate thresholds
        self.thresh_lo = torch.randint(thr_min, thr_max, (self.out_channels,))
        self.thresh_hi = self.thresh_lo + torch.randint(0, thr_max//2, (self.out_channels,))

        self.tc = ternary_conversion

    # get the thresholds packed in a single 32 bit register
    # bits 15:0 : thresh_hi
    # bits 31:16: thresh_lo
    @property
    def thresholds_p(self):
        thr_lo = torch.where(self.thresh_lo < 0, 2**16+self.thresh_lo, self.thresh_lo)
        thr_hi = torch.where(self.thresh_hi < 0, 2**16+self.thresh_hi, self.thresh_hi)

        return (thr_lo << 16 | thr_hi).numpy()

    # get the weights in their compressed form
    @property
    def weight_c(self):
        return self.tc.compress_tensor(self.weight.data.permute(0, 2, 3, 1))

    def forward(self, x, preacts=False):
        x = super().forward(x)
        if preacts:
            return x
        tmp1 = -1*(x < self.thresh_lo.reshape(-1, 1, 1))
        tmp2 = (x >= self.thresh_hi.reshape(-1, 1, 1))
        x = tmp1 + tmp2
        return x


if __name__=='__main__':
    params = {}
    params['dim_in_x'] = 4
    params['dim_in_y'] = 4
    params['dim_kernel_x'] = 3
    params['dim_kernel_y'] = 3
    params['ch_in'] = 5
    params['ch_out'] = 5
    params['ch_in_compressed'] = int(params['ch_in'] * 0.8)
    params['ch_out_compressed'] = int(params['ch_out'] * 0.8)
    params['stride_x'] = 1
    params['stride_y'] = 1
    params['padding_x'] = 1
    params['padding_y'] = 1

    # are the following correct? Add dilatons later if needed
    params['dim_out_x'] = (params['dim_in_x'] + 2*params['padding_x'] - (params['dim_kernel_x']-1) - 1) // params['stride_x'] + 1
    params['dim_out_y'] = (params['dim_in_y'] + 2*params['padding_y'] - (params['dim_kernel_y']-1) - 1) // params['stride_y'] + 1

    assert params['ch_in'] % 5 == 0, 'Number of input channels must be a multiple of 5'
    assert params['ch_out'] % 5 == 0, 'Number of output channels must be a multiple of 5'

    tc = TernaryConversion(
        enc_stimuli_path='./testdata_gen_files/encoder_stimuli.txt',
        enc_exp_responses_path='./testdata_gen_files/encoder_exp_responses.txt',
        dec_stimuli_path='./testdata_gen_files/decoder_stimuli.txt',
        dec_exp_responses_path='./testdata_gen_files/decoder_exp_responses.txt'
    )

    # initialize golden model
    net = TernaryConv2dWithThreshold(
        in_channels=params['ch_in'],
        out_channels=params['ch_out'],
        kernel_size=(params['dim_kernel_y'], params['dim_kernel_x']),
        ternary_conversion=tc,
        stride=(params['stride_y'], params['stride_x']),
        padding=(params['padding_y'], params['padding_x']),
        groups=1)

    x = torch.randint(-1, 2, (1, params['ch_in'], params['dim_in_y'], params['dim_in_x'])).type(torch.float32)

    y = net(x)
    y_preact = net(x, preacts=True)

    x_compressed = tc.compress_tensor(x.permute(0, 2, 3, 1))
    y_compressed = tc.compress_tensor(y.permute(0, 2, 3, 1).flip(dims=(3,)))
    w_compressed = net.weight_c.data
    thr_packed = net.thresholds_p

    with open('./inputs.txt', 'w') as f:
        print('pWeight:\n', net.weight, file=f)
        print('pIn:\n', x, file=f)
        print('out_preact:\n', y_preact, file=f)
        print('thresh_lo:\n', net.thresh_lo, file=f)
        print('thresh_hi:\n', net.thresh_hi, file=f)
        print('outp:\n', y, file=f)
        print('outp_compressed:\n', y_compressed, file=f)

    # write data.h
    tk = {
      'data_h_incguard': 'DATA_H',
      'weight_varname': 'pWeight',
      'inp_varname': 'pIn',
      'thr_varname': 'pThr',
      'weights': w_compressed,
      'acts': x_compressed,
      'thr': thr_packed,
      'exp_outp_varname': 'pOut_exp',
      'exp_outp': y_compressed,
      'params': params
    }

    tmpl = Template(filename="./testdata_gen_files/data.h.template")
    s = tmpl.render(**tk)
    with open('./data.h', "w") as f:
        f.write(s)

    tmpl_matmul = Template(filename="./testdata_gen_files/matmul_ternary.h.template")
    s = tmpl_matmul.render()
    with open('./matmul_ternary.h', "w") as f:
        f.write(s)

    tmpl_matmul = Template(filename="./testdata_gen_files/matmul_ternary_4x1.h.template")
    s = tmpl_matmul.render()
    with open('./matmul_ternary_4x1.h', "w") as f:
        f.write(s)
