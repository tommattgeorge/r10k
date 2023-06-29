import ProcTypes;

Vector#(8, IType) d8i=newVector();
Vector#(8, Word) d832=newVector();
Vector#(8, Bool) dbl8=newVector();
Vector#(8, Bit#(6)) d68=newVector();
Vector#(8, Bit#(3)) d38=newVector();

module IssueQueue;

input Bool fullFlush default=False;
input Bit#(2) maxIssue default=0;
input Bit#(2) queueNum default=0;
input Bit#(64) readyFlags default=64'h0000000000000001;

Reg#(Bit#(64)) outReadyFlag0(0);
Reg#(Bit#(64)) outReadyFlag1(0);

method Bit#(64) moutReadyFlag0=outReadyFlag0;
method Bit#(64) moutReadyFlag1=outReadyFlag1;

Vector#(4, IType) unvec = newVector();

for(Integer i=0; i<4; i=i+1) begin
    unvec[i] = Unsupported;
end

input Vector#(4, IType) inOperation default = unvec;

input Vector#(4, Word) inImmediate default=newVector();

input Vector#(4, Bit#(3)) inROB default = newVector();

input Vector#(4, PIndx) inRT default=newVector();
input Vector#(4, PIndx) inRS default=newVector();
input Vector#(4, PIndx) inRD default=newVector();

input Vector#(4, Bit#(2)) inQueue default=newVector();

input Vector#(4, Bool) inUImm default=newVector();

Reg#(Bool) outUImm0(False);
Reg#(Bool) outUImm1(False);
Reg#(IType) outOperation0(Unsupported);
Reg#(IType) outOperation1(Unsupported);
Reg#(Word) outImmediate0(0);
Reg#(Word) outImmediate1(0);
Reg#(PIndx) outRT0(0);
Reg#(PIndx) outRT1(0);
Reg#(PIndx) outRS0(0);
Reg#(PIndx) outRS1(0);
Reg#(PIndx) outRD0(0);
Reg#(PIndx) outRD1(0);
Reg#(Bit#(3)) outROB0(0);
Reg#(Bit#(3)) outROB1(0);

method IType moutOperation0=outOperation0;
method IType moutOperation1=outOperation1;
method Word moutImmediate0=outImmediate0;
method Word moutImmediate1=outImmediate1;
method PIndx moutRT0=outRT0;
method PIndx moutRT1=outRT1;
method PIndx moutRS0=outRS0;
method PIndx moutRS1=outRS1;
method PIndx moutRD0=outRD0;
method PIndx moutRD1=outRD1;
method Bit#(3) moutROB0=outROB0;
method Bit#(3) moutROB1=outROB1;
method Bool moutUImm0 = outUImm0;
method Bool moutUImm1 = outUImm1;

Reg#(Vector#(8, IType)) operation(d8i);
Reg#(Vector#(8, Word)) immediate(d832);
Reg#(Vector#(8, Bool)) valid(dbl8);
Reg#(Vector#(8, PIndx)) rt(d68);
Reg#(Vector#(8, PIndx)) rs(d68);
Reg#(Vector#(8, PIndx)) rd(d68);
Reg#(Vector#(8, Bit#(3))) rob(d38);
Reg#(Vector#(8, Bool)) usesImm(dbl8);
Reg#(Bit#(2)) numIssued(0);

method Bit#(2) mnumIssued=numIssued;


Reg#(Vector#(8, Bool)) entryReady(dbl8);

rule tick;
    if(fullFlush) begin
        valid <= dbl8;
        numIssued<=0;
        outReadyFlag0<=0;
        outReadyFlag1<=0;
        outOperation0<=Unsupported;
        outImmediate0<=0;
        outRT0<=0;
        outRS0<=0;
        outRD0<=0;
        outROB0<=0;
        outUImm0<=False;
        outOperation1<=Unsupported;
        outImmediate1<=0;
        outRT1<=0;
        outRS1<=0;
        outRD1<=0;
        outROB1<=0;
        outUImm1<=False;
    end
    else begin
        Vector#(8, Bool) wvalid=valid;
        Bool winserted=False;
        Vector#(8, IType) woperation=operation;
        Vector#(8, Word) wimmediate=immediate;
        Vector#(8, PIndx) wrt=rt;
        Vector#(8, PIndx) wrs=rs;
        Vector#(8, PIndx) wrd=rd;
        Vector#(8, Bit#(3)) wrob=rob;
        Vector#(8, Bool) wusesImm=usesImm;
        Vector#(8, Bool) wentryReady=entryReady;
        for(Integer i=0;i<8;i=i+1) begin
            wentryReady[i]=valid[i] && ((readyFlags>>rs[0])&1)==1 && ((readyFlags>>rt[0])&1)==1;
        end
        for(Integer i=0;i<7;i=i+1) begin
            if((!wvalid[i])&&(wvalid[i+1])) begin
                wvalid[i]=True;
                woperation[i]=woperation[i+1];
                wimmediate[i]=wimmediate[i+1];
                wrt[i]=wrt[i+1];
                wrs[i]=wrs[i+1];
                wrd[i]=wrd[i+1];
                wrob[i]=wrob[i+1];
                wusesImm[i]=wusesImm[i+1];
                wvalid[i+1]=False;
            end
        end
        Vector#(8, Bit#(3)) queueChoice = newVector();
        Bit#(2) chooseIdx = 0;
        Bool done = False;

        for(Integer i=0; i<8; i=i+1) begin
            if(chooseIdx == 0 && inQueue[0]!=queueNum) begin
                chooseIdx = 1;
            end
            if(chooseIdx == 1 && inQueue[1]!=queueNum) begin
                chooseIdx = 2;
            end
            if(chooseIdx == 2 && inQueue[2]!=queueNum) begin
                chooseIdx = 3;
            end
            if(chooseIdx == 3 && inQueue[3]!=queueNum) done = True;

            if(!done && !wvalid[i] && inOperation[queueNum] != Unsupported) begin
                queueChoice[i] = {1,chooseIdx};
                if(chooseIdx == 2'b11) done = True;
                chooseIdx = chooseIdx + 1;
            end

        end

        for(Integer i=0; i<8; i=i+1) begin
            if(queueChoice[i][2] == 1) begin
                wvalid[i] = True;
                woperation[i]=inOperation[queueChoice[i][1:0]];
                wimmediate[i]=inImmediate[queueChoice[i][1:0]];
                wrt[i]=inRT[queueChoice[i][1:0]];
                wrs[i]=inRS[queueChoice[i][1:0]];
                wrd[i]=inRD[queueChoice[i][1:0]];
                wrob[i]=inROB[queueChoice[i][1:0]];
                wusesImm[i]=inUImm[queueChoice[i][1:0]];
            end
        end

        Bit#(2) wnumIssued=0;
        Bit#(64) woutReadyFlag0=outReadyFlag0;
        Bit#(64) woutReadyFlag1=outReadyFlag1;
        Bool woutUImm0=outUImm0;
        Bool woutUImm1=outUImm1;
        IType woutOperation0=outOperation0;
        IType woutOperation1=outOperation1;
        Word woutImmediate0=outImmediate0;
        Word woutImmediate1=outImmediate1;
        PIndx woutRT0=outRT0;
        PIndx woutRT1=outRT1;
        PIndx woutRS0=outRS0;
        PIndx woutRS1=outRS1;
        PIndx woutRD0=outRD0;
        PIndx woutRD1=outRD1;
        Bit#(3) woutROB0=outROB0;
        Bit#(3) woutROB1=outROB1;

        for(Integer i=0;i<8;i=i+1) begin
            if(entryReady[i] && wnumIssued< maxIssue) begin
                if(wnumIssued==0) begin
                    woutOperation0=operation[i];
                    woutImmediate0=immediate[i];
                    woutRT0=rt[i];
                    woutRS0=rs[i];
                    woutRD0=rd[i];
                    woutROB0=rob[i];
                    woutUImm0=usesImm[i];
                    woutReadyFlag0=(1<<rd[i]);
                    wnumIssued=1;
                    wvalid[i]=False;
                end
                else begin
                    woutOperation1=operation[i];
                    woutImmediate1=immediate[i];
                    woutRT1=rt[i];
                    woutRS1=rs[i];
                    woutRD1=rd[i];
                    woutROB1=rob[i];
                    woutUImm1=usesImm[i];
                    woutReadyFlag1=(1<<rd[i]);
                    wnumIssued=2;
                    wvalid[i]=False;
                end
            end
        end

        outReadyFlag0 <= woutReadyFlag0;
        outReadyFlag1 <= woutReadyFlag1;
        outUImm0 <= woutUImm0;
        outUImm1 <= woutUImm1;

        outOperation0<=woutOperation0;
        outOperation1<=woutOperation1;

        outImmediate0<=woutImmediate0;
        outImmediate1<=woutImmediate1;

        outRT0<=woutRT0;
        outRT1<=woutRT1;
        outRS0<=woutRS0;
        outRS1<=woutRS1;
        outRD0<=woutRD0;
        outRD1<=woutRD1;
        outROB0<=woutROB0;
        outROB1<=woutROB1;

        rt<=wrt;
        rs<=wrs;
        rd<=wrd;
        rob<=wrob;
        usesImm<=wusesImm;
        valid<=wvalid;
        operation<=woperation;
        immediate<=wimmediate;
        numIssued<=wnumIssued;
        entryReady<=wentryReady;
    end

endrule

endmodule


