import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic mem_resp,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output branch_funct3_t cmpop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,

    output logic mem_read,
    output logic mem_write,
	 
	 output logic [3:0] mem_byte_enable
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                lb, lbu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                sb: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    FETCH1,
    FETCH2,
    FETCH3,
    DECODE,
    IMM,
    REG,
    LUI,
    AUIPC,
    BR,
    CSR,
    CALC_ADDR,
    LD1,
    LD2,
    ST1,
    ST2
} state, next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
    cmpop = branch_funct3_t'(funct3);
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
    aluop = alu_ops'(funct3);
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b1111;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    load_regfile = 1'b1;
    regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    load_mar = 1'b1;
    marmux_sel = sel;
endfunction

function void loadMDR();
    load_mdr = 1'b1;
    mem_read = 1'b1;
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    alumux1_sel = sel1;
    alumux2_sel = sel2;
    
    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    cmpmux_sel = sel;
    cmpop = op;
endfunction




/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    if(rst) begin
        /* FIGURE THIS OUT LATER */
    end else begin
        unique case(state)
            FETCH1: loadMAR(marmux::pc_out);
            FETCH2: loadMDR();
            FETCH3: load_ir = 1'b1;
            IMM: begin
                loadPC(pcmux::pc_plus4);
                unique case(funct3)
                    add: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                        loadRegfile(regfilemux::alu_out);
                    end
                    sll: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sll);
                        loadRegfile(regfilemux::alu_out);
                    end
                    slt: begin
                            //setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_slt);
                            setCMP(cmpmux::i_imm, blt);
                            loadRegfile(regfilemux::br_en);
                    end
                    sltu: begin 
                            //setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_slt);
                            setCMP(cmpmux::i_imm, bltu);
                            loadRegfile(regfilemux::br_en);
                    end
                    axor: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_xor);
                        loadRegfile(regfilemux::alu_out);
                    end
                    sr: begin
                        unique case(funct7[5])
                            1'b0: setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                            1'b1: setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                        endcase
                        loadRegfile(regfilemux::alu_out);
                    end
                    aor: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_or);
                        loadRegfile(regfilemux::alu_out);
                    end
                    aand: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_and);
                        loadRegfile(regfilemux::alu_out);
                    end
                endcase
            end 
            REG: begin
                loadPC(pcmux::pc_plus4);
                unique case(funct3)
                    add: begin
                        unique case(funct7[5])
                            1'b0: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
                            1'b1: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                        endcase
                        loadRegfile(regfilemux::alu_out);
                    end
                    sll: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sll);
                        loadRegfile(regfilemux::alu_out);
                    end
                    slt: begin
                            //setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_slt);
                            setCMP(cmpmux::i_imm, blt);
                            loadRegfile(regfilemux::br_en);
                    end
                    sltu: begin 
                            //setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_slt);
                            setCMP(cmpmux::i_imm, bltu);
                            loadRegfile(regfilemux::br_en);

                    end
                    axor: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_xor);
                        loadRegfile(regfilemux::alu_out);
                    end
                    sr: begin
                        unique case(funct7[5])
                            1'b0: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                            1'b1: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                        endcase
                        loadRegfile(regfilemux::alu_out);
                    end
                    aor: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_or);
                        loadRegfile(regfilemux::alu_out);
                    end
                    aand: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_and);
                        loadRegfile(regfilemux::alu_out);
                    end
                endcase
            end 
            LUI: begin
                loadRegfile(regfilemux::u_imm);
                loadPC(pcmux::pc_plus4);
            end
            AUIPC: begin
                setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
                loadPC(pcmux::alu_out);
            end
            BR: begin
                setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
                if(br_en)
                    loadPC(pcmux::alu_out);
                else 
                    loadPC(pcmux::pc_plus4);
            end
            CALC_ADDR: begin 
                if(opcode == op_load)
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                else 
                    setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
                loadMAR(marmux::alu_out);
            end
            LD1: loadMDR();
            LD2: begin
                loadRegfile(regfilemux::lw);
                loadPC(pcmux::pc_plus4);
            end
            ST1: mem_write = 1'b1;
            ST2: loadPC(pcmux::pc_plus4);

            //CSR:

           
        endcase
    end 
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	next_state = state;
    if(rst) begin
        next_state = FETCH1;
    end else begin
        unique case(state)
            FETCH1: next_state = FETCH2;
            FETCH2: begin
                if(mem_resp != 0)
                    next_state = FETCH3;
                else
                    next_state = FETCH2;
            end 
            FETCH3: next_state = DECODE;
            DECODE: begin
                unique case(opcode)
                    op_lui: next_state = LUI;
                    op_auipc: next_state = AUIPC;
                    op_br: next_state = BR;
                    op_load, op_store: next_state = CALC_ADDR;
                    op_imm: next_state = IMM;
                    op_reg: next_state = REG;
                    op_csr: next_state = CSR;
                    /*
                    op_jal:
                    op_jalr: 
                    */
                    default: next_state = FETCH1;
                endcase
            end
            IMM, REG, LUI, AUIPC, BR: next_state = FETCH1;
            CALC_ADDR: begin
                if(opcode == op_load)
                    next_state = LD1;
                else if (opcode == op_store)
                    next_state = ST1;
                else
                    next_state = FETCH1;
            end
            LD1: begin
                if(mem_resp != 0) 
                    next_state = LD2;
                else
                    next_state = LD1;
            end
            ST1: begin
                if(mem_resp != 0)
                    next_state = ST2;
                else
                    next_state = ST1;
            end
            LD2, ST2: next_state = FETCH1;

            //CSR:

            default: next_state = FETCH1;
        endcase
    end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : control
