
// ----------------------------------------------
// Combines the passed in waves
// ----------------------------------------------

module combine_waves(
    input clk,
    input reset,
    input new_sample,
    input note_done,
    input [2:0] available_waves,
    input [15:0] wave_1, wave_2, wave_3,
    output [15:0] combined_wave_out
);

// Update whenever a note finishes are there's a new note, grab the 16 MSBs, just was we did with the step
//dffre #(.WIDTH(16)) combine_wave_flop (.clk(clk), .en(note_done || new_sample), .r(reset), .d(combine_waves[17:2]), .q(combined_wave_out));

// Extra two bits for precision
wire [17:0] combine_waves;

// Audio samples are signed 2's complements. To extend, prepend the MSB twice, in 2's these are the same value
// Additional logic to add 18'd0 if the given wave is not available
wire [17:0] extended_wave_1 = {{2{wave_1[15]}}, wave_1};
wire [17:0] extended_wave_2 = {{2{wave_2[15]}}, wave_2};
wire [17:0] extended_wave_3 = {{2{wave_3[15]}}, wave_3};

// Number of available waves
wire [1:0] num_available = available_waves[0] + available_waves[1] + available_waves[2];

// Add samples
assign combine_waves = extended_wave_1 + extended_wave_2 + extended_wave_3;

// The extra two MSB bits of precision & truncating can have the effect of dividing the original value by 4
// Therefore, dynamically truncate based on the number of waves added
assign combined_wave_out = (num_available == 2'd3) ? combine_waves[17:2] : 
                           (num_available == 2'd2) ? combine_waves[16:1] : 
                           combine_waves[15:0];
                           

endmodule
