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
    logic co;
    logic [3:0] s;

    //Step 1,2 : Full adder
    fa f1(.a(pb[0]), .b(pb[1]), .ci(pb[2]), .s(right[0]), .co(right[1]));
    fa4 f41(.a(pb[3:0]), .b(pb[7:4]), .ci(pb[19]), .s(right[3:0]), .co(right[4]));

    //Step 3 : BCD adder  
    bcdadd1 ba1(.a(pb[3:0]), .b(pb[7:4]), .ci(pb[19]), .co(co), .s(s));
    ssdec s0(.in(s), .out(ss0[6:0]), .enable(1));
    ssdec s1(.in({3'b0,co}), .out(ss1[6:0]), .enable(1));
    ssdec s5(.in(pb[7:4]), .out(ss5[6:0]), .enable(1));
    ssdec s7(.in(pb[3:0]), .out(ss7[6:0]), .enable(1));

    //Step 4 : 4-digit BCD adder
    //logic co;
    //logic [15:0] s;
    bcdadd4 ba1(.a(16'h1234), .b(16'h1111), .ci(0), .co(red), .s(s));
    ssdec s0(.in(s[3:0]),   .out(ss0[6:0]), .enable(1));
    ssdec s1(.in(s[7:4]),   .out(ss1[6:0]), .enable(1));
    ssdec s2(.in(s[11:8]),  .out(ss2[6:0]), .enable(1));
    ssdec s3(.in(s[15:12]), .out(ss3[6:0]), .enable(1));

    //Step 5 : A nine's-complement circuit
    logic [3:0] out;
    bcd9comp1 cmp1(.in(pb[3:0]), .out(out));
    ssdec s0(.in(pb[3:0]), .out(ss0[6:0]), .enable(1));
    ssdec s1(.in(out), .out(ss1[6:0]), .enable(1));
endmodule


module fa (input logic a, b, ci,
          output logic s, co);

    assign s = a ^ b ^ ci;
    assign co = (a & b) | (a & ci) | (b & ci);

endmodule


module fa4 (input logic [3:0] a, b,
            input logic ci,
            output logic [3:0] s,
            output logic co);
    
    logic c1, c2, c3;  

    fa fa0 (.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(c1));
    fa fa1 (.a(a[1]), .b(b[1]), .ci(c1), .s(s[1]), .co(c2));
    fa fa2 (.a(a[2]), .b(b[2]), .ci(c2), .s(s[2]), .co(c3));
    fa fa3 (.a(a[3]), .b(b[3]), .ci(c3), .s(s[3]), .co(co));

endmodule
    
module bcdadd1 (input logic [3:0] a, b,
                input logic ci,
                output logic [3:0] s,
                output logic co);
    
    logic [3:0] s_raw;
    logic c_raw, cout, sum;
    logic [3:0] add;
    logic [3:0] s_final;

    fa4 adder1 (.a(a), .b(b), .ci(ci), .s(s_raw), .co(c_raw));
    assign sum = (s[3] & s[2]) | (s[3] & s[1]) | c_raw;
    assign add = sum ? 4'b0000 : 4'b0110;
    
    fa4 adder2 (.a(a), .b(add), .ci(ci), .s(s_final), .co(cout));
    assign s = s_final;
    assign c = sum;
 
endmodule



module bcdadd4 (input logic [15:0] a, b,
                input logic ci,
                output logic [15:0] s,
                output logic co);
    
    logic c1, c2, c3;  
    
    bcdadd1 bcd0 (.a(a[3:0]), .b(b[3:0]), .ci(ci),  .s(s[3:0]), .co(c1));
    bcdadd1 bcd1 (.a(a[7:4]), .b(b[7:4]), .ci(c1),  .s(s[7:4]), .co(c2));
    bcdadd1 bcd2 (.a(a[11:8]), .b(b[11:8]), .ci(c2),  .s(s[11:8]), .co(c3));
    bcdadd1 bcd3 (.a(a[15:12]), .b(b[15:12]), .ci(c3),  .s(s[15:12]), .co(co));

endmodule

module bcd9comp1 (input logic [3:0] in,
                  output logic [3:0] out);

    always_comb begin
        case (in)
            4'd0: out = 4'd9;
            4'd1: out = 4'd8;
            4'd2: out = 4'd7;
            4'd3: out = 4'd6;
            4'd4: out = 4'd5;
            4'd5: out = 4'd4;
            4'd6: out = 4'd3;
            4'd7: out = 4'd2;
            4'd8: out = 4'd1;
            4'd9: out = 4'd0;
            default: out = 4'd0; 
        endcase
    end  

endmodule

module bcdaddsub4 (input  logic [15:0] a, b,
                   input logic op, // 0 = A + B, 1 = A - B
                   output [15:0] logic s);
    
    logic [3:0] b0, b1, b2, b3;
    logic [15:0] bcd_mid;

    //Calculating nine's complement via bcd9comp1
    bcd9comp1 comp0 (.in(b[3:0]), .out(b0));
    bcd9comp1 comp1 (.in(b[7:4]), .out(b1));
    bcd9comp1 comp2 (.in(b[11:8]), .out(b2));
    bcd9comp1 comp3 (.in(b[15:12]), .out(b3));

    assign bcd_mid = (op == 1) ? {b3, b2, b1, b0}: b;

    logic [15:0] bcd_final;
    assign bcd_final = (op == 1) ? bcd_mid : b;

    logic co;
    bcdadd4 addsub1(.a(a), .b(bcd_final), .ci(op), .s(s), .co(co));

endmodule


module ssdec (
  input  logic [3:0] in,    
  input  logic enable,        
  output logic [6:0] out      
);

  assign out = (!enable) ? 7'b0000000 :  
               (in == 4'h0) ? 7'b0111111 :
               (in == 4'h1) ? 7'b0000110 :
               (in == 4'h2) ? 7'b1011011 :
               (in == 4'h3) ? 7'b1001111 :
               (in == 4'h4) ? 7'b1100110 :
               (in == 4'h5) ? 7'b1101101 :
               (in == 4'h6) ? 7'b1111101 :
               (in == 4'h7) ? 7'b0000111 :
               (in == 4'h8) ? 7'b1111111 :
               (in == 4'h9) ? 7'b1100111 :
               (in == 4'hA) ? 7'b1110111 :
               (in == 4'hB) ? 7'b1111100 :
               (in == 4'hC) ? 7'b0111001 :
               (in == 4'hD) ? 7'b1011110 :
               (in == 4'hE) ? 7'b1111001 :
               (in == 4'hF) ? 7'b1110001 : 7'b0000000;

endmodule
