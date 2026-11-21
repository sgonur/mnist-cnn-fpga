module Argmax (
    input  signed [20:0] scores [0:9], // Final scores for digits 0-9
    output logic    [3:0]  winning_digit // 4-bit index (0 to 9)
);
    integer i;
    logic signed [20:0] max_val;

    always_comb begin
        max_val = scores[0];
        winning_digit = 4'd0;
        
        for (i = 1; i < 10; i = i + 1) begin
            if (scores[i] > max_val) begin
                max_val = scores[i];
                winning_digit = i[3:0];
            end
        end
    end
endmodule