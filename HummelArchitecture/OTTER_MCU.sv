
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ryan Cramer
// Module Name: OTTER_MCU
//////////////////////////////////////////////////////////////////////////////////


module OTTER_MCU(
    input CLK,
    input RST,
    input [31:0] IOBUS_IN,
    output logic IOBUS_WR,
    output [31:0] IOBUS_ADDR,
    output [31:0] IOBUS_OUT
);

logic rst;
logic [31:0] nextPC;
logic [31:0] PC_F;
logic [31:0] nextPC_F;

logic [2:0] PCsel;
logic PCoffset_sel;

logic [31:0] nextPC_D;
logic [31:0] PC_D;
logic [31:0] fwd_rs1data_D;
logic [31:0] fwd_rs2data_D;
logic [1:0] fwd1_D_sel;
logic [1:0] fwd2_D_sel;
logic [31:0] rs1data_D;
logic [31:0] rs2data_D;
logic [31:0] targetPC_D;
logic [31:0] isr_D;
logic [1:0] rd_sel_E;
logic MEMread2_D;
logic MEMwrite2_D;
logic [31:0] imm_D;
logic ALUsrc1sel_D;
logic ALUsrc2sel_D;
logic [3:0] ALUfunct_D;
logic [1:0] rd_sel_D;


logic [31:0] PC_E;
logic [31:0] nextPC_E;
logic [31:0] targetPC_E;
logic [31:0] rs1data_E;
logic [31:0] rs2data_E;
logic RDwrite_E;
logic MEMread2_E;
logic MEMwrite2_E;
logic [31:0] ALUresult_E;
logic [3:0] ALUfunct_E;
logic ALUsrc1sel_E;
logic ALUsrc2sel_E;
logic [31:0] ALUsrc1_E;
logic [31:0] ALUsrc2_E;
logic [31:0] fwd_rs1data_E;
logic [31:0] fwd_rs2data_E;
logic fwd1_E_sel;
logic fwd2_E_sel;
logic [31:0] isr_E;
logic [31:0] imm_E;

logic [31:0] nextPC_M;
logic [31:0] ALUresult_M;
logic [31:0] rs2data_M;
logic [31:0] isr_M;
logic [31:0] ir_M;
logic RDwrite_M;
logic MEMread2_M;
logic MEMwrite2_M;
logic [31:0] MEM_DOUT_2_M;
logic [31:0] rd_data_M;
logic [1:0] rd_sel_M;


logic take_branch;
logic flush;
logic stall;
logic jump_flag;
logic [2:0] immSel;
logic [31:0] red_data;
logic [31:0] CSR_rd = 32'b0;


PC OTTER_PC(
    .RST(RST),
    .CLK(CLK),
    .PC_IN(nextPC_F),
    .PC_WE(1'b1),
    .PC_OUT(nextPC)
);

/*BP OTTER_BRANCH_PREDICTOR(
    .CLK(CLK),
    .RST(rst),
    .TARGET_PC(),
    .NEXT_PC(),
    .PC(),
    .FWD_RS1_DATA(),
    .FWD_RS2_DATA(),
    .TAKE_BRANCH(),
    .FLUSH(),
    .STALL(),
    .D_OP(),
    .D_FUNC3(),
    .PC_SEL()
);*/

MUX8T1 FETCH_MUX(
    .SEL(PCsel),
    .D0(nextPC),
    .D1(targetPC_D),
    .D2(PC_D),
    .D3(nextPC_E),
    .D4(targetPC_E),
    .D5(),
    .D6(),
    .D7(),
    .DOUT(PC_F)
);

// nextPC_F = PC_F + 4; goes into Pipeline REG
// PC_F goes into Pipeline REG

MEM OTTER_MEM(
    .CLK(CLK),
    .ADDR2(ALUresult_M),
    .DIN2(rs2data_M),
    .ADDR1(PC_F[15:2]),
    .RDEN1(1'b1),
    .RDEN2(MEMread2_E),
    .WE2(MEMwrite2_M),
    .SIZE(isr_M[13:12]),
    .SIGN(ir_M[14]),
    .IO_IN(IOBUS_IN),
    .DOUT2(MEM_DOUT2_M),
    .DOUT1(isr_D)
);

REG_FILE OTTER_RF (
    .clk(CLK),
    .en(RDwrite_M),
    .adr1(isr_D[19:15]),
    .adr2(isr_D[24:20]),
    .wd(reg_data),
    .wa(isr_M[11:7]),
    .rs1(rs1data_D),
    .rs2(rs2data_D)
);

CONTROL_UNIT OTTER_CU(
    .opcode(isr_D[6:0]),
    .funct3(isr_D[14:12]),
    .func7(isr_D[30]),
    .ALUsrc1sel(ALUsrc1sel_D),
    .ALUsrc2sel(ALUsrc2sel_D),
    .ALUfunct(ALUfunct_D),
    .MEMread2(MEMread2_D),
    .RDwrite(RDwrite_D),
    .rd_sel(rd_sel_D),
    .jump_flag(jump_flag),
    .imm_sel(immSel)
);

IG OTTER_IG(
    .IMM_IN(isr_D),
    .IMM_SEL(immSel),
    .IMM_OUT(imm_D)
);

MUX4T1 FWDMUX1_D(
    .SEL(fwd1_D_sel),
    .D0(rs1data_D),
    .D1(ALUresult_E),
    .D2(rd_data_M),
    .D3(),
    .DOUT(fwd_rs1data_D)
);

MUX4T1 FWDMUX2_D(
    .SEL(fwd2_D_sel),
    .D0(rs2data_D),
    .D1(ALUresult_E),
    .D2(rd_data_M),
    .D3(),
    .DOUT(fwd_rs2data_D)
);
/*
TP OTTER_TG(
    .PC_OFFSET_SEL(),
    .IMM(),
    .PC(PC_D),
    .FWD_RS1(fwd_rs1data_D),
    .TARGET_PC(targetPC_D)
); */

MUX2T1 FWDMUX1_E1(
    .SEL(fwd1_D_sel),
    .D0(rs1data_E),
    .D1(rd_data_M),
    .DOUT(fwd_rs1data_E)
);

MUX2T1 FWDMUX2_E1(
    .SEL(fwd2_D_sel),
    .D0(rs2data_E),
    .D1(rd_data_M),
    .DOUT(fwd_rs2data_E)
);

MUX2T1 FWDMUX1_E2(
    .SEL(ALUsrc1sel_E),
    .D0(fwd_rs1data_E),
    .D1(PC_E),
    .DOUT(ALUsrc1_E)
);

MUX2T1 FWDMUX2_E2(
    .SEL(ALUsrc2sel_E),
    .D0(fwd_rs2data_E),
    .D1(imm_E),
    .DOUT(ALUsrc2_E)
);

ALU OTTER_ALU(
    .SRC_A(ALUsrc1_E),
    .SRC_B(ALUsrc2_E),
    .ALU_CTRL(ALUfunct_E),
    .RESULT(ALUresult_E),
    .ZERO()
);

BCG OTTER_BCG(
    .RS1_E(fwd_rs1data_E),
    .RS2_E(fwd_rs2data_E),
    .IR_E(isr_E),
    .TAKE_BRANCH(take_branch)
);


MUX4T1 WB_MUX(
    .SEL(rd_sel_M),
    .D0(nextPC_M),
    .D1(CSR_rd),
    .D2(MEM_DOUT2_M),
    .D3(ALUresult_M),
    .DOUT(reg_data)
);

HDU OTTER_HDU(
    .TAKE_BRANCH(take_branch),
    .PC_D(PC_D),
    .ISR_D(isr_D),
    .ISR_E(),
    .NEXT_PC_E(),
    .TARGET_PC_E(),
    .RD_WRITE_E(),
    .FWD1_SEL_D(fwd1_D_sel),
    .FWD2_SEL_D(fwd2_D_sel),
    .FWD1_SEL_E(fwd1_E_sel),
    .FWD2_SEL_E(fwd2_E_sel),
    .ISR_M(isr_M),
    .RD_WRITE_M(RDwrite_M),
    .FLUSH(),
    .STALL()
);

always_ff@(posedge CLK) begin
    nextPC_D <= nextPC_F;
    PC_D <= PC_F;
    
    nextPC_E <= nextPC_D;
    PC_E <= PC_D;
    rs1data_E <= fwd_rs1data_D;
    rs2data_E <= fwd_rs2data_D;
    
    ALUsrc1sel_E <= ALUsrc1sel_D;
    ALUsrc2sel_E <= ALUsrc2sel_D;
    ALUfunct_E <= ALUfunct_D;
    MEMread2_E <= MEMread2_D;
    MEMwrite2_E <= MEMwrite2_D;
    RDwrite_E <= RDwrite_D;
    rd_sel_E <= rd_sel_D;
    targetPC_E <= targetPC_D;
    imm_E <= imm_D;
    isr_E <= isr_D;
    
    nextPC_M <= nextPC_E;
    ALUresult_M <= ALUresult_E;
    rs2data_M <= rs2data_E;
    MEMread2_M <= MEMread2_E;
    MEMwrite2_M <= MEMwrite2_E;
    RDwrite_M <= RDwrite_E;
    rd_sel_M <= rd_sel_E;
    isr_M <= isr_E;
    
end
endmodule
