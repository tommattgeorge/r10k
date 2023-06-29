import ALU1;
import ProcTypes;

module Alu;

input Word rs default=0;
input Word rt default=0;
input Word imm default=0;
input Bool useImm default=False;
input IType aluOp default=Unsupported;

Reg#(Word) aluOut(0);

method Word maluOut(Word rs1, Word rt1, Word imm1, Bool useImm1, IType aluOp1)=getAluOut(rs1, rt1, imm1, useImm1, aluOp1);

function Word getAluOut(Word rs1, Word rt1, Word imm1, Bool useImm1, IType aluOp1);
    return alu(rs1, (useImm1)?imm1:rt1, aluOp1);
endfunction

rule tick;
    aluOut<=alu(rs, (useImm)?imm:rt, aluOp);
endrule

endmodule

