module threshold_compress
#(
  parameter OUTPUT_WIDTH = 8
)
(
  input  logic [31:0]             data_i,
  input  logic [31:0]             threshold_i,
  input  logic                    enable_i,
  input  logic                    rst_ni,
  input  logic                    clk_i,
  output logic [OUTPUT_WIDTH-1:0] data_o
);

  localparam COMPREG_WIDTH = int'(OUTPUT_WIDTH * 1.25);
  localparam COUNTER_MAX   = COMPREG_WIDTH / 2;
  localparam COUNTER_WIDTH = $clog2(COUNTER_MAX);

  logic signed [15:0]              threshold_lo, threshold_hi;
  logic signed [1:0]               activation;

  logic [2:0]                      cnt_d, cnt_q;
  logic [COMPREG_WIDTH/2-1:0][1:0] compreg_d, compreg_q;

  assign threshold_lo = threshold_i[15:0];
  assign threshold_hi = threshold_i[31:16];

  assign activation = (data_i < threshold_lo) ? -2'd1 : ((data_i < threshold_hi) ? 2'd0 : 2'd1);

  assign cnt_d = (cnt_q < COUNTER_MAX-1) ? cnt_q + 1 : '0;

  always_comb begin
    for (int i=0; i<COMPREG_WIDTH/2; i++) begin
      compreg_d[i] = compreg_q[i];
      if (i == cnt_q) begin
        compreg_d[i] = activation;
      end
    end
  end

  generate
    for (genvar i=0; i<OUTPUT_WIDTH/8; i++) begin
      ternary_encoder i_ternary_encoder
      (
        .encoder_i (compreg_q [5*i +: 5]),
        .encoder_o (data_o    [8*i +: 8])
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