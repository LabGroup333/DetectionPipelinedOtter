`timescale 1ns/1ps


// FORWARD_UNIT.sv
module FORWARDING_UNIT(
    input  logic [4:0] rs1_D, rs2_D,      // Source register addresses from Decode stage
    input  logic [4:0] rd_E, rd_M,        // Destination registers from EX and MEM stages
    input  logic       regWrite_E, regWrite_M,
    output logic [1:0] forwardA, forwardB // Control signals to choose forwarding source
);

    // Forwarding for rs1
    always_comb begin
        forwardA = 2'b00; // default: use register file value
        if (regWrite_E && (rd_E != 5'b0) && (rd_E == rs1_D))
            forwardA = 2'b10; // forward from EX stage
        else if (regWrite_M && (rd_M != 5'b0) && (rd_M == rs1_D))
            forwardA = 2'b01; // forward from MEM stage
    end

    // Forwarding for rs2
    always_comb begin
        forwardB = 2'b00; // default: use register file value
        if (regWrite_E && (rd_E != 5'b0) && (rd_E == rs2_D))
            forwardB = 2'b10; // forward from EX stage
        else if (regWrite_M && (rd_M != 5'b0) && (rd_M == rs2_D))
            forwardB = 2'b01; // forward from MEM stage
    end

endmodule
