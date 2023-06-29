import ProcTypes;

Vector#(256, Bit#(2)) bp=newVector();
Vector#(256, Bit#(8)) lp=newVector();

module BranchPredictor;

input Bool updateEnable default=False;
input Word updatePC default=0;
input Bool updateValue default=False;
input Bool direction default=False;

Reg#(Bit#(8)) ghr(0);
Reg#(Vector#(256, Bit#(8))) lhr(lp);
Reg#(Vector#(256, Bit#(2))) gSatCnt(bp);
Reg#(Vector#(256, Bit#(2))) pSatCnt(bp);
Reg#(Vector#(256, Bit#(2))) tSatCnt(bp);

method Bool dPred=direction;
method Bool gPred=(gSatCnt[ghr][1]==1);
method Bool pPred(Word pc)=(pSatCnt[pc[9:2]][1]==1);
method Bool tPred(Word pc)=(tSatCnt[lhr[pc[9:2]]][1]==1);
method Bool vPred(Word pc)=((tSatCnt[lhr[pc[9:2]]][1] & gSatCnt[ghr][1])
 | (tSatCnt[lhr[pc[9:2]]][1] & pSatCnt[pc[9:2]][1]) |
  (gSatCnt[ghr][1] & pSatCnt[pc[9:2]][1]))==1;


rule tick;
    if(updateEnable) begin
        case(gSatCnt[ghr])
            2'b00: begin
                if(updateValue) gSatCnt[ghr]<=2'b01;
                else gSatCnt[ghr]<=2'b00;
            end
            2'b01: begin
                if(updateValue) gSatCnt[ghr]<=2'b10;
                else gSatCnt[ghr]<=2'b00;
            end
            2'b10: begin
                if(updateValue) gSatCnt[ghr]<=2'b11;
                else gSatCnt[ghr]<=2'b01;
            end
            2'b11: begin
                if(updateValue) gSatCnt[ghr]<=2'b11;
                else gSatCnt[ghr]<=2'b10;
            end
        endcase
        ghr<=(ghr<<1)|(updateValue?8'b1:8'b0);

        case(pSatCnt[updatePC[9:2]])
            2'b00: begin
                if(updateValue) pSatCnt[updatePC[9:2]]<=2'b01;
                else pSatCnt[updatePC[9:2]]<=2'b00;
            end
            2'b01: begin
                if(updateValue) pSatCnt[updatePC[9:2]]<=2'b10;
                else pSatCnt[updatePC[9:2]]<=2'b00;
            end
            2'b10: begin
                if(updateValue) pSatCnt[updatePC[9:2]]<=2'b11;
                else pSatCnt[updatePC[9:2]]<=2'b01;
            end
            2'b11: begin
                if(updateValue) pSatCnt[updatePC[9:2]]<=2'b11;
                else pSatCnt[updatePC[9:2]]<=2'b10;
            end
        endcase

        case(tSatCnt[lhr[updatePC[9:2]]])
            2'b00: begin
                if(updateValue) tSatCnt[lhr[updatePC[9:2]]]<=2'b01;
                else tSatCnt[lhr[updatePC[9:2]]]<=2'b00;
            end
            2'b01: begin
                if(updateValue) tSatCnt[lhr[updatePC[9:2]]]<=2'b10;
                else tSatCnt[lhr[updatePC[9:2]]]<=2'b00;
            end
            2'b10: begin
                if(updateValue) tSatCnt[lhr[updatePC[9:2]]]<=2'b11;
                else tSatCnt[lhr[updatePC[9:2]]]<=2'b01;
            end
            2'b11: begin
                if(updateValue) tSatCnt[lhr[updatePC[9:2]]]<=2'b11;
                else tSatCnt[lhr[updatePC[9:2]]]<=2'b10;
            end
        endcase
        lhr[updatePC[9:2]]<=(lhr[updatePC[9:2]]<<1)|(updateValue?8'b1:8'b0);
    end
endrule

endmodule



