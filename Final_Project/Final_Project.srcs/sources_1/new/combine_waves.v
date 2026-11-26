
// ----------------------------------------------
// Combines the passed in waves
// ----------------------------------------------

module combine_waves(
    input [2:0] available_waves,
    input [15:0] wave_1, wave_2, wave_3,
    output [15:0] combined_wave_out
);

dffr #(.WIDTH(16)) combine_wave_flop (.clk(clk), .r(reset), .d(combine_waves), .q(combined_wave_out));

// Extra two bits for precision
wire [17:0] combine_waves;

// Audio samples are signed 2's complements. To extend, prepend the MSB twice, in 2's these are the same value
// Additional logic to add 18'd0 if the given wave is not available
wire [17:0] extended_wave_1 = available_waves[0] ? {{2{wave_1[15]}}, wave_1} : 18'd0;
wire [17:0] extended_wave_2 = available_waves[1] ? {{2{wave_2[15]}}, wave_2} : 18'd0;
wire [17:0] extended_wave_3 = available_waves[2] ? {{2{wave_3[15]}}, wave_3} : 18'd0;

// Add the samples
assign combine_waves = extended_wave_1 + extended_wave_2 + extended_wave_3;

// Grab the 16 MSBs, just was we did with the step
assign combined_wave_out = combine_waves[17:2];

endmodule
