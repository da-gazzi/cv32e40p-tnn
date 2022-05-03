#!/bin/bash

# exit when any command fails
set -e

VER=2019.3
LIB=work

if [-e $LIB]; then
  rm -rf $LIB
fi

questa-${VER} vlib $LIB

# compile SystemVerilog sourcecode
questa-$VER vlog -work ${LIB} -sv ../../rtl/ternary_encoder.sv
questa-$VER vlog -work ${LIB} -sv ../../rtl/threshold_compress.sv

# compile testbench
questa-$VER vlog -work ${LIB} -sv ./tb_threshold_compress.sv

# optimize the design
questa-$VER vopt -work ${LIB} +acc -o tb_opt tb_threshold_compress

# run simulation
questa-$VER vsim -lib ${LIB} tb_opt -do 'source scripts/vsim.tcl'