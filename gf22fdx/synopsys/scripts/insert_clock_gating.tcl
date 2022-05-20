set CLK_GATE_CELL "GF22FDX_SC8T_104CPP_BASE_CSC24L_TT_0P80V_0P00V_0P00V_0P00V_25C/SC8T_CKGPRELATNX4_CSC24L"

set_attribute [get_cells  $CLK_GATE_CELL  ] is_clock_gating_cell true

set_clock_gating_style -minimum_bitwidth 3 -positive_edge_logic integrated:$CLK_GATE_CELL -control_point  before  -control_signal scan_enable  -max_fanout 256

echo "Setting clock gating variables"
set compile_clock_gating_through_hierarchy true ;
set power_cg_balance_stages false ;
