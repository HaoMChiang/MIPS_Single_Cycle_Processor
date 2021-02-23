`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/13/2021 12:38:05 PM
// Design Name: 
// Module Name: datapath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module datapath(
    input clk, reset, 
    input reg_dst, reg_write,
    input alu_src,
    input mem_read, mem_write,
    input mem_to_reg, 
    input [3:0] ALU_Control,
    input branch, jump,
    output [31:0] datapath_result,
    output [5:0] inst_31_26, 
    output [5:0] inst_5_0
    );
        
    reg [9:0] pc; 
    
    wire [9:0] pc_plus4;
    wire [31:0] instr;
    wire [4:0] write_reg_addr;
    wire [31:0] write_back_data;
    wire [31:0] reg1, reg2;
    wire [31:0] imm_value;
    wire [31:0] alu_in2;
    wire zero;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] shift_left_two;
    wire [9:0] branch_address;
    wire [9:0] next_pc_address;
    wire [27:0] jump_address;
    wire [9:0] branch_or_pc_plus4;
    wire branch_and_zero;
        
    always @(posedge clk or posedge reset)  
    begin   
        if(reset)   
           pc <= 10'b0000000000;  
        else  
           pc <= next_pc_address;  
    end  
 
    assign pc_plus4 = pc + 10'b0000000100;
        
    instruction_mem inst_mem (
        .read_addr(pc),
        .data(instr));
        
    assign inst_31_26 = instr[31:26];
    assign inst_5_0 = instr[5:0];
    
    mux2 #(.mux_width(5)) reg_mux 
    (   .a(instr[20:16]),
        .b(instr[15:11]),
        .sel(reg_dst),
        .y(write_reg_addr));
        
    register_file reg_file (
        .clk(clk),  
        .reset(reset),  
        .reg_write_en(reg_write),  
        .reg_write_dest(write_reg_addr),  
        .reg_write_data(write_back_data),  
        .reg_read_addr_1(instr[25:21]), 
        .reg_read_addr_2(instr[20:16]), 
        .reg_read_data_1(reg1),
        .reg_read_data_2(reg2));  
        
    sign_extend sign_ex_inst (
        .sign_ex_in(instr[15:0]),
        .sign_ex_out(imm_value));
         
    mux2 #(.mux_width(32)) alu_mux 
    (   .a(reg2),
        .b(imm_value),
        .sel(alu_src),
        .y(alu_in2));
        
    ALU alu_inst (
        .a(reg1),
        .b(alu_in2),
        .alu_control(ALU_Control),
        .zero(zero),
        .alu_result(alu_result));
        
    assign shift_left_two = imm_value << 2;
    assign branch_address = pc_plus4 + shift_left_two[9:0];
    assign branch_and_zero = zero & branch;
    assign jump_address = {instr[25:0],2'b00};

    mux2 #(.mux_width(10)) branch_mux 
    (   .a(pc_plus4),
        .b(branch_address),
        .sel(branch_and_zero),
        .y(branch_or_pc_plus4)); 
                         
     mux2 #(.mux_width(10)) next_address_mux 
    (   .a(branch_or_pc_plus4),
        .b(jump_address[9:0]),
        .sel(jump),
        .y(next_pc_address));       
          
    data_memory data_mem (
        .clk(clk),
        .mem_access_addr(alu_result),
        .mem_write_data(reg2),
        .mem_write_en(mem_write),
        .mem_read_en(mem_read),
        .mem_read_data(mem_read_data));
       
     mux2 #(.mux_width(32)) writeback_mux 
    (   .a(alu_result),
        .b(mem_read_data),
        .sel(mem_to_reg),
        .y(write_back_data));  
        
    assign datapath_result = write_back_data;
endmodule
