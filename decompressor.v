module decompressor(
    input  wire [15:0] instr_c,
    output reg  [31:0] instr_32
);
    wire [1:0] op = instr_c[1:0];
    wire [2:0] funct3 = instr_c[15:13];

    // Macros para expandir los registros comprimidos x8-x15 (Rs1' y Rs2')
    wire [4:0] rs1_c = {2'b01, instr_c[9:7]};
    wire [4:0] rs2_c = {2'b01, instr_c[4:2]};
    
    always @* begin
        case (op)
            // ==========================================
            // CUADRANTE 0 (op = 2'b00)
            // ==========================================
            2'b00: begin
                case (funct3)
                    3'b010: // c.lw rd', imm(rs1') -> lw rd, imm(rs1)
                        instr_32 = {{5'b0, instr_c[5], instr_c[12:10], instr_c[6], 2'b00}, rs1_c, 3'b010, rs2_c, 7'b0000011};
                    3'b110: // c.sw rs2', imm(rs1') -> sw rs2, imm(rs1)
                        instr_32 = {{5'b0, instr_c[5], instr_c[12]}, rs2_c, rs1_c, 3'b010, {instr_c[11:10], instr_c[6], 2'b00}, 7'b0100011};
                    default: instr_32 = 32'h00000013; // NOP
                endcase
            end
            
            // ==========================================
            // CUADRANTE 1 (op = 2'b01)
            // ==========================================
            2'b01: begin
                case (funct3)
                    3'b000: // c.addi rd, imm -> addi rd, rd, imm
                        instr_32 = {{{6{instr_c[12]}}, instr_c[12], instr_c[6:2]}, instr_c[11:7], 3'b000, instr_c[11:7], 7'b0010011};
                    3'b001, 3'b101: // c.jal (001) / c.j (101) -> jal x1, offset / jal x0, offset
                        instr_32 = {{instr_c[12], instr_c[8], instr_c[10:9], instr_c[6], instr_c[7], instr_c[2], instr_c[11], instr_c[5:3]}, 1'b0, 10'b0, (funct3==3'b001 ? 5'b00001 : 5'b00000), 7'b1101111};
                    3'b011: // c.lui rd, nzimm -> lui rd, nzimm
                        instr_32 = {{15{instr_c[12]}}, instr_c[6:2], 12'b0, instr_c[11:7], 7'b0110111};
                    3'b100: begin // Operaciones Lógicas y Matemáticas Complejas
                        case (instr_c[11:10])
                            2'b00: // c.srli rd', shamt -> srli rd, rd, shamt
                                instr_32 = {7'b0000000, instr_c[6:2], rs1_c, 3'b101, rs1_c, 7'b0010011};
                            2'b01: // c.srai rd', shamt -> srai rd, rd, shamt
                                instr_32 = {7'b0100000, instr_c[6:2], rs1_c, 3'b101, rs1_c, 7'b0010011};
                            2'b10: // c.andi rd', imm -> andi rd, rd, imm
                                instr_32 = {{{6{instr_c[12]}}, instr_c[12], instr_c[6:2]}, rs1_c, 3'b111, rs1_c, 7'b0010011};
                            2'b11: begin // c.sub, c.xor, c.or, c.and
                                case (instr_c[6:5])
                                    2'b00: instr_32 = {7'b0100000, rs2_c, rs1_c, 3'b000, rs1_c, 7'b0110011}; // c.sub
                                    2'b01: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b100, rs1_c, 7'b0110011}; // c.xor
                                    2'b10: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b110, rs1_c, 7'b0110011}; // c.or
                                    2'b11: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b111, rs1_c, 7'b0110011}; // c.and
                                endcase
                            end
                        endcase
                    end
                    3'b110: // c.beqz rs1', offset -> beq rs1', x0, offset
                        instr_32 = {{{4{instr_c[12]}}, instr_c[6:5], instr_c[2]}, 5'b00000, rs1_c, 3'b000, {instr_c[11:10], instr_c[4:3], instr_c[12]}, 7'b1100011};
                    3'b111: // c.bnez rs1', offset -> bne rs1', x0, offset
                        instr_32 = {{{4{instr_c[12]}}, instr_c[6:5], instr_c[2]}, 5'b00000, rs1_c, 3'b001, {instr_c[11:10], instr_c[4:3], instr_c[12]}, 7'b1100011};
                    default: instr_32 = 32'h00000013; // NOP
                endcase
            end
            
            // ==========================================
            // CUADRANTE 2 (op = 2'b10)
            // ==========================================
            2'b10: begin
                case (funct3)
                    3'b000: // c.slli rd, shamt -> slli rd, rd, shamt
                        instr_32 = {7'b0000000, instr_c[6:2], instr_c[11:7], 3'b001, instr_c[11:7], 7'b0010011};
                    3'b010: // c.lwsp rd, imm(x2) -> lw rd, imm(sp)
                        instr_32 = {{4'b0, instr_c[3:2], instr_c[12], instr_c[6:4], 2'b00}, 5'b00010, 3'b010, instr_c[11:7], 7'b0000011};
                    3'b100: begin
                        if (instr_c[12] == 0) // c.jr rs1 -> jalr x0, rs1, 0
                            instr_32 = {12'b0, instr_c[11:7], 3'b000, 5'b00000, 7'b1100111};
                        else begin
                            if (instr_c[6:2] == 0) // c.jalr rs1 -> jalr x1, rs1, 0
                                instr_32 = {12'b0, instr_c[11:7], 3'b000, 5'b00001, 7'b1100111};
                            else // c.add rd, rs2 -> add rd, rd, rs2
                                instr_32 = {7'b0000000, instr_c[6:2], instr_c[11:7], 3'b000, instr_c[11:7], 7'b0110011};
                        end
                    end
                    3'b110: // c.swsp rs2, imm(x2) -> sw rs2, imm(sp)
                        instr_32 = {{4'b0, instr_c[8:7], instr_c[12:9]}, instr_c[6:2], 5'b00010, 3'b010, {2'b00, 5'b00000}, 7'b0100011};
                    default: instr_32 = 32'h00000013; // NOP
                endcase
            end
            default: instr_32 = 32'h00000013; // NOP general de seguridad
        endcase
    end
endmodule