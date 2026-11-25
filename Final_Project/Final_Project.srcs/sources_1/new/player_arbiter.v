
// ----------------------------------------------
// Returns the MSB (priority note player)
// ----------------------------------------------

module player_arbiter(
    input wire [3:0] available_players,
    output wire [2:0] chosen_player    
);

reg [1:0] player;

always @(*) begin
    case (available_players)
        4'b1xxx: player = 3'd0; // Schedule player
        4'b01xx: player = 3'd1; // Player 1
        4'b001x: player = 3'd2; // Player 2
        4'b0001: player = 3'd3; // Player 3
        
        default: player = 3'd4; // don't default to schedule note player, this signals none are available
    endcase
end

assign chosen_player = player;

endmodule
