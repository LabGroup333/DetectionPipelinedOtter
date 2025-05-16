`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ryan Cramer
// Create Date: 04/29/2025 04:52:21 PM
// Module Name: OTTER_MCU 
//////////////////////////////////////////////////////////////////////////////////

module OTTER_MCU(
    input CLK,
    input RST
);

    // PC wires
    logic [31:0] pc, nextPC;
    logic [31:0] ir, wdata;
    logic zero_E;
    logic [31:0] alu_result_wire;
    logic [31:0] rs1_wire, rs2_wire;
    logic [31:0] alu_srcA_D1, alu_srcB_D1, alu_srcB_D2;
    logic alu_srcA_sel;
    logic [1:0] alu_srcB_sel;
    logic reg_write, mem_write, mem_rd2;

    // Hazard wires
    logic [1:0] forwardA, forwardB;
    logic [31:0] alu_in_A, alu_in_B;
    logic [31:0] mem_write_data;

    // Pipeline registers
    typedef struct packed {
        logic [31:0] IR, nextPC, PC;
        logic RegWrite, MemWrite, MemRead2;
        logic Jump, Branch;
        logic [1:0] RF_Sel, ImmSrc;
        logic [3:0] ALUControl;
        logic [31:0] SrcA_Out, SrcB_Out;
        logic [31:0] R1Data, R2Data;
        logic [4:0] RdD;
        logic [31:0] MemData, ALUResult;    
    } pipeline_reg_t;

    pipeline_reg_t FD, DE, EM, MW;

    // Register file
    REG_FILE OTTER_REG_FILE(
        .CLK(CLK),
        .EN(MW.RegWrite),
        .ADR1(FD.IR[19:15]),
        .ADR2(FD.IR[24:20]),
        .WA(MW.RdD),
        .WD(wdata),
        .RS1(rs1_wire),
        .RS2(rs2_wire)
    ); 

    // Forward MUX for memory write data
    always_comb begin
        case (forwardB)
            2'b00: mem_write_data = EM.R2Data;
            2'b10: mem_write_data = EM.ALUResult;
            2'b01: mem_write_data = wdata;
            default: mem_write_data = 32'bx;
        endcase
    end

    // Memory
    OTTER_mem_dualport OTTER_MEM(
        .MEM_ADDR1(pc),
        .MEM_ADDR2(EM.ALUResult),
        .MEM_CLK(CLK),
        .MEM_DIN2(mem_write_data),
        .MEM_WRITE2(EM.MemWrite),
        .MEM_READ1(1'b1),
        .MEM_READ2(EM.MemRead2),
        .IO_IN(32'b0),
        .ERR(),
        .MEM_DOUT1(ir),
        .MEM_DOUT2(MW.MemData),
        .IO_WR()
    );

    // PC
    PC OTTER_PC(
        .CLK(CLK),
        .RST(RST),
        .PC_WRITE(1'b1),
        .PC_SOURCE(3'd0),
        .JALR(32'd0),
        .JAL(32'd0),
        .BRANCH(32'd0),
        .MTVEC(32'd0),
        .MEPC(32'd0),
        .PC_OUT(pc),
        .PC_OUT_INC(nextPC)
    );

    // Immediate generation
    IG IMMED_GEN(
        .IR(FD.IR[31:7]),
        .U_TYPE(alu_srcA_D1),
        .I_TYPE(alu_srcB_D1),
        .S_TYPE(alu_srcB_D2),
        .B_TYPE(),
        .J_TYPE()
    ); 

    // Control Unit
    CTRL_UNIT OTTER_CU(
        .OPCODE(FD.IR[6:0]),
        .FUNC3(FD.IR[14:12]),
        .FUNC7(FD.IR[30]),
        .REG_WRITE(reg_write),
        .MEM_WRITE(mem_write),
        .MEM_READ2(mem_rd2),
        .RF_SEL(DE.RF_Sel),
        .ALU_FUN(DE.ALUControl),
        .ALU_SRCA(alu_srcA_sel),
        .ALU_SRCB(alu_srcB_sel)
    ); 

    // ALU input MUXes
    TwoMux ALU_Src_A(
        .SEL(alu_srcA_sel),
        .ZERO(rs1_wire),
        .ONE(alu_srcA_D1),
        .OUT(DE.SrcA_Out)
    ); 

    FourMux ALU_Src_B(
        .SEL(alu_srcB_sel),
        .ZERO(rs2_wire),
        .ONE(alu_srcB_D1),
        .TWO(alu_srcB_D2),
        .THREE(FD.PC),
        .OUT(DE.SrcB_Out)
    ); 

    // Forwarding unit
    FORWARDING_UNIT OTTER_FWD (
        .rs1_D(DE.IR[19:15]),
        .rs2_D(DE.IR[24:20]),
        .rd_E(EM.RdD),
        .rd_M(MW.RdD),
        .regWrite_E(EM.RegWrite),
        .regWrite_M(MW.RegWrite),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    always_comb begin
        case (forwardA)
            2'b00: alu_in_A = DE.SrcA_Out;
            2'b10: alu_in_A = EM.ALUResult;
            2'b01: alu_in_A = wdata;
            default: alu_in_A = 32'bx;
        endcase
    end

    always_comb begin
        case (forwardB)
            2'b00: alu_in_B = DE.SrcB_Out;
            2'b10: alu_in_B = EM.ALUResult;
            2'b01: alu_in_B = wdata;
            default: alu_in_B = 32'bx;
        endcase
    end

    // ALU
    ALU OTTER_ALU(
        .SRC_A(alu_in_A),
        .SRC_B(alu_in_B),
        .ALU_CTRL(DE.ALUControl),
        .RESULT(alu_result_wire),
        .ZERO(zero_E)
    );

    // Register file write MUX
    FourMux REG_FILE_MUX(
        .SEL(MW.RF_Sel),
        .ZERO(MW.nextPC),
        .ONE(32'd0),
        .TWO(MW.MemData),
        .THREE(MW.ALUResult),
        .OUT(wdata)
    ); 

    // Pipeline register updates
    always_ff @(posedge CLK or posedge RST) begin
        if (RST) begin
            FD.IR <= 32'b0;
            FD.PC <= 32'b0;
            FD.nextPC <= 32'b0;
        end else begin
            FD.IR <= ir;
            FD.PC <= pc;
            FD.nextPC <= nextPC;
        end
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            DE.PC <= 32'b0;
            DE.nextPC <= 32'b0;
            DE.IR <= 32'b0;
            DE.R1Data <= 32'b0;
            DE.R2Data <= 32'b0;
            DE.RdD <= 5'b0;
            DE.MemRead2 <= 1'b0;
            DE.MemWrite <= 1'b0;
            DE.RegWrite <= 1'b0;
            DE.RF_Sel <= 2'b0;
            DE.ALUControl <= 4'b0;
            DE.SrcA_Out <= 32'b0;
            DE.SrcB_Out <= 32'b0;
        end else begin
            DE.PC <= FD.PC;
            DE.nextPC <= FD.nextPC;
            DE.IR <= FD.IR;
            DE.R1Data <= rs1_wire;
            DE.R2Data <= rs2_wire;
            DE.RdD <= FD.IR[11:7];
            DE.MemRead2 <= mem_rd2;
            DE.MemWrite <= mem_write;
            DE.RegWrite <= reg_write;
        end
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            EM.RegWrite <= 1'b0;
            EM.MemWrite <= 1'b0;
            EM.MemRead2 <= 1'b0;
            EM.RF_Sel <= 2'b0;
            EM.ALUControl <= 4'b0;
            EM.R1Data <= 32'b0;
            EM.R2Data <= 32'b0;
            EM.PC <= 32'b0;
            EM.nextPC <= 32'b0;
            EM.RdD <= 5'b0;
            EM.SrcA_Out <= 32'b0;
            EM.SrcB_Out <= 32'b0;
            EM.ALUResult <= 32'b0;
        end else begin
            EM.RegWrite <= DE.RegWrite;
            EM.MemWrite <= DE.MemWrite;
            EM.MemRead2 <= DE.MemRead2;
            EM.RF_Sel <= DE.RF_Sel;
            EM.ALUControl <= DE.ALUControl;
            EM.R1Data <= DE.R1Data;
            EM.R2Data <= DE.R2Data;
            EM.PC <= DE.PC;
            EM.nextPC <= DE.nextPC;
            EM.RdD <= DE.RdD;
            EM.SrcA_Out <= DE.SrcA_Out;
            EM.SrcB_Out <= DE.SrcB_Out;
            EM.ALUResult <= alu_result_wire;
        end
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            MW.RegWrite <= 1'b0;
            MW.RF_Sel <= 2'b0;
            MW.ALUResult <= 32'b0;
            MW.RdD <= 5'b0;
            MW.nextPC <= 32'b0;
            MW.MemData <= 32'b0;
        end else begin
            MW.RegWrite <= EM.RegWrite;
            MW.RF_Sel <= EM.RF_Sel;
            MW.ALUResult <= EM.ALUResult;
            MW.RdD <= EM.RdD;
            MW.nextPC <= EM.nextPC;
        end
    end

endmodule
