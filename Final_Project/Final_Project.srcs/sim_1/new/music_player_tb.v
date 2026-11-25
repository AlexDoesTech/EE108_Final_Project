`timescale 1ns / 1ps

module music_player_tb;

    reg clk;
    reg reset;
    reg play_button;
    reg next_button;
    reg new_frame;

    wire new_sample_generated;
    wire [15:0] sample_out;

    music_player #(.BEAT_COUNT(10)) dut (
        .clk(clk),
        .reset(reset),
        .play_button(play_button),
        .next_button(next_button),
        .new_frame(new_frame),
        .new_sample_generated(new_sample_generated),
        .sample_out(sample_out)
    );

    // Generate system clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Simulate AC97 codec frames
    initial begin
        new_frame = 0;

        forever begin
            repeat (99) @(negedge clk);
            new_frame = 1;
            @(negedge clk);
            new_frame = 0;
        end
    end

    // Test sequence
    initial begin

        reset = 1;
        play_button = 0;
        next_button = 0;

        // Reset music player
        repeat (10) @(negedge clk);
        reset = 0;

        // Begin playing first song
        repeat (10) @(negedge clk);
        play_button = 1;
        @(negedge clk);
        play_button = 0;

        // Allow notes and chords to play
        repeat (200000) @(negedge clk);

        // Pause song
        play_button = 1;
        @(negedge clk);
        play_button = 0;

        repeat (10000) @(negedge clk);

        // Resume song
        play_button = 1;
        @(negedge clk);
        play_button = 0;

        repeat (200000) @(negedge clk);

        // Switch to next song
        next_button = 1;
        @(negedge clk);
        next_button = 0;

        repeat (200000) @(negedge clk);

        $finish;

    end

endmodule