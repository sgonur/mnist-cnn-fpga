module ReLU
  #(
    parameter width_p = 16
  )
  (
    input signed [width_p-1:0] data_i,
    output signed [width_p-1:0] data_o
  );
//*---------------------------------------------------------
// Module Name: ReLU
// Designed by: Kailan Bugata
// Description: This module implements the ReLU activation function for a 16-bit signed input, outputting a 16-bit signed result.
//*---------------------------------------------------------

assign data_o = (data_i[width_p-1] == 1'b1) ? 0' : data_i;



endmodule