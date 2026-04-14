`timescale 1ns / 1ps

module ProgramCounter_16bit(
    input wire clk,
    input wire reset,
    input wire [15:0] next,
    output reg [15:0] current
    );
    

    always @(posedge clk or posedge reset) begin
        if (reset) 
            current <= 16'd0;
        else 
            current <= next;
    end
    
endmodule