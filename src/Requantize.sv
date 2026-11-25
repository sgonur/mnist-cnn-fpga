module Requantize
  #(
    parameter int ACCUM_WIDTH = 21,
    parameter int MULT_WIDTH  = 16,
    parameter int SHIFT_VAL   = 12,
    parameter signed [MULT_WIDTH-1:0] SCALE_M = 16'd167
  )
  (
    input  signed [ACCUM_WIDTH-1:0] data_i, // 21-bit signed input from ReLU
    output reg    [7:0]             data_o  // Unsigned 8-bit output uint8 for next layer
  );
//*---------------------------------------------------------
// Module Name: Requantize
// Description: Implements fixed-point scaling (M), right-shift (S), 
//              and saturation clipping to convert wide accumulators back to uint8.
//*---------------------------------------------------------

  // Expanded width to hold the product of Accumulator * Scale Factor
  localparam int PROD_WIDTH = ACCUM_WIDTH + MULT_WIDTH;
  
  wire signed [PROD_WIDTH-1:0] scaled_product;
  wire signed [ACCUM_WIDTH-1:0] shifted_result;
  
  // Step 1: Multiply by the fixed-point scaling factor M
  assign scaled_product = data_i * SCALE_M;
  
  // Step 2: Arithmetic right-shift by S to scale down
  // (>>> preserves sign during the shift)
  assign shifted_result = scaled_product >>> SHIFT_VAL;
  
  // Step 3: Saturation Clipping to [0, 255]
  always_comb begin
    if (shifted_result < 0) begin
      data_o = 8'd0;       // Clamp negative values to 0
    end else if (shifted_result > 255) begin
      data_o = 8'hFF;      // Clamp overflowing values to 255
    end else begin
      data_o = shifted_result[7:0]; // Safe to truncate to 8 bits
    end
  end

endmodule