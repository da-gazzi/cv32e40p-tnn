// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Subword multiplier and MAC                                 //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Advanced MAC unit for PULP.                                //
//                 added parameter SHARED_DSP_MULT to offload dot-product     //
//                 instructions to the shared unit                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import riscv_nn_defines::*;

module riscv_nn_mult
#(
  parameter SHARED_DSP_MULT = 1,
  parameter TNN_EXTENSION   = 0,
  parameter TNN_UNSIGNED = 0
  )
(
  input  logic        clk,
  input  logic        rst_n,

  input  logic        enable_i,
  input  logic [ 3:0] operator_i,

  // integer and short multiplier
  input  logic        short_subword_i,
  input  logic [ 1:0] short_signed_i,

  input  logic [31:0] op_a_i,
  input  logic [31:0] op_b_i,
  input  logic [31:0] op_c_i,

  input  logic [ 4:0] imm_i,


  // dot multiplier
  input  logic [ 1:0] dot_signed_i,
  input  logic [31:0] dot_op_h_a_i,
  input  logic [31:0] dot_op_h_b_i,
  input  logic [31:0] dot_op_b_a_i,
  input  logic [31:0] dot_op_b_b_i,
  input  logic [31:0] dot_op_n_a_i,
  input  logic [31:0] dot_op_n_b_i,
  input  logic [31:0] dot_op_c_a_i,
  input  logic [31:0] dot_op_c_b_i,
  input  logic [31:0] dot_op_t_a_i,
  input  logic [31:0] dot_op_t_b_i,
  input  logic [31:0] dot_op_c_i,
  input  logic        is_clpx_i,
  input  logic [ 1:0] clpx_shift_i,
  input  logic        clpx_img_i,

  output logic [31:0] result_o,

  output logic        multicycle_o,
  output logic        ready_o,
  input  logic        ex_ready_i
);

  ///////////////////////////////////////////////////////////////
  //  ___ _  _ _____ ___ ___ ___ ___   __  __ _   _ _  _____   //
  // |_ _| \| |_   _| __/ __| __| _ \ |  \/  | | | | ||_   _|  //
  //  | || .  | | | | _| (_ | _||   / | |\/| | |_| | |__| |    //
  // |___|_|\_| |_| |___\___|___|_|_\ |_|  |_|\___/|____|_|    //
  //                                                           //
  ///////////////////////////////////////////////////////////////

  logic [16:0] short_op_a;
  logic [16:0] short_op_b;
  logic [32:0] short_op_c;
  logic [33:0] short_mul;
  logic [33:0] short_mac;
  logic [31:0] short_round, short_round_tmp;
  logic [33:0] short_result;

  logic        short_mac_msb1;
  logic        short_mac_msb0;

  logic [ 4:0] short_imm;
  logic [ 1:0] short_subword;
  logic [ 1:0] short_signed;
  logic        short_shift_arith;
  logic [ 4:0] mulh_imm;
  logic [ 1:0] mulh_subword;
  logic [ 1:0] mulh_signed;
  logic        mulh_shift_arith;
  logic        mulh_carry_q;
  logic        mulh_active;
  logic        mulh_save;
  logic        mulh_clearcarry;
  logic        mulh_ready;

  enum logic [2:0] {IDLE, STEP0, STEP1, STEP2, FINISH} mulh_CS, mulh_NS;

  // prepare the rounding value
  assign short_round_tmp = (32'h00000001) << imm_i;
  assign short_round = (operator_i == MUL_IR) ? {1'b0, short_round_tmp[31:1]} : '0;

  // perform subword selection and sign extensions
  assign short_op_a[15:0] = short_subword[0] ? op_a_i[31:16] : op_a_i[15:0];
  assign short_op_b[15:0] = short_subword[1] ? op_b_i[31:16] : op_b_i[15:0];

  assign short_op_a[16]   = short_signed[0] & short_op_a[15];
  assign short_op_b[16]   = short_signed[1] & short_op_b[15];

  assign short_op_c       = mulh_active ? $signed({mulh_carry_q, op_c_i}) : $signed(op_c_i);

  assign short_mul        = $signed(short_op_a) * $signed(short_op_b);
  assign short_mac        = $signed(short_op_c) + $signed(short_mul) + $signed(short_round);

   //we use only short_signed_i[0] as it cannot be short_signed_i[1] 1 and short_signed_i[0] 0
  assign short_result     = $signed({short_shift_arith & short_mac_msb1, short_shift_arith & short_mac_msb0, short_mac[31:0]}) >>> short_imm;

  // choose between normal short multiplication operation and mulh operation
  assign short_imm         = mulh_active ? mulh_imm         : imm_i;
  assign short_subword     = mulh_active ? mulh_subword     : {2{short_subword_i}};
  assign short_signed      = mulh_active ? mulh_signed      : short_signed_i;
  assign short_shift_arith = mulh_active ? mulh_shift_arith : short_signed_i[0];

  assign short_mac_msb1    = mulh_active ? short_mac[33] : short_mac[31];
  assign short_mac_msb0    = mulh_active ? short_mac[32] : short_mac[31];


  always_comb
  begin
    mulh_NS          = mulh_CS;
    mulh_imm         = 5'd0;
    mulh_subword     = 2'b00;
    mulh_signed      = 2'b00;
    mulh_shift_arith = 1'b0;
    mulh_ready       = 1'b0;
    mulh_active      = 1'b1;
    mulh_save        = 1'b0;
    mulh_clearcarry  = 1'b0;
    multicycle_o     = 1'b0;

    case (mulh_CS)
      IDLE: begin
        mulh_active = 1'b0;
        mulh_ready  = 1'b1;
        mulh_save   = 1'b0;
        if ((operator_i == MUL_H) && enable_i) begin
          mulh_ready  = 1'b0;
          mulh_NS     = STEP0;
        end
      end

      STEP0: begin
        multicycle_o = 1'b1;
        mulh_imm         = 5'd16;
        mulh_active      = 1'b1;
        //AL*BL never overflows
        mulh_save        = 1'b0;
        mulh_NS          = STEP1;
        //Here always a 32'b unsigned result (no carry)
      end

      STEP1: begin
        multicycle_o = 1'b1;
        //AL*BH is signed iff B is signed
        mulh_signed      = {short_signed_i[1], 1'b0};
        mulh_subword     = 2'b10;
        mulh_save        = 1'b1;
        mulh_shift_arith = 1'b1;
        mulh_NS          = STEP2;
        //Here signed 32'b + unsigned 32'b result.
        //Result is a signed 33'b
        //Store the carry as it will be used as sign extension, we do
        //not shift
      end

      STEP2: begin
        multicycle_o = 1'b1;
        //AH*BL is signed iff A is signed
        mulh_signed      = {1'b0, short_signed_i[0]};
        mulh_subword     = 2'b01;
        mulh_imm         = 5'd16;
        mulh_save        = 1'b1;
        mulh_clearcarry  = 1'b1;
        mulh_shift_arith = 1'b1;
        mulh_NS          = FINISH;
        //Here signed 32'b + signed 33'b result.
        //Result is a signed 34'b
        //We do not store the carries as the bits 34:33 are shifted back, so we clear it
      end

      FINISH: begin
        mulh_signed  = short_signed_i;
        mulh_subword = 2'b11;
        mulh_ready   = 1'b1;
        if (ex_ready_i)
          mulh_NS = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n)
    begin
      mulh_CS      <= IDLE;
      mulh_carry_q <= 1'b0;
    end else begin
      mulh_CS      <= mulh_NS;

      if (mulh_save)
        mulh_carry_q <= ~mulh_clearcarry & short_mac[32];
      else if (ex_ready_i) // clear carry when we are going to the next instruction
        mulh_carry_q <= 1'b0;
    end
  end

  // 32x32 = 32-bit multiplier
  logic [31:0] int_op_a_msu;
  logic [31:0] int_op_b_msu;
  logic [31:0] int_result;

  logic        int_is_msu;

  assign int_is_msu = (operator_i == MUL_MSU32); // TODO: think about using a separate signal here, could prevent some switching

  assign int_op_a_msu = op_a_i ^ {32{int_is_msu}};
  assign int_op_b_msu = op_b_i & {32{int_is_msu}};

  assign int_result = $signed(op_c_i) + $signed(int_op_b_msu) + $signed(int_op_a_msu) * $signed(op_b_i);

  ///////////////////////////////////////////////
  //  ___   ___ _____   __  __ _   _ _  _____  //
  // |   \ / _ \_   _| |  \/  | | | | ||_   _| //
  // | |) | (_) || |   | |\/| | |_| | |__| |   //
  // |___/ \___/ |_|   |_|  |_|\___/|____|_|   //
  //                                           //
  ///////////////////////////////////////////////

  logic [31:0] dot_char_result;
  logic [31:0] dot_nibble_result;
  logic [31:0] dot_crumble_result;
  logic [31:0] dot_ternary_result;
  logic [32:0] dot_short_result;
  logic [31:0] accumulator;
  logic [15:0] clpx_shift_result;

   generate
     if (SHARED_DSP_MULT == 0) begin

        logic [3:0][ 8:0] dot_char_op_a;
        logic [3:0][ 8:0] dot_char_op_b;
        logic [3:0][17:0] dot_char_mul;

        logic [7:0][4:0] dot_nibble_op_a;
        logic [7:0][4:0] dot_nibble_op_b;
        logic [7:0][9:0] dot_nibble_mul;

        logic [15:0][2:0] dot_crumble_op_a;
        logic [15:0][2:0] dot_crumble_op_b;
        logic [15:0][5:0] dot_crumble_mul;

        logic [1:0][16:0] dot_short_op_a;
        logic [1:0][16:0] dot_short_op_b;
        logic [1:0][33:0] dot_short_mul;
        logic      [16:0] dot_short_op_a_1_neg; //to compute -rA[31:16]*rB[31:16] -> (!rA[31:16] + 1)*rB[31:16] = !rA[31:16]*rB[31:16] + rB[31:16]
        logic      [31:0] dot_short_op_b_ext;


        assign dot_char_op_a[0] = {dot_signed_i[1] & dot_op_b_a_i[ 7], dot_op_b_a_i[ 7: 0]};
        assign dot_char_op_a[1] = {dot_signed_i[1] & dot_op_b_a_i[15], dot_op_b_a_i[15: 8]};
        assign dot_char_op_a[2] = {dot_signed_i[1] & dot_op_b_a_i[23], dot_op_b_a_i[23:16]};
        assign dot_char_op_a[3] = {dot_signed_i[1] & dot_op_b_a_i[31], dot_op_b_a_i[31:24]};

        assign dot_char_op_b[0] = {dot_signed_i[0] & dot_op_b_b_i[ 7], dot_op_b_b_i[ 7: 0]};
        assign dot_char_op_b[1] = {dot_signed_i[0] & dot_op_b_b_i[15], dot_op_b_b_i[15: 8]};
        assign dot_char_op_b[2] = {dot_signed_i[0] & dot_op_b_b_i[23], dot_op_b_b_i[23:16]};
        assign dot_char_op_b[3] = {dot_signed_i[0] & dot_op_b_b_i[31], dot_op_b_b_i[31:24]};

        assign dot_char_mul[0]  = $signed(dot_char_op_a[0]) * $signed(dot_char_op_b[0]);
        assign dot_char_mul[1]  = $signed(dot_char_op_a[1]) * $signed(dot_char_op_b[1]);
        assign dot_char_mul[2]  = $signed(dot_char_op_a[2]) * $signed(dot_char_op_b[2]);
        assign dot_char_mul[3]  = $signed(dot_char_op_a[3]) * $signed(dot_char_op_b[3]);

        assign dot_char_result  = $signed(dot_char_mul[0]) + $signed(dot_char_mul[1]) +
                                  $signed(dot_char_mul[2]) + $signed(dot_char_mul[3]) +
                                  $signed(dot_op_c_i);

        /* nibble */
        assign dot_nibble_op_a[0] = {dot_signed_i[1] & dot_op_n_a_i[3], dot_op_n_a_i[3:0]};
        assign dot_nibble_op_a[1] = {dot_signed_i[1] & dot_op_n_a_i[7], dot_op_n_a_i[7:4]};
        assign dot_nibble_op_a[2] = {dot_signed_i[1] & dot_op_n_a_i[11], dot_op_n_a_i[11:8]};
        assign dot_nibble_op_a[3] = {dot_signed_i[1] & dot_op_n_a_i[15], dot_op_n_a_i[15:12]};
        assign dot_nibble_op_a[4] = {dot_signed_i[1] & dot_op_n_a_i[19], dot_op_n_a_i[19:16]};
        assign dot_nibble_op_a[5] = {dot_signed_i[1] & dot_op_n_a_i[23], dot_op_n_a_i[23:20]};
        assign dot_nibble_op_a[6] = {dot_signed_i[1] & dot_op_n_a_i[27], dot_op_n_a_i[27:24]};
        assign dot_nibble_op_a[7] = {dot_signed_i[1] & dot_op_n_a_i[31], dot_op_n_a_i[31:28]};

        assign dot_nibble_op_b[0] = {dot_signed_i[0] & dot_op_n_b_i[3], dot_op_n_b_i[3:0]};
        assign dot_nibble_op_b[1] = {dot_signed_i[0] & dot_op_n_b_i[7], dot_op_n_b_i[7:4]};
        assign dot_nibble_op_b[2] = {dot_signed_i[0] & dot_op_n_b_i[11], dot_op_n_b_i[11:8]};
        assign dot_nibble_op_b[3] = {dot_signed_i[0] & dot_op_n_b_i[15], dot_op_n_b_i[15:12]};
        assign dot_nibble_op_b[4] = {dot_signed_i[0] & dot_op_n_b_i[19], dot_op_n_b_i[19:16]};
        assign dot_nibble_op_b[5] = {dot_signed_i[0] & dot_op_n_b_i[23], dot_op_n_b_i[23:20]};
        assign dot_nibble_op_b[6] = {dot_signed_i[0] & dot_op_n_b_i[27], dot_op_n_b_i[27:24]};
        assign dot_nibble_op_b[7] = {dot_signed_i[0] & dot_op_n_b_i[31], dot_op_n_b_i[31:28]};

        assign dot_nibble_mul[0]  = $signed(dot_nibble_op_a[0]) * $signed(dot_nibble_op_b[0]);
        assign dot_nibble_mul[1]  = $signed(dot_nibble_op_a[1]) * $signed(dot_nibble_op_b[1]);
        assign dot_nibble_mul[2]  = $signed(dot_nibble_op_a[2]) * $signed(dot_nibble_op_b[2]);
        assign dot_nibble_mul[3]  = $signed(dot_nibble_op_a[3]) * $signed(dot_nibble_op_b[3]);
        assign dot_nibble_mul[4]  = $signed(dot_nibble_op_a[4]) * $signed(dot_nibble_op_b[4]);
        assign dot_nibble_mul[5]  = $signed(dot_nibble_op_a[5]) * $signed(dot_nibble_op_b[5]);
        assign dot_nibble_mul[6]  = $signed(dot_nibble_op_a[6]) * $signed(dot_nibble_op_b[6]);
        assign dot_nibble_mul[7]  = $signed(dot_nibble_op_a[7]) * $signed(dot_nibble_op_b[7]);

        assign dot_nibble_result  = $signed(dot_nibble_mul[0]) + $signed(dot_nibble_mul[1]) +
                                    $signed(dot_nibble_mul[2]) + $signed(dot_nibble_mul[3]) +
                                    $signed(dot_nibble_mul[4]) + $signed(dot_nibble_mul[5]) +
                                    $signed(dot_nibble_mul[6]) + $signed(dot_nibble_mul[7]) +
                                    $signed(dot_op_c_i);

        /*crumble */
        assign dot_crumble_op_a[0]  = {dot_signed_i[1] & dot_op_c_a_i[1], dot_op_c_a_i[1:0]};
        assign dot_crumble_op_a[1]  = {dot_signed_i[1] & dot_op_c_a_i[3], dot_op_c_a_i[3:2]};
        assign dot_crumble_op_a[2]  = {dot_signed_i[1] & dot_op_c_a_i[5], dot_op_c_a_i[5:4]};
        assign dot_crumble_op_a[3]  = {dot_signed_i[1] & dot_op_c_a_i[7], dot_op_c_a_i[7:6]};
        assign dot_crumble_op_a[4]  = {dot_signed_i[1] & dot_op_c_a_i[9], dot_op_c_a_i[9:8]};
        assign dot_crumble_op_a[5]  = {dot_signed_i[1] & dot_op_c_a_i[11], dot_op_c_a_i[11:10]};
        assign dot_crumble_op_a[6]  = {dot_signed_i[1] & dot_op_c_a_i[13], dot_op_c_a_i[13:12]};
        assign dot_crumble_op_a[7]  = {dot_signed_i[1] & dot_op_c_a_i[15], dot_op_c_a_i[15:14]};
        assign dot_crumble_op_a[8]  = {dot_signed_i[1] & dot_op_c_a_i[17], dot_op_c_a_i[17:16]};
        assign dot_crumble_op_a[9]  = {dot_signed_i[1] & dot_op_c_a_i[19], dot_op_c_a_i[19:18]};
        assign dot_crumble_op_a[10] = {dot_signed_i[1] & dot_op_c_a_i[21], dot_op_c_a_i[21:20]};
        assign dot_crumble_op_a[11] = {dot_signed_i[1] & dot_op_c_a_i[23], dot_op_c_a_i[23:22]};
        assign dot_crumble_op_a[12] = {dot_signed_i[1] & dot_op_c_a_i[25], dot_op_c_a_i[25:24]};
        assign dot_crumble_op_a[13] = {dot_signed_i[1] & dot_op_c_a_i[27], dot_op_c_a_i[27:26]};
        assign dot_crumble_op_a[14] = {dot_signed_i[1] & dot_op_c_a_i[29], dot_op_c_a_i[29:28]};
        assign dot_crumble_op_a[15] = {dot_signed_i[1] & dot_op_c_a_i[31], dot_op_c_a_i[31:30]};

        assign dot_crumble_op_b[0]  = {dot_signed_i[0] & dot_op_c_b_i[1], dot_op_c_b_i[1:0]};
        assign dot_crumble_op_b[1]  = {dot_signed_i[0] & dot_op_c_b_i[3], dot_op_c_b_i[3:2]};
        assign dot_crumble_op_b[2]  = {dot_signed_i[0] & dot_op_c_b_i[5], dot_op_c_b_i[5:4]};
        assign dot_crumble_op_b[3]  = {dot_signed_i[0] & dot_op_c_b_i[7], dot_op_c_b_i[7:6]};
        assign dot_crumble_op_b[4]  = {dot_signed_i[0] & dot_op_c_b_i[9], dot_op_c_b_i[9:8]};
        assign dot_crumble_op_b[5]  = {dot_signed_i[0] & dot_op_c_b_i[11], dot_op_c_b_i[11:10]};
        assign dot_crumble_op_b[6]  = {dot_signed_i[0] & dot_op_c_b_i[13], dot_op_c_b_i[13:12]};
        assign dot_crumble_op_b[7]  = {dot_signed_i[0] & dot_op_c_b_i[15], dot_op_c_b_i[15:14]};
        assign dot_crumble_op_b[8]  = {dot_signed_i[0] & dot_op_c_b_i[17], dot_op_c_b_i[17:16]};
        assign dot_crumble_op_b[9]  = {dot_signed_i[0] & dot_op_c_b_i[19], dot_op_c_b_i[19:18]};
        assign dot_crumble_op_b[10] = {dot_signed_i[0] & dot_op_c_b_i[21], dot_op_c_b_i[21:20]};
        assign dot_crumble_op_b[11] = {dot_signed_i[0] & dot_op_c_b_i[23], dot_op_c_b_i[23:22]};
        assign dot_crumble_op_b[12] = {dot_signed_i[0] & dot_op_c_b_i[25], dot_op_c_b_i[25:24]};
        assign dot_crumble_op_b[13] = {dot_signed_i[0] & dot_op_c_b_i[27], dot_op_c_b_i[27:26]};
        assign dot_crumble_op_b[14] = {dot_signed_i[0] & dot_op_c_b_i[29], dot_op_c_b_i[29:28]};
        assign dot_crumble_op_b[15] = {dot_signed_i[0] & dot_op_c_b_i[31], dot_op_c_b_i[31:30]};

        assign dot_crumble_mul[0]  = $signed(dot_crumble_op_a[0]) * $signed(dot_crumble_op_b[0]);
        assign dot_crumble_mul[1]  = $signed(dot_crumble_op_a[1]) * $signed(dot_crumble_op_b[1]);
        assign dot_crumble_mul[2]  = $signed(dot_crumble_op_a[2]) * $signed(dot_crumble_op_b[2]);
        assign dot_crumble_mul[3]  = $signed(dot_crumble_op_a[3]) * $signed(dot_crumble_op_b[3]);
        assign dot_crumble_mul[4]  = $signed(dot_crumble_op_a[4]) * $signed(dot_crumble_op_b[4]);
        assign dot_crumble_mul[5]  = $signed(dot_crumble_op_a[5]) * $signed(dot_crumble_op_b[5]);
        assign dot_crumble_mul[6]  = $signed(dot_crumble_op_a[6]) * $signed(dot_crumble_op_b[6]);
        assign dot_crumble_mul[7]  = $signed(dot_crumble_op_a[7]) * $signed(dot_crumble_op_b[7]);
        assign dot_crumble_mul[8]  = $signed(dot_crumble_op_a[8]) * $signed(dot_crumble_op_b[8]);
        assign dot_crumble_mul[9]  = $signed(dot_crumble_op_a[9]) * $signed(dot_crumble_op_b[9]);
        assign dot_crumble_mul[10]  = $signed(dot_crumble_op_a[10]) * $signed(dot_crumble_op_b[10]);
        assign dot_crumble_mul[11]  = $signed(dot_crumble_op_a[11]) * $signed(dot_crumble_op_b[11]);
        assign dot_crumble_mul[12]  = $signed(dot_crumble_op_a[12]) * $signed(dot_crumble_op_b[12]);
        assign dot_crumble_mul[13]  = $signed(dot_crumble_op_a[13]) * $signed(dot_crumble_op_b[13]);
        assign dot_crumble_mul[14]  = $signed(dot_crumble_op_a[14]) * $signed(dot_crumble_op_b[14]);
        assign dot_crumble_mul[15]  = $signed(dot_crumble_op_a[15]) * $signed(dot_crumble_op_b[15]);

        assign dot_crumble_result = $signed(dot_crumble_mul[0]) + $signed(dot_crumble_mul[1]) +
                                    $signed(dot_crumble_mul[2]) + $signed(dot_crumble_mul[3]) +
                                    $signed(dot_crumble_mul[4]) + $signed(dot_crumble_mul[5]) +
                                    $signed(dot_crumble_mul[6]) + $signed(dot_crumble_mul[7]) +
                                    $signed(dot_crumble_mul[8]) + $signed(dot_crumble_mul[9]) +
                                    $signed(dot_crumble_mul[10]) + $signed(dot_crumble_mul[11]) +
                                    $signed(dot_crumble_mul[12]) + $signed(dot_crumble_mul[13]) +
                                    $signed(dot_crumble_mul[14]) + $signed(dot_crumble_mul[15]) +
                                    $signed(dot_op_c_i);

       if (TNN_EXTENSION == 1) begin : compressedMAC
         if (TNN_UNSIGNED == 1) begin : unsigned_TMAC
          logic [39:0]      dot_op_t_decoded_a;
          logic [39:0]      dot_op_t_decoded_b;
          logic [19:0][2:0] dot_ternary_op_a;
          logic [19:0][2:0] dot_ternary_op_b;
          logic [19:0][3:0] dot_ternary_mul;

          /*ternary*/
          for (genvar g=0; g<4; g++) begin: gen_decomp_logic
            ternary_decoder i_ternary_decoder_a
            (
              .decoder_i(dot_op_t_a_i       [8*g  +: 8] ),
              .decoder_o(dot_op_t_decoded_a [10*g +: 10])
            );

            ternary_decoder i_ternary_decoder_b
            (
              .decoder_i(dot_op_t_b_i       [8*g  +: 8] ),
              .decoder_o(dot_op_t_decoded_b [10*g +: 10])
            );
          end // block: gen_decomp_logic
          for (genvar g=0; g<20; g++) begin
            ternary_signed_to_unsigned i_tern_s2u_a
                        (
                         .din_i(dot_op_t_decoded_a[g*2+1:g*2]),
                         .make_unsigned_i(~dot_signed_i[1]),
                         .dout_o(dot_ternary_op_a[g])
                          );
            ternary_signed_to_unsigned i_tern_s2u_b
              (
               .din_i(dot_op_t_decoded_b[g*2+1:g*2]),
               .make_unsigned_i(~dot_signed_i[0]),
               .dout_o(dot_ternary_op_b[g])
               );
            assign dot_ternary_mul[g] = $signed(dot_ternary_op_a[g]) * $signed(dot_ternary_op_b[g]);

          end // for (genvar g=0; g<20; g++)

         assign dot_ternary_result = $signed(dot_ternary_mul[0]) + $signed(dot_ternary_mul[1]) +
                                     $signed(dot_ternary_mul[2]) + $signed(dot_ternary_mul[3]) +
                                     $signed(dot_ternary_mul[4]) + $signed(dot_ternary_mul[5]) +
                                     $signed(dot_ternary_mul[6]) + $signed(dot_ternary_mul[7]) +
                                     $signed(dot_ternary_mul[8]) + $signed(dot_ternary_mul[9]) +
                                     $signed(dot_ternary_mul[10]) + $signed(dot_ternary_mul[11]) +
                                     $signed(dot_ternary_mul[12]) + $signed(dot_ternary_mul[13]) +
                                     $signed(dot_ternary_mul[14]) + $signed(dot_ternary_mul[15]) +
                                     $signed(dot_ternary_mul[16]) + $signed(dot_ternary_mul[17]) +
                                     $signed(dot_ternary_mul[18]) + $signed(dot_ternary_mul[19]) +
                                     $signed(dot_op_c_i);
         end else begin : signed_TMAC // block: unsigned_TMAC

           logic [39:0]      dot_op_t_decoded_a;
           logic [39:0]      dot_op_t_decoded_b;
           logic [19:0][1:0] dot_ternary_op_a;
           logic [19:0][1:0] dot_ternary_op_b;
           logic [19:0][1:0] dot_ternary_mul;

           /*ternary*/
           for (genvar g=0; g<4; g++) begin: gen_decomp_logic
             ternary_decoder i_ternary_decoder_a
                         (
                          .decoder_i(dot_op_t_a_i       [8*g  +: 8] ),
                          .decoder_o(dot_op_t_decoded_a [10*g +: 10])
                          );

             ternary_decoder i_ternary_decoder_b
               (
                .decoder_i(dot_op_t_b_i       [8*g  +: 8] ),
                .decoder_o(dot_op_t_decoded_b [10*g +: 10])
                );
           end // block: gen_decomp_logic
           assign dot_ternary_op_a = {>>{dot_op_t_decoded_a}};
           assign dot_ternary_op_b = {>>{dot_op_t_decoded_b}};

           for (genvar g=0; g<20; g++) begin : ternary_mult
             assign dot_ternary_mul[g]  = $signed(dot_ternary_op_a[g]) * $signed(dot_ternary_op_b[g]);
           end
           
         assign dot_ternary_result = $signed(dot_ternary_mul[0]) + $signed(dot_ternary_mul[1]) +
                                     $signed(dot_ternary_mul[2]) + $signed(dot_ternary_mul[3]) +
                                     $signed(dot_ternary_mul[4]) + $signed(dot_ternary_mul[5]) +
                                     $signed(dot_ternary_mul[6]) + $signed(dot_ternary_mul[7]) +
                                     $signed(dot_ternary_mul[8]) + $signed(dot_ternary_mul[9]) +
                                     $signed(dot_ternary_mul[10]) + $signed(dot_ternary_mul[11]) +
                                     $signed(dot_ternary_mul[12]) + $signed(dot_ternary_mul[13]) +
                                     $signed(dot_ternary_mul[14]) + $signed(dot_ternary_mul[15]) +
                                     $signed(dot_ternary_mul[16]) + $signed(dot_ternary_mul[17]) +
                                     $signed(dot_ternary_mul[18]) + $signed(dot_ternary_mul[19]) +
                                     $signed(dot_op_c_i);
         end // else: !if(TNN_UNSIGNED == 1)
       end else begin : no_TMAC // block: compressedMAC
         assign dot_ternary_result = '0;
       end
        assign dot_short_op_a[0]    = {dot_signed_i[1] & dot_op_h_a_i[15], dot_op_h_a_i[15: 0]};
        assign dot_short_op_a[1]    = {dot_signed_i[1] & dot_op_h_a_i[31], dot_op_h_a_i[31:16]};
        assign dot_short_op_a_1_neg = dot_short_op_a[1] ^ {17{(is_clpx_i & ~clpx_img_i)}}; //negates whether clpx_img_i is 0 or 1, only REAL PART needs to be negated

        assign dot_short_op_b[0] = (is_clpx_i & clpx_img_i) ? {dot_signed_i[0] & dot_op_h_b_i[31], dot_op_h_b_i[31:16]} : {dot_signed_i[0] & dot_op_h_b_i[15], dot_op_h_b_i[15: 0]};
        assign dot_short_op_b[1] = (is_clpx_i & clpx_img_i) ? {dot_signed_i[0] & dot_op_h_b_i[15], dot_op_h_b_i[15: 0]} : {dot_signed_i[0] & dot_op_h_b_i[31], dot_op_h_b_i[31:16]};

        assign dot_short_mul[0]  = $signed(dot_short_op_a[0]) * $signed(dot_short_op_b[0]);
        assign dot_short_mul[1]  = $signed(dot_short_op_a_1_neg) * $signed(dot_short_op_b[1]);

        assign dot_short_op_b_ext = $signed(dot_short_op_b[1]);
        assign accumulator        = is_clpx_i ? dot_short_op_b_ext & {32{~clpx_img_i}} : $signed(dot_op_c_i);

        assign dot_short_result  = $signed(dot_short_mul[0][31:0]) + $signed(dot_short_mul[1][31:0]) + $signed(accumulator);
        assign clpx_shift_result = $signed(dot_short_result[31:15])>>>clpx_shift_i;

     end else begin
        assign dot_char_result    = '0;
        assign dot_short_result   = '0;
        assign dot_nibble_result  = '0;
        assign dot_crumble_result = '0;
        assign dot_ternary_result = '0;
     end
  endgenerate

  ////////////////////////////////////////////////////////
  //   ____                 _ _     __  __              //
  //  |  _ \ ___  ___ _   _| | |_  |  \/  |_   ___  __  //
  //  | |_) / _ \/ __| | | | | __| | |\/| | | | \ \/ /  //
  //  |  _ <  __/\__ \ |_| | | |_  | |  | | |_| |>  <   //
  //  |_| \_\___||___/\__,_|_|\__| |_|  |_|\__,_/_/\_\  //
  //                                                    //
  ////////////////////////////////////////////////////////

  always_comb
  begin
    result_o   = '0;

    unique case (operator_i)
      MUL_MAC32, MUL_MSU32: result_o = int_result[31:0];

      MUL_I, MUL_IR, MUL_H: result_o = short_result[31:0];

      MUL_DOT8:  result_o = dot_char_result[31:0];
      MUL_DOT4:  result_o = dot_nibble_result[31:0];
      MUL_DOT2:  result_o = dot_crumble_result[31:0];
      MUL_TDOT2: begin
        if (TNN_EXTENSION == 1) begin
          result_o = dot_ternary_result[31:0];
        end
      end
      MUL_DOT16: begin
        if(is_clpx_i) begin
          if(clpx_img_i) begin
            result_o[31:16] = clpx_shift_result;
            result_o[15:0]  = dot_op_c_i[15:0];
          end else begin
            result_o[15:0]  = clpx_shift_result;
            result_o[31:16] = dot_op_c_i[31:16];
          end
        end else begin
            result_o = dot_short_result[31:0];
        end
      end

      default: ; // default case to suppress unique warning
    endcase
  end

  assign ready_o      = mulh_ready;

  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------

  // check multiplication result for mulh
  `ifndef VERILATOR
  assert property (
    @(posedge clk) ((mulh_CS == FINISH) && (operator_i == MUL_H) && (short_signed_i == 2'b11))
    |->
    (result_o == (($signed({{32{op_a_i[31]}}, op_a_i}) * $signed({{32{op_b_i[31]}}, op_b_i})) >>> 32) ) );

  // check multiplication result for mulhsu
  assert property (
    @(posedge clk) ((mulh_CS == FINISH) && (operator_i == MUL_H) && (short_signed_i == 2'b01))
    |->
    (result_o == (($signed({{32{op_a_i[31]}}, op_a_i}) * {32'b0, op_b_i}) >> 32) ) );

  // check multiplication result for mulhu
  assert property (
    @(posedge clk) ((mulh_CS == FINISH) && (operator_i == MUL_H) && (short_signed_i == 2'b00))
    |->
    (result_o == (({32'b0, op_a_i} * {32'b0, op_b_i}) >> 32) ) );
  `endif
endmodule
