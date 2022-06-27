from utils import *
import argparse


if __name__=='__main__':
    n_tests = 3

    tc = TernaryConversion(
        enc_stimuli_path='./gen_files/encoder_stimuli.txt',
        enc_exp_responses_path='./gen_files/encoder_exp_responses.txt',
        dec_stimuli_path='./gen_files/decoder_stimuli.txt',
        dec_exp_responses_path='./gen_files/decoder_exp_responses.txt'
    )

    params = {}
    params['dim_in_x'] = [8, 16, 32]
    params['dim_in_y'] = [8, 16, 32]
    params['dim_kernel_x'] = [3, 3, 3]
    params['dim_kernel_y'] = [3, 3, 3]
    params['ch_in'] = [20, 20, 20]
    params['ch_out'] = [20, 20, 20]
    params['ch_in_compressed'] = [int(x * 0.8) for x in params['ch_in']]
    params['ch_out_compressed'] = [int(x * 0.8) for x in params['ch_out']]
    params['stride_x'] = [1, 1, 1]
    params['stride_y'] = [1, 1, 1]
    params['padding_x'] = [1, 1, 1]
    params['padding_y'] = [1, 1, 1]

    params['ch_in_compressed'] = []
    params['ch_out_compressed'] = []
    params['dim_out_x'] = []
    params['dim_out_y'] = []

    n_inp_acts = []
    n_weights = []

    for i in range(n_tests):
        params['ch_in_compressed'].append(int(params['ch_in'][i]*0.8))
        params['ch_out_compressed'].append(int(params['ch_out'][i]*0.8))

        params['dim_out_x'].append((params['dim_in_x'][i] + 2*params['padding_x'][i] - \
            (params['dim_kernel_x'][i]-1) - 1) // params['stride_x'][i] + 1)
        params['dim_out_y'].append((params['dim_in_y'][i] + 2*params['padding_y'][i] - \
            (params['dim_kernel_y'][i]-1) - 1) // params['stride_y'][i] + 1)

        assert params['ch_in'][i] % 5 == 0, 'Number of input channels must be a multiple of 5'
        assert params['ch_out'][i] % 5 == 0, 'Number of output channels must be a multiple of 5'

        n_inp_acts.append(params['dim_in_x'][i] * params['dim_in_y'][i] * params['ch_in'][i])
        n_weights.append(params['dim_kernel_x'][i] * params['dim_kernel_y'][i] * params['ch_in'][i] * params['ch_out'][i])

    # initialize golden model and generate dummy data
    net = TernaryConv2dWithThreshold(
        in_channels=max(params['ch_in']),
        out_channels=max(params['ch_out']),
        kernel_size=(max(params['dim_kernel_y']), max(params['dim_kernel_x'])),
        ternary_conversion=tc,
        stride=(min(params['stride_y']), min(params['stride_x'])),
        padding=(min(params['padding_y']), min(params['padding_x'])),
        groups=1)

    x = torch.randint(-1, 2, (1, max(params['ch_in']), max(params['dim_in_y']), max(params['dim_in_x']))).type(torch.float32)

    # generate weights, acts (uncompressed) and rqs params
    x_uncompressed = pack_crumbs(x.permute(0, 2, 3, 1))
    w_uncompressed = pack_crumbs(net.weight)
    kappa = torch.randint(low=-2**8, high=2**8, size=(max(params['ch_out']), 1))
    lambdax = torch.randint(low=-2**8, high=2**8, size=(max(params['ch_out']), 1))

    # generate weights, acts (compressed) and thresholds
    x_compressed = tc.compress_tensor(x.permute(0, 2, 3, 1))
    w_compressed = net.weight_c.data
    thr_packed = net.thresholds_p

    # write data_statstest.h
    tk = {
    'n_tests': n_tests,
    'data_h_incguard': 'DATA_STATS_H',
    'weight_varname': 'pWeight',
    'weight_c_varname': 'pWeight_c',
    'inp_varname': 'pIn',
    'inp_c_varname': 'pIn_c',
    'thr_varname': 'pThr',
    'kappa_varname': 'pKappa',
    'lambda_varname': 'pLambda',
    'weights': w_uncompressed,
    'weights_c': w_compressed,
    'acts': x_uncompressed,
    'acts_c': x_compressed,
    'thr': thr_packed,
    'kappa': kappa,
    'lambdax': lambdax,
    'params': params,
    'ternary_test': True
    }

    tmpl = Template(filename="./gen_files/data_statstest.h.template")
    s = tmpl.render(**tk)
    with open('./data_statstest.h', "w") as f:
        f.write(s)

    tmpl_test_ternary = Template(filename="./gen_files/test_stats.c.template")
    s = tmpl_test_ternary.render(**tk)
    with open('./test_stats_ternary.c', "w") as f:
        f.write(s)

    tk['ternary_test'] = False
    tmpl_test_xpulpnn = Template(filename="./gen_files/test_stats.c.template")
    s = tmpl_test_xpulpnn.render(**tk)
    with open('./test_stats_xpulpnn.c', "w") as f:
        f.write(s)
