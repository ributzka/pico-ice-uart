`timescale 1ns/1ps

module top (
  input clk_i,
  input rst_ni,
  input uart_rx_i,
  output uart_tx_o,
  output LED_R,
  output LED_G,
  output LED_B
);

logic [7:0] uart_data_out;
logic uart_ready_out;
logic uart_ready_in;

uart uart (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .divider_i(14'd104),
  .rx_i(uart_rx_i),
  .tx_o(uart_tx_o),
  .data_o(uart_data_out),
  .ready_o(uart_ready_out),
  .data_i(data_out),
  .ready_i(uart_ready_in)
);

logic [7:0] data_out;
always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    data_out <= 8'h00;
    uart_ready_in <= 1'b0;
  end else begin
    uart_ready_in <= 1'b0;
    if (uart_ready_out) begin
      data_out <= uart_data_out;
      uart_ready_in <= 1'b1;
    end
  end
end

assign LED_R = data_out[2];
assign LED_G = data_out[1];
assign LED_B = data_out[0];

endmodule
