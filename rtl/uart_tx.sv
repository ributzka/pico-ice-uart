`timescale 1ns/1ps

module uart_tx (
    input clk_i,
    input rst_ni,
    input [13:0] divider_i,
    input [7:0] data_i,
    input ready_i,
    output busy_o,
    output tx_o
);

logic [9:0] data_out, data_out_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_out <= 10'b1;
    end else begin
        data_out <= data_out_next;
    end
end

assign tx_o = data_out[0];

logic [13:0] count, count_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        count <= 14'b0;
    end else begin
        count <= count_next;
    end
end

// Bit counter
logic [3:0] bit_count, bit_count_next;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        bit_count <= 4'b0;
    end else begin
       bit_count <= bit_count_next;
    end
end

// State machine
typedef enum {
    IDLE,
    SEND
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

assign busy_o = (state != IDLE);

// Next state logic
always_comb begin
    // Per default stay in the current state
    state_next = state;
    data_out_next = data_out;
    count_next = count;
    bit_count_next = bit_count;

    case (state)
        IDLE: begin
            // Add start and stop bit to data.
            if (ready_i) begin
                data_out_next = {1'b1, data_i, 1'b0};
                state_next = SEND;
                count_next = divider_i;
            end
        end

        SEND: begin
            count_next = count - 1;

            if (count == 0) begin
                data_out_next = data_out >> 1;
                bit_count_next = bit_count + 1;
                count_next = divider_i;

                if (bit_count == 10) begin
                    state_next = IDLE;
                    data_out_next = 10'b1;
                end
            end
        end

        default: begin
            state_next = IDLE;
        end
    endcase
end

endmodule