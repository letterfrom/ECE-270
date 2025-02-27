`default_nettype none

module top (
    // I/O ports
    input  logic [3:0] pb, // R, S, T, U
    output logic [7:0] right // F7 to F0
); 

// 16-bit output bus
logic [15:0] p;
logic enable1, enable2;

assign enable1 = ~pb[3];
assign enable2 = pb[3];

hc138 decoder1 (.e1(1'b0), .e2(1'b0), .e3(enable1), .a(pb[2:0]), .y(p[7:0]));
hc138 decoder2 (.e1(1'b0), .e2(1'b0), .e3(enable2), .a(pb[2:0]), .y(p[15:8]));

//Assigning the output with NAND, AND logic
assign right[0] = ~(p[12] & p[14] & p[15]);
assign right[1] = ~(p[5] &p[10] & p[11]);
assign right[2] = ~(p[1] & p[6] & p[8]);
assign right[3] = ~(p[4] & p[13] & p[7]);
assign right[4] = ~(p[0] & p[2] & p[3]);
assign right[5] = p[0] & p[3];
assign right[6] = p[2] & p[13];
assign right[7] = p[4] & p[7];

endmodule

// A SystemVerilog implementation of the 74HC138
// 3-to-8 decoder with active-low outputs.
module hc138(input logic e1,e2,e3,
             input logic [2:0] a,
             output [7:0]y);

  logic enable;
  logic [7:0] ypos;  // uninverted y
  assign enable = ~e1 & ~e2 & e3;
  assign ypos = { enable &  a[2] &  a[1] &  a[0],
                  enable &  a[2] &  a[1] & ~a[0],
                  enable &  a[2] & ~a[1] &  a[0],
                  enable &  a[2] & ~a[1] & ~a[0],
                  enable & ~a[2] &  a[1] &  a[0],
                  enable & ~a[2] &  a[1] & ~a[0],
                  enable & ~a[2] & ~a[1] &  a[0],
                  enable & ~a[2] & ~a[1] & ~a[0] };
  assign y = ~ypos;
endmodule
