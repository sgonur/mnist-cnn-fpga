module MAC8_16
  (
    input clk_i,
    input reset_i,
    input [7:0] data_i,
    input signed [7:0] weight_i,
    output signed [15:0] mac_o //we might need to increase the output length
  );
//*---------------------------------------------------------
// Module Name: MAC8_16
// Designed by: Kailan Bugata
// Description: This module implements multiply-accumulate for an unsigned 8-bit input data and 8-bit signed weight value, outputting a 16-bit signed output.
//*---------------------------------------------------------

wire signed [15:0] product;

assign product = $signed({1'b0, data_i}) * weight_i; //casted data_i to signed for the multiplication

logic signed [15:0] accumulator_d, accumulator_q;

always_comb begin
  accumulator_d = accumulator_q + product;
end

always_ff @(posedge clk_i) begin
  if (reset_i) begin
    accumulator_q <= 16'sd0;
  end else begin
    accumulator_q <= accumulator_d;
  end
end

endmodule