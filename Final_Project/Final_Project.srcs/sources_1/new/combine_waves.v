
// ----------------------------------------------
// Combines the passed in waves
// ----------------------------------------------

module combine_waves(
    input [2:0] available_waves,
    input [15:0] wave_1, wave_2, wave_3,
    output [15:0] combined_wave_out
);

reg [15:0] combine_waves;

always @(*) begin
    // Combine the waves only if a sample is ready
    combine_waves = available_waves[0] ? combine_waves + wave_1 : combine_waves;
    combine_waves = available_waves[1] ? combine_waves + wave_2 : combine_waves;
    combine_waves = available_waves[2] ? combine_waves + wave_3 : combine_waves;
    
end

assign combined_wave_out = combine_waves;

endmodule
