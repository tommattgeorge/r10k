import ProcTypes;

module Freelist;

input Bit#(3) numRequest default=0;
//input Bit#(3) numAdd;
input PIndx nowFree0 default=0;
input PIndx nowFree1 default=0;
input PIndx nowFree2 default=0;
input PIndx nowFree3 default=0;

Vector#(32,Bit#(6)) dfreg=newVector();
for(Integer i=0;i<32;i=i+1) begin
        dfreg[i]=i+32;
end

Reg#(Vector#(32,PIndx)) freeRegisters(dfreg);

Reg#(Word) total_free(0);
Reg#(PIndx) head(0);
Reg#(PIndx) tail(0);
Reg#(Bit#(3)) nonZero(0);
Reg#(Bit#(6)) numFree(32);

method PIndx free3(Bit#(3) used)=freeRegisters[(head+{0,used})%32];
method PIndx free2(Bit#(3) used)=freeRegisters[(head+{0,used}+31)%32];
method PIndx free1(Bit#(3) used)=freeRegisters[(head+{0,used}+30)%32];
method PIndx free0(Bit#(3) used)=freeRegisters[(head+{0,used}+29)%32];
method Bit#(6) mnumFree(Bit#(3) used)=numFree-{0,used};

rule tick;
    Bit#(3) wnonZero=0;
    PIndx wtail=tail;
    PIndx whead=head;
    Vector#(32,PIndx) wfreeRegisters=freeRegisters;
    if(nowFree0!=0) begin
        wfreeRegisters[wtail]=nowFree0;
        wtail=wtail+1;
        if(wtail==32) wtail=0;
        wnonZero=wnonZero+1;
    end
    if(nowFree1!=0) begin
        wfreeRegisters[wtail]=nowFree1;
        wtail=wtail+1;
        if(wtail==32) wtail=0;
        wnonZero=wnonZero+1;
    end
    if(nowFree2!=0) begin
        wfreeRegisters[wtail]=nowFree2;
        wtail=wtail+1;
        if(wtail==32) wtail=0;
        wnonZero=wnonZero+1;
    end
    if(nowFree3!=0) begin
        wfreeRegisters[wtail]=nowFree3;
        wtail=wtail+1;
        if(wtail==32) wtail=0;
        wnonZero=wnonZero+1;
    end
    Bit#(6) wnumFree=numFree-{0,numRequest}+{0,wnonZero};
    //total_free<=total_free+wnumFree;
    whead=whead+{0,numRequest};
    if(whead>=32) whead=whead-32;
    head<=whead;
    tail<=wtail;
    nonZero<=wnonZero;
    numFree<=wnumFree;
    freeRegisters<=wfreeRegisters;
endrule

endmodule

