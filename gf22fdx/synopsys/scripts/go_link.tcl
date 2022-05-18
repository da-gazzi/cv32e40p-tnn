# 
# go_link.tcl
#
# Copyright (C) 2017 ETH Zurich
# All rights reserved.
# 

#SETUP
source scripts/rm_setup/design_setup.tcl

#SYNTHESIS SCRIPT
source scripts/utils/colors.tcl
source scripts/utils/area_report.tcl

suppress_message { VER-130 }
set_host_option -max_core $NUM_CORES

set reAnalyzeRTL "TRUE"

#set OUT_FILENAME "pulpissimo"
OUT_FILENAME "pulp_soc"

file delete -force -- ./work
source -echo -verbose ./scripts/analyze_auto/ips_add_files.tcl
# set up .v files to use obsolete Verilog 2001 standard (necessary for some idiotic memory cuts)
set hdlin_vrlg_std 2001
source -echo -verbose ./scripts/analyze_auto/rtl_add_files.tcl

#elaborate pulpissimo
elaborate pulp_soc

#current_design pulpissimo
current_design pulp_soc 

if { [link] == 0 } {
  exit 1
}
exit 0

