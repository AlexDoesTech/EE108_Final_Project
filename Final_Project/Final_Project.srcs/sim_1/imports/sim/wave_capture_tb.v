`timescale 1ns/1ps

module wave_capture_tb ();

    // Wire & Registers Instantiations
    reg clk;
    reg reset;
    reg new_sample_ready;
    reg [15:0] new_sample_in;
    reg wave_display_idle;

    wire [8:0] write_address;
    wire write_enable;
    wire [7:0]  write_sample;
    wire read_index;

    // Wave Capture DUT
    wave_capture dut (
        .clk(clk),
        .reset(reset),
        .new_sample_ready(new_sample_ready),
        .new_sample_in(new_sample_in),
        .wave_display_idle(wave_display_idle),
        .write_address(write_address),
        .write_enable(write_enable),
        .write_sample(write_sample),
        .read_index(read_index)
    );

    // Clock cycle
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Helper task: deliver one audio sample.
    // new_sample_ready is a one-cycle pulse, like a real codec would give,
    // followed by some idle cycles (samples arrive much slower than clk).
    // ------------------------------------------------------------
    localparam CYCLES_BETWEEN_SAMPLES = 4;

    task send_sample(input signed [15:0] value);
        begin
            @(negedge clk);
            new_sample_in    = value;
            new_sample_ready = 1'b1;
            @(negedge clk);
            new_sample_ready = 1'b0;
            repeat (CYCLES_BETWEEN_SAMPLES - 1) @(negedge clk);
        end
    endtask

    // Wave Display Idle Switching
    // This block periodically switches wave_display_idle to mimic
    // the VGA changing the the wire high/low
    localparam BUSY_CYCLES = 300;
    localparam IDLE_CYCLES = 50;

    initial begin
        wave_display_idle = 1'b0;
        @(negedge reset);
        forever begin
            repeat (BUSY_CYCLES) @(negedge clk);
            wave_display_idle = 1'b1;
            repeat (IDLE_CYCLES) @(negedge clk);
            wave_display_idle = 1'b0;
        end
    end


    // Print internal wires & registers
    always @(posedge clk) begin
        if (!reset && write_enable)
            $display("WRITE  addr=%0d (buf %0d, slot %0d)  sample=%0d  read_index=%b",
                     write_address, write_address[8], write_address[7:0],
                     write_sample, read_index);
    end

    // Print states
    reg [1:0] last_state;
    always @(posedge clk) begin
        if (!reset && dut.state !== last_state)
            $display("t=%0t  STATE  %0d -> %0d   (idle=%b, read_index=%b)",
                     $time, last_state, dut.state, wave_display_idle, read_index);
        last_state <= dut.state;
    end
    

    // Tests
    integer i;
    reg signed [15:0] wave;

    initial begin
        // Initialize everything so nothing starts undefined
        reset            = 1'b1;
        new_sample_ready = 1'b0;
        new_sample_in    = 16'd0;

        // Reset the module so everything starts fresh (reset is set high above)
        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Test with a triangle wave (for testing purposes it's close enought of a sine)
        // Will start negative so as to begin a cross from neg -> pos (this will ensure that the cross logic is functional)
        wave = -16'sd8192;
        for (i = 0; i < 1200; i = i + 1) begin
            send_sample(wave);
            // step up for 32 samples, down for 32 samples
            if ((i / 32) % 2 == 0)
                wave = wave + 16'sd512;
            else
                wave = wave - 16'sd512;
        end

        // Constant positive signal (no stepping or crossing)
        // State should stay in ARMED
        for (i = 0; i < 50; i = i + 1)
            send_sample(16'sd1000);

        repeat (10) @(posedge clk);
        $finish;
    end

    // Safety net so a stuck FSM doesn't hang the simulation forever
    initial begin
        #2_000_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule