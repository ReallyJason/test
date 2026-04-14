`timescale 1ns / 1ps

module instruction_memory(
    input [15:0] address,
    output reg [15:0] instruction
    );

    reg [15:0] mem [0:255]; //256 location address -> 16 bits at each address
    integer i;
    
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 16'h0000; //all mem is 0
        end
        
        mem[0] = 16'h3102;   // addi s1, s0, 2              #2           
        mem[1] = 16'h3203;   // addi s2, s0, 3              #3
        mem[2] = 16'h0310;   // add s3, s1   (FUNC=0000)    #2
        
        mem[3] = 16'h2311;   // sw s3, 1(s1)    (2)+1=3     #3
        mem[4] = 16'h1411;   // lw s4, 1(s1)    (2)+1=3     #3
        mem[5] = 16'h354F;   // addi s5, s4, -1    2-1=1    #1
        mem[6] = 16'h4551;   // beq s5, s5, 1      1-1=0    #0
        mem[7] = 16'h3609;   // addi s6, s0, 9              #0

    end
    
    //We shift the address right by 1 because instructions are 2 bytes long, 
    always @(*) begin
        instruction = mem[address[15:1]];
    end

endmodule