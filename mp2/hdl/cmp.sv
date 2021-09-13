import rv32i_types::*;

module cmp(
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] i_imm,
    input cmpmux::cmpmux_sel_t cmpmux,
    input branch_funct3_t cmpop,
    output logic br_en
);

    logic [31:0] arg2;
    always_comb begin
        arg2 = cmpmux == cmpmux::rs2_out ? rs2 : i_imm;

        unique case(cmpop)
            beq: br_en = rs1 == arg2;
            bne: br_en = rs1 != arg2;
            blt: br_en = $signed(rs1) < $signed(rs2);
            bge: br_en = $signed(rs1) >= $signed(rs2);
            bltu: br_en = rs1 < rs2;
            bgeu: br_en = rs1 >= rs2;
        endcase
    end

endmodule : cmp