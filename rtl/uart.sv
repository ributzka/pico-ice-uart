`timescale 1ns/1ps

module uart (
    input clk_i,
    input rst_ni,
    input [13:0] divider_i,
    input rx_i,
    output tx_o,
    input [7:0] data_i,
    input ready_i,
    output [7:0] data_o,
    output ready_o
);

logic [7:0] data_out;
logic data_ready;
logic empty;
logic rd_enable;
logic ready;
assign rd_enable = !empty;
assign ready_o = ready;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        ready <= 1'b0;
    end else begin
        ready <= rd_enable;
    end
end

uart_rx uart_rx (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .rx_i(rx_i),
    .divider_i(divider_i),
    .data_o(data_out),
    .ready_o(data_ready)
);

fifo fifo_rx (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .wr_en_i(data_ready),
    .rd_en_i(rd_enable),
    .data_i(data_out),
    .data_o(data_o),
    .empty_o(empty),
    .full_o()
);


logic uart_tx_busy;
logic [7:0] fifo_tx_data;
logic uart_tx_ready, uart_tx_ready2;
logic fifo_tx_empty;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        uart_tx_ready <= 1'b0;
    end else begin
        uart_tx_ready <= !fifo_tx_empty && !uart_tx_busy;
    end
end
assign uart_tx_ready2 = uart_tx_ready && !uart_tx_busy;

uart_tx uart_tx (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .divider_i(divider_i),
    .data_i(fifo_tx_data),
    .ready_i(uart_tx_ready2),
    .busy_o(uart_tx_busy),
    .tx_o(tx_o)
);

fifo fifo_tx (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .wr_en_i(ready_i),
    .rd_en_i(uart_tx_ready2),
    .data_i(data_i),
    .data_o(fifo_tx_data),
    .empty_o(fifo_tx_empty),
    .full_o()
);

endmodule