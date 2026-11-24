module wave_display (
    input clk,
    input reset,
    input [10:0] x,  // [0..1279]
    input [9:0]  y,  // [0..1023]
    input valid,
    input [7:0] read_value,
    input read_index,
    output wire [8:0] read_address,
    output wire valid_pixel,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b
);
    wire [7:0] read_value_adjusted;
    wire [7:0] prev_value;
    reg [8:0] next_address;
    reg not_in_quad_bounds;
    reg in_top_half;
    reg [7:0] y_value;
    reg [23:0] color;
    
    // Address flop
    dffr #(9) addr_flop (.clk(clk), .r(reset), .d(next_address), .q(read_address));
    
    // Previous Value Flop - flips on every new RAM value
    dffre #(8) prev_addr_flop (.clk(clk), .r(reset), .en(next_address != read_address), .d(read_value_adjusted), .q(prev_value));
    
    
    always @(*) begin     
        not_in_quad_bounds = (x[10:8] == 3'b000) || (x[10:8] == 3'b011);
        in_top_half = (y[9] == 1'b0);
        
        // Handle X Address Logic
        if (~not_in_quad_bounds) begin
            next_address = {read_index, x[9], x[7:1]};
        end
        
        else begin
            next_address = 9'dX;
        end
        
        // Handle Y Value Logic
        if (in_top_half) begin
            y_value = y[8:1];
        end
        else begin
            y_value = 8'dX;
        end
        
        // Ensure edges are not drawn
        if (~valid_pixel) begin
            color = 24'd0;
        end
        
        // Rising Wave
        else if ((y_value <= read_value_adjusted) && (y_value >= prev_value)) begin
            color = 24'hFFFFFF;
        end
        
        // Falling Wave
        else if ((y_value >= read_value_adjusted) && (y_value <= prev_value)) begin
            color = 24'hFFFFFF;
        end
        
        // Set to Black
        else begin
            color = 24'd0;
        end
 
    end
    
    // Check it's within bounds. Also check that the edges of the display, cuts off the extra vertical excess
    assign valid_pixel = ((~not_in_quad_bounds && in_top_half && valid) && (x[10:2] != 9'b001_000000 && x[10:2] != 9'b010_111111));
    assign read_value_adjusted = (read_value >> 1) + 8'd32;
    assign r = color[23:16];
    assign g = color[15:8];
    assign b = color[7:0];


endmodule