module ternary_signed_to_unsigned 
  (
   input logic [1:0] din_i,
   input logic make_unsigned_i,
   output logic [2:0] dout_o
   );

  logic               sign_bit;

  assign sign_bit = make_unsigned_i ? 1'b0 : din_i[1];

always_comb begin
  dout_o = {sign_bit, din_i};
  if (make_unsigned_i) begin
    dout_o[1:0] = din_i + 1;
  end
end

endmodule // ternary_signed_to_unsigned
