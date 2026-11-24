module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle,

    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index
);

`define ARMED   2'd0
`define ACTIVE  2'd1
`define WAIT    2'd2


wire [1:0] state;
reg [1:0] next_state;

wire [15:0] curr_sample;
wire [15:0] prev_sample;

reg [8:0] addr;
reg [7:0] samp;


reg write_en;

reg prev_neg;

wire [7:0] counter; 
reg [7:0] next_count;

reg change_index;
reg index;

// Sample Flop
dffre #(16) sample_flop (.clk(clk), .r(reset), .en(new_sample_ready), .d(new_sample_in), .q(curr_sample)); 

// Previous Sample Flop
dffre #(16) prev_sample_flop (.clk(clk), .r(reset), .en(new_sample_ready), .d(curr_sample), .q(prev_sample));

// State Flop
dffr #(2) state_flop (.clk(clk), .r(reset), .d(next_state), .q(state));

// Count Flop - keep it in time with the new samples and addresses
dffre #(8) count_flop (.clk(clk), .r(reset), .en(new_sample_ready), .d(next_count), .q(counter));

// Read Index Flop -- for resets, changes in the same clock cycle as next_state, No added delay
dffr #(1) read_index_flop (.clk(clk), .r(reset), .d(index), .q(read_index));


always @(*) begin
    
    // In the case that the next sample is 0, the states will never switch. Have this as a backup. On next sample ready, capture will begin writing to RAM
    prev_neg = (curr_sample == 16'd0) ? prev_sample[15] : 1'b0;

    case(state)
        `ARMED: begin
            next_count = 8'd0;
            index = read_index;
            write_en = 1'b0;
            
            // Because we're dealing with 2's complement, check the sign bit to see if prev is negative and curr is positive
            if ((prev_sample[15] && ~curr_sample[15]) || prev_neg) begin
                next_state = `ACTIVE;
            end
            
            else begin
                next_state = `ARMED;
            end
        end
        
        `ACTIVE: begin
            // We don't want it to start writing and counting before we've moved to the next sample. This is only on entering the state
            if (prev_neg && counter == 8'd0) begin
                next_state = `ACTIVE;
            end
            
            else if (counter >= 8'd255) begin
                write_en = 1'b0;
                next_state = `WAIT;
            end
            
            else begin
                write_en = 1'b1;
                addr = {~read_index, counter};
                samp = new_sample_in[15:8] + 8'd128;

                next_count = counter + 8'd1;
                next_state = `ACTIVE;
            end
        end
        
        `WAIT: begin
            if (wave_display_idle) begin
                index = ~read_index;
                next_state = `ARMED;
            end
            
            else begin
                next_state = `WAIT;
            end
        end
        
        default: next_state = `ARMED;
    
    endcase

end

assign write_address = addr;
assign write_sample = samp;
assign write_enable = write_en;

endmodule
