# 
#  EXAMPLE FILE, ADAPT FOR YOUR DESIGN !!!!!!
#
#  PLEASE DO NOT USE AS IT IS. 
#
#  TCL version of the file

# -------------------------------------------------------------
#  1. Read std. cell models (core, pads), special ram model 
# -------------------------------------------------------------

  #  reset state, clear database (to make rerun possible)
  build -force
  read_netlist -delete

  source scripts/read_lib.tcl

# -------------------------------------------------------------
#  2. Read netlist (post layout netlist from Encounter)
#     build model
# -------------------------------------------------------------

  read_netlist ../encounter/out/final.v

  #  for cells/blocks you do not have an appropriate model the safest
  #  is to read an empty module declaration (interface only) and
  #  declare the module as black box 
  #  NOTE: This is generally NOT required for the umc rams defined
  #        in your ".cockpitrc" file as an appropriate model for them
  #        gets already included in the "read_umc.cmd" script above! 
  # 
 
  #  read_netlist myram_empty.v   // (optional, but safer)
  #  set_build -black_box myram   // required

  run_build_model chip

# -------------------------------------------------------------
#  3. Define clocks, scan-chains, constant input ports
# 
#  => Remark: SKIP this point if you already have created
#     the *.stil file needed in point 5.
# -------------------------------------------------------------

  add_clocks 0 PxlClkxCI SerialClkxCI -shift

  add_scan_chains chain1  HActxSI HActxSO
  add_scan_chains chain2  RxDI    TxDO
  add_scan_enables 1 ScanEnablexTI

  add_pi_constraints 1 ResetxRBI
  add_pi_constraints 0 TestRamEnaxTI
  add_pi_constraints 1 TestRamSlRngxTI

# -------------------------------------------------------------
#  4. Write test protocol file (based on current settings)
# 
#  => Remark: SKIP this point if you already have created
#     the *.stil file needed in point 5.
# -------------------------------------------------------------

  write_drc_file chip.stil

  #  If you employ a reset synchronisation register you need to
  #  modify 'chip.stil' as follows: 
  #  In order to load this register (during initialization) with
  #  a value that deasserts reset, we need to add a vector in the
  #  "test_setup" section that pulses the clocks ("P") while
  #  applying the appropriate value at the reset port. 
  #   
  #  example (first vector added):
  # 
  #     "test_setup" {
  #        W "_default_WFT_";
  #        V { "ResetxRBI"=1; "TestRamEnaxTI"=0; "TestRamSlRngxTI"=1; "PxlClkxCI"=P; "SerialClkxCI"=P; }
  #        V { "ResetxRBI"=1; "TestRamEnaxTI"=0; "TestRamSlRngxTI"=1; "PxlClkxCI"=0; "SerialClkxCI"=0; }
  #     }

# -------------------------------------------------------------
#  5. Run DRC
# -------------------------------------------------------------

  #  with rules from test protocol file
  run_drc chip.stil

# -------------------------------------------------------------
#  6. Add faults, generate test patterns 
# 
#     Remark: TetraMax can't generate patterns with 100% test
#     coverage due to the "add pi constraints" statements, e.g.
#     stuck-at-1 faults on a low-active reset network will 
#     remain untested (-> AU fault class).
# -------------------------------------------------------------

  #  create fault dictionary
  add_faults -all

  #  Please read at least the following sections in the TetraMAX Online Help:
  #  - "Fundamental Concepts" -> "What are Fault Classes?"
  #  - "Fundamental Concepts" -> "Understanding ATPG Modes"
  #     and on this page the link on the bottom "ATPG Mode Sequence" 
  #  - "Understanding Reported Data" -> "Run ATPG"
  # 
  #  Full-scan designs should only need basic-scan mode whereas partial-scan
  #  designs will also need fast-sequential and possibly full-sequential mode.
  # 
  #  For fast runtimes it is recommended to do multiple passes whereby  
  #  the idea is to detect most faults using low effort settings and simple
  #  modes (e.g. basic-scan) before targeting the remaining faults with high
  #  effort settings and more complex modes (fast/full-sequential). 

  report_settings atpg         // see the current atpg settings

  #  basic scan mode

  # set_atpg -abort_limit 100    // more effort 
  #  run_atpg                    // standard algorithm
  #  run_atpg basic_scan_only    // run only this mode (if others are enabled too) 
  run_atpg -auto_compression   // special algorithm, compact patterns


  #  If you need fast sequential mode

  #  set_atpg -abort_limit 500     // effort 
  #  set_atpg -capture_cycles 4     // 0 -> disable, 2..10 -> enable&effort
  #  run_atpg fast_sequential_only  // run only this mode
  #  run_atpg                      // run all enabled modes 

  #  If you need full sequential mode

  #  set_atpg -full_seq_time 20    // effort
  #  set_atpg -full_seq_atpg        // disable with -nofull_seq_atpg  
  #  run_atpg full_sequential_only  // run only this mode
  #  run_atpg                      // run all enabled modes
  
  #  inspect faults (examples, may be different for your design)

  report_faults -summary
  report_faults -level 3 32 -verbose
  # analyze_faults -class AN
  # analyze_faults top_1/U338/A2 -stuck 0 -verbose -display

  write_faults reports/faults-au.rpt -replace -class AU 
  write_faults reports/faults-nd.rpt -replace -class ND 
  write_faults reports/faults-ud.rpt -replace -class UD 


# -------------------------------------------------------------
#  7. Save and export test patterns 
# -------------------------------------------------------------

  #  reduce number of patterns
  #  not necessarily needed if you use -auto_compression 
  #
  #  run_pattern_compression 5 -min_eliminated_pats 0 -max_useless_passes off -verbose

  #   write patterns pattern/pattern.binary  -replace -internal -format binary
  write_patterns pattern/pattern.wglflat -replace -internal -format wgl_flat -sorted -order_pins

# -------------------------------------------------------------
#  8. Translate patterns to HP-Tester format 
# -------------------------------------------------------------

  #  see 
  #
  #    http://eda.ee.ethz.ch/index.php/Tester_ATPG_Vectors
  #
  #  To convert your vectors for the tester
