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

    logic [2:0] q;
    logic [2:0] next_q;
    logic [1:0] f;

    always_ff @(posedge pb[0] , negedge pb[1]) begin
        if (~pb[1])
        q <= 3'd4;  // async reset to 4
    
        else
        q <= next_q;
    end

    logic [7:0] p;

    hc138 decode(.a(q), .e1(1'b0), .e2(1'b0), .e3(1'b1), .y(p));
    hc151 mux1(.i(8'b10100110), .s(q), .e(1'b1), .z(f[0]));
    hc151 mux2(.i(8'b10100010), .s(q), .e(1'b1), .z(f[1]));

    assign next_q[0] = ~(p[0] & p[3] & p[6] & p[7]);
    assign next_q[1] = ~(p[0] & p[2] & p[3] & p[4]);
    assign next_q[2] = ~(p[1] & p[2] & p[3] & p[6]);
    assign right[2:0] = next_q;
    assign left[2:0] = q;
    assign right[7:6] = f;

endmodule


// A SystemVerilog implementation of the 74HC138
// 3-to-8 decoder with active-low outputs.
module hc138(input logic e1,e2,e3,
             input logic [2:0]a,
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


// A SystemVerilog implementation of the 74HC151
// 8-to-1 multiplexer with 3 select lines, and both  
// active-high and active-low outputs.
module hc151(input logic e,
             input logic [2:0] s,
             input logic [7:0] i,
             output logic z,
             output logic zb);
  
  assign zb = ~z;
  assign z =  (s == 0) & i[0] |
              (s == 1) & i[1] |
              (s == 2) & i[2] |
              (s == 3) & i[3] |
              (s == 4) & i[4] |
              (s == 5) & i[5] |
              (s == 6) & i[6] |
              (s == 7) & i[7] ;
endmodule
