`default_nettype none

typedef enum logic [3:0] {
  LS0=0, LS1=1, LS2=2, LS3=3, LS4=4, LS5=5, LS6=6, LS7=7,
  INIT=8, OPEN=9, ALARM=10
} state_t;

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

    logic [4:0] keycode;
    logic strobe;
    
    keysync sk1 (.clk(hz100), .rst(reset), .keyin(pb[19:0]), .keyout(keycode), .keyclk(strobe));
    clock_psc psc (.clk(hz100), .rst(reset), .lim(8'd49), .hzX(red));
    keysync sk1 (.clk(keyclk), .rst(reset), .en(~|keyout[4:1]), .button(keyout[0]), .seq(seq));
    sequence_sr sr0 (.clk(keyclk), .rst(rst), .en(en), .button(keyout[0]), .seq(seq));
    fsm fsm0 (.clk(keyclk), .rst(rst), .keyout(keyout), .seq(seq), .state(state));
    display disp0 (.hzX(red), .state(state), .ss(ss), .red(red), .green(green), .blue(blue));

    assign right[0] = strobe; // only for testing within prelab, comment out when starting the lab
    assign right[5:1] = keycode; // only for testing within prelab, comment out when starting the lab
    

endmodule

module clock_psc (
    input logic clk,        
    input logic rst,
    input logic [7:0] lim,
    output logic hzX 
);

    logic [7:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 8'd0;
            hzX <= 1'b0;
        end
        else if (lim == 8'd0) begin
            hzX <= clk;  // No division, direct connection
        end
        else begin
            if (count == lim) begin
                count <= 8'd0;
                hzX <= ~hzX;  // Toggle output clock
            end
            else begin
                count <= count + 8'd1;
            end
        end
    end

endmodule


module keysync (
    input  logic clk,               // Clock input (hz100)
    input  logic rst,               // Asynchronous reset
    input  logic [19:0] keyin, 
    output logic [4:0] keyout,
    output logic keyclk 
);

    logic key_pressed;
    logic sync_ff1, sync_ff2;

    assign key_pressed = |keyin;
    assign keyout[0] = keyin[1] | keyin[3] | keyin[5] | keyin[7] | keyin[9] | keyin[11] | keyin[13] | keyin[15] | keyin[17] | keyin[19];   
    assign keyout[1] = keyin[2] | keyin[3] | keyin[6] | keyin[7] | keyin[10] | keyin[11] | keyin[14] | keyin[15] | keyin[18] | keyin[19];
    assign keyout[2] = keyin[4] | keyin[5] | keyin[6] | keyin[7] | keyin[12] | keyin[13] | keyin[14] | keyin[15];
    assign keyout[3] = keyin[8] | keyin[9] | keyin[10] | keyin[11] | keyin[12] | keyin[13] | keyin[14] | keyin[15];
    assign keyout[4] = keyin[16] | keyin[17] | keyin[18] | keyin[19];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end
        else begin
            sync_ff1 <= key_pressed;
            sync_ff2 <= sync_ff1;
        end
    end

    // Strobe
    assign keyclk = sync_ff2;

endmodule

module sequence_sr (
    input  logic clk,      
    input  logic rst,        
    input  logic en,         
    input  logic button,    
    output logic [7:0] seq   
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            seq <= 8'b00000000;
        end
        else if (en) begin
            seq <= {seq[6:0], button}; 
        end
    end

endmodule

module fsm (
    input  logic clk,               
    input  logic rst,               
    input  logic [4:0] keyout,    
    input  logic [7:0] seq,       
    output logic [3:0] state        
);

    state_t lockstate, n_lockstate;
    logic M, R;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lockstate <= INIT;
        end
        else begin
            lockstate <= n_lockstate;
        end
    end

    assign state = lockstate;

    always_comb begin
        casez(({lockstate, M, R}))
            // Figure 2
            {INIT, 1'b?, 1'b1} : n_lockstate = LS0;

            // Figure 3
            {LS0, 1'b1, 1'b0}: n_lockstate = LS1;
            {LS1, 1'b1, 1'b0}: n_lockstate = LS2;
            {LS2, 1'b1, 1'b0}: n_lockstate = LS3;
            {LS3, 1'b1, 1'b0}: n_lockstate = LS4;
            {LS4, 1'b1, 1'b0}: n_lockstate = LS5;
            {LS5, 1'b1, 1'b0}: n_lockstate = LS6;
            {LS6, 1'b1, 1'b0}: n_lockstate = LS7;
            {LS7, 1'b1, 1'b0}: n_lockstate = OPEN;
            {OPEN, 1'b?, 1'b1}: n_lockstate = LS0;

            // Figure 4 : Error Cases
            {LS0, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS1, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS2, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS3, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS4, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS5, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS6, 1'b0, 1'b0}: n_lockstate = ALARM;
            {LS7, 1'b0, 1'b0}: n_lockstate = ALARM;

            // Figure 5 : Relock behavior
            {LS0, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS1, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS2, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS3, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS4, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS5, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS6, 1'b?, 1'b1}: n_lockstate = LS0;
            {LS7, 1'b?, 1'b1}: n_lockstate = LS0;

            //default case
            default: n_lockstate = lockstate;

        endcase
    end
endmodule

module display (
    input  logic hzX,          // 2Hz clock from clock_psc
    input  logic [3:0] state,  
    output logic [63:0] ss,    
    output logic red,          
    output logic green,        
    output logic blue         
);

    localparam SeCuRE = 64'b01101101_01111001_00111001_00111110_01010000_01111001;
    logicparam logic [63:0] OPEN = 64'b00111111_01110011_01111001_01010100;
    logicparam logic [63:0] CALL911 = 64'b00111001_01110111_00111000_00111000_00000000_01100111_00000110_00000110;

    always_comb begin
        // Default: all outputs off
        ss   = 64'b0;
        red  = 1'b0;
        green= 1'b0;
        blue = 1'b0;

        case (state)
            // INIT state → blank
            4'd8: begin
                ss    = 64'b0;
                red   = 1'b0;
                green = 1'b0;
                blue  = 1'b0;
            end

            // LS0 to LS7 (SeCuRE) states
            4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7: begin
                //ss    = SeCuRE | (64'h80 << (8 * state));
                red   = 1'b0;
                green = 1'b0;
                blue  = 1'b1; // Blue LED ON
            end

            // OPEN state
            4'd9: begin
                ss    = OPEN;
                red   = 1'b0;
                green = 1'b1;
                blue  = 1'b0;
            end

            // ALARM state
            4'd10: begin
                ss    = CALL911;
                red   = hzX;  // Red LED flashes at 2Hz
                green = 1'b0;
                blue  = 1'b0;
            end

            default: begin
                ss    = 64'b0;
                red   = 1'b0;
                green = 1'b0;
                blue  = 1'b0;
            end
        endcase
    end

endmodule
