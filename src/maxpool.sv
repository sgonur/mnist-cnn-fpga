module maxpool
  #(
    // Width (pixels per line) and height (lines per frame) of the input image.
    // conv1 outputs 24x24 (28 - 5 + 1).
     parameter                       linewidth_px_p = 24
    ,parameter                       height_px_p    = linewidth_px_p
    ,parameter                       width_p        = 16)
   ( input [0:0]                     clk_i
    ,input [0:0]                     reset_i
    ,input [0:0]                     valid_i
    ,output [0:0]                    ready_o
    ,input signed [width_p - 1 : 0]  data_i
    ,output [0:0]                    valid_o
    ,input [0:0]                     ready_i
    ,output signed [width_p - 1 : 0] data_o
    );

//*---------------------------------------------------------
// Module Name: maxpool
// Designed by: Satvik Gonur
// Description: 2x2 max pooling with stride 2 on a raster-order stream of one
// channel. Takes linewidth_px_p x height_px_p pixels in and produces
// (linewidth_px_p/2) x (height_px_p/2) pixels out, also in raster order.
//
// Each accepted pixel is placed by a column/row counter:
//   even col : remember it in left_q.
//   odd col  : hmax = max(left_q, data_i), the max of a horizontal pair.
//     even row : store hmax in the line buffer at col/2.
//     odd row  : output max(line_buf[col/2], hmax), the max of the 2x2 block.
// So one output appears for every 4 inputs, on odd row and odd col.
// Odd sizes drop the last column/row, matching PyTorch's floor behaviour.
// Comparisons are signed. ReLU outputs are never negative, so this also works
// for them.
//*---------------------------------------------------------

localparam out_width_lp = linewidth_px_p / 2;
localparam col_bits_lp = (linewidth_px_p > 1) ? $clog2(linewidth_px_p) : 1;
localparam row_bits_lp = (height_px_p > 1) ? $clog2(height_px_p) : 1;
localparam idx_bits_lp = (out_width_lp > 1) ? $clog2(out_width_lp) : 1;

wire in_fire_w = valid_i & ready_o; // handshake

// ---------------- Position counters ----------------
logic [col_bits_lp - 1 : 0] col_q;
logic [row_bits_lp - 1 : 0] row_q;

always_ff @(posedge clk_i) begin
    if (reset_i) begin
        col_q <= '0;
        row_q <= '0;
    end else if (in_fire_w) begin
        if (col_q == col_bits_lp'(linewidth_px_p - 1)) begin // check if column 23
            col_q <= '0;
            row_q <= (row_q == row_bits_lp'(height_px_p - 1)) ? '0 : row_q + 1'b1; // go back to column 0
        end else begin
            col_q <= col_q + 1'b1;
        end
    end
end

wire odd_col_w = col_q[0];
wire odd_row_w = row_q[0];
// Odd widths/heights leave a trailing column/row with no partner. Ignore it.
// (Compare at 32 bits: 2*out_width_lp can be one past what col_q can hold.)
wire in_pool_w = (32'(col_q) < 32'(2 * out_width_lp))
               & (32'(row_q) < 32'(2 * (height_px_p / 2)));

// ---------------- Horizontal pair ----------------
logic signed [width_p - 1 : 0] left_q;

always_ff @(posedge clk_i) begin
    if (in_fire_w & ~odd_col_w) begin
        left_q <= data_i;
    end
end

wire signed [width_p - 1 : 0] hmax_w = (data_i > left_q) ? data_i : left_q;

// ---------------- Line buffer (one entry per output column) ----------------
logic signed [width_p - 1 : 0] line_buf [out_width_lp - 1 : 0];
wire [idx_bits_lp - 1 : 0] buf_idx_w = idx_bits_lp'(col_q >> 1);

always_ff @(posedge clk_i) begin
    if (in_fire_w & in_pool_w & odd_col_w & ~odd_row_w) begin
        line_buf[buf_idx_w] <= hmax_w;
    end
end

wire signed [width_p - 1 : 0] above_w = line_buf[buf_idx_w];
wire signed [width_p - 1 : 0] pool_w  = (hmax_w > above_w) ? hmax_w : above_w;

// ---------------- Output register (elastic) ----------------
wire emit_w = in_fire_w & in_pool_w & odd_col_w & odd_row_w;

elastic #(
    .width_p(width_p)
) out_reg (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(pool_w),
    .valid_i(emit_w),
    .ready_o(ready_o),
    .valid_o(valid_o),
    .data_o(data_o),
    .ready_i(ready_i)
);

endmodule
