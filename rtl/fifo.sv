`timescale 1ns/1ps
`default_nettype none

module fifo #(parameter DATA_WIDTH = 8, parameter DEPTH = 16) (
    input logic clk_i,
    input logic rst_ni,
    
    input logic [DATA_WIDTH-1:0] data_i,
    input logic wr_en_i,
    output logic full_o,
    
    output logic [DATA_WIDTH-1:0] data_o,
    input logic rd_en_i,
    output logic empty_o
);

logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];
logic [$clog2(DEPTH)-1:0] wr_ptr;
logic [$clog2(DEPTH)-1:0] rd_ptr;
logic [$clog2(DEPTH):0] count;

logic wr_en, rd_en;
assign wr_en = wr_en_i && !full_o;
assign rd_en = rd_en_i && !empty_o;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
    end else begin
        if (wr_en) begin
            wr_ptr <= wr_ptr + 1;
        end
        if (rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end
    end
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
       count <= 0;
    end else begin
        if (wr_en && !rd_en) begin
            count <= count + 1;
        end else if (rd_en && !wr_en) begin
            count <= count - 1;
        end else begin 
            count <= count;
        end
    end
end

always @(posedge clk_i) begin
    if (wr_en) begin
        mem[wr_ptr] <= data_i;
    end
end

always @(posedge clk_i) begin
    data_o <= mem[rd_ptr];
end

always_comb begin
    empty_o = (count == 0);
    full_o = (count == DEPTH);
end

endmodule