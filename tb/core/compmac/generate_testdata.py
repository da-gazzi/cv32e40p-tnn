from random import randrange
from mako.template import Template
import numpy as np

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
    dec_stimuli_file = open('./testdata_gen_files/decoder_stimuli.txt', 'r')
    dec_stimuli = dec_stimuli_file.readlines()
    dec_stimuli_file.close()

    dec_exp_resp_file = open('./testdata_gen_files/decoder_exp_responses.txt', 'r')
    dec_exp_resp = dec_exp_resp_file.readlines()
    dec_exp_resp_file.close()

    decoding_map = {key.strip(): value.strip() for key, value in zip(dec_stimuli, dec_exp_resp)}

    generated_stim1 = []
    generated_stim2 = []
    generated_responses = []

    for i in range(NUM_STIMULI):
        # produce 32-bit compressed inputs
        stim1_bin = ''.join([str(randrange(0, 2)) for _ in range(32)])
        stim2_bin = ''.join([str(randrange(0, 2)) for _ in range(32)])

        # convert the compressed input strings to ints to write them later in the data.h file
        stim1 = int(stim1_bin, 2)
        stim2 = int(stim2_bin, 2)

        # decode the compressed 32-bit inputs to 40 bits
        stim1_bin_split = [stim1_bin[0:8], stim1_bin[8:16], stim1_bin[16:24], stim1_bin[24:32]]
        stim2_bin_split = [stim2_bin[0:8], stim2_bin[8:16], stim2_bin[16:24], stim2_bin[24:32]]
        decoded1_split = [decoding_map[x] for x in stim1_bin_split]
        decoded2_split = [decoding_map[x] for x in stim2_bin_split]
        decoded1_bin = ''.join(decoded1_split)
        decoded2_bin = ''.join(decoded2_split)
        decoded1_trits = [trit2dec(decoded1_bin[2*n:2*(n+1)]) for n in range(len(decoded1_bin)//2)]
        decoded2_trits = [trit2dec(decoded2_bin[2*n:2*(n+1)]) for n in range(len(decoded2_bin)//2)]

        # generate the dot product
        exp_resp = int(np.dot(decoded1_trits, decoded2_trits))
        generated_stim1.append(stim1)
        generated_stim2.append(stim2)
        generated_responses.append(exp_resp)

    # write data.h
    tk = {
      'data_h_incguard': 'DATA_H',
      'num_stimuli': NUM_STIMULI,
      'stim1_varname': 'compr_w',
      'stim2_varname': 'compr_x',
      'stim1': generated_stim1,
      'stim2': generated_stim2,
      'exp_resp_varname': 'exp_responses',
      'exp_resp': generated_responses
    }
    tmpl = Template(filename="./testdata_gen_files/data.h.template")
    s = tmpl.render(**tk)
    with open('./data.h', "w") as f:
        f.write(s)

#    # write to files
#    with open("test_generation_files/stimuli.txt", "w") as fp:
#        fp.writelines(f'{l}\n' for l in generated_stimuli)
#
#    with open("test_generation_files/exp_responses.txt", "w") as fp:
#        fp.writelines(f'{l}\n' for l in generated_responses)
