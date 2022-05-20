remove_design -design
sh rm -rf WORK/*

set DESIGN_NAME "ri5cy_tnn"

# ------------------------------------------------------------------------------
# Analyze design
# ------------------------------------------------------------------------------
source scripts/analyze_auto/analyze.tcl


# ------------------------------------------------------------------------------
# Elaborate design
# ------------------------------------------------------------------------------
elaborate riscv_nn_core -library WORK

# write technology-independent netlist
sh mkdir -p ./netlists
write -hierarchy -format verilog  -output ./netlists/$DESIGN_NAME.unmapped.v


# ------------------------------------------------------------------------------
# Add constraints
# ------------------------------------------------------------------------------
# create clocks
create_clock clk_i -period 2500

# exceptions
source -echo -verbose ./scripts/constraints/exceptions.sdc

# input output delays
source -echo -verbose ./scripts/constraints/input_output_delay.sdc

# insert clock gate
source -echo -verbose ./scripts/insert_clock_gating.tcl


# ------------------------------------------------------------------------------
# Compile design
# ------------------------------------------------------------------------------
compile_ultra -no_autoungroup -no_boundary_optimization -timing -gate_clock


# ------------------------------------------------------------------------------
# Write netlist
# ------------------------------------------------------------------------------
sh mkdir -p ./netlists
write -format verilog -hier -o ./netlists/$DESIGN_NAME.v


# ------------------------------------------------------------------------------
# Generate reports
# ------------------------------------------------------------------------------
sh mkdir -p ./reports

report_timing > reports/timing.rpt
report_area   > reports/area.rpt
