`timescale 1ns/1ps

module uart_rx (
    input clk_i,
    input rst_ni,
    input rx_i,
    input [13:0] divider_i,
    output [7:0] data_o,
    output ready_o
);

logic [7:0] data_out, data_out_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_out <= 8'b0;
    end else begin
        data_out <= data_out_next;
    end
end

assign data_o = data_out;

logic ready, ready_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        ready <= 1'b0;
    end else begin
        ready <= ready_next;
    end
end
assign ready_o = ready;

// Remove Metastability with multiple flip-flops
logic [2:0] data_clean;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_clean <= 3'b0;
    end else begin
        data_clean <= {data_clean[1:0], rx_i};
    end
end

// Counter for sampling
logic [13:0] count, count_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        count <= 14'd0;
    end else begin
        count <= count_next;
    end
end

// Bit counter
logic [2:0] bit_count, bit_count_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        bit_count <= 3'b0;
    end else begin
       bit_count <= bit_count_next;
    end
end

// State machine
typedef enum {
    IDLE,
    START,
    DATA,
    STOP
} state_t;

state_t state, state_next;

// State register
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state <= IDLE;
    end else begin
        state <= state_next;
    end
end

// Next state logic
always_comb begin
    // Per default stay in the current state
    state_next = state;
    data_out_next = data_out;
    count_next = count;
    bit_count_next = bit_count;

    // Per default not ready
    ready_next = 1'b0;

    case (state)
        IDLE: begin
            // Check for start bit (falling edge 1 -> 0).
            if (data_clean[2:1] == 2'b10) begin
                state_next = START;
                count_next = divider_i >> 1;
            end
        end

        START: begin
            count_next = count - 1;
        
            if (count == 0) begin            
                state_next = DATA;
                count_next = divider_i;
                bit_count_next = 3'b0;

                // Check that start bit is still zero. If not, go back to IDLE.
                if (data_clean[2:1] != 2'b00) begin
                    state_next = IDLE;
                end
            end
        end

        DATA: begin
            count_next = count - 1;

            if (count == 0) begin
                // Read data bit.
                data_out_next = {data_clean[2], data_out[7:1]};
                bit_count_next = bit_count + 1;
                count_next = divider_i;

                if (bit_count == 7) begin
                    state_next = STOP;
                    count_next = divider_i;
                end
            end
        end

        STOP: begin
            count_next = count - 1;

            if (count == 0) begin
                state_next = IDLE;
                count_next = 0;
                ready_next = 1'b1;
            end
        end

        default: begin
            state_next = IDLE;
        end
    endcase
end

endmodule