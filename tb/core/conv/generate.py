from utils import *
import argparse


if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--kernel', required=False, action='store_true')
    parser.add_argument('--testdata', required=False, action='store_true')
    args = parser.parse_args()

    params = {}
    params['dim_in_x'] = 2
    params['dim_in_y'] = 2
    params['dim_kernel_x'] = 2
    params['dim_kernel_y'] = 2
    params['ch_in'] = 5
    params['ch_out'] = 5
    params['ch_in_compressed'] = int(params['ch_in'] * 0.8)
    params['ch_out_compressed'] = int(params['ch_out'] * 0.8)
    params['stride_x'] = 2
    params['stride_y'] = 2
    params['padding_x'] = 1
    params['padding_y'] = 1

    # are the following correct? Add dilatons later if needed
    params['dim_out_x'] = (params['dim_in_x'] + 2*params['padding_x'] - (params['dim_kernel_x']-1) - 1) // params['stride_x'] + 1
    params['dim_out_y'] = (params['dim_in_y'] + 2*params['padding_y'] - (params['dim_kernel_y']-1) - 1) // params['stride_y'] + 1

    assert params['ch_in'] % 5 == 0, 'Number of input channels must be a multiple of 5'
    assert params['ch_out'] % 5 == 0, 'Number of output channels must be a multiple of 5'

    tc = TernaryConversion(
        enc_stimuli_path='./gen_files/encoder_stimuli.txt',
        enc_exp_responses_path='./gen_files/encoder_exp_responses.txt',
        dec_stimuli_path='./gen_files/decoder_stimuli.txt',
        dec_exp_responses_path='./gen_files/decoder_exp_responses.txt'
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
    # reorder the expected outputs to match it with the way the kernels produce the outputs (is there maybe sth wrong with the kernels?)
    y_compressed = y_compressed.reshape(-1, params['ch_out']//5).flip(dims=(1,)).reshape(-1)
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

    if args.testdata:
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

        tmpl = Template(filename="./gen_files/data.h.template")
        s = tmpl.render(**tk)
        with open('./data.h', "w") as f:
            f.write(s)

    if args.kernel:
        tmpl_matmul = Template(filename="./gen_files/matmul_ternary.h.template")
        s = tmpl_matmul.render(kernel_type='4x2')
        with open('./matmul_ternary.h', "w") as f:
            f.write(s)

        tmpl_matmul = Template(filename="./gen_files/matmul_ternary.h.template")
        s = tmpl_matmul.render(kernel_type='4x1')
        with open('./matmul_ternary_4x1.h', "w") as f:
            f.write(s)
