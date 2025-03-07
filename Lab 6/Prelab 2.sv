`default_nettype none

module top (
    // I/O ports
    input  logic hz100, reset,
    input  logic [20:0] pb,
    output logic [7:0] left, right, ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
    output logic red, green, blue,
    
    // UART ports
    output logic [7:0] txdata,
    input  logic [7:0] rxdata,
    output logic txclk, rxclk,
    input  logic txready, rxready
);

    enc16to4 u1(.in(pb[15:0]), .out(right[3:0]), .strobe(green));

endmodule

module enc16to4 (
    input logic [15:0] in,
    output logic [3:0] out,
    output logic strobe
)



endmodule

