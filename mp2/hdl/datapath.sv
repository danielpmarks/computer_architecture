`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,
    input rst,

    /* Memory bus */
    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    
    /* ALU operator selects */
    input alu_ops aluop,
    
    /* Loading signals */
    input load_ir,
    input load_mar,
    input load_pc,
    input load_regfile,
    input load_mdr,
    input load_data_out,

    /* MUX selects */
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input pcmux::pcmux_sel_t pcmux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,

    /* IR sections */
    output logic [2:0] funct3,
    output logic [6:0] funct7,

    output logic [4:0] rs1, rs2, rd,
    output rv32i_opcode opcode,
	 
	output logic br_en,
    output rv32i_word mem_address
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out, pc_out;
rv32i_word mdrreg_out;
rv32i_word marmux_out;
rv32i_word alu_out, alumux1_out, alumux2_out;

logic [31:0] rs1_out, rs2_out;
rv32i_word regfilemux_out;

/*****************************************************************************/


/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor

logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;


ir IR(
    .clk (clk),
    .rst (rst),
    .load (load_ir),
    .in (mem_rdata),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .clk (clk),
    .rst (rst),
    .load (load_mar),
    .in ({marmux_out[31:2], 2'b00}),
    .out (mem_address)
);

register mem_data_out(
    .clk (clk),
    .rst (rst),
    .load (load_data_out),
    .in(rs2_out),
    .out(mem_wdata)
);

pc_register PC(
    .clk (clk),
    .rst (rst),
    .load (load_pc),
    .in (pcmux_out),
    .out (pc_out)
);


/* REGFILE */
regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(rd != 5'd0 ? load_regfile : 1'b0),
    .in(regfilemux_out),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);



/*****************************************************************************/

/******************************* ALU and CMP *********************************/



alu ALU(
    .aluop(aluop),
    .a(alumux1_out), 
    .b(alumux2_out), 
    .f(alu_out)

);

cmp compare(
    .rs1(rs1_out),
    .rs2(rs2_out),
    .i_imm(i_imm),
    .cmpmux(cmpmux_sel),
    .cmpop(branch_funct3_t'(funct3)),
    .br_en(br_en)
);

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
    pcmux_out = 0;
	 marmux_out = 0;
	 alumux1_out = 0;
	 alumux2_out = 0;
	 regfilemux_out = 0;
	 
	 unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
       
        default: `BAD_MUX_SEL;
    endcase


    unique case (marmux_sel)
        marmux::pc_out: marmux_out = pc_out;
        marmux::alu_out: marmux_out = alu_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_out;
        alumux::pc_out: alumux1_out = pc_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (alumux2_sel)
        alumux::i_imm: alumux2_out = i_imm;
        alumux::u_imm: alumux2_out = u_imm;
        alumux::b_imm: alumux2_out = b_imm;
        alumux::s_imm: alumux2_out = s_imm;
        alumux::j_imm: alumux2_out = j_imm;
        alumux::rs2_out: alumux2_out = rs2_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {{31{1'b0}}, br_en};
        regfilemux::u_imm: regfilemux_out = u_imm;
        regfilemux::lw: regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb: regfilemux_out = {{24{mdrreg_out[3]}}, mdrreg_out[3:0]};
        regfilemux::lbu: regfilemux_out = {{24{1'b0}}, mdrreg_out[3:0]};
        regfilemux::lh: regfilemux_out = {{16{mdrreg_out[7]}}, mdrreg_out[7:0]};
        regfilemux::lhu: regfilemux_out = {{24{1'b0}}, mdrreg_out[7:0]};
        default: `BAD_MUX_SEL;
    endcase

end
/*****************************************************************************/
endmodule : datapath
