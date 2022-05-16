module threshold_compress
#(
  parameter OUTPUT_WIDTH = 8, // note: until now, only OUTPUT_WIDTH=8 has been tested
  // do not modify or set these params!
  parameter COMPREG_WIDTH = int'(OUTPUT_WIDTH * 1.25),
  parameter COUNTER_MAX   = COMPREG_WIDTH / 2,
  parameter COUNTER_WIDTH = $clog2(COUNTER_MAX)
)
(
  input  logic signed [31:0]              preactivation_i,
  input  logic        [15:0]              threshold_lo_i,
  input  logic        [15:0]              threshold_hi_i,

  input  logic        [COUNTER_WIDTH-1:0] counter_i,        // previous counter state
  input  logic        [COMPREG_WIDTH-1:0] precompressed_i,  // previously computed activations
  input  logic        [OUTPUT_WIDTH-1:0]  compressed_i,     // previously compressed activations

  input  logic                            enable_i,
  input  logic                            rst_ni,
  input  logic                            clk_i,

  output logic       [COUNTER_WIDTH-1:0]  counter_o,        // counter state
  output logic       [COMPREG_WIDTH-1:0]  precompressed_o,  // computed activations
  output logic       [OUTPUT_WIDTH-1:0]   compressed_o,
  output logic                            compreg_full_o    // signalizes the compression register is full
);

  logic signed [1:0]               activation;

  logic [COMPREG_WIDTH/2-1:0][1:0] encoder_in;
  logic [OUTPUT_WIDTH-1:0]         encoder_out;

  always_comb begin
    activation = '0;
    encoder_in = '0;

    counter_o = '0;
    precompressed_o = '0;
    compreg_full_o = 1'b0;
    compressed_o = '0;

    if (enable_i) begin
      if (preactivation_i < threshold_lo_i) begin
        activation = -2'd1;
      end else if (preactivation_i >= threshold_hi_i) begin
        activation = 2'd1;
      end

      encoder_in = (activation << COMPREG_WIDTH'(counter_i << 1)) | precompressed_i;

      if (counter_i < COUNTER_MAX-1) begin
        precompressed_o = encoder_in;
        counter_o = counter_i + 1;
      end else if (counter_i == COUNTER_MAX-1) begin
        counter_o = '0;
        compreg_full_o = 1'b1;
      end

      compressed_o = encoder_out;
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

endmodule