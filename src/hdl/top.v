// Board top level: blinks LEDs from a free-running counter.
// Port names must match src/constraints/top.xdc.
`timescale 1ns / 1ps
`default_nettype none

module top #(
    parameter integer CNT_WIDTH = 27   // ~1.3 s period on the MSB at 100 MHz
) (
    input  wire       clk,
    input  wire       btn_rst,
    output wire [3:0] led
);

    /* verilator lint_off UNUSEDSIGNAL */
    wire [CNT_WIDTH-1:0] count;   // only the top 4 bits drive LEDs
    wire                 wrap_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    counter #(.WIDTH(CNT_WIDTH)) u_counter (
        .clk   (clk),
        .rst   (btn_rst),
        .en    (1'b1),
        .count (count),
        .wrap  (wrap_unused)
    );

    assign led = count[CNT_WIDTH-1 -: 4];

endmodule

`default_nettype wire
