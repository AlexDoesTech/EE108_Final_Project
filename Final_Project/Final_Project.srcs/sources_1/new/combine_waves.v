
// ----------------------------------------------
// Combines the passed in waves
// ----------------------------------------------

module combine_waves(
    input combine_waves, // when high, the waves should be combined, otherwise 
    input [15:0] wave_to_add, wave_sum, 
    output [15:0] combined_wave_out
);

    assign combined_wave_out = combine_waves ? (wave_to_add + wave_sum) : wave_sum; // adds the wave to the rolling sum only when combine_waves is high

endmodule
