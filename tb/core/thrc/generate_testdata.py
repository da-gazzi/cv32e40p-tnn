from random import randrange
from mako.template import Template
import numpy as np

MAX_PREACTIVATION = 1152 # kernel_height*kernel_width*input_channels*2
MIN_PREACTIVATION = -MAX_PREACTIVATION
MAX_THRESHOLD = MAX_PREACTIVATION
MIN_THRESHOLD = -MAX_THRESHOLD
NUM_STIMULI = 100

def getbinary(x, n):
    # get n-bit binary representation of x
    if x >= 0:
        return format(x, 'b').zfill(n)
    else:
        return format(2**n+x, 'b')

def trit2dec(x: str):
    assert x in ['11', '00', '01'], 'Invalid encoded trit'
    if (x=='00'):
        return 0
    elif (x=='01'):
        return 1
    return -1

if __name__=='__main__':
    enc_stimuli_file = open('./testdata_gen_files/encoder_stimuli.txt', 'r')
    enc_stimuli = enc_stimuli_file.readlines()
    enc_stimuli_file.close()

    enc_exp_resp_file = open('./testdata_gen_files/encoder_exp_responses.txt', 'r')
    enc_exp_resp = enc_exp_resp_file.readlines()
    enc_exp_resp_file.close()

    encoding_map = {key.strip(): value.strip() for key, value in zip(enc_stimuli, enc_exp_resp)}

    generated_preactivations = []
    generated_thresholds = []
    generated_responses = []

    for i in range(NUM_STIMULI):
        # generate five preactivations
        preactivations = [randrange(MIN_PREACTIVATION, MAX_PREACTIVATION) for x in range(5)]

        # generate one low and one high threshold and pack them in one 32-bit binary vector
        thresholds = [randrange(MIN_THRESHOLD, MAX_THRESHOLD) for x in range(2)]
        threshold_lo = min(thresholds)
        threshold_hi = max(thresholds)
        thresholds_packed_bin = getbinary(threshold_lo, 16) + getbinary(threshold_hi, 16)
        thresholds_packed = int(thresholds_packed_bin, 2)

        # produce five ternary activations and compress them into one 8-bit vector
        activations = [-1 if preact < threshold_lo else (0 if preact < threshold_hi else 1) for preact in preactivations]
        activations.reverse()
        activations_bin = ''.join([getbinary(activation, 2) for activation in activations])
        activations_compr_bin = encoding_map[activations_bin]
        # replace 'don't cares' with '0' (modelsim sets ouput bit to 0 when it can be X)
        if 'X' in activations_compr_bin:
            activations_compr_bin = activations_compr_bin.replace('X', '0')
        activations_compr = int(activations_compr_bin, 2)

        generated_thresholds.append(thresholds_packed)
        generated_preactivations = generated_preactivations + preactivations
        generated_responses.append(activations_compr)

    # write data.h
    tk = {
      'data_h_incguard': 'DATA_H',
      'num_stimuli': NUM_STIMULI,
      'thresholds_varname': 'thresholds',
      'preactivations_varname': 'preactivations',
      'thresholds': generated_thresholds,
      'preactivations': generated_preactivations,
      'exp_resp_varname': 'exp_responses',
      'exp_resp': generated_responses
    }
    tmpl = Template(filename="./testdata_gen_files/data.h.template")
    s = tmpl.render(**tk)
    with open('./data.h', "w") as f:
        f.write(s)
