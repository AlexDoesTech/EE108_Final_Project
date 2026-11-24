`timescale 1ns/1ps
 
module wave_display_tb ();
 
    // Wire & Registers Instantiations
    reg  clk;
    reg  reset;
    reg  [10:0] x;
    reg  [9:0]  y;
    reg  valid;
    reg  read_index;
 
    wire [7:0] read_value;
    wire [8:0] read_address;
    wire valid_pixel;
    wire [7:0] r, g, b;
 
    // Module Instantiatons
 
    // fake_sample_ram only has an 8-bit addr port, while read_address is
    // 9 bits, so connect the low 8 bits.
    fake_sample_ram ram (
        .clk (clk),
        .addr(read_address[7:0]),
        .dout(read_value)
    );
 
    wave_display dut (
        .clk(clk),
        .reset(reset),
        .x(x),
        .y(y),
        .valid(valid),
        .read_value(read_value),
        .read_index(read_index),
        .read_address(read_address),
        .valid_pixel(valid_pixel),
        .r(r),
        .g(g),
        .b(b)
    );
 
    // Clock Cycle
    initial clk = 1'b0;
    always #5 clk = ~clk;
 
    // ------------------------------------------------------------
    // Helper task: present one (x, y) pixel for one clock.
    // Inputs change on the negedge so they're stable at the posedge.
    // ------------------------------------------------------------
    task drive_pixel(input [10:0] px, input [9:0] py);
        begin
            @(negedge clk);
            x = px;
            y = py;
        end
    endtask
 
 
    // Terminal Output
    always @(posedge clk) begin
        if (!reset)
            $display("x=%0d y=%0d | addr=%0d ram=%0d | valid_pixel=%b rgb=%h%h%h",
                     x, y, read_address, read_value, valid_pixel, r, g, b);
    end
 

    // Tests
    integer i, j;
 
    initial begin
        // Initialize everything so nothing starts undefined
        reset      = 1'b1;
        valid      = 1'b0;
        read_index = 1'b0;
        x          = 11'd0;
        y          = 10'd0;
 
        // Hold reset for a couple of cycles
        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        valid = 1'b1;
 
        // Test a sweep of pixels in the window
        // i, j are bounded by the ranges for x, y
        for (j = 0; j < 256; j = j + 1)
            for (i = 11'b00100000000; i < 11'b01100000000; i = i + 11'd1)
                drive_pixel(i, j);
 
        // Specific edge cases
        drive_pixel(11'd10,  10'd10);    // left edge
        drive_pixel(11'd300, 10'd100);   // somewhere in the middle
        drive_pixel(11'd300, 10'd700);   // bottom half
 
        // Test valid pixel functionality (doesn't display when low)
        valid = 1'b0;
        drive_pixel(11'd300, 10'd100);
        valid = 1'b1;
 
        repeat (5) @(posedge clk);
        $finish;
    end
 
endmodule