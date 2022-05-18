# This script was generated automatically by bender.
set ROOT "/home/msc22f6/riscv-tnn"
set search_path_initial $search_path

set search_path $search_path_initial

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-1ff0d61d20423252/src/rtl/tc_sram.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-1ff0d61d20423252/src/rtl/tc_clk.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-1ff0d61d20423252/src/deprecated/pulp_clock_gating_async.sv" \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-1ff0d61d20423252/src/deprecated/cluster_clk_cells.sv" \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-1ff0d61d20423252/src/deprecated/pulp_clk_cells.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/binary_to_gray.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cb_filter_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cc_onehot.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cf_math_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/clk_int_div.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/delta_counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/ecc_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/edge_propagator_tx.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/exp_backoff.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/fifo_v3.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/gray_to_binary.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/isochronous_4phase_handshake.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/isochronous_spill_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/lfsr.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/lfsr_16bit.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/lfsr_8bit.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/mv_filter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/onehot_to_bin.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/plru_tree.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/popcount.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/rr_arb_tree.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/rstgen_bypass.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/serial_deglitch.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/shift_reg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/spill_register_flushable.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_demux.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_filter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_fork.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_intf.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_join.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_mux.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/sub_per_hash.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/sync.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/sync_wedge.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/unread.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_reset_ctrlr_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_2phase.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_4phase.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/addr_decode.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cb_filter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_fifo_2phase.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/ecc_decode.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/ecc_encode.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/edge_detect.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/lzc.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/max_counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/rstgen.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/spill_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_delay.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_fifo.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_fork_dynamic.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_reset_ctrlr.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_fifo_gray.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/fall_through_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/id_queue.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_to_mem.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_arbiter_flushable.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_xbar.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_fifo_gray_clearable.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/cdc_2phase_clearable.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_arbiter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/stream_omega_net.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/clock_divider_counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/clk_div.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/find_first_one.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/generic_LFSR_8bit.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/generic_fifo.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/prioarbiter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/pulp_sync.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/pulp_sync_wedge.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/rrarbiter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/clock_divider.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/fifo_v2.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/deprecated/fifo_v1.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/edge_propagator_ack.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/edge_propagator.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/src/edge_propagator_rx.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/defs_div_sqrt_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/iteration_div_sqrt_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/control_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/norm_div_sqrt_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/preprocess_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/nrbd_nrsc_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/div_sqrt_top_mvp.sv" \
        "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-54055ed0497a054a/hdl/div_sqrt_mvp_wrapper.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-e5986d271c95bfea/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_pkg.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_cast_multi.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_classifier.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_divsqrt_multi.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_fma.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_fma_multi.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_noncomp.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_opgroup_block.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_opgroup_fmt_slice.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_opgroup_multifmt_slice.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_rounding.sv" \
        "$ROOT/.bender/git/checkouts/fpnew-84cf1174bb6b3fe0/src/fpnew_top.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/rtl/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/rtl/include/apu_core_nn_package.sv" \
        "$ROOT/rtl/include/riscv_nn_defines.sv" \
        "$ROOT/rtl/include/riscv_nn_tracer_defines.sv" \
        "$ROOT/rtl/register_file_nn_test_wrap.sv" \
        "$ROOT/rtl/riscv_nn_alu.sv" \
        "$ROOT/rtl/riscv_nn_alu_basic.sv" \
        "$ROOT/rtl/riscv_nn_alu_div.sv" \
        "$ROOT/rtl/riscv_nn_compressed_decoder.sv" \
        "$ROOT/rtl/riscv_nn_controller.sv" \
        "$ROOT/rtl/riscv_nn_cs_registers.sv" \
        "$ROOT/rtl/riscv_nn_decoder.sv" \
        "$ROOT/rtl/riscv_nn_int_controller.sv" \
        "$ROOT/rtl/riscv_nn_ex_stage.sv" \
        "$ROOT/rtl/riscv_nn_hwloop_controller.sv" \
        "$ROOT/rtl/riscv_nn_hwloop_regs.sv" \
        "$ROOT/rtl/riscv_nn_id_stage.sv" \
        "$ROOT/rtl/riscv_nn_if_stage.sv" \
        "$ROOT/rtl/riscv_nn_load_store_unit.sv" \
        "$ROOT/rtl/riscv_nn_mult.sv" \
        "$ROOT/rtl/riscv_nn_pmp.sv" \
        "$ROOT/rtl/riscv_nn_prefetch_buffer.sv" \
        "$ROOT/rtl/riscv_nn_prefetch_L0_buffer.sv" \
        "$ROOT/rtl/riscv_nn_core.sv" \
        "$ROOT/rtl/riscv_nn_apu_disp.sv" \
        "$ROOT/rtl/riscv_nn_fetch_fifo.sv" \
        "$ROOT/rtl/riscv_nn_L0_buffer.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/rtl/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
    } \
    [list \
        "$ROOT/rtl/riscv_nn_register_file_latch.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
