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

    ssdec sd (.in(right[3:0]), .enable(1'b1), .out(ss0[6:0]));

    prienc16to4 u1 (.in(pb[15:0]), .out(right[3:0]), .strobe(green));

endmodule

// Seven-segment display decoder module
module ssdec (
    input logic [3:0] in,   // 4-bit binary input
    input logic enable,     // Enable signal
    output logic [6:0] out  // 7-segment display output
);

 // Assign 7-segment display value using conditional (ternary) operators
    assign out = (!enable) ? 7'b0000000 :  // If enable is 0, display is off
                 (in == 4'h0) ? 7'b0111111 :
                 (in == 4'h1) ? 7'b0000110 :
                 (in == 4'h2) ? 7'b1011011 :
                 (in == 4'h3) ? 7'b1001111 :
                 (in == 4'h4) ? 7'b1100110 :
                 (in == 4'h5) ? 7'b1101101 :
                 (in == 4'h6) ? 7'b1111101 :
                 (in == 4'h7) ? 7'b0000111 :
                 (in == 4'h8) ? 7'b1111111 :
                 (in == 4'h9) ? 7'b1101111 :
                 (in == 4'hA) ? 7'b1110111 :
                 (in == 4'hB) ? 7'b1111100 :
                 (in == 4'hC) ? 7'b0111001 :
                 (in == 4'hD) ? 7'b1011110 :
                 (in == 4'hE) ? 7'b1111001 :
                 (in == 4'hF) ? 7'b1110001 : 7'b0000000;

endmodule

module prienc16to4 (
    input logic [15:0] in,
    output logic [3:0] out,
    output logic strobe
);

    assign strobe = (in != 16'b0) ? 1 : 0;

    assign out = (in[15]) ? 4'b1111 :
                 (in[14]) ? 4'b1110 :
                 (in[13]) ? 4'b1101 :
                 (in[12]) ? 4'b1100 :
                 (in[11]) ? 4'b1011 :
                 (in[10]) ? 4'b1010 :
                 (in[9])  ? 4'b1001 :
                 (in[8])  ? 4'b1000 :
                 (in[7])  ? 4'b0111 :
                 (in[6])  ? 4'b0110 :
                 (in[5])  ? 4'b0101 :
                 (in[4])  ? 4'b0100 :
                 (in[3])  ? 4'b0011 :
                 (in[2])  ? 4'b0010 :
                 (in[1])  ? 4'b0001 :
                 (in[0])  ? 4'b0000 : 4'b0000;

endmodule
