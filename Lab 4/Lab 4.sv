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

assign red = pb[0];

assign ss0[0] = pb[0];
assign ss0[1] = pb[1];
assign ss0[2] = pb[2];
assign ss0[3] = pb[3];
assign ss0[4] = pb[4];
assign ss0[5] = pb[5];
assign ss0[6] = pb[6];
assign ss0[7] = pb[7];

bargraph bar_g (
    .in(pb[15:0]),
    .out({left[7:0], right[7:0]})
);

decode3to8 dec_3to8 (
    .in(pb[2:0]),
    .out({ss7[7], ss6[7], ss5[7], ss4[7], ss3[7], ss2[7], ss1[7], ss0[7]})
);

endmodule


module bargraph (
    input logic [15:0] in,
    output logic [15:0] out
);

assign out = (in[15] ? 16'hFFFF :
             in[14] ? 16'h7FFF :
             in[13] ? 16'h3FFF :
             in[12] ? 16'h1FFF :
             in[11] ? 16'h0FFF :
             in[10] ? 16'h07FF :
             in[9]  ? 16'h03FF :
             in[8]  ? 16'h01FF :
             in[7]  ? 16'h00FF :
             in[6]  ? 16'h007F :
             in[5]  ? 16'h003F :
             in[4]  ? 16'h001F :
             in[3]  ? 16'h000F :
             in[2]  ? 16'h0007 :
             in[1]  ? 16'h0003 :
             in[0]  ? 16'h0001 : 16'h0000);

endmodule


module decode3to8 (
    input logic [2:0] in,
    output logic [7:0] out
);

assign out = (in == 3'b000) ? 8'b00000001 :
             (in == 3'b001) ? 8'b00000010 :
             (in == 3'b010) ? 8'b00000100 :
             (in == 3'b011) ? 8'b00001000 :
             (in == 3'b100) ? 8'b00010000 :
             (in == 3'b101) ? 8'b00100000 :
             (in == 3'b110) ? 8'b01000000 :
             (in == 3'b111) ? 8'b10000000 : 8'b00000000;

endmodule
