`timescale 1ns / 1ps

module Branch_Condition_Generator_tb;

    // Inputs
    reg [31:0] RS1_E;
    reg [31:0] RS2_E;
    reg [31:0] IR_E;

    // Output
    wire take_branch;

    // Instantiate the Unit Under Test (UUT)
    Branch_Condition_Generator uut (
        .RS1_E(RS1_E),
        .RS2_E(RS2_E),
        .IR_E(IR_E),
        .take_branch(take_branch)
    );

    // Task to display results
    task check_branch(
        input [31:0] rs1,
        input [31:0] rs2,
        input [2:0] funct3,
        input string name
    );
        begin
            RS1_E = rs1;
            RS2_E = rs2;
            IR_E = {17'b0, funct3, 12'b0}; // Place funct3 at [14:12]
            #1; // Wait for combinational logic to settle
            $display("%s: RS1_E=%0d, RS2_E=%0d, IR_E[14:12]=%03b => take_branch=%b",
                name, RS1_E, RS2_E, funct3, take_branch);
        end
    endtask

    initial begin
        $display("=== Branch_Condition_Generator Testbench ===");

        // BEQ (funct3 = 3'b000)
        check_branch(32'd10, 32'd10, 3'b000, "BEQ (equal)");
        check_branch(32'd10, 32'd20, 3'b000, "BEQ (not equal)");

        // BNE (funct3 = 3'b001)
        check_branch(32'd10, 32'd20, 3'b001, "BNE (not equal)");
        check_branch(32'd10, 32'd10, 3'b001, "BNE (equal)");

        // BLT (funct3 = 3'b100)
        check_branch(32'd5, 32'd10, 3'b100, "BLT (less)");
        check_branch(32'd10, 32'd5, 3'b100, "BLT (not less)");
        check_branch(-32'd5, 32'd0, 3'b100, "BLT (negative less)");

        // BGE (funct3 = 3'b101)
        check_branch(32'd10, 32'd5, 3'b101, "BGE (greater)");
        check_branch(32'd5, 32'd10, 3'b101, "BGE (not greater)");
        check_branch(-32'd5, 32'd0, 3'b101, "BGE (negative not greater)");

        // BLTU (funct3 = 3'b110)
        check_branch(32'd5, 32'd10, 3'b110, "BLTU (unsigned less)");
        check_branch(32'd10, 32'd5, 3'b110, "BLTU (unsigned not less)");
        check_branch(32'hFFFFFFFF, 32'd0, 3'b110, "BLTU (unsigned max)");

        // BGEU (funct3 = 3'b111)
        check_branch(32'd10, 32'd5, 3'b111, "BGEU (unsigned greater)");
        check_branch(32'd5, 32'd10, 3'b111, "BGEU (unsigned not greater)");
        check_branch(32'hFFFFFFFF, 32'd0, 3'b111, "BGEU (unsigned max)");

        // Default case
        check_branch(32'd10, 32'd10, 3'b010, "Default (should be 0)");

        $display("=== Testbench Complete ===");
        $finish;
    end

endmodule
