module threshold_compress
#(
  parameter OUTPUT_WIDTH = 8, // note: until now, only OUTPUT_WIDTH=8 has been tested
  // do not modify or set these params!
  parameter COMPREG_WIDTH = int'(OUTPUT_WIDTH * 1.25),
  parameter COUNTER_MAX   = COMPREG_WIDTH / 2,
  parameter COUNTER_WIDTH = $clog2(COUNTER_MAX)
)
(
  input  logic signed [31:0]              data_i,
  input  logic        [31:0]              thresholds_i,
  input  logic                            enable_i,
  input  logic                            rst_ni,
  input  logic                            clk_i,
  output logic        [OUTPUT_WIDTH-1:0]  data_o,
  output logic        [COUNTER_WIDTH-1:0] counter_o,
  output logic                            compreg_full_o  // signalizes the compression register is full
);

  logic signed [15:0]              threshold_lo, threshold_hi;
  logic signed [1:0]               activation;

  logic [COUNTER_WIDTH:0]          cnt_d, cnt_q;
  logic [COMPREG_WIDTH/2-1:0][1:0] compreg_d, compreg_q;

  logic [COMPREG_WIDTH/2-1:0][1:0] encoder_in;
  logic [OUTPUT_WIDTH-1:0]         encoder_out;

  always_comb begin
    activation = '0;
    encoder_in = '0;

    compreg_d = '0;
    cnt_d = cnt_q;

    compreg_full_o = 1'b0;
    data_o = '0;
    counter_o = '0;

    threshold_hi = thresholds_i[15:0];
    threshold_lo = thresholds_i[31:16];

    if (enable_i) begin
      if (data_i < threshold_lo) begin
        activation = -2'd1;
      end else if (data_i >= threshold_hi) begin
        activation = 2'd1;
      end

      encoder_in = (activation << (cnt_q << 1)) | compreg_q;

      if (cnt_q < COUNTER_MAX-1) begin
        compreg_d = encoder_in;
        cnt_d = cnt_q + 1;
      end else if (cnt_q == COUNTER_MAX-1) begin
        cnt_d = '0;
        compreg_full_o = 1'b1;
      end

      data_o = encoder_out;
      counter_o = cnt_q;
    end
  end

  generate
    for (genvar i=0; i<OUTPUT_WIDTH/8; i++) begin
      ternary_encoder i_ternary_encoder
      (
        .encoder_i (encoder_in [5*i +: 5]),
        .encoder_o (encoder_out[8*i +: 8])
      );
    end
  endgenerate

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      cnt_q     <= '0;
      compreg_q <= '0;
    end else if (enable_i) begin
      cnt_q     <= cnt_d;
      compreg_q <= compreg_d;
    end
  end

endmodule