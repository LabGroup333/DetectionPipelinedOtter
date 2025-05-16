`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Closed CLOCK!!!! and letucet
// 
// Create Date: 04/27/2024 10:58:32 PM
// Design Name: 
// Module Name: ForwardMarch
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

module ForwardMarch(
    input [4:0] rs1_e, rs2_e,rs1_d, rs2_d,
    input de_ex_rs1_used, de_ex_rs2_used, 
          mem_rd_used,wb_rd_used, de_rs1_used,
          de_rs2_used, de_ex_rd_used, stalleded,
    input [4:0] ex_mem_rd, mem_wb_rd, id_ex_rd,
    input ex_mem_regWrite, mem_wb_regWrite,
    input memRead2, stalled,
    input [2:0] pcSource,
    //output logic pcWrite,
    output reg [1:0] ForwardA, ForwardB,
    output reg stall, flush //lol poker reference
    );
        
    //this is basically decoder except poker(balatro referecne)
    always_comb begin
        //OK HERE WE GO
        ForwardA = 2'b00; ForwardB = 2'b00;
        stall = 1'b0; flush = 1'b0; 
        //pcWrite = 1'b1;
        
        ////////////////////////////////////////////////////////////////////////////////////////////
        //forwarding statements for A
//        if (stalled) begin
//            ForwardA= 2'b11;
//        end
         if((rs1_e == ex_mem_rd) && ex_mem_regWrite && de_ex_rs1_used && mem_rd_used && !stalleded) begin//add extra stuff alter
            ForwardA = 2'b10;
        end 
        else if(((rs1_e == mem_wb_rd) && mem_wb_regWrite) && de_ex_rs1_used && wb_rd_used) begin
            ForwardA = 2'b01;
        end        
        /////////////////////////////////////////////////////////////////////////////////////////////
        //forwarding statements for B
//        if (stalled) begin
//            ForwardB= 2'b11;
//        end
         if(((rs2_e == ex_mem_rd) && ex_mem_regWrite) && de_ex_rs2_used && mem_rd_used && !stalleded) begin //add extra stuff later
            ForwardB = 2'b10;
        end
        
        else if(((rs2_e == mem_wb_rd) && mem_wb_regWrite) && de_ex_rs2_used && wb_rd_used)begin
            ForwardB = 2'b01;
        end
                       
        /////////////////////////////////////////////////////////////////////////////////////////////
        //load stalling w/ stall
        if((memRead2 && !stalled && de_ex_rd_used && ((de_rs1_used && rs1_d == id_ex_rd) || (de_rs2_used && rs2_d == id_ex_rd)))) begin
            stall = 1'b1;
            //pcWrite = 1'b0;
        end
        
        if(pcSource != 0) begin  //honestly idk
            flush = 1'b1;
        end
        else begin
            flush = 0;
        end
        /////////////////////////////////////////////////////////////////////////////////////////////
    end
endmodule
