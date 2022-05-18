set NUM_CORES 8

set IPS_PATH        "../../ips"
set RTL_PATH        "../../rtl"
set DESIGN_PATH     "../../"

set reAnalyzeRTL   "TRUE"
set doDFT          "FALSE"
set OUT_FILENAME   "pulp_soc"

set myTARGET_LIBRARY [list GF22FDX_SC8T_104CPP_BASE_CSC20L_SSG_0P59V_0P00V_0P00V_0P00V_125C GF22FDX_SC8T_104CPP_BASE_CSC24L_SSG_0P59V_0P00V_0P00V_0P00V_125C GF22FDX_SC8T_104CPP_BASE_CSC28L_SSG_0P59V_0P00V_0P00V_0P00V_125C]
set CLK_GATE_CELL    "GF22FDX_SC8T_104CPP_BASE_CSC24L_SSG_0P59V_0P00V_0P00V_0P00V_125C/SC8T_CKGPRELATNX4_CSC24L"
set FLL              "$IPS_PATH/gf22_FLL/deliverable"

dz_set_pvt ${myTARGET_LIBRARY}

set ADDITIONAL_LINK_LIB_FILES     "IN22FDX_S1D_NFRG_W04096B032M04C128_104cpp_SSG_0P590V_0P720V_0P000V_0P000V_125C.db           \
                                   IN22FDX_S1D_NFRG_W02048B032M04C128_104cpp_SSG_0P590V_0P720V_0P000V_0P000V_125C.db           \
                                   IN22FDX_ROMI_FRG_W02048B032M32C064_boot_code_104cpp_SSG_0P590V_0P720V_0P000V_0P000V_125C.db \
                                   IN22FDX_GPIO18_10M3S30P_SSG_0P59_1P08_125.db                                                \
                                   gf22_FLL_SSG_0P72V_0P00V_0P00V_0P00V_125C.db                                                \
                                   GF22FDX_SC8T_104CPP_HPK_CSL_SSG_0P59V_0P00V_0P00V_0P00V_125C.db"

set link_library   [concat $link_library  $ADDITIONAL_LINK_LIB_FILES]

set search_path [ join "$IPS_PATH/axi/per2axi
                        $IPS_PATH/axi/axi2per
                        $IPS_PATH/axi/axi2mem
                        $IPS_PATH/axi/axi_node
                        $IPS_PATH/apb_periph/apb_i2c
                        $IPS_PATH/mchan/include
                        $IPS_PATH/cluster_peripherals/include
                        $IPS_PATH/cluster_peripherals/event_unit/include
                        $IPS_PATH/common_cells/include
                        $IPS_PATH/fp-interconnect/marx/includes_fpu
                        $IPS_PATH/riscy-nn/rtl/include
                        $IPS_PATH/zero-riscy/include
                        $IPS_PATH/hwpe-ctrl/rtl
                        $IPS_PATH/hwpe-stream/rtl
                        $IPS_PATH/xne/rtl
                        $FLL/DB
                        $DESIGN_PATH/rtl/includes
                        $search_path"
                ]

define_design_lib work -path ./work


echo " design_setup has been sourced \n"
