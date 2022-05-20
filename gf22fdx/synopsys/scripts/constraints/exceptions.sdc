################
## Exceptions
################

set_ideal_network [ get_ports clk_i ]
set_ideal_network [ get_ports rst_ni ]

set_dont_touch_network [ get_ports clk_i ]
set_dont_touch_network [ get_ports rst_ni ]

set_max_time_borrow 0 [ get_cells id_stage_i/registers_i/riscv_nn_register_file_i/mem_reg* ]

# CORE MULTICYCLE PATH and RETIMING
set_multicycle_path 2 -setup -through  [ get_cells id_stage_i/registers_i/riscv_nn_register_file_i/mem_reg* ]
set_multicycle_path 1 -hold  -through  [ get_cells id_stage_i/registers_i/riscv_nn_register_file_i/mem_reg* ]
#set_multicycle_path 2 -setup -through [ get_cells id_stage_i/registers_i/riscv_nn_register_file_i/mem_fp_reg*/Q ]
#set_multicycle_path 1 -hold  -through [ get_cells id_stage_i/registers_i/riscv_nn_register_file_i/mem_fp_reg*/Q ]
