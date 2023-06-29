import ProcTypes;

Vector#(16,Word) dpred=newVector();

module Ras;

input Bool pop default=False;
input Bool push default=False;
input Word linkPC default=0;

Reg#(Vector#(16,Word)) predStack(dpred);
Reg#(Bit#(4)) count(0);
Reg#(Word) missed(0);

input Bit#(3) incorrect_pops default=0;
input Bit#(3) incorrect_pushes default=0;
Reg#(Bit#(3)) add_pops(0);
Reg#(Bit#(3)) remove_pushes(0);
Reg#(Word) total_occupancy(0);
Reg#(Word) max_fullness(0);

method Word pred=predStack[count];

rule tick;
    Bit#(3) wadd_pops=incorrect_pops;
    Bit#(3) wremove_pushes=incorrect_pushes;
    Bit#(4) wcount=count;
    Word wmissed=missed;
    for(Integer i=0;i<4;i=i+1) begin
        if(wadd_pops!=0) begin
            if(wcount!=15) begin
                wcount=wcount+1;
            end
            else begin
                wmissed=wmissed+1;
            end
            wadd_pops=wadd_pops-1;
        end
    end
    for(Integer i=0;i<4;i=i+1) begin
        if(wremove_pushes!=0) begin
            if(wmissed != 0) begin
                wmissed=wmissed-1;
            end
            else begin
                if(wcount!=0) begin
                    wcount=wcount-1;
                end
            end
            wremove_pushes=wremove_pushes-1;
        end
    end
    if(pop) begin
        if(wmissed!=0) begin
            wmissed=wmissed-1;
        end
        else begin
            if(wcount!=0) begin
                wcount=wcount-1;
            end
        end
    end
    if(push) begin
        if(wcount!=15) begin
            predStack[wcount]<=linkPC;
            wcount=wcount+1;
        end
        else begin
            wmissed=wmissed+1;
        end
    end
    count<=wcount;
    missed<=wmissed;
    remove_pushes<=wremove_pushes;
    add_pops<=wadd_pops;
endrule

endmodule


