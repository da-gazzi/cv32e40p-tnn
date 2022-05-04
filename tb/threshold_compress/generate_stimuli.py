from random import randrange

MAX_PREACTIVATION = 1152 # kernel_height*kernel_width*input_channels*2
MIN_PREACTIVATION = 0
MAX_THRESHOLD = MAX_PREACTIVATION
MIN_THRESHOLD = 0
NUM_STIMULI = 100

def getbinary(x, n):
    # get n-bit binary representation of x
    if x >= 0:
        return format(x, 'b').zfill(n)
    else:
        return format(2**n+x, 'b')


if __name__=='__main__':
    enc_stimuli_file = open('./stimuli/encoder_stimuli.txt', 'r')
    enc_stimuli = enc_stimuli_file.readlines()
    enc_stimuli_file.close()

    enc_exp_resp_file = open('./stimuli/encoder_exp_responses.txt', 'r')
    enc_exp_resp = enc_exp_resp_file.readlines()
    enc_exp_resp_file.close()

    encoding_map = {key.strip(): value.strip() for key, value in zip(enc_stimuli, enc_exp_resp)}

    generated_stimuli = []
    generated_responses = []

    for i in range(NUM_STIMULI):
        preactivations = [randrange(MIN_PREACTIVATION, MAX_PREACTIVATION) for x in range(5)]
        preactivations_bin = [getbinary(preactivation, 32) for preactivation in preactivations]
        thresholds = [randrange(MIN_THRESHOLD, MAX_THRESHOLD) for x in range(2)]
        threshold_lo = min(thresholds)
        threshold_hi = max(thresholds)
        thresholds_bin = getbinary(threshold_lo, 16) + getbinary(threshold_hi, 16)

        activations = [-1 if preact < threshold_lo else (0 if preact < threshold_hi else 1) for preact in preactivations]
        activations.reverse()
        activations_bin = ''.join([getbinary(activation, 2) for activation in activations])
        activations_bin_compr = encoding_map[activations_bin]

        generated_stimuli.append(thresholds_bin)
        generated_stimuli = generated_stimuli + preactivations_bin
        generated_responses.append(activations_bin_compr)

    # write to files
    with open("stimuli/stimuli.txt", "w") as fp:
        fp.writelines(f'{l}\n' for l in generated_stimuli)

    with open("stimuli/exp_responses.txt", "w") as fp:
        fp.writelines(f'{l}\n' for l in generated_responses)
