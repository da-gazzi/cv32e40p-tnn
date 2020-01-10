import riscv_defines::*;

module riscv_qnt_unit
(
  input logic         clk,
  input logic         rst_n,

  input logic         enable_i, // to enable the module
  input logic [2:0]   vecmode_i, // to choose 4 or 2 bit

  input logic [31:0]  op_a_i, // "input" operand
  input logic [31:0]  op_b_i, // "address" to the thresholds

  input logic [31:0]  threshold_i, //from regfile_wdata_wb_o of exstage
  input logic         threshold_valid_i, // from wb_ready_i of ex stage
  input logic         request_granted_i, // memory grants current mem request

  output logic        threshold_request_o, // request data from LSU /MEM
  output logic [31:0] threshold_address_o, // address to LSU for fetching threshold

  output logic [31:0] result_o,
  output logic        multicycle_o,

  input logic         ex_ready_i,
  output logic        ready_o

  );

  // FSM signals
  typedef enum      logic [4:0] {INIT, FIRST_CMP, FIRST_CMP2, SECOND_CMP, SECOND_CMP2, THIRD_CMP, THIRD_CMP2, FOURTH_CMP, FINISH} state;
  logic             is_stall, inverted_comp, is_prev_inv_comp2, is_not_first_addr, res_shift_en, update_on_previous, is_second_pix_fetch_addr, update_first_pix, update_second_pix, inverted_comp2, is_prev_inv_comp;
  logic [1:0]       addr_incr;
  logic 	    is_stall_q;

  state cs, ns;

  // comparison datapath signals

  // first pixel
  logic            cmp_res;
  logic [15: 0]    comp_op_a, comp_op_b;
  logic [31: 0]    rd_temp, res_n, res_q;
  // pipeline Signals
  logic            cmp_res_q;


  // second pixel
  logic            cmp_res2;
  logic [15: 0]    comp2_op_a, comp2_op_b;
  logic [31: 0]    rd2_temp, res2_n, res2_q;
  //pipeline Signals
  logic            cmp_res2_q;

  // address update datapath signals

  logic [ 5: 0]    next_address;
  logic [ 5: 0]    curr_address;
  logic [ 5: 0]    th_address;

  logic [ 3: 0]    offset_a;

  logic [ 5: 0]    next_address2;
  logic [ 5: 0]    curr_address2;
  logic [ 5: 0]    th_address2;
  logic [15: 0]    op_b2;
  logic [ 5: 0]    offset_init;

  // DATAPATH : COMPARISON AND UPDATE OF RESULT

  // LSB of input , first pixel to be qnt
  // take only 16 bit of thresholds- threshols are native 16 bit
  //consider eliminate is_prev_inv_comp2
  assign comp_op_a   =  op_a_i[15: 0] ;
  assign comp_op_b   =  threshold_i[15: 0];
  //assign comp_op_a   = (inverted_comp==1'b1) ? threshold_i[15: 0]  : op_a_i[15: 0] ;
  //assign comp_op_b   = (inverted_comp==1'b1) ? op_a_i[15: 0]       : threshold_i[15: 0];

  // MSB of input , second pixel to be qnt
  // take only 16 bit of thresholds- threshols are native 16 bit
  //consider eliminate is_prev_inv_comp2
  assign comp2_op_a   = op_a_i[31:16] ;
  assign comp2_op_b   =  threshold_i[15: 0];
  //assign comp2_op_a   = (inverted_comp2==1'b1) ? threshold_i[15: 0]  : op_a_i[31:16] ;
  //assign comp2_op_b   = (inverted_comp2==1'b1) ? op_a_i[31:16]       : threshold_i[15: 0];

  // Comparison of input pixels with thresholds
  assign cmp_res  = (inverted_comp ==1'b1) ? !($signed(comp_op_a)  > $signed(comp_op_b))  : ($signed(comp_op_a)  > $signed(comp_op_b));
  assign cmp_res2 = (inverted_comp2==1'b1) ? !($signed(comp2_op_a) > $signed(comp2_op_b)) : ($signed(comp2_op_a) > $signed(comp2_op_b));


  // temporary register, needed to make the upload of qntzed pix accordingly to the comp result
  // for the time being, better adding a new temporary signal for second pixel
  assign rd_temp  = (update_on_previous == 1'b1) ? res_q  : 32'b0;
  assign rd2_temp = (update_on_previous == 1'b1) ? res2_q : 32'b0;


  // if comparison is on first pixel, then do not update the parial result of second pixel
  assign res_n  = update_first_pix ? (res_shift_en ? {rd_temp[30: 0] , cmp_res}  : rd_temp[31:0])  : res_q;
  assign res2_n = update_second_pix ? (res_shift_en ? {rd2_temp[30: 0], cmp_res2} : rd2_temp[31:0]) : res2_q;


  // DATAPATH: UPDATE THE ADDRESS TO FETCH THRESHOLDS
  always_comb begin
    offset_a = 4'b0000;
    case(addr_incr)
      2'b00: offset_a = 4'b0000;  //offset a is 4 bit
      2'b01: offset_a = 4'b1000;
      2'b10: offset_a = 4'b0100;
      2'b11: offset_a = 4'b0010;
    endcase // case (addr_incr)
  end

  assign offset_init = (vecmode_i == VEC_MODE2) ? 6'd8 : 6'd32;
  assign op_b2 = op_b_i[15: 0] + {10'b0, offset_init};

  // for the time being, update at the same time both address (one of twos will be wrong), then choose properly
  assign th_address  = is_not_first_addr ? curr_address  : op_b_i[ 5: 0];
  assign th_address2 = is_not_first_addr ? curr_address2 : op_b2 [ 5: 0];


  // next address should remain fixed if at this cycle we are processing the other pixel
  assign next_address  = is_second_pix_fetch_addr ? th_address : ((cmp_res_q  ^ is_prev_inv_comp) ? (th_address  + offset_a): (th_address  - offset_a));
  assign next_address2 = is_second_pix_fetch_addr ? ((cmp_res2_q ^ is_prev_inv_comp2) ? (th_address2 + offset_a): (th_address2 - offset_a)) : th_address2;

  // here we need a signal to choose properly the address to send to the LSU
  assign threshold_address_o = is_second_pix_fetch_addr ? {op_b_i[31:16], op_b2[15:6], next_address2} :  {op_b_i[31:6], next_address};


  // DATA REGISTERS

  always_ff@(posedge clk, negedge rst_n) begin

    if (~rst_n)
      is_stall_q <= 1'b0;
    else
      is_stall_q <= is_stall;

    if (~rst_n) begin
      curr_address    <= 6'b0;
      curr_address2   <= 6'b0;
      cmp_res_q       <=  1'b0;
      cmp_res2_q      <=  1'b0;
      res_q           <= 32'b0;
      res2_q          <= 32'b0;
    end else if (enable_i & ~is_stall) begin
      curr_address    <= next_address;
      curr_address2   <= next_address2;
      cmp_res_q       <= cmp_res;
      cmp_res2_q      <= cmp_res2;
      res_q           <= res_n;
      res2_q          <= res2_n;
    end
  end


/////////////////////////////////////////////7
///////// NEW FSM ////////////////////////////////
////////////////////////////////////////////////
//////////////////////////////////////////////////

  // FSM: comb part update next state

  always_comb  begin

    threshold_request_o = 1'b0;
    is_stall = 1'b0;
    inverted_comp  = 1'b0;
    is_prev_inv_comp2  = 1'b0;
    addr_incr  = 2'h0;
    is_not_first_addr  = 1'b0;
    res_shift_en  = 1'b0;
    update_on_previous  = 1'b0;
    is_second_pix_fetch_addr  = 1'b0;
    update_first_pix  = 1'b0;
    update_second_pix  = 1'b0;
    inverted_comp2 = 1'b0;
    is_prev_inv_comp = 1'b0;
    ns = INIT;
    ready_o = 1'b1;
    result_o = 32'b0;

    case(cs)
      INIT: begin
        if(enable_i) begin
          threshold_request_o = 1'b1;
          ready_o = 1'b0;
        end

        if (request_granted_i & enable_i)
          ns = FIRST_CMP;
        else
          ns = INIT;

      end

      FIRST_CMP: begin
        ready_o = 1'b0;
        inverted_comp = 1'b1;
        is_prev_inv_comp = 1'b1;
        is_prev_inv_comp2 = 1'b1;  //onsider eliminte this signal
        inverted_comp2 = 1'b1;
        //addr_incr = 2'h0;  // here we gen the first address of thresh of pix 2, then +/-0
        //is_not_first_addr = 1'b0;  // here we generate the first address of threhold related to pixel 2, update on initial address
        res_shift_en = 1'b1;  // shift enabled for pixel 1
        //update_on_previous = 1'b0;  // update on '0' --> init
        is_second_pix_fetch_addr = 1'b1; // fetch address of threshold pixel 2
        update_first_pix = 1'b1; // enable partial result pixel 1
        //update_second_pix = 1'b0; // disable partial result pixel 2
        threshold_request_o = 1'b1;


        if(vecmode_i == VEC_MODE2) begin
          if (threshold_valid_i & request_granted_i) begin
            ns = THIRD_CMP2;
	     is_stall = 1'b0;
          end else begin
            ns = FIRST_CMP;
	    is_stall = 1'b1;
	  end

        end else begin
	  if(is_stall_q) begin
	     if (threshold_valid_i | request_granted_i) begin
		ns = FIRST_CMP2;
	     end else begin
		ns = FIRST_CMP;
		is_stall = 1'b1;
	     end
	  end else if (threshold_valid_i & request_granted_i) begin
            ns = FIRST_CMP2;
	    is_stall = 1'b0;
          end else begin
            ns = FIRST_CMP;
	    is_stall = 1'b1;
          end
	end // else: !if(vecmode_i == VEC_MODE2)
      end

      FIRST_CMP2: begin
        ready_o = 1'b0;
        inverted_comp = 1'b1;
        inverted_comp2 = 1'b1;
        is_prev_inv_comp = 1'b1;
        is_prev_inv_comp2 = 1'b1;  //consider eliminte this signal
        addr_incr = 2'h1;  // here we gen the second address of thresh of pix 1, then +/- 4 in the tree
        is_not_first_addr = 1'b1;  // update address on previous value
        res_shift_en = 1'b1;  // shift enabled for pixel 2
        //update_on_previous = 1'b0;  // update on '0' --> init pixel 2
        //is_second_pix_fetch_addr = 1'b0; // fetch address of threshold pixel 1
        update_second_pix = 1'b1; // enable partial result pixel 2
        //update_first_pix = 1'b0; // disable partial result pixel 1
        threshold_request_o = 1'b1;
        if(is_stall_q) begin
	   if (threshold_valid_i | request_granted_i) begin
	      ns = SECOND_CMP;
	   end else begin
	      ns = FIRST_CMP2;
	      is_stall = 1'b1;
	   end
	end else if (threshold_valid_i & request_granted_i) begin
          ns = SECOND_CMP;
	  is_stall = 1'b0;
        end else begin
          ns = FIRST_CMP2;
	  is_stall = 1'b1;
	end
      end

      SECOND_CMP: begin
        ready_o = 1'b0;
        //inverted_comp = 1'b0;
        is_prev_inv_comp2 = 1'b1;  //consider eliminte this signal
        addr_incr = 2'h1;  // here we gen the second address of thresh of pix 2, then +/- 4 in the tree
        is_not_first_addr = 1'b1;  // update on previous address
        res_shift_en = 1'b1;  // shift enabled for pixel 1
        update_on_previous = 1'b1;  // update on previous partial result
        is_second_pix_fetch_addr = 1'b1; // fetch address of threshold pixel 2
        update_first_pix = 1'b1; // enable partial result pixel 1
        //update_second_pix = 1'b0; // disable partial result pixel 2
        threshold_request_o = 1'b1;
	if(is_stall_q) begin
	   if (threshold_valid_i | request_granted_i) begin
	      ns = SECOND_CMP2;
	   end else begin
	      ns = SECOND_CMP;
	      is_stall = 1'b1;
	   end
	end else if (threshold_valid_i & request_granted_i) begin
           ns = SECOND_CMP2;
	   is_stall = 1'b0;
        end else begin
           ns = SECOND_CMP;
	   is_stall = 1'b1;
	end
      end // case: SECOND_CMP

      SECOND_CMP2: begin   // cmp pix 2 with secondo threshold, fetch third threshold related to pix 1
        ready_o = 1'b0;
        //inverted_comp = 1'b0;
        //is_prev_inv_comp2 = 1'b0;  //consider eliminte this signal
        addr_incr = 2'h2;  // here we gen the third address of thresh of pix 1, then +/- 2 in the tree
        is_not_first_addr = 1'b1;  // update on previous address
        res_shift_en = 1'b1;  // shift enabled for pixel 2
        update_on_previous = 1'b1;  // update on previous partial result
        //is_second_pix_fetch_addr = 1'b0; // fetch address of threshold pixel 1
        //update_first_pix = 1'b0; // disable partial result pixel 1
        update_second_pix = 1'b1; // enable partial result pixel 2
        threshold_request_o = 1'b1;
	if(is_stall_q) begin
	   if (threshold_valid_i | request_granted_i) begin
	      ns = THIRD_CMP;
	   end else begin
	      ns = SECOND_CMP2;
	      is_stall = 1'b1;
	   end
	end else if (threshold_valid_i & request_granted_i) begin
           ns = THIRD_CMP;
	   is_stall = 1'b0;
        end else begin
           ns = SECOND_CMP2;
	   is_stall = 1'b1;
	end
      end

      THIRD_CMP: begin   // cmp pixel 1 with third threshold, fetch third threshold of pixel 2
        ready_o = 1'b0;
        //inverted_comp = 1'b0;
        //is_prev_inv_comp2 = 1'b0;  //consider eliminte this signal
        addr_incr = 2'h2;  // here we gen the third address of thresh of pix 2, then +/- 2 in the tree
        is_not_first_addr = 1'b1;  // update on previous address
        res_shift_en = 1'b1;  // shift enabled for pixel 1
        update_on_previous = 1'b1;  // update on previous partial result
        is_second_pix_fetch_addr = 1'b1; // fetch address of threshold pixel 2
        update_first_pix = 1'b1; // enable partial result pixel 1
        //update_second_pix = 1'b0; // disable partial result pixel 2
        threshold_request_o = 1'b1;
	if(is_stall_q) begin
	   if (threshold_valid_i | request_granted_i) begin
	      ns = THIRD_CMP2;
	   end else begin
	      ns = THIRD_CMP;
	      is_stall = 1'b1;
	   end
	end else if (threshold_valid_i & request_granted_i) begin
          ns = THIRD_CMP2;
	  is_stall = 1'b0;
        end else begin
          ns = THIRD_CMP;
	  is_stall = 1'b1;
	end
      end

      THIRD_CMP2: begin   // cmp pixel 2 with third threshold, fetch fourth threshold of pix 1
        ready_o = 1'b0;
        //inverted_comp = 1'b0;
        if (vecmode_i == VEC_MODE2) begin
          inverted_comp2 = 1'b1;
          is_prev_inv_comp = 1'b1;
        end
        //is_prev_inv_comp2 = 1'b0;  //consider eliminte this signal
        addr_incr = 2'h3;  // here we gen the fourth address of thresh of pix 1, then +/- 1 in the tree
        is_not_first_addr = 1'b1;  // update on previous address
        res_shift_en = 1'b1;  // shift enabled for pixel 2
        update_on_previous = 1'b1;  // update on previous partial result
        //is_second_pix_fetch_addr = 1'b0; // fetch address of threshold pixel 1
        //update_first_pix = 1'b0; // disable partial result pixel 1
        update_second_pix = 1'b1; // enable partial result pixel 2
        threshold_request_o = 1'b1;
	if(is_stall_q) begin
	   if (threshold_valid_i | request_granted_i) begin
	      ns =FOURTH_CMP;
	   end else begin
	      ns = THIRD_CMP2;
	      is_stall = 1'b1;
	   end
	end else if (threshold_valid_i & request_granted_i) begin
           ns = FOURTH_CMP;
	   is_stall = 1'b0;
        end else begin
           ns = THIRD_CMP2;
	   is_stall = 1'b1;
	end
      end // case: THIRD_CMP2

      FOURTH_CMP: begin  // cmp pixel 1 with fourth threshold, fetch fourth threshold of pix 2
        ready_o = 1'b0;
        //inverted_comp = 1'b0;
        if( vecmode_i == VEC_MODE2)
          is_prev_inv_comp2 = 1'b1;
        //is_prev_inv_comp2 = 1'b0;  //consider eliminte this signal
        addr_incr = 2'h3;  // here we gen the fourth address of thresh of pix 2, then +/- 1 in the tree
        is_not_first_addr = 1'b1;  // update on previous address
        res_shift_en = 1'b1;  // shift enabled for pixel 1, last update
        update_on_previous = 1'b1;  // update on previous partial result
        is_second_pix_fetch_addr = 1'b1; // fetch address of threshold pixel 2
        update_first_pix = 1'b1; // enable partial result pixel 1
        //update_second_pix = 1'b0; // disable partial result pixel 2
        threshold_request_o = 1'b1;
	if(is_stall_q) begin
	   if (threshold_valid_i | request_granted_i) begin
	      ns = FINISH;
	   end else begin
	      ns = FOURTH_CMP;
		is_stall = 1'b1;
	   end
	end else if (threshold_valid_i & request_granted_i) begin
           ns = FINISH;
	   is_stall = 1'b0;
        end else begin
           ns = FOURTH_CMP;
	   is_stall = 1'b1;
	end
      end

      FINISH: begin
        ready_o = 1'b1;
        //inverted_comp = 1'b0;
        //is_prev_inv_comp2 = 1'b0;
        is_not_first_addr = 1'b1;  // it doesn't matter, no more data req_i
        res_shift_en = 1'b1;  // shift enabled for pixel 1, last update
        update_on_previous = 1'b1;  // update on previous partial result
        //is_second_pix_fetch_addr = 1'b0;  // indifferent, no more fetches
        //update_first_pix = 1'b0;  // disable partial result pixel 1
        update_second_pix = 1'b1;  // enable partial result pixel 2

        threshold_request_o = 1'b0;

        if(threshold_valid_i) begin
          ns = INIT;
	  is_stall = 1'b0;
          if(vecmode_i == VEC_MODE2)
            result_o = { 28'b0 , res2_n[ 1: 0] , res_n[ 1: 0]};
          else
            result_o = { 24'b0 , res2_n[ 3: 0] , res_n[ 3: 0]};
        end else begin
          ns = cs;
	  is_stall = 1'b1;
        end
      end

    endcase // case (cs)

  end // always_comb

  /// FSM : update state
  always_ff @(posedge clk , negedge rst_n) begin
    if(~rst_n) begin
      cs <= INIT;
    end else begin
      cs <= ns;
    end
  end








  endmodule
