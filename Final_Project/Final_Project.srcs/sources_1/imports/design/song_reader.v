`define SONG_WIDTH 7
`define NOTE_WIDTH 6
`define DURATION_WIDTH 6
`define SCHEDULE_WIDTH 1
`define METADATA_WIDTH 3

// ----------------------------------------------
// Define State Assignments
// ----------------------------------------------
`define SWIDTH 3
`define PAUSED             3'b000
`define WAIT               3'b001
`define INCREMENT_ADDRESS  3'b010
`define RETRIEVE_NOTE      3'b011
`define PLAYER_AVAILABLE   3'b100
`define NEW_NOTE_READY     3'b101


module song_reader(
    input clk,
    input reset,
    input play,
    input [1:0] song,
    input note_done,
    input player_available,
    output wire song_done,
    output wire [5:0] note,
    output wire [5:0] duration,
    output wire schedule,
    output wire [2:0] metadata,
    output wire new_note
);
    wire [`SONG_WIDTH-1:0] curr_note_num, next_note_num;
    wire [`SCHEDULE_WIDTH + `NOTE_WIDTH + `DURATION_WIDTH + `METADATA_WIDTH -1:0] schedule_note_and_duration;
    wire [`SONG_WIDTH + 1:0] rom_addr = {song, curr_note_num};

    wire [`SWIDTH-1:0] state;
    reg  [`SWIDTH-1:0] next;

    // For identifying when we reach the end of a song
    wire overflow;

    dffr #(`SONG_WIDTH) note_counter (
        .clk(clk),
        .r(reset),
        .d(next_note_num),
        .q(curr_note_num)
    );
    dffr #(`SWIDTH) fsm (
        .clk(clk),
        
        .r(reset),
        .d(next),
        .q(state)
    );

    song_rom rom(.clk(clk), .addr(rom_addr), .dout(schedule_note_and_duration));

    always @(*) begin
        case (state)
            `PAUSED:            next = play ? `RETRIEVE_NOTE : `PAUSED;
            `RETRIEVE_NOTE:     next = play ? `PLAYER_AVAILABLE : `PAUSED;
            `PLAYER_AVAILABLE:  next = !play ? `PAUSED
                                             : player_available ? `NEW_NOTE_READY
                                                           : `PLAYER_AVAILABLE;  
            `NEW_NOTE_READY:    next = play ? `WAIT: `PAUSED;
            `WAIT:              next = !play ? `PAUSED
                                             : (note_done ? `INCREMENT_ADDRESS
                                                          : `WAIT);
            `INCREMENT_ADDRESS: next = (play && ~overflow) ? `RETRIEVE_NOTE
                                                           : `PAUSED;
            default:            next = `PAUSED;
        endcase
    end


    assign {overflow, next_note_num} =
        (state == `INCREMENT_ADDRESS) ? {1'b0, curr_note_num} + 1
                                      : {1'b0, curr_note_num};
    assign new_note = (state == `NEW_NOTE_READY);
    assign {schedule, note, duration, metadata} = schedule_note_and_duration;
    assign song_done = overflow;

endmodule
