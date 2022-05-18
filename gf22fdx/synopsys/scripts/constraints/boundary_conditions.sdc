################
## Boundary Conditions
################

set PAD_LIB   IN22FDX_GPIO18_10M3S30P_SSG_0P59_1P08_125
set DRIV_CELL IN22FDX_GPIO18_10M3S30P_IO_H
set DRIV_PIN  PAD
set LOAD_CELL IN22FDX_GPIO18_10M3S30P_IO_H
set LOAD_PIN  PAD

set_driving_cell  -no_design_rule -library ${PAD_LIB} -lib_cell ${DRIV_CELL} -pin ${DRIV_PIN} [all_inputs]
set_load [load_of ${PAD_LIB}/${LOAD_CELL}/${LOAD_PIN}] [all_inputs]

# PAD MODE 0
set_case_analysis 0 [get_pins soc_peripherals_i/apb_soc_ctrl_i/r_pad_fun0_reg*/Q]
set_case_analysis 0 [get_pins soc_peripherals_i/apb_soc_ctrl_i/r_pad_fun1_reg*/Q]
