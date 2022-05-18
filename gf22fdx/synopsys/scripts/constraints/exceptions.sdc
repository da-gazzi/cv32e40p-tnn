################
## Exceptions
################

set_ideal_network [ get_ports jtag_tck_i ]
set_ideal_network [ get_ports jtag_trst_ni ]
set_ideal_network [ get_ports rstn_glob_i ]
set_ideal_network [ get_ports ref_clk_i ]
set_ideal_network [ get_ports slow_clk_i ]

set_dont_touch_network [ get_ports ref_clk_i ]
set_dont_touch_network [ get_ports jtag_tck_i ]
set_dont_touch_network [ get_ports jtag_trst_ni ]
set_dont_touch_network [ get_ports rstn_glob_i ]
set_dont_touch_network [ get_ports slow_clk_i ]

# CORE MULTICYCLE PATH and RETIMING 
set_multicycle_path 2 -setup -through [get_pins fc_subsystem_i/FC_CORE.lFC_CORE/id_stage_i/registers_i/riscv_register_file_i/mem_reg*/Q]
set_multicycle_path 1 -hold  -through [get_pins fc_subsystem_i/FC_CORE.lFC_CORE/id_stage_i/registers_i/riscv_register_file_i/mem_reg*/Q]
#set_multicycle_path 2 -setup -through [get_pins fc_subsystem_i/FC_CORE.lFC_CORE/id_stage_i/registers_i/riscv_register_file_i/mem_fp_reg*/Q]
#set_multicycle_path 1 -hold  -through [get_pins fc_subsystem_i/FC_CORE.lFC_CORE/id_stage_i/registers_i/riscv_register_file_i/mem_fp_reg*/Q]
#set_optimize_registers true -designs  [get_designs soc_fp_fma_wrapper*]
#set_optimize_registers true -designs  [get_designs soc_fpu_core*]

set_false_path -through [get_pins i_clk_rst_gen/rstn_soc_sync_o]

