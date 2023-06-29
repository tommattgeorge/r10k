import ProcTypes;

Vector#(64, Word) d6432=newVector();

module RegisterFile;

input PIndx readAddr0 default=0;
input PIndx readAddr1 default=0;
input PIndx readAddr2 default=0;
input PIndx readAddr3 default=0;
input PIndx readAddr4 default=0;
input PIndx readAddr5 default=0;
input PIndx readAddr6 default=0;
input PIndx readAddr7 default=0;

Reg#(Vector#(64, Word)) regs(d6432);

function Word choose(PIndx addr,
 Bool we0, PIndx wa0, Word wv0,
 Bool we1, PIndx wa1, Word wv1,
 Bool we2, PIndx wa2, Word wv2,
 Bool we3, PIndx wa3, Word wv3);
    Word ret=regs[addr];
    if(we0 && wa0==addr) ret=wv0;
    else if(we1 && wa1==addr) ret=wv1;
    else if(we2 && wa2==addr) ret=wv2;
    else if(we3 && wa3==addr) ret=wv3;
    return ret;
endfunction

method Word readValue(PIndx addr,
 Bool we0, PIndx wa0, Word wv0,
 Bool we1, PIndx wa1, Word wv1,
 Bool we2, PIndx wa2, Word wv2,
 Bool we3, PIndx wa3, Word wv3)=choose(addr, we0, wa0, wv0, we1, wa1, wv1, we2, wa2, wv2, we3, wa3, wv3);

/*
method Word readValue0(PIndx addr, Bool we0, Word wa0, Word wv0)=(we0 && wa0==addr)?wv0:regs[addr];
method Word readValue1(PIndx addr, Bool we1, Word wa1, Word wv1)=(we1 && wa1==addr)?wv1:regs[addr];
method Word readValue2(PIndx addr, Bool we2, Word wa2, Word wv2)=(we2 && wa2==addr)?wv2:regs[addr];
method Word readValue3(PIndx addr, Bool we3, Word wa3, Word wv3)=(we3 && wa3==addr)?wv3:regs[addr];
method Word readValue4(PIndx addr, Bool we4, Word wa4, Word wv4)=(we4 && wa4==addr)?wv4:regs[addr];
method Word readValue5(PIndx addr, Bool we5, Word wa5, Word wv5)=(we5 && wa5==addr)?wv5:regs[addr];
method Word readValue6(PIndx addr, Bool we6, Word wa6, Word wv6)=(we6 && wa6==addr)?wv6:regs[addr];
method Word readValue7(PIndx addr, Bool we7, Word wa7, Word wv7)=(we7 && wa7==addr)?wv7:regs[addr];
*/

input Bool writeEnable0 default=False;
input PIndx writeAddr0 default=0;
input Word writeValue0 default=0;
input Bool writeEnable1 default=False;
input PIndx writeAddr1 default=0;
input Word writeValue1 default=0;
input Bool writeEnable2 default=False;
input PIndx writeAddr2 default=0;
input Word writeValue2 default=0;
input Bool writeEnable3 default=False;
input PIndx writeAddr3 default=0;
input Word writeValue3 default=0;

rule tick;
    Vector#(64, Word) wregs = regs;
    for(Integer i=1;i<64;i=i+1) begin
        if(writeAddr0==i && writeEnable0) wregs[i]=writeValue0;
        else if(writeAddr1==i && writeEnable1) wregs[i]=writeValue1;
        else if(writeAddr2==i && writeEnable2) wregs[i]=writeValue2;
        else if(writeAddr3==i && writeEnable3) wregs[i]=writeValue3;
    end
    regs <= wregs;
endrule

endmodule


module ReadyRegisterList;

input Bit#(64) toBeReady0 default=0;
input Bit#(64) toBeReady1 default=0;
input Bit#(64) toBeReady2 default=0;
input Bit#(64) toBeReady3 default=0;
input Bit#(64) clearReady0 default=0;
input Bit#(64) clearReady1 default=0;
input Bit#(64) clearReady2 default=0;
input Bit#(64) clearReady3 default=0;
input Bool fullFlush default=False;

Reg#(Bit#(64)) readyList(64'h00000000ffffffff);

method Bit#(64) mreadyList(Bit#(64) nr0, Bit#(64) nr1, Bit#(64) nr2, Bit#(64) nr3, Bit#(64) cr0, Bit#(64) cr1, Bit#(64) cr2, Bit#(64) cr3)=
((readyList| nr0 | nr1
            | nr2 | nr3 |
            64'h0000000000000001) & ~cr0
            & ~cr1 & ~cr2 & ~cr3);

rule tick;
    if(!fullFlush) begin
        readyList<=((readyList| toBeReady0 | toBeReady1
            | toBeReady2 | toBeReady3 |
            64'h0000000000000001) & ~clearReady0
            & ~clearReady1 & ~clearReady2 & ~clearReady3);
    end
endrule

endmodule

