import ProcTypes;


Vector#(32,Bit#(6)) drat=newVector();

module Rename;

    Reg#(PIndx) r_rsA(0);
    Reg#(PIndx) r_rsB(0);
    Reg#(PIndx) r_rsC(0);
    Reg#(PIndx) r_rsD(0);
    Reg#(PIndx) r_rtA(0);
    Reg#(PIndx) r_rtB(0);
    Reg#(PIndx) r_rtC(0);
    Reg#(PIndx) r_rtD(0);
    Reg#(PIndx) r_rdA(0);
    Reg#(PIndx) r_rdB(0);
    Reg#(PIndx) r_rdC(0);
    Reg#(PIndx) r_rdD(0);

Vector#(32,Bit#(6)) drmap=newVector();
for(Integer i=0;i<32;i=i+1) begin
        drmap[i]=i;
end

    Reg#(Vector#(32, PIndx)) map(drmap);
    Reg#(Vector#(32, PIndx)) newMAP(drmap);

    input Bool fullFlush default = False;
    input Bit#(3) numInstr default =0;
    input Vector#(32, PIndx) replacementMAP default =drmap;
    input Bit#(6) numFree default =32;

    input PIndx d_rsA default=0;
    input PIndx d_rsB default=0;
    input PIndx d_rsC default=0;
    input PIndx d_rsD default=0;
    input PIndx d_rtA default=0;
    input PIndx d_rtB default=0;
    input PIndx d_rtC default=0;
    input PIndx d_rtD default=0;
    input PIndx d_rdA default=0;
    input PIndx d_rdB default=0;
    input PIndx d_rdC default=0;
    input PIndx d_rdD default=0;

    input PIndx freeA default=0;
    input PIndx freeB default=0;
    input PIndx freeC default=0;
    input PIndx freeD default=0;


    method PIndx mr_rsA=r_rsA;
    method PIndx mr_rsB=r_rsB;
    method PIndx mr_rsC=r_rsC;
    method PIndx mr_rsD=r_rsD;
    method PIndx mr_rtA=r_rtA;
    method PIndx mr_rtB=r_rtB;
    method PIndx mr_rtC=r_rtC;
    method PIndx mr_rtD=r_rtD;
    method PIndx mr_rdA=r_rdA;
    method PIndx mr_rdB=r_rdB;
    method PIndx mr_rdC=r_rdC;
    method PIndx mr_rdD=r_rdD;

    Reg#(Bit#(3)) numRenamed(0);
    method Bit#(3) mnumRenamed=numRenamed;

    rule tick;

        if(fullFlush) begin
            map <= replacementMAP;
            r_rsA<=0;
            r_rsB<=0;
            r_rsC<=0;
            r_rsD<=0;
            r_rtA<=0;
            r_rtB<=0;
            r_rtC<=0;
            r_rtD<=0;
            r_rdA<=0;
            r_rdB<=0;
            r_rdC<=0;
            r_rdD<=0;
            numRenamed<=0;
        end
        else begin
            if(numFree<4) begin
                r_rsA<=0;
                r_rsB<=0;
                r_rsC<=0;
                r_rsD<=0;
                r_rtA<=0;
                r_rtB<=0;
                r_rtC<=0;
                r_rtD<=0;
                r_rdA<=0;
                r_rdB<=0;
                r_rdC<=0;
                r_rdD<=0;
                numRenamed<=0;
            end
            else begin

                PIndx wr_rsA = r_rsA;
                PIndx wr_rtA = r_rtA;
                PIndx wr_rdA = r_rdA;

                PIndx wr_rsB = r_rsB;
                PIndx wr_rtB = r_rtB;
                PIndx wr_rdB = r_rdB;

                PIndx wr_rsC = r_rsC;
                PIndx wr_rtC = r_rtC;
                PIndx wr_rdC = r_rdC;

                PIndx wr_rsD = r_rsD;
                PIndx wr_rtD = r_rtD;
                PIndx wr_rdD = r_rdD;

                Bit#(3) wnumRenamed = 0;

                Vector#(32, PIndx) wmap = map;
                               
                case (numInstr)
                    3'd0: begin

                    end
                    3'd1: begin
                        wr_rsA=map[d_rsA];
                        wr_rtA=map[d_rtA];
                        if(d_rdA!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdA=freeA;
                                    wmap[d_rdA] = freeA;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdA=0;
                        end
                    end
                    3'd2: begin
                        wr_rsA=map[d_rsA];
                        wr_rtA=map[d_rtA];
                        if(d_rdA!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdA=freeA;
                                    wmap[d_rdA] = freeA;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdA=0;
                        end
                        wr_rsB=map[d_rsB];
                        wr_rtB=map[d_rtB];
                        if(d_rdB!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdB=freeA;
                                    wmap[d_rdB] = freeA;
                                end
                                3'd1: begin
                                    wr_rdB=freeB;
                                    wmap[d_rdB] = freeB;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdB=0;
                        end
                    end
                    3'd3: begin
                        wr_rsA=map[d_rsA];
                        wr_rtA=map[d_rtA];
                        if(d_rdA!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdA=freeA;
                                    wmap[d_rdA] = freeA;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdA=0;
                        end
                        wr_rsB=map[d_rsB];
                        wr_rtB=map[d_rtB];
                        if(d_rdB!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdB=freeA;
                                    wmap[d_rdB] = freeA;
                                end
                                3'd1: begin
                                    wr_rdB=freeB;
                                    wmap[d_rdB] = freeB;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdB=0;
                        end
                        wr_rsC=map[d_rsC];
                        wr_rtC=map[d_rtC];
                        if(d_rdC!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdC=freeA;
                                    wmap[d_rdC] = freeA;
                                end
                                3'd1: begin
                                    wr_rdC=freeB;
                                    wmap[d_rdC] = freeB;
                                end
                                3'd2: begin
                                    wr_rdC=freeC;
                                    wmap[d_rdC] = freeC;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdC=0;
                        end
                    end
                    3'd4: begin
                        wr_rsA=map[d_rsA];
                        wr_rtA=map[d_rtA];
                        if(d_rdA!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdA=freeA;
                                    wmap[d_rdA] = freeA;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdA=0;
                        end
                        wr_rsB=map[d_rsB];
                        wr_rtB=map[d_rtB];
                        if(d_rdB!=0) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdB=freeA;
                                    wmap[d_rdB] = freeA;
                                end
                                3'd1: begin
                                    wr_rdB=freeB;
                                    wmap[d_rdB] = freeB;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdB=0;
                        end
                        wr_rsC=map[d_rsC];
                        wr_rtC=map[d_rtC];
                        if(d_rdC!=0 ) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdC=freeA;
                                    wmap[d_rdC] = freeA;
                                end
                                3'd1: begin
                                    wr_rdC=freeB;
                                    wmap[d_rdC] = freeB;
                                end
                                3'd2: begin
                                    wr_rdC=freeC;
                                    wmap[d_rdC] = freeC;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdC=0;
                        end
                        wr_rsD=map[d_rsD];
                        wr_rtD=map[d_rtD];
                        if(d_rdD!=0 && d_rdA != d_rdD && d_rdB != d_rdD && d_rdC != d_rdD) begin
                            case (wnumRenamed)
                                3'd0: begin
                                    wr_rdD=freeA;
                                    wmap[d_rdD] = freeA;
                                end
                                3'd1: begin
                                    wr_rdD=freeB;
                                    wmap[d_rdD] = freeB;
                                end
                                3'd2: begin
                                    wr_rdD=freeC;
                                    wmap[d_rdD] = freeC;
                                end
                                3'd3: begin
                                    wr_rdD=freeD;
                                    wmap[d_rdD] = freeD;
                                end
                                default: begin

                                end
                            endcase
                            wnumRenamed=wnumRenamed+1;
                        end
                        else begin
                            wr_rdD=0;
                        end
                    end
                    default: begin

                    end
                endcase

                map <= wmap;

                r_rsA <= wr_rsA;
                r_rtA <= wr_rtA;
                r_rdA <= wr_rdA;

                r_rsB <= wr_rsB;
                r_rtB <= wr_rtB;
                r_rdB <= wr_rdB;
                
                r_rsC <= wr_rsC;
                r_rtC <= wr_rtC;
                r_rdC <= wr_rdC;

                r_rsD <= wr_rsD;
                r_rtD <= wr_rtD;
                r_rdD <= wr_rdD;

            end
        end

    endrule
endmodule

