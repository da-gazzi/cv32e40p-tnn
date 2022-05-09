from random import randrange

MIN_STIMULUS = -1000
MAX_STIMULUS = 1000
NUM_STIMULI = 1000

def getbinary(x, n):
    # get n-bit binary representation of x
    if x >= 0:
        return format(x, 'b').zfill(n)
    else:
        return format(2**n+x, 'b')


if __name__=='__main__':
    dec_stimuli_file = open('./test_generation_files/decoder_stimuli.txt', 'r')
    dec_stimuli = dec_stimuli_file.readlines()
    dec_stimuli_file.close()

    dec_exp_resp_file = open('./test_generation_files/decoder_exp_responses.txt', 'r')
    dec_exp_resp = dec_exp_resp_file.readlines()
    dec_exp_resp_file.close()

    decoding_map = {key.strip(): value.strip() for key, value in zip(dec_stimuli, dec_exp_resp)}

    generated_stimuli = []
    generated_responses = []

    for i in range(NUM_STIMULI):
        import ipdb; ipdb.set_trace()
        stim = [randrange(-1, 2) for _ in range(16)] # produce 16 signed trits {-1, 0, 1}
        stim_bin = ''.join([getbinary(x, 2) for x in stim])
        stim_bin_split = [stim_bin[0:8], stim_bin[8:16], stim_bin[16:24], stim_bin[24:32]]
        exp_resp_split = [decoding_map[x] for x in stim_bin_split]
        exp_resp_bin = ''.join(exp_resp_split)

        generated_stimuli.append(stim_bin)
        generated_responses.append(exp_resp_bin)

#    # write to files
#    with open("test_generation_files/stimuli.txt", "w") as fp:
#        fp.writelines(f'{l}\n' for l in generated_stimuli)
#
#    with open("test_generation_files/exp_responses.txt", "w") as fp:
#        fp.writelines(f'{l}\n' for l in generated_responses)
