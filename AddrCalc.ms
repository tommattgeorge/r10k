import ProcTypes;

module AddrCalc;

input Word regVal default=0;
input Word imm default=0;

Reg#(Word) effAddr(0);

method Word meffAddr(Word a, Word b)=effAddr;

rule tick;
    effAddr<=regVal+imm;
endrule

endmodule