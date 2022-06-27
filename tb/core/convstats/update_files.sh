#!/bin/bash

cp ~/xpulptnn-kernels/matmul_ternary*.h .
cp ~/xpulptnn-kernels/conv_ternary.h .
cp ~/xpulptnn-kernels/pulp_nn_utils.h .
cp ~/xpulptnn-kernels/gen_files/matmul*.h.template ./gen_files/
cp ~/xpulptnn-kernels/gen_files/data_statstest.h.template ./gen_files/
cp ~/xpulptnn-kernels/gen_files/test_stats.c.template ./gen_files/
cp ~/xpulptnn-kernels/generate_statstest.py .
cp ~/xpulptnn-kernels/data_statstest.h .
cp ~/xpulptnn-kernels/test_stats_ternary.c .
