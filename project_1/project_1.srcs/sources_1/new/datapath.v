module datapath(
    input clk,
    input reset,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an
);

    wire [15:0] pc_current, pc_next, pc_plus2, pc_branch_target, pc_after_branch;
    wire [15:0] instruction;
    wire [3:0] opcode, rt_rd, rs, funct, immediate;
    wire [15:0] imm_sign_ext, branch_offset, jump_offset;
    wire [15:0] write_data, read_data1, read_data2, alu_input_b, alu_result, mem_read_data;
    wire reg_write, mem_to_reg, mem_write, mem_read, alu_src, branch, branch_ne, jump, zero;
    wire [1:0] alu_op;
    reg  [2:0] alu_control;

    assign an = 4'b1110;
    hex_decoder display_unit (
        .bin_in(alu_result[3:0]), 
        .seg_out(seg)
    );

    // --- PC Logic ---
    assign led = pc_current;
    ProgramCounter_16bit pc_reg(
        .clk(clk), 
        .reset(reset), 
        .next(pc_next), 
        .current(pc_current)
    );

    assign pc_plus2 = pc_current + 16'd2;

    instruction_memory imem(
        .address(pc_current), 
        .instruction(instruction)
    );

    // --- Decode & Control ---
    instruction_decode decode(
        .instruction(instruction), 
        .opcode(opcode), 
        .rt_rd(rt_rd), 
        .rs(rs),
        .funct(funct), 
        .immediate(immediate), 
        .imm_sign_ext(imm_sign_ext),
        .branch_offset(branch_offset), 
        .jump_offset(jump_offset)
    );

    control_unit ctrl(
        .opcode(opcode), 
        .reg_write(reg_write), 
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write), 
        .mem_read(mem_read), 
        .alu_src(alu_src),
        .branch(branch), 
        .branch_ne(branch_ne), 
        .jump(jump), 
        .alu_op(alu_op)
    );

    register_file registers(
        .clk(clk), 
        .reg_write(reg_write), 
        .read_reg1(rs), 
        .read_reg2(rt_rd),
        .write_reg(rt_rd), 
        .write_data(write_data), 
        .read_data1(read_data1), 
        .read_data2(read_data2)
    );

    assign alu_input_b = alu_src ? imm_sign_ext : read_data2;

    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 3'b000;
            2'b01: alu_control = 3'b001;
            2'b10: begin
                case (funct)
                    4'b0000: alu_control = 3'b000;
                    4'b0001: alu_control = 3'b001;
                    4'b0010: alu_control = 3'b011;
                    4'b0011: alu_control = 3'b010;
                    default: alu_control = 3'b000;
                endcase
            end
            default: alu_control = 3'b000;
        endcase
    end

    alu execution_unit(
        .a(read_data1), .b(alu_input_b), .alu_control(alu_control), .result(alu_result), .zero(zero)
    );

    // --- Memory & Writeback ---
    data_memory dmem(
        .clk(clk), .address(alu_result), .write_data(read_data2),
        .mem_write(mem_write), .mem_read(mem_read), .read_data(mem_read_data)
    );

    assign write_data = mem_to_reg ? mem_read_data : alu_result;

    // --- Next PC ---
    wire branch_taken = (branch & zero) | (branch_ne & ~zero);
    assign pc_branch_target = pc_plus2 + branch_offset;
    assign pc_after_branch = branch_taken ? pc_branch_target : pc_plus2;
    assign pc_next = jump ? (pc_plus2 + jump_offset) : pc_after_branch;

endmodule