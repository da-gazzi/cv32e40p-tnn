#!/bin/bash

$PULP_RISCV_GCC_TOOLCHAIN/bin/riscv32-unknown-elf-gcc -E test.c > test_prepr.c
