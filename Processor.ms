import ProcTypes;

import Decode;



import RegisterFile;
import Rename;
import Freelist;

import Ras;
import BranchPredictor;

import IssueQueue;

import Alu;
import BranchCompare;

import MainMemory;
import MainMemory2;

import InstCache;
import TwoWayCache;

import CacheTypes;
import CacheHelpers;

import Forwarding;

Vector#(8,Bool) drready=newVector();
Vector#(8,IType) drobop=newVector();
Vector#(8,PIndx) drob6=newVector();
Vector#(8, Bit#(5)) drob5=newVector();
Vector#(8, Bit#(4)) drob4=newVector();
Vector#(8, Word) drobwd=newVector();
Vector#(8, Bit#(3)) drob3=newVector();

module Processor;


RegisterFile rf;
ReadyRegisterList ready_regs;

Rename rename;
Freelist freelist;
Ras ras;
BranchPredictor brp;

IssueQueue aluQueue;
IssueQueue brjrQueue;
IssueQueue ldstQueue;

Alu alu0;
Alu alu1;
BranchCompare bcomp;

MainMemory2 iMem;

InstCache iCache(iMem);

MainMemory dMem;

CacheWrapper#(TwoWayCache) dCache(dMem);



//Reg#(Bool) done(False);//is the simulation over?

Reg#(Word) pc(0);
Reg#(Word) correctTarget(0);

Reg#(Word) instrA(0);
Reg#(Word) instrB(0);
Reg#(Word) instrC(0);
Reg#(Word) instrD(0);

Reg#(Word) pc_inc(0);
Reg#(Word) pc_same(0);
Reg#(Word) pc_br(0);
Reg#(Word) pc_jmp(0);

Reg#(Bool) fullFlush(False);
Reg#(Bool) fullFlushed(False);
Reg#(Bool) robFulled(False);

Vector#(32,Bit#(6)) dmap=newVector();
for(Integer i=0;i<32;i=i+1) begin
        dmap[i]=i;
end

Reg#(Vector#(32,Bit#(6))) map(dmap);


Reg#(IType) memOp(Unsupported);
Reg#(Bool) isMemRetire(False);
Reg#(Word) oldCacheOut(0);
Reg#(Word) mar(0);
Reg#(Word) smdr(0);

Reg#(Word) link_pc(0);
Reg#(Bool) push_link(False);
Reg#(Bool) pop_link(False);
Reg#(Bool) br_dir(True);

Reg#(Bit#(3)) numInstr(0);

Reg#(Bit#(3)) r_numInstr(0);


//post decode regs
Reg#(IType) d_opA(Unsupported);
Reg#(IType) d_opB(Unsupported);
Reg#(IType) d_opC(Unsupported);
Reg#(IType) d_opD(Unsupported);
Reg#(Bit#(2)) d_queueA(0);
Reg#(Bit#(2)) d_queueB(0);
Reg#(Bit#(2)) d_queueC(0);
Reg#(Bit#(2)) d_queueD(0);
Reg#(PIndx) d_rsA(0);
Reg#(PIndx) d_rsB(0);
Reg#(PIndx) d_rsC(0);
Reg#(PIndx) d_rsD(0);
Reg#(PIndx) d_rtA(0);
Reg#(PIndx) d_rtB(0);
Reg#(PIndx) d_rtC(0);
Reg#(PIndx) d_rtD(0);
Reg#(PIndx) d_rdA(0);
Reg#(PIndx) d_rdB(0);
Reg#(PIndx) d_rdC(0);
Reg#(PIndx) d_rdD(0);

Reg#(Bool) d_usesImmA(False);
Reg#(Bool) d_usesImmB(False);
Reg#(Bool) d_usesImmC(False);
Reg#(Bool) d_usesImmD(False);
Reg#(Word) d_immA(0);
Reg#(Word) d_immB(0);
Reg#(Word) d_immC(0);
Reg#(Word) d_immD(0);

Reg#(Bool) d_isMemA(False);
Reg#(Bool) d_isMemB(False);
Reg#(Bool) d_isMemC(False);
Reg#(Bool) d_isMemD(False);
Reg#(Bool) d_isALUA(False);
Reg#(Bool) d_isALUB(False);
Reg#(Bool) d_isALUC(False);
Reg#(Bool) d_isALUD(False);
Reg#(Bit#(3)) d_isCFA(0);
Reg#(Bit#(3)) d_isCFB(0);
Reg#(Bit#(3)) d_isCFC(0);
Reg#(Bit#(3)) d_isCFD(0);
Reg#(Word) d_targetA(0);
Reg#(Word) d_targetB(0);
Reg#(Word) d_targetC(0);
Reg#(Word) d_targetD(0);
Reg#(Word) d_PCA(0);
Reg#(Word) d_PCB(0);
Reg#(Word) d_PCC(0);
Reg#(Word) d_PCD(0);

Reg#(Bool) d_predA(False);
Reg#(Bool) d_predB(False);
Reg#(Bool) d_predC(False);
Reg#(Bool) d_predD(False);

Reg#(Word) d_instrA(0);
Reg#(Word) d_instrB(0);
Reg#(Word) d_instrC(0);
Reg#(Word) d_instrD(0);



//post rename regs

Reg#(Word) r_instrA(0);
Reg#(Word) r_instrB(0);
Reg#(Word) r_instrC(0);
Reg#(Word) r_instrD(0);

Reg#(IType) r_opA(Unsupported);
Reg#(IType) r_opB(Unsupported);
Reg#(IType) r_opC(Unsupported);
Reg#(IType) r_opD(Unsupported);
Reg#(Bit#(2)) r_queueA(0);
Reg#(Bit#(2)) r_queueB(0);
Reg#(Bit#(2)) r_queueC(0);
Reg#(Bit#(2)) r_queueD(0);

Reg#(Bit#(5)) r_lrdA(0);
Reg#(Bit#(5)) r_lrdB(0);
Reg#(Bit#(5)) r_lrdC(0);
Reg#(Bit#(5)) r_lrdD(0);
Reg#(Bool) r_usesImmA(False);
Reg#(Bool) r_usesImmB(False);
Reg#(Bool) r_usesImmC(False);
Reg#(Bool) r_usesImmD(False);
Reg#(Word) r_immA(0);
Reg#(Word) r_immB(0);
Reg#(Word) r_immC(0);
Reg#(Word) r_immD(0);

Reg#(Bool) r_isMemA(False);
Reg#(Bool) r_isALUA(False);
Reg#(Bool) r_isMemB(False);
Reg#(Bool) r_isALUB(False);
Reg#(Bool) r_isMemC(False);
Reg#(Bool) r_isALUC(False);
Reg#(Bool) r_isMemD(False);
Reg#(Bool) r_isALUD(False);

Reg#(Bit#(3)) r_isCFA(0);
Reg#(Bit#(3)) r_isCFB(0);
Reg#(Bit#(3)) r_isCFC(0);
Reg#(Bit#(3)) r_isCFD(0);
Reg#(Word) r_targetA(0);
Reg#(Word) r_targetB(0);
Reg#(Word) r_targetC(0);
Reg#(Word) r_targetD(0);
Reg#(Word) r_PCA(0);
Reg#(Word) r_PCB(0);
Reg#(Word) r_PCC(0);
Reg#(Word) r_PCD(0);
Reg#(Bool) r_predA(False);
Reg#(Bool) r_predB(False);
Reg#(Bool) r_predC(False);
Reg#(Bool) r_predD(False);

Reg#(Bit#(204)) remapped(0);

Reg#(PIndx) rob_free0(0);
Reg#(PIndx) rob_free1(0);
Reg#(PIndx) rob_free2(0);
Reg#(PIndx) rob_free3(0);

Reg#(Bool) updatePredictor_we(False);
Reg#(Word) updatePredictorPC(0);
Reg#(Bool) updatePrediction(False);


Reg#(Bit#(3)) incorrect_pushes(0);
Reg#(Bit#(3)) incorrect_pops(0);


Reg#(PIndx) store_reg(0);

Reg#(PIndx) link_reg(0);
Reg#(Word) link_value(0);
Reg#(Bit#(64)) link_ready(0);
Reg#(Bool) load_we(False);
Reg#(PIndx) load_reg(0);
Reg#(Word) load_value(0);

Reg#(Bit#(3)) rob_head(0);
Reg#(Bit#(3)) rob_tail(0);
Reg#(Bit#(4)) rob_free(8);


Reg#(Vector#(8,Bool)) rob_ready(drready);
Reg#(Vector#(8,Bool)) rob_flushed(drready);
Reg#(Vector#(8,IType)) rob_op(drobop);
Reg#(Vector#(8, Bit#(5))) rob_logreg(drob5);
Reg#(Vector#(8, PIndx)) rob_phyreg(drob6);
Reg#(Vector#(8,Bool)) rob_pred(drready);
Reg#(Vector#(8,Word)) rob_pred_target(drobwd);
Reg#(Vector#(8,Bool)) rob_dir(drready);
Reg#(Vector#(8,Word)) rob_eff_target(drobwd);
Reg#(Vector#(8,Bool)) rob_isMem(drready);
Reg#(Vector#(8,Bit#(3))) rob_isCF(drob3);
Reg#(Vector#(8, Word)) rob_debug_instr(drobwd);
Reg#(Vector#(8, Word)) rob_debug_pc(drobwd);


Reg#(Bit#(3)) numRetired(0);
Reg#(Bit#(64)) rob_unready0(0);
Reg#(Bit#(64)) rob_unready1(0);
Reg#(Bit#(64)) rob_unready2(0);
Reg#(Bit#(64)) rob_unready3(0);

Reg#(Bool) retireDone(False);

Reg#(Bool) alu0_we(False);
Reg#(Bool) alu1_we(False);
Reg#(PIndx) ex_rdA(0);
Reg#(PIndx) ex_rdB(0);
Reg#(Word) exv_rdA(0);
Reg#(Word) exv_rdB(0);
Reg#(Bool) ldst_done(False);
Reg#(Bool) brjr_done(False);
Reg#(Bit#(3)) ex_roba(0);
Reg#(Bit#(3)) ex_robb(0);
Reg#(Bit#(3)) ex_robc(0);
Reg#(Bit#(3)) ex_robd(0);
Reg#(Bool) ex_brjr_taken(False);
Reg#(Word) ex_effAddr(0);
Reg#(Word) ex_brjr_target(0);

Reg#(Bool) loadDone(True);


Reg#(Bool) gotFlushed(False);


Reg#(Vector#(8,PIndx)) ldstq_areg(drob6);
Reg#(Vector#(8,PIndx)) ldstq_dreg(drob6);
Reg#(Vector#(8,Word)) ldstq_a(drobwd);
Reg#(Vector#(8,Word)) ldstq_d(drobwd);
Reg#(Vector#(8,Bool)) ldstq_hasAddr(drready);
Reg#(Vector#(8,Bool)) ldstq_Valid(drready);
Reg#(Vector#(8,Bool)) ldstq_isStore(drready);
Reg#(Vector#(8,Bool)) ldstq_isLoad(drready);
Reg#(Vector#(8,Bool)) ldstq_hasData(drready);
Reg#(Vector#(8, Bit#(3))) ldstq_rob(drob3);
Reg#(Bit#(3)) ldstq_nextFree(0);
Reg#(Vector#(8,Bool)) ldstq_wroteValue(drready);

Reg#(Word) pre_load(0);
Reg#(Bool) pre_load_we(False);
Reg#(Bool) data_snooped(False);
Reg#(Bit#(3)) data_snooper(0);
Reg#(Bool) unresolved_store(False);
Reg#(Bool) earlyaccess(False);


//ir registers
Reg#(IType) ir_opA(Unsupported);
Reg#(IType) ir_opB(Unsupported);
Reg#(IType) ir_opC(Unsupported);
Reg#(IType) ir_opD(Unsupported);
Reg#(PIndx) ir_rsA(0);
Reg#(PIndx) ir_rsB(0);
Reg#(PIndx) ir_rsC(0);
Reg#(PIndx) ir_rsD(0);
Reg#(PIndx) ir_rtA(0);
Reg#(PIndx) ir_rtB(0);
Reg#(PIndx) ir_rtC(0);
Reg#(PIndx) ir_rtD(0);
Reg#(PIndx) ir_rdA(0);
Reg#(PIndx) ir_rdB(0);
Reg#(PIndx) ir_rdC(0);
Reg#(PIndx) ir_rdD(0);
Reg#(Word) irv_rsA(0);
Reg#(Word) irv_rsB(0);
Reg#(Word) irv_rsC(0);
Reg#(Word) irv_rsD(0);
Reg#(Word) irv_rtA(0);
Reg#(Word) irv_rtB(0);
Reg#(Word) irv_rtD(0);
Reg#(Bool) ir_usesImmA(False);
Reg#(Bool) ir_usesImmB(False);
Reg#(Bool) ir_usesImmC(False);
Reg#(Bool) ir_usesImmD(False);
Reg#(Word) ir_immA(0);
Reg#(Word) ir_immB(0);
Reg#(Word) ir_immC(0);
Reg#(Word) ir_immD(0);
Reg#(Bit#(3)) ir_roba(0);
Reg#(Bit#(3)) ir_robb(0);
Reg#(Bit#(3)) ir_robc(0);
Reg#(Bit#(3)) ir_robd(0);
Reg#(Bit#(2)) ir_ALUNumIssued(0);
Reg#(Bit#(2)) ir_LDSTNumIssued(0);
Reg#(Bit#(2)) ir_BRJRNumIssued(0);

Reg#(Word) cycle(0);
Reg#(Word) instrs(0);

Reg#(Bool) notIssued(True);
Reg#(Bool) badReq(False);

rule tick;

Bit#(3) numRenamed=0;


Bool rob_full=rob_free<4;

//from instruction cache to decode

Maybe#(Vector#(2,Line)) dline = iCache.data;

Bool wbadReq = badReq;

if(badReq && isValid(dline)) wbadReq = False;

if(fullFlush && !isValid(dline)) wbadReq = True;

Bool iStall=(!iCache.reqEnabled || badReq);
Bool renameStall=(freelist.mnumFree(numRenamed)<4);
Bool wfullFlush=False;

cycle<=cycle+1;

Word nextFetchAt=0;

Word inAddrA=pc;
Word inAddrB=pc+4;
Word inAddrC=pc+8;
Word inAddrD=pc+12;

Word wmar=mar;
Word wsmdr=smdr;


if(fullFlush || !rob_full) begin
        r_opA<=d_opA;
        r_opB<=d_opB;
        r_opC<=d_opC;
        r_opD<=d_opD;
        r_lrdA<=d_rdA[4:0];
        r_lrdB<=d_rdB[4:0];
        r_lrdC<=d_rdC[4:0];
        r_lrdD<=d_rdD[4:0];

        r_usesImmA<=d_usesImmA;
        r_usesImmB<=d_usesImmB;
        r_usesImmC<=d_usesImmC;
        r_usesImmD<=d_usesImmD;
        r_immA<=d_immA;
        r_immB<=d_immB;
        r_immC<=d_immC;
        r_immD<=d_immD;
        r_isMemA<=d_isMemA;
        r_isMemB<=d_isMemB;
        r_isMemC<=d_isMemC;
        r_isMemD<=d_isMemD;
        r_isCFA<=d_isCFA;
        r_isCFB<=d_isCFB;
        r_isCFC<=d_isCFC;
        r_isCFD<=d_isCFD;
        r_isALUA<=d_isALUA;
        r_isALUB<=d_isALUB;
        r_isALUC<=d_isALUC;
        r_isALUD<=d_isALUD;
        r_targetA<=d_targetA;
        r_targetB<=d_targetB;
        r_targetC<=d_targetC;
        r_targetD<=d_targetD;
        r_PCA<=d_PCA;
        r_PCB<=d_PCB;
        r_PCC<=d_PCC;
        r_PCD<=d_PCD;
        r_predA<=d_predA;
        r_predB<=d_predB;
        r_predC<=d_predC;
        r_predD<=d_predD;
        r_instrA<=d_instrA;
        r_instrB<=d_instrB;
        r_instrC<=d_instrC;
        r_instrD<=d_instrD;
end

rename.d_rsA=d_rsA;
rename.d_rsB=d_rsB;
rename.d_rsC=d_rsC;
rename.d_rsD=d_rsD;
rename.d_rtA=d_rtA;
rename.d_rtB=d_rtB;
rename.d_rtC=d_rtC;
rename.d_rtD=d_rtD;
rename.d_rdA=d_rdA;
rename.d_rdB=d_rdB;
rename.d_rdC=d_rdC;
rename.d_rdD=d_rdD;

numRenamed=rename.mnumRenamed;

rename.freeA=freelist.free0(numRenamed);
rename.freeB=freelist.free1(numRenamed);
rename.freeC=freelist.free2(numRenamed);
rename.freeD=freelist.free3(numRenamed);
rename.numFree=freelist.mnumFree(numRenamed);

PIndx r_rsA=rename.mr_rsA;
PIndx r_rsB=rename.mr_rsB;
PIndx r_rsC=rename.mr_rsC;
PIndx r_rsD=rename.mr_rsD;
PIndx r_rtA=rename.mr_rtA;
PIndx r_rtB=rename.mr_rtB;
PIndx r_rtC=rename.mr_rtC;
PIndx r_rtD=rename.mr_rtD;
PIndx r_rdA=rename.mr_rdA;
PIndx r_rdB=rename.mr_rdB;
PIndx r_rdC=rename.mr_rdC;
PIndx r_rdD=rename.mr_rdD;


PIndx wrob_free0=rob_free0;
PIndx wrob_free1=rob_free1;
PIndx wrob_free2=rob_free2;
PIndx wrob_free3=rob_free3;


freelist.nowFree0=rob_free0;
freelist.nowFree1=rob_free1;
freelist.nowFree2=rob_free2;
freelist.nowFree3=rob_free3;
freelist.numRequest=numRenamed;
//freelist.numAdd=numAddFree;

Bool wupdatePredictor_we=updatePredictor_we;
Word wupdatePredictorPC=updatePredictorPC;
Bool wupdatePrediction=updatePrediction;



Bit#(3) wincorrect_pushes=0;
Bit#(3) wincorrect_pops=0;


Bit#(64) readyList=0;
PIndx wstore_reg=store_reg;

PIndx wload_reg=load_reg;

Bit#(3) wrob_head=rob_head;
Bit#(3) wrob_tail=rob_tail;
Bit#(4) wrob_free=rob_free;

Vector#(8,Bool) wrob_ready=rob_ready;
Vector#(8,Bool) wrob_flushed=rob_flushed;
Vector#(8,IType) wrob_op=rob_op;
Vector#(8, Bit#(5)) wrob_logreg=rob_logreg;
Vector#(8,PIndx) wrob_phyreg=rob_phyreg;
Vector#(8,Bool) wrob_pred=rob_pred;
Vector#(8,Word) wrob_pred_target=rob_pred_target;
Vector#(8,Bool) wrob_dir=rob_dir;
Vector#(8,Word) wrob_eff_target=rob_eff_target;
Vector#(8,Bool) wrob_isMem=rob_isMem;
Vector#(8,Bit#(3)) wrob_isCF=rob_isCF;
Vector#(8,Word) wrob_debug_instr=rob_debug_instr;
Vector#(8,Word) wrob_debug_pc=rob_debug_pc;

Bit#(3) wnumRetired=numRetired;
Bit#(64) wrob_unready0=rob_unready0;
Bit#(64) wrob_unready1=rob_unready1;
Bit#(64) wrob_unready2=rob_unready2;
Bit#(64) wrob_unready3=rob_unready3;

Bool wretireDone=retireDone;

Bit#(64) load_ready=0;

Bool wloadDone=loadDone;

Bool wnotIssued = notIssued;

if(!loadDone && notIssued) begin
        wloadDone = True;
        wnotIssued = False;
end

if(!loadDone && isValid(dCache.data)) begin
        wloadDone = True;
end

if(wloadDone && !fullFlush ) begin
        load_ready=1<<load_reg;
end



Vector#(8,PIndx) wldstq_areg=ldstq_areg;
Vector#(8,PIndx) wldstq_dreg=ldstq_dreg;
Vector#(8,Word) wldstq_a=ldstq_a;
Vector#(8,Word) wldstq_d=ldstq_d;
Vector#(8,Bool) wldstq_hasAddr=ldstq_hasAddr;
Vector#(8,Bool) wldstq_Valid=ldstq_Valid;
Vector#(8,Bool) wldstq_isStore=ldstq_isStore;
Vector#(8,Bool) wldstq_isLoad=ldstq_isLoad;
Vector#(8,Bool) wldstq_hasData=ldstq_hasData;
Vector#(8, Bit#(3)) wldstq_rob=ldstq_rob;
Bit#(3) wldstq_nextFree=ldstq_nextFree;
Vector#(8,Bool) wldstq_wroteValue=ldstq_wroteValue;

Word wpre_load=0;
Bool wpre_load_we=False;
Bool wdata_snooped=data_snooped;
Bit#(3) wdata_snooper=data_snooper;
Bool wunresolved_store=unresolved_store;


if(r_numInstr>=1 && !rob_full) begin
        if(r_queueA==0 || r_isMemA) wrob_ready[wrob_tail]=True;
        else wrob_ready[wrob_tail]=False;
        wrob_flushed[wrob_tail]=fullFlush;
        wrob_op[wrob_tail]=r_opA;
        if(r_opA==STORE) begin
                wrob_phyreg[wrob_tail]=r_rtA;
                wrob_logreg[wrob_tail]=0;
        end
        else begin
                wrob_phyreg[wrob_tail]=r_rdA;
                wrob_logreg[wrob_tail]=r_lrdA;
        end
        wrob_pred[wrob_tail]=r_predA;
        wrob_pred_target[wrob_tail]=r_targetA;
        wrob_dir[wrob_tail]=r_predA;
        wrob_eff_target[wrob_tail]=r_PCA+4;
        wrob_isMem[wrob_tail]=r_isMemA;
        wrob_isCF[wrob_tail]=r_isCFA;
        wrob_debug_pc[wrob_tail] =r_PCA;
        wrob_debug_instr[wrob_tail]=r_instrA;
        wrob_tail=wrob_tail+1;
        wrob_free=wrob_free-1;
        if(r_isMemA) begin
                wldstq_areg[wldstq_nextFree]=r_rsA;
                if(r_opA==STORE) begin
                        wldstq_dreg[wldstq_nextFree]=r_rtA;
                        wldstq_isStore[wldstq_nextFree]=True;
                        wldstq_isLoad[wldstq_nextFree]=False;
                end
                else begin
                        wldstq_dreg[wldstq_nextFree]=r_rdA;
                        wldstq_isStore[wldstq_nextFree]=False;
                        wldstq_isLoad[wldstq_nextFree]=True;
                end
                wldstq_wroteValue[wldstq_nextFree]=False;
                wldstq_hasAddr[wldstq_nextFree]=False;
                wldstq_Valid[wldstq_nextFree]=True;
                wldstq_hasData[wldstq_nextFree]=False;
                wldstq_rob[wldstq_nextFree]=wrob_tail-1;
                wldstq_nextFree=wldstq_nextFree+1;
        end
end
if(r_numInstr>=2 && !rob_full) begin
        if(r_queueB==0 || r_isMemB) wrob_ready[wrob_tail]=True;
        else wrob_ready[wrob_tail]=False;
        wrob_flushed[wrob_tail]=fullFlush;
        wrob_op[wrob_tail]=r_opB;
        if(r_isMemB && r_opB==STORE) begin
                wrob_phyreg[wrob_tail]=r_rtB;
                wrob_logreg[wrob_tail]=0;
        end
        else begin
                wrob_phyreg[wrob_tail]=r_rdB;
                wrob_logreg[wrob_tail]=r_lrdB;
        end
        wrob_pred[wrob_tail]=r_predB;
        wrob_pred_target[wrob_tail]=r_targetB;
        wrob_dir[wrob_tail]=r_predB;
        wrob_eff_target[wrob_tail]=r_PCB+4;
        wrob_isMem[wrob_tail]=r_isMemB;
        wrob_isCF[wrob_tail]=r_isCFB;
        wrob_debug_pc[wrob_tail] =r_PCB;
        wrob_debug_instr[wrob_tail]=r_instrB;
        wrob_tail=wrob_tail+1;
        wrob_free=wrob_free-1;
        if(r_isMemB) begin
                wldstq_areg[wldstq_nextFree]=r_rsB;
                if(r_opB==STORE) begin
                        wldstq_dreg[wldstq_nextFree]=r_rtB;
                        wldstq_isStore[wldstq_nextFree]=True;
                        wldstq_isLoad[wldstq_nextFree]=False;
                end
                else begin
                        wldstq_dreg[wldstq_nextFree]=r_rdB;
                        wldstq_isStore[wldstq_nextFree]=False;
                        wldstq_isLoad[wldstq_nextFree]=True;
                end
                wldstq_wroteValue[wldstq_nextFree]=False;
                wldstq_hasAddr[wldstq_nextFree]=False;
                wldstq_Valid[wldstq_nextFree]=True;
                wldstq_hasData[wldstq_nextFree]=False;
                wldstq_rob[wldstq_nextFree]=wrob_tail-1;
                wldstq_nextFree=wldstq_nextFree+1;
        end
end
if(r_numInstr>=3 && !rob_full) begin
        if(r_queueC==0 || r_isMemC) wrob_ready[wrob_tail]=True;
        else wrob_ready[wrob_tail]=False;
        wrob_flushed[wrob_tail]=fullFlush;
        wrob_op[wrob_tail]=r_opC;
        if(r_isMemC && r_opC==STORE) begin
                wrob_phyreg[wrob_tail]=r_rtC;
                wrob_logreg[wrob_tail]=0;
        end
        else begin
                wrob_phyreg[wrob_tail]=r_rdC;
                wrob_logreg[wrob_tail]=r_lrdC;
        end
        wrob_pred[wrob_tail]=r_predC;
        wrob_pred_target[wrob_tail]=r_targetC;
        wrob_dir[wrob_tail]=r_predC;
        wrob_eff_target[wrob_tail]=r_PCC+4;
        wrob_isMem[wrob_tail]=r_isMemC;
        wrob_isCF[wrob_tail]=r_isCFC;
        wrob_debug_pc[wrob_tail] =r_PCC;
        wrob_debug_instr[wrob_tail]=r_instrC;
        wrob_tail=wrob_tail+1;
        wrob_free=wrob_free-1;
        if(r_isMemC) begin
                wldstq_areg[wldstq_nextFree]=r_rsC;
                if(r_opC==STORE) begin
                        wldstq_dreg[wldstq_nextFree]=r_rtC;
                        wldstq_isStore[wldstq_nextFree]=True;
                        wldstq_isLoad[wldstq_nextFree]=False;
                end
                else begin
                        wldstq_dreg[wldstq_nextFree]=r_rdC;
                        wldstq_isStore[wldstq_nextFree]=False;
                        wldstq_isLoad[wldstq_nextFree]=True;
                end
                wldstq_wroteValue[wldstq_nextFree]=False;
                wldstq_hasAddr[wldstq_nextFree]=False;
                wldstq_Valid[wldstq_nextFree]=True;
                wldstq_hasData[wldstq_nextFree]=False;
                wldstq_rob[wldstq_nextFree]=wrob_tail-1;
                wldstq_nextFree=wldstq_nextFree+1;
        end
end
if(r_numInstr>=4 && !rob_full) begin
        if(r_queueD==0 || r_isMemD) wrob_ready[wrob_tail]=True;
        else wrob_ready[wrob_tail]=False;
        wrob_flushed[wrob_tail]=fullFlush;
        wrob_op[wrob_tail]=r_opD;
        if(r_isMemD && r_opD==STORE) begin
                wrob_phyreg[wrob_tail]=r_rtD;
                wrob_logreg[wrob_tail]=0;
        end
        else begin
                wrob_phyreg[wrob_tail]=r_rdD;
                wrob_logreg[wrob_tail]=r_lrdD;
        end
        wrob_pred[wrob_tail]=r_predD;
        wrob_pred_target[wrob_tail]=r_targetD;
        wrob_dir[wrob_tail]=r_predD;
        wrob_eff_target[wrob_tail]=r_PCD+4;
        wrob_isMem[wrob_tail]=r_isMemD;
        wrob_isCF[wrob_tail]=r_isCFD;
        wrob_debug_pc[wrob_tail] =r_PCD;
        wrob_debug_instr[wrob_tail]=r_instrD;
        wrob_tail=wrob_tail+1;
        wrob_free=wrob_free-1;
        if(r_isMemD) begin
                wldstq_areg[wldstq_nextFree]=r_rsD;
                if(r_opD==STORE) begin
                        wldstq_dreg[wldstq_nextFree]=r_rtD;
                        wldstq_isStore[wldstq_nextFree]=True;
                        wldstq_isLoad[wldstq_nextFree]=False;
                end
                else begin
                        wldstq_dreg[wldstq_nextFree]=r_rdD;
                        wldstq_isStore[wldstq_nextFree]=False;
                        wldstq_isLoad[wldstq_nextFree]=True;
                end
                wldstq_wroteValue[wldstq_nextFree]=False;
                wldstq_hasAddr[wldstq_nextFree]=False;
                wldstq_Valid[wldstq_nextFree]=True;
                wldstq_hasData[wldstq_nextFree]=False;
                wldstq_rob[wldstq_nextFree]=wrob_tail-1;
                wldstq_nextFree=wldstq_nextFree+1;
        end
end
//note: make sure you are using w values and not the old Reg#s
Bit#(3) rob_slot0=wrob_tail;
Bit#(3) rob_slot1=wrob_tail+1;
Bit#(3) rob_slot2=wrob_tail+2;
Bit#(3) rob_slot3=wrob_tail+3;

rob_tail<=wrob_tail;

//commenting out the below line since it seems unneeded
//if(!fullFlush && !gotFlushed) begin
if(alu0_we && !rob_flushed[ex_roba]) begin
        wrob_ready[ex_roba]=True;
end
if(alu1_we && !rob_flushed[ex_robb]) begin
        wrob_ready[ex_robb]=True;
end
if(brjr_done && !rob_flushed[ex_robd]) begin
        wrob_ready[ex_robd]=True;
        wrob_dir[ex_robd]=ex_brjr_taken;
        if(ex_brjr_taken) begin
                wrob_eff_target[ex_robd]=ex_brjr_target;
        end
end

Bool link_we = False;
PIndx link_reg = 0;
Word link_value = 0;
Bit#(64) link_ready = 0;

if(r_isCFA[2]==1) begin
        link_we=True;
        link_reg=r_rdA;
        link_value=r_PCA+4;
        link_ready=1<<r_rdA;
end
else if(r_isCFB[2]==1) begin
        link_we=True;
        link_reg=r_rdB;
        link_value=r_PCB+4;
        link_ready=1<<r_rdB;
end
else if(r_isCFC[2]==1) begin
        link_we=True;
        link_reg=r_rdC;
        link_value=r_PCC+4;
        link_ready=1<<r_rdC;
end
else if(r_isCFD[2]==1) begin
        link_we=True;
        link_reg=r_rdD;
        link_value=r_PCD+4;
        link_ready=1<<r_rdD;
end


readyList=ready_regs.mreadyList(
1<<ir_rdA, 1<<ir_rdB, link_ready, load_ready,
rob_unready0, rob_unready1, rob_unready2, rob_unready3);


IType wmemOp=Unsupported;

Bool wisMemRetire=isMemRetire;

Word cacheOut=0;

if(isValid(dCache.data)) begin
        cacheOut=fromMaybe(?,dCache.data);
end

Word pre_load_data=(pre_load_we)?pre_load:cacheOut;

Word store_value=rf.readValue(store_reg, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);

for(Integer i=0;i<8;i=i+1) begin
        if(ldstq_Valid[i] && ldstq_rob[i]==ex_robc ) begin
                wldstq_hasAddr[i]=True;
                wldstq_a[i]=ex_effAddr;
        end
end
if(wdata_snooped) begin
        wldstq_d[data_snooper]=store_value;
        if(ldstq_Valid[data_snooper]) wldstq_hasData[data_snooper]=True;
        wdata_snooped=False;
end
for(Integer i=0;i<8;i=i+1) begin
        if(!wdata_snooped && ldstq_Valid[i] && !ldstq_hasData[i] &&
        ldstq_isStore[i] && ((readyList>>wldstq_dreg[i])&1)==1) begin
                wstore_reg=ldstq_dreg[i];
                wdata_snooped=True;
                wdata_snooper=i;
        end
end

data_snooped<=wdata_snooped;

Bool stop_forwarding=False;

if(ldstq_isStore[0] && ldstq_Valid[0] && ldstq_hasAddr[0]
        && ldstq_hasData[0]) begin
        for(Integer j=1;j<8;j=j+1) begin
                if(ldstq_isStore[j] &&
                        ldstq_a[0]==ldstq_a[j] ||
                        !ldstq_hasAddr[j]) begin
                        stop_forwarding=True;
                end
                if(!stop_forwarding && ldstq_isLoad[j] && ldstq_Valid[j]
                        &&    ldstq_hasAddr[j] && !ldstq_hasData[j] &&
                        ldstq_a[0]==ldstq_a[j]) begin
                        wldstq_hasData[j]=True;
                        wldstq_d[j]=ldstq_d[0];
                end
        end
end


wretireDone=False;

wnumRetired=0;


if(dCache.reqEnabled) wisMemRetire=False;

wrob_unready0=0;
wrob_unready1=0;
wrob_unready2=0;
wrob_unready3=0;

wrob_free0=0;
wrob_free1=0;
wrob_free2=0;
wrob_free3=0;

wupdatePredictor_we=False;
wincorrect_pushes=0;
wincorrect_pops=0;
Word wcorrectTarget=correctTarget;

Vector#(32,Bit#(6)) wmap=map;

Bit#(3) ldstqIdx = 0;

wfullFlush=False;

if(!wretireDone && !wfullFlush &&
(rob_ready[wrob_head] || rob_flushed[wrob_head])) begin
        if(rob_isCF[wrob_head][0]==1 && !rob_flushed[wrob_head]) begin
                if(!wupdatePredictor_we) begin
                        if(rob_op[wrob_head]==JAL) begin

                        end
                        else if(rob_op[wrob_head]==JALR) begin
                                if(rob_pred_target[wrob_head]
                                                !=rob_eff_target[wrob_head]) begin
                                        wcorrectTarget=rob_eff_target[wrob_head];
                                        wfullFlush=True;

                                end
                        end
                        else begin
                                if(rob_dir[wrob_head]!=rob_pred[wrob_head]) begin
                                        if(rob_dir[wrob_head]) begin
                                                wcorrectTarget=rob_pred_target[wrob_head];
                                        end
                                        else begin
                                                wcorrectTarget=rob_eff_target[wrob_head];
                                        end
                                        wfullFlush=True;
                                        
                                end
                                wupdatePredictor_we=True;
                                wupdatePredictorPC=rob_debug_pc[wrob_head];
                                wupdatePrediction=rob_dir[wrob_head];
                        end
                        if(rob_isCF[wrob_head][2]==1) begin
                                wrob_free0=map[rob_logreg[wrob_head]];
                                wrob_unready0=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wrob_free0=0;
                        end
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                end
        end
        else if(rob_isMem[wrob_head] && !rob_flushed[wrob_head]) begin
                if(
                        (rob_op[wrob_head]==LOAD && ldstq_hasAddr[ldstqIdx] &&
                        ( (!wisMemRetire && wloadDone) || (ldstq_hasData[ldstqIdx] && wloadDone) || ldstq_wroteValue[ldstqIdx]))
                        || (rob_op[wrob_head]==STORE && !wisMemRetire && ldstq_hasAddr[ldstqIdx] && ldstq_hasData[ldstqIdx])
                ) begin
                        if(!(rob_op[wrob_head]==STORE)) begin
                                if(ldstq_hasData[ldstqIdx] && ldstq_wroteValue[ldstqIdx]) begin

                                end
                                else if(ldstq_hasData[ldstqIdx]
                                                && !ldstq_wroteValue[ldstqIdx]) begin
                                        wpre_load=ldstq_d[ldstqIdx];
                                        wload_reg=ldstq_dreg[ldstqIdx];
                                        wpre_load_we=True;
                                        wnotIssued=True;
                                        wloadDone=False;
                                end
                                else begin
                                        wisMemRetire=True;
                                        wmemOp=rob_op[wrob_head];
                                        wmar=ldstq_a[ldstqIdx];
                                        wload_reg=rob_phyreg[wrob_head];
                                        wloadDone=False;
                                end
                                wrob_free0=map[rob_logreg[wrob_head]];
                                wrob_unready0=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wsmdr=ldstq_d[ldstqIdx];
                                wisMemRetire=True;
                                wmemOp=rob_op[wrob_head];
                                wmar=ldstq_a[ldstqIdx];
                                wrob_free0=0;
                        end
                        ldstqIdx = ldstqIdx + 1;

                        wldstq_nextFree=wldstq_nextFree-1;
                        wdata_snooper=wdata_snooper-1;
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                        wrob_free0=0;
                end
        end
        else begin
                if(rob_isCF[wrob_head][0]==1) begin
                        if(rob_isCF[wrob_head][2]==1&&rob_logreg[wrob_head]!=0) begin
                                wincorrect_pushes=wincorrect_pushes+1;
                        end
                        if(rob_op[wrob_head]==JALR &&
                                (rob_debug_instr[wrob_head][19:15]!=0)) begin
                                wincorrect_pops=wincorrect_pops+1;
                        end
                end
                wnumRetired=wnumRetired+1;
                if(!rob_flushed[wrob_head]) begin
                        wrob_free0=map[rob_logreg[wrob_head]];
                        wrob_unready0=1<<map[rob_logreg[wrob_head]];
                        wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                end
                else if(rob_flushed[wrob_head] && rob_logreg[wrob_head]!=0) begin
                        wrob_free0=rob_phyreg[wrob_head];
                        wrob_unready0=1<<rob_phyreg[wrob_head];
                end
                wrob_ready[wrob_head]=False;
                wrob_flushed[wrob_head]=False;
                wrob_logreg[wrob_head]=0;
                wrob_phyreg[wrob_head]=0;
                wrob_head=wrob_head+1;
        end
end
else begin
        wrob_free0=0;
end

if(wrob_head==wrob_tail) wretireDone=True;


if(!wretireDone && !wfullFlush &&
(rob_ready[wrob_head] || rob_flushed[wrob_head])) begin
        if(rob_isCF[wrob_head][0]==1 && !rob_flushed[wrob_head]) begin
                if(!wupdatePredictor_we) begin
                        if(rob_op[wrob_head]==JAL) begin

                        end
                        else if(rob_op[wrob_head]==JALR) begin
                                if(rob_pred_target[wrob_head]
                                                !=rob_eff_target[wrob_head]) begin
                                        wcorrectTarget=rob_eff_target[wrob_head];
                                        wfullFlush=True;
                                        
                                end
                        end
                        else begin
                                if(rob_dir[wrob_head]!=rob_pred[wrob_head]) begin
                                        if(rob_dir[wrob_head]) begin
                                                wcorrectTarget=rob_pred_target[wrob_head];
                                        end
                                        else begin
                                                wcorrectTarget=rob_eff_target[wrob_head];
                                        end
                                        wfullFlush=True;
                                        
                                end
                                wupdatePredictor_we=True;
                                wupdatePredictorPC=rob_debug_pc[wrob_head];
                                wupdatePrediction=rob_dir[wrob_head];
                        end
                        if(rob_isCF[wrob_head][2]==1) begin
                                wrob_free1=map[rob_logreg[wrob_head]];
                                wrob_unready1=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wrob_free1=0;
                        end
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                end
        end
        else if(rob_isMem[wrob_head] && !rob_flushed[wrob_head]) begin
                if(
                        (rob_op[wrob_head]==LOAD && ldstq_hasAddr[ldstqIdx] &&
                        ( (!wisMemRetire && wloadDone) || (ldstq_hasData[ldstqIdx] && wloadDone) || ldstq_wroteValue[ldstqIdx]))
                        || (rob_op[wrob_head]==STORE && !wisMemRetire && ldstq_hasAddr[ldstqIdx] && ldstq_hasData[ldstqIdx])
                ) begin
                        if(!(rob_op[wrob_head]==STORE)) begin
                                if(ldstq_hasData[ldstqIdx] && ldstq_wroteValue[ldstqIdx]) begin

                                end
                                else if(ldstq_hasData[ldstqIdx]
                                                && !ldstq_wroteValue[ldstqIdx]) begin
                                        wpre_load=ldstq_d[ldstqIdx];
                                        wload_reg=ldstq_dreg[ldstqIdx];
                                        wpre_load_we=True;
                                        wnotIssued=True;
                                        wloadDone=False;
                                end
                                else begin
                                        wisMemRetire=True;
                                        wmemOp=rob_op[wrob_head];
                                        wmar=ldstq_a[ldstqIdx];
                                        wload_reg=rob_phyreg[wrob_head];
                                        wloadDone=False;
                                end
                                wrob_free1=map[rob_logreg[wrob_head]];
                                wrob_unready1=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wsmdr=ldstq_d[ldstqIdx];
                                wisMemRetire=True;
                                wmemOp=rob_op[wrob_head];
                                wmar=ldstq_a[ldstqIdx];
                                wrob_free1=0;
                        end
                        ldstqIdx = ldstqIdx + 1;
                        
                        wldstq_nextFree=wldstq_nextFree-1;
                        wdata_snooper=wdata_snooper-1;
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                        wrob_free1=0;
                end
        end
        else begin
                if(rob_isCF[wrob_head][0]==1) begin
                        if(rob_isCF[wrob_head][2]==1&&rob_logreg[wrob_head]==1) begin
                                wincorrect_pushes=wincorrect_pushes+1;
                        end
                        if(rob_op[wrob_head]==JALR &&
                                (rob_debug_instr[wrob_head][19:15]==1)) begin
                                wincorrect_pops=wincorrect_pops+1;
                        end
                end
                wnumRetired=wnumRetired+1;
                if(!rob_flushed[wrob_head]) begin
                        wrob_free1=map[rob_logreg[wrob_head]];
                        wrob_unready1=1<<map[rob_logreg[wrob_head]];
                        wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                end
                else if(rob_flushed[wrob_head] && rob_logreg[wrob_head]!=0) begin
                        wrob_free1=rob_phyreg[wrob_head];
                        wrob_unready1=1<<rob_phyreg[wrob_head];
                end
                wrob_ready[wrob_head]=False;
                wrob_flushed[wrob_head]=False;
                wrob_logreg[wrob_head]=0;
                wrob_phyreg[wrob_head]=0;
                wrob_head=wrob_head+1;
        end
end
else begin
        wrob_free1=0;
end

if(wrob_head==wrob_tail) wretireDone=True;

if(!wretireDone && !wfullFlush &&
(rob_ready[wrob_head] || rob_flushed[wrob_head])) begin
        if(rob_isCF[wrob_head][0]==1 && !rob_flushed[wrob_head]) begin
                if(!wupdatePredictor_we) begin
                        if(rob_op[wrob_head]==JAL) begin

                        end
                        else if(rob_op[wrob_head]==JALR) begin
                                if(rob_pred_target[wrob_head]
                                                !=rob_eff_target[wrob_head]) begin
                                        wcorrectTarget=rob_eff_target[wrob_head];
                                        wfullFlush=True;
                                        
                                end
                        end
                        else begin
                                if(rob_dir[wrob_head]!=rob_pred[wrob_head]) begin
                                        if(rob_dir[wrob_head]) begin
                                                wcorrectTarget=rob_pred_target[wrob_head];
                                        end
                                        else begin
                                                wcorrectTarget=rob_eff_target[wrob_head];
                                        end
                                        wfullFlush=True;
                                        
                                end
                                wupdatePredictor_we=True;
                                wupdatePredictorPC=rob_debug_pc[wrob_head];
                                wupdatePrediction=rob_dir[wrob_head];
                        end
                        if(rob_isCF[wrob_head][2]==1) begin
                                wrob_free2=map[rob_logreg[wrob_head]];
                                wrob_unready2=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wrob_free2=0;
                        end
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                end
        end
        else if(rob_isMem[wrob_head] && !rob_flushed[wrob_head]) begin
                if(
                        (rob_op[wrob_head]==LOAD && ldstq_hasAddr[ldstqIdx] &&
                        ( (!wisMemRetire && wloadDone) || (ldstq_hasData[ldstqIdx] && wloadDone) || ldstq_wroteValue[ldstqIdx]))
                        || (rob_op[wrob_head]==STORE && !wisMemRetire && ldstq_hasAddr[ldstqIdx] && ldstq_hasData[ldstqIdx])
                ) begin
                        if(!(rob_op[wrob_head]==STORE)) begin
                                if(ldstq_hasData[ldstqIdx] && ldstq_wroteValue[ldstqIdx]) begin

                                end
                                else if(ldstq_hasData[ldstqIdx]
                                                && !ldstq_wroteValue[ldstqIdx]) begin
                                        wpre_load=ldstq_d[ldstqIdx];
                                        wload_reg=ldstq_dreg[ldstqIdx];
                                        wpre_load_we=True;
                                        wnotIssued=True;
                                        wloadDone=False;
                                end
                                else begin
                                        wisMemRetire=True;
                                        wmemOp=rob_op[wrob_head];
                                        wmar=ldstq_a[ldstqIdx];
                                        wload_reg=rob_phyreg[wrob_head];
                                        wloadDone=False;
                                end
                                wrob_free2=map[rob_logreg[wrob_head]];
                                wrob_unready2=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wsmdr=ldstq_d[ldstqIdx];
                                wisMemRetire=True;
                                wmemOp=rob_op[wrob_head];
                                wmar=ldstq_a[ldstqIdx];
                                wrob_free2=0;
                        end
                        ldstqIdx = ldstqIdx + 1;
                        
                        wldstq_nextFree=wldstq_nextFree-1;
                        wdata_snooper=wdata_snooper-1;
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                        wrob_free2=0;
                end
        end
        else begin
                if(rob_isCF[wrob_head][0]==1) begin
                        if(rob_isCF[wrob_head][2]==1&&rob_logreg[wrob_head]==1) begin
                                wincorrect_pushes=wincorrect_pushes+1;
                        end
                        if(rob_op[wrob_head]==JALR &&
                                (rob_debug_instr[wrob_head][19:15]==1)) begin
                                wincorrect_pops=wincorrect_pops+1;
                        end
                end
                wnumRetired=wnumRetired+1;
                if(!rob_flushed[wrob_head]) begin
                        wrob_free2=map[rob_logreg[wrob_head]];
                        wrob_unready2=1<<map[rob_logreg[wrob_head]];
                        wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                end
                else if(rob_flushed[wrob_head] && rob_logreg[wrob_head]!=0) begin
                        wrob_free2=rob_phyreg[wrob_head];
                        wrob_unready2=1<<rob_phyreg[wrob_head];
                end
                wrob_ready[wrob_head]=False;
                wrob_flushed[wrob_head]=False;
                wrob_logreg[wrob_head]=0;
                wrob_phyreg[wrob_head]=0;
                wrob_head=wrob_head+1;
        end
end
else begin
        wrob_free2=0;
end

if(wrob_head==wrob_tail) wretireDone=True;

if(!wretireDone && !wfullFlush &&
(rob_ready[wrob_head] || rob_flushed[wrob_head])) begin
        if(rob_isCF[wrob_head][0]==1 && !rob_flushed[wrob_head]) begin
                if(!wupdatePredictor_we) begin
                        if(rob_op[wrob_head]==JAL) begin

                        end
                        else if(rob_op[wrob_head]==JALR) begin
                                if(rob_pred_target[wrob_head]
                                                !=rob_eff_target[wrob_head]) begin
                                        wcorrectTarget=rob_eff_target[wrob_head];
                                        wfullFlush=True;
                                        
                                end
                        end
                        else begin
                                if(rob_dir[wrob_head]!=rob_pred[wrob_head]) begin
                                        if(rob_dir[wrob_head]) begin
                                                wcorrectTarget=rob_pred_target[wrob_head];
                                        end
                                        else begin
                                                wcorrectTarget=rob_eff_target[wrob_head];
                                        end
                                        wfullFlush=True;
                                        
                                end
                                wupdatePredictor_we=True;
                                wupdatePredictorPC=rob_debug_pc[wrob_head];
                                wupdatePrediction=rob_dir[wrob_head];
                        end
                        if(rob_isCF[wrob_head][2]==1) begin
                                wrob_free3=map[rob_logreg[wrob_head]];
                                wrob_unready3=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wrob_free3=0;
                        end
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                end
        end
        else if(rob_isMem[wrob_head] && !rob_flushed[wrob_head]) begin
                if(
                        (rob_op[wrob_head]==LOAD && ldstq_hasAddr[ldstqIdx] &&
                        ( (!wisMemRetire && wloadDone) || (ldstq_hasData[ldstqIdx] && wloadDone) || ldstq_wroteValue[ldstqIdx]))
                        || (rob_op[wrob_head]==STORE && !wisMemRetire && ldstq_hasAddr[ldstqIdx] && ldstq_hasData[ldstqIdx])
                ) begin
                        if(!(rob_op[wrob_head]==STORE)) begin
                                if(ldstq_hasData[ldstqIdx] && ldstq_wroteValue[ldstqIdx]) begin

                                end
                                else if(ldstq_hasData[ldstqIdx]
                                                && !ldstq_wroteValue[ldstqIdx]) begin
                                        wpre_load=ldstq_d[ldstqIdx];
                                        wload_reg=ldstq_dreg[ldstqIdx];
                                        wpre_load_we=True;
                                        wnotIssued=True;
                                        wloadDone=False;
                                end
                                else begin
                                        wisMemRetire=True;
                                        wmemOp=rob_op[wrob_head];
                                        wmar=ldstq_a[ldstqIdx];
                                        wload_reg=rob_phyreg[wrob_head];
                                        wloadDone=False;
                                end
                                wrob_free3=map[rob_logreg[wrob_head]];
                                wrob_unready3=1<<map[rob_logreg[wrob_head]];
                                wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                        end
                        else begin
                                wsmdr=ldstq_d[ldstqIdx];
                                wisMemRetire=True;
                                wmemOp=rob_op[wrob_head];
                                wmar=ldstq_a[ldstqIdx];
                                wrob_free3=0;
                        end
                        ldstqIdx = ldstqIdx + 1;
                        
                        wldstq_nextFree=wldstq_nextFree-1;
                        wdata_snooper=wdata_snooper-1;
                        wrob_ready[wrob_head]=False;
                        wrob_flushed[wrob_head]=False;
                        wrob_logreg[wrob_head]=0;
                        wrob_phyreg[wrob_head]=0;
                        wrob_head=wrob_head+1;
                end
                else begin
                        wretireDone=True;
                        wrob_free3=0;
                end
        end
        else begin
                if(rob_isCF[wrob_head][0]==1) begin
                        if(rob_isCF[wrob_head][2]==1&&rob_logreg[wrob_head]==1) begin
                                wincorrect_pushes=wincorrect_pushes+1;
                        end
                        if(rob_op[wrob_head]==JALR &&
                                (rob_debug_instr[wrob_head][19:15]==1)) begin
                                wincorrect_pops=wincorrect_pops+1;
                        end
                end
                wnumRetired=wnumRetired+1;
                if(!rob_flushed[wrob_head]) begin
                        wrob_free3=map[rob_logreg[wrob_head]];
                        wrob_unready3=1<<map[rob_logreg[wrob_head]];
                        wmap[rob_logreg[wrob_head]]=rob_phyreg[wrob_head];
                end
                else if(rob_flushed[wrob_head] && rob_logreg[wrob_head]!=0) begin
                        wrob_free3=rob_phyreg[wrob_head];
                        wrob_unready3=1<<rob_phyreg[wrob_head];
                end
                wrob_ready[wrob_head]=False;
                wrob_flushed[wrob_head]=False;
                wrob_logreg[wrob_head]=0;
                wrob_phyreg[wrob_head]=0;
                wrob_head=wrob_head+1;
        end
end
else begin
        wrob_free3=0;
end

if(wfullFlush) begin
        for(Integer i=0;i<8;i=i+1) begin
                wrob_flushed[i]=True;
        end
end

for(Integer j=1; j<=4; j=j+1) begin
        if(j <= ldstqIdx) begin
                for(Integer i=0;i<15;i=i+1) begin
                        wldstq_areg[i]=wldstq_areg[i+1];
                        wldstq_dreg[i]=wldstq_dreg[i+1];
                        wldstq_a[i]=wldstq_a[i+1];
                        wldstq_d[i]=wldstq_d[i+1];
                        wldstq_hasAddr[i]=wldstq_hasAddr[i+1];
                        wldstq_Valid[i]=wldstq_Valid[i+1];
                        wldstq_isStore[i]=wldstq_isStore[i+1];
                        wldstq_isLoad[i]=wldstq_isLoad[i+1];
                        wldstq_hasData[i]=wldstq_hasData[i+1];
                        wldstq_rob[i]=wldstq_rob[i+1];
                        wldstq_wroteValue[i]=wldstq_wroteValue[i+1];
                end
                wldstq_areg[15]=0;
                wldstq_dreg[15]=0;
                wldstq_a[15]=0;
                wldstq_d[15]=0;
                wldstq_hasAddr[15]=False;
                wldstq_Valid[15]=False;
                wldstq_isStore[15]=False;
                wldstq_isLoad[15]=False;
                wldstq_hasData[15]=False;
                wldstq_rob[15]=0;
                wldstq_wroteValue[15]=False;
        end
end


Word nxtPc=0;
fullFlush<=wfullFlush;
correctTarget <= wcorrectTarget;

rename.fullFlush=fullFlush;
rename.replacementMAP=wmap;

if( (iStall && !fullFlush) || (rob_full && !fullFlush) || (renameStall && !fullFlush)) begin
        pc <= pc;
        nxtPc=pc;
end
else if(fullFlush) begin
        pc<=correctTarget;
        nxtPc=correctTarget;
end
else begin
        pc<=nextFetchAt;
        nxtPc=nextFetchAt;
end

if(iCache.reqEnabled) begin
iCache.req1=
Valid(MemReq{op: Ld, addr: nxtPc, data: 0});
end
else begin
iCache.req1=Invalid;
end

if(iCache.reqEnabled) begin
iCache.req2=
Valid(MemReq{op: Ld, addr: nxtPc+12, data: 0});
end
else begin
iCache.req2=Invalid;
end

wrob_free=wrob_free + zeroExtend(wnumRetired);
wunresolved_store=False;

map<=wmap;

Word inInstA=
(!badReq && isValid(dline))?fromMaybe(?,dline)[0][getWordOffset(inAddrA)]:instrA;

Word inInstB=instrB;
if((!badReq && isValid(dline))) begin
        if(getIndex(inAddrA)==getIndex(inAddrB)) begin
                inInstB=
                fromMaybe(?,dline)[0][getWordOffset(inAddrB)];
        end
        else begin
                inInstB=
                fromMaybe(?,dline)[1][getWordOffset(inAddrB)];
        end
end

Word inInstC=instrC;
if((!badReq && isValid(dline))) begin
        if(getIndex(inAddrA)==getIndex(inAddrC)) begin
                inInstC=
                fromMaybe(?,dline)[0][getWordOffset(inAddrC)];
        end
        else begin
                inInstC=
                fromMaybe(?,dline)[1][getWordOffset(inAddrC)];
        end
end

Word inInstD=
(!badReq && isValid(dline))?fromMaybe(?,dline)[1][getWordOffset(inAddrD)]:instrD;

badReq <= wbadReq;

if(iStall || fullFlush) begin
        inInstA=0;
        inInstB=0;
        inInstC=0;
        inInstD=0;
end

instrA<=inInstA;
instrB<=inInstB;
instrC<=inInstC;
instrD<=inInstD;




//do cache operations here
//did them up above

Bool wpop_link=pop_link;
Bool wpush_link=push_link;
Word wpca=inAddrA;
Word wpcb=inAddrB;
Word wpcc=inAddrC;
Word wpcd=inAddrD;

Bit#(3) numi=0;


DecodedInst dInstA=decode(inInstA, wpca, fullFlush);
DecodedInst dInstB=decode(inInstB, wpcb, fullFlush);
DecodedInst dInstC=decode(inInstC, wpcc, fullFlush);
DecodedInst dInstD=decode(inInstD, wpcd, fullFlush);

IType opA=dInstA.iType;
IType opB=dInstB.iType;
IType opC=dInstC.iType;
IType opD=dInstD.iType;

Bit#(2) queueA=dInstA.queue;
Bit#(2) queueB=dInstB.queue;
Bit#(2) queueC=dInstC.queue;
Bit#(2) queueD=dInstD.queue;

PIndx rsA={1'b0,dInstA.src1};
PIndx rsB={1'b0,dInstB.src1};
PIndx rsC={1'b0,dInstC.src1};
PIndx rsD={1'b0,dInstD.src1};
PIndx rtA={1'b0,dInstA.src2};
PIndx rtB={1'b0,dInstB.src2};
PIndx rtC={1'b0,dInstC.src2};
PIndx rtD={1'b0,dInstD.src2};
PIndx rdA={1'b0,dInstA.dst};
PIndx rdB={1'b0,dInstB.dst};
PIndx rdC={1'b0,dInstC.dst};
PIndx rdD={1'b0,dInstD.dst};

Bool usesImmA=dInstA.usesImm;
Bool usesImmB=dInstB.usesImm;
Bool usesImmC=dInstC.usesImm;
Bool usesImmD=dInstD.usesImm;

Word immA=dInstA.imm;
Word immB=dInstB.imm;
Word immC=dInstC.imm;
Word immD=dInstD.imm;

Bool isMemA=dInstA.isMem;
Bool isALUA=dInstA.isALU;
Bool isMemB=dInstB.isMem;
Bool isALUB=dInstB.isALU;
Bool isMemC=dInstC.isMem;
Bool isALUC=dInstC.isALU;
Bool isMemD=dInstD.isMem;
Bool isALUD=dInstD.isALU;

Bit#(3) isCFA=dInstA.isCF;
Bit#(3) isCFB=dInstB.isCF;
Bit#(3) isCFC=dInstC.isCF;
Bit#(3) isCFD=dInstD.isCF;

Bool predA=False;
Bool predB=False;
Bool predC=False;
Bool predD=False;

Word targetA=dInstA.target;
Word targetB=dInstB.target;
Word targetC=dInstC.target;
Word targetD=dInstD.target;

Word wlink_pc = 0;
Bool wbr_dir = False;

if(opA==Unsupported) begin
        numi=0;
end

else begin
if(isCFA[0]==1) begin
        wlink_pc = wpca+immA;
        if(isCFA[2]==1 && rdA!=0) wpush_link=True;
        if(opA==JALR) wpop_link=True;
        wbr_dir = isCFA[1]==1;
        //when checking make sure you write A not B
        if(opA==JALR) begin
                nextFetchAt=ras.pred;
                targetA=ras.pred;
                predA=True;
        end
        else if(opA==JAL) begin
                nextFetchAt=targetA;
                predA=True;
        end
        else begin
                Bool br_pred=brp.tPred(wpca);
                if(br_pred) begin
                        nextFetchAt=targetA;
                        predA=True;
                end
                else begin
                        nextFetchAt=wpca+4;
                        predA=False;
                end
        end
        opB=Unsupported;
        queueB=0;
        rsB=0;
        rtB=0;
        rdB=0;
        usesImmB=False;
        immB=0;
        isMemB=False;
        isALUB=False;
        isCFB=0;
        targetB=0;
        wpcb=0;
        inInstB=0;

        opC=Unsupported;
        queueC=0;
        rsC=0;
        rtC=0;
        rdC=0;
        usesImmC=False;
        immC=0;
        isMemC=False;
        isALUC=False;
        isCFC=0;
        targetC=0;
        wpcc=0;
        inInstC=0;

        opD=Unsupported;
        queueD=0;
        rsD=0;
        rtD=0;
        rdD=0;
        usesImmD=False;
        immD=0;
        isMemD=False;
        isALUD=False;
        isCFD=0;
        targetD=0;
        wpcd=0;
        inInstD=0;

        numi=1;
end

//make sure it is all B not A
else begin
if(isCFB[0]==1) begin
wlink_pc = wpcb + immB;
if(isCFB[2]==1 && rdB!=0) wpush_link=True;
if(opB==JALR) wpop_link=True;
wbr_dir = isCFB[1]==1;
//when checking make sure you write A not B
if(opB==JALR) begin
        nextFetchAt=ras.pred;
        targetB=ras.pred;
        predB=True;
end
else if(opB==JAL) begin
        nextFetchAt=targetB;
        predB=True;
end
else begin
        Bool br_pred=brp.tPred(wpcb);
        if(br_pred) begin
                nextFetchAt=targetB;
                predB=True;
        end
        else begin
                nextFetchAt=wpcb+4;
                predB=False;
        end
end

opC=Unsupported;
queueC=0;
rsC=0;
rtC=0;
rdC=0;
usesImmC=False;
immC=0;
isMemC=False;
isALUC=False;
isCFC=0;
targetC=0;
wpcc=0;
inInstC=0;

opD=Unsupported;
queueD=0;
rsD=0;
rtD=0;
rdD=0;
usesImmD=False;
immD=0;
isMemD=False;
isALUD=False;
isCFD=0;
targetD=0;
wpcd=0;
inInstD=0;

numi=2;
end

//change A to C
else begin
if(isCFC[0]==1) begin
wlink_pc = wpcc+immC;
if(isCFC[2]==1 && rdC!=0) wpush_link=True;
if(opC==JALR) wpop_link=True;
wbr_dir = isCFC[1]==1;
//when checking make sure you write C not A
if(opC==JALR) begin
        nextFetchAt=ras.pred;
        targetC=ras.pred;
        predC=True;
end
else if(opC==JAL) begin
        nextFetchAt=targetC;
        predC=True;
end
else begin
        Bool br_pred=brp.tPred(wpcc);
        if(br_pred) begin
                nextFetchAt=targetC;
                predC=True;
        end
        else begin
                nextFetchAt=wpcc+4;
                predC=False;
        end
end

opD=Unsupported;
queueD=0;
rsD=0;
rtD=0;
rdD=0;
usesImmD=False;
immD=0;
isMemD=False;
isALUD=False;
isCFD=0;
targetD=0;
wpcd=0;
inInstD=0;


numi=3;
end

else begin
if(isCFD[0]==1) begin
wlink_pc = wpcd+immD;
if(isCFD[2]==1 && rdD!=0) wpush_link=True;
if(opD==JALR) wpop_link=True;
wbr_dir = isCFD[1]==1;
//when checking make sure you write A not B
if(opD==JALR) begin
        nextFetchAt=ras.pred;
        targetD=ras.pred;
        predD=True;
end
else if(opD==JAL) begin
        nextFetchAt=targetD;
        predD=True;
end
else begin
        Bool br_pred=brp.tPred(wpcd);
        if(br_pred) begin
                nextFetchAt=targetD;
                predD=True;
        end
        else begin
                nextFetchAt=wpcd+4;
                predD=False;
        end
end

numi=4;
end

else begin
        nextFetchAt=wpcd+4;
        numi=4;
end

end

end

end

end


if(iStall || fullFlush || renameStall || rob_full) begin
        wpop_link=False;
        wpush_link=False;
end

//return address stack
ras.pop=pop_link;
ras.push=push_link;
ras.linkPC=link_pc;
ras.incorrect_pushes=incorrect_pushes;
ras.incorrect_pops=incorrect_pops;

br_dir <= wbr_dir;
link_pc <= wlink_pc;

rename.numInstr=((fullFlush || renameStall || rob_full) ? 0:numInstr);


if(fullFlush || ! (rob_full || renameStall)) begin

        numInstr<=numi;

        d_opA<=opA;
        d_opB<=opB;
        d_opC<=opC;
        d_opD<=opD;
        d_queueA<=queueA;
        d_queueB<=queueB;
        d_queueC<=queueC;
        d_queueD<=queueD;

        d_rsA<=rsA;
        d_rsB<=rsB;
        d_rsC<=rsC;
        d_rsD<=rsD;
        d_rtA<=rtA;
        d_rtB<=rtB;
        d_rtC<=rtC;
        d_rtD<=rtD;
        d_rdA<=rdA;
        d_rdB<=rdB;
        d_rdC<=rdC;
        d_rdD<=rdD;
        d_usesImmA<=usesImmA;
        d_usesImmB<=usesImmB;
        d_usesImmC<=usesImmC;
        d_usesImmD<=usesImmD;
        d_immA<=immA;
        d_immB<=immB;
        d_immC<=immC;
        d_immD<=immD;
        d_isMemA<=isMemA;
        d_isMemB<=isMemB;
        d_isMemC<=isMemC;
        d_isMemD<=isMemD;
        d_isALUA<=isALUA;
        d_isALUB<=isALUB;
        d_isALUC<=isALUC;
        d_isALUD<=isALUD;
        d_isCFA<=isCFA;
        d_isCFB<=isCFB;
        d_isCFC<=isCFC;
        d_isCFD<=isCFD;
        d_targetA<=targetA;
        d_targetB<=targetB;
        d_targetC<=targetC;
        d_targetD<=targetD;
        d_PCA<=wpca;
        d_PCB<=wpcb;
        d_PCC<=wpcc;
        d_PCD<=wpcd;
        d_instrA<=inInstA;
        d_instrB<=inInstB;
        d_instrC<=inInstC;
        d_instrD<=inInstD;

        d_predA<=predA;
        d_predB<=predB;
        d_predC<=predC;
        d_predD<=predD;

end

if(!(fullFlush || iStall)) begin
        pop_link<=wpop_link;
        push_link<=wpush_link;
end


if(fullFlush || renameStall) begin
        r_numInstr<=0;
        r_queueA<=0;
        r_queueB<=0;
        r_queueC<=0;
        r_queueD<=0;
end
else begin
        r_numInstr<=numInstr;
        r_queueA<=d_queueA;
        r_queueB<=d_queueB;
        r_queueC<=d_queueC;
        r_queueD<=d_queueD;
end




if(wfullFlush) begin
        for(Integer i=0;i<8;i=i+1) begin
                wldstq_Valid[i]=False;
        end
        wldstq_nextFree=0;
end
else begin
        for(Integer i=0;i<8;i=i+1) begin
                if(wloadDone && (!wisMemRetire || ldstq_hasData[i])
                   && ldstq_isLoad[i] && ldstq_Valid[i] && !fullFlush && ldstq_hasAddr[i]
                   && !ldstq_wroteValue[i]) begin
                        if(ldstq_hasData[i]) begin
                                wpre_load=ldstq_d[i];
                                wload_reg=ldstq_dreg[i];
                                wpre_load_we=True;
                                wnotIssued=True;
                                wloadDone=False;
                                wldstq_wroteValue[i]=True;
                        end
                end
        end
end

notIssued<=wnotIssued;
isMemRetire<=wisMemRetire;
memOp<=wmemOp;


dCache.req=
((wmemOp==LOAD||wmemOp==STORE) && dCache.reqEnabled)?
Valid(MemReq{op:(wmemOp==LOAD)?Ld:St,addr:wmar,data:wsmdr}):Invalid;



mar<=wmar;
smdr<=wsmdr;


rob_free0<=wrob_free0;
rob_free1<=wrob_free1;
rob_free2<=wrob_free2;
rob_free3<=wrob_free3;
//numAddFree<=wnumAddFree;

brp.updatePC=wupdatePredictorPC;
brp.updateEnable=wupdatePredictor_we;
brp.updateValue=wupdatePrediction;
brp.direction=br_dir;

updatePredictor_we<=wupdatePredictor_we;
updatePredictorPC<=wupdatePredictorPC;
updatePrediction<=wupdatePrediction;


incorrect_pushes<=wincorrect_pushes;
incorrect_pops<=wincorrect_pops;

store_reg<=wstore_reg;

load_reg<=wload_reg;

rob_head<=wrob_head;
rob_free<=wrob_free;

rob_ready<=wrob_ready;
rob_flushed<=wrob_flushed;
rob_op<=wrob_op;
rob_logreg<=wrob_logreg;
rob_phyreg<=wrob_phyreg;
rob_pred<=wrob_pred;
rob_pred_target<=wrob_pred_target;
rob_dir<=wrob_dir;
rob_eff_target<=wrob_eff_target;
rob_isMem<=wrob_isMem;
rob_isCF<=wrob_isCF;
rob_debug_instr<=wrob_debug_instr;
rob_debug_pc<=wrob_debug_pc;


numRetired<=wnumRetired;
rob_unready0<=wrob_unready0;
rob_unready1<=wrob_unready1;
rob_unready2<=wrob_unready2;
rob_unready3<=wrob_unready3;
instrs<=instrs+zeroExtend(wnumRetired);

retireDone<=wretireDone;

loadDone<=wloadDone;

ldstq_areg<=wldstq_areg;
ldstq_dreg<=wldstq_dreg;
ldstq_a<=wldstq_a;
ldstq_d<=wldstq_d;
ldstq_hasAddr<=wldstq_hasAddr;
ldstq_Valid<=wldstq_Valid;
ldstq_isStore<=wldstq_isStore;
ldstq_isLoad<=wldstq_isLoad;
ldstq_hasData<=wldstq_hasData;
ldstq_rob<=wldstq_rob;
ldstq_nextFree<=wldstq_nextFree;
ldstq_wroteValue<=wldstq_wroteValue;

pre_load<=wpre_load;
pre_load_we<=wpre_load_we;
data_snooped<=wdata_snooped;
data_snooper<=wdata_snooper;
unresolved_store<=wunresolved_store;

map<=wmap;

Bit#(64) i_readyA=0;
Bit#(64) i_readyB=0;
Bit#(64) i_readyC=0;
Bit#(64) i_readyD=0;


ready_regs.toBeReady0=(fullFlush ? 0:aluQueue.moutReadyFlag0);
ready_regs.toBeReady1=(fullFlush ? 0:aluQueue.moutReadyFlag1);
ready_regs.toBeReady2=(fullFlush ? 0:link_ready);
ready_regs.toBeReady3=load_ready;
ready_regs.clearReady0=wrob_unready0;
ready_regs.clearReady1=wrob_unready1;
ready_regs.clearReady2=wrob_unready2;
ready_regs.clearReady3=wrob_unready3;
//do ready Reg# list here

IType i_opA=Unsupported;
IType i_opB=Unsupported;
IType i_opC=Unsupported;
IType i_opD=Unsupported;
PIndx i_rsA=0;
PIndx i_rsB=0;
PIndx i_rsC=0;
PIndx i_rsD=0;
PIndx i_rtA=0;
PIndx i_rtB=0;
PIndx i_rtC=0;
PIndx i_rtD=0;
PIndx i_rdA=0;
PIndx i_rdB=0;
PIndx i_rdC=0;
PIndx i_rdD=0;

Bool i_usesImmA=False;
Bool i_usesImmB=False;
Bool i_usesImmC=False;
Bool i_usesImmD=False;
Word i_immA=0;
Word i_immB=0;
Word i_immC=0;
Word i_immD=0;
Bit#(3) i_roba=0;
Bit#(3) i_robb=0;
Bit#(3) i_robc=0;
Bit#(3) i_robd=0;


Bit#(2) aluNumIssued=0;
Bit#(2) ldstNumIssued=0;
Bit#(2) brjrNumIssued=0;

readyList=ready_regs.mreadyList(
aluQueue.moutReadyFlag0, aluQueue.moutReadyFlag1, link_ready, load_ready,
wrob_unready0, wrob_unready1, wrob_unready2, wrob_unready3);


aluQueue.fullFlush=fullFlush;
aluQueue.maxIssue=2'b10;
aluQueue.queueNum=2'b01;
aluQueue.readyFlags=readyList;

Vector#(4, IType) inOperationVec = newVector();
Vector#(4, Word) inImmediateVec = newVector();
Vector#(4, PIndx) inRTVec = newVector();
Vector#(4, PIndx) inRSVec = newVector();
Vector#(4, PIndx) inRDVec = newVector();
Vector#(4, Bit#(2)) inQueueVec = newVector();
Vector#(4, Bit#(3)) inROBVec = newVector();
Vector#(4, Bool) inUImmVec = newVector();

inOperationVec[0] = r_opA;
inOperationVec[1] = r_opB;
inOperationVec[2] = r_opC;
inOperationVec[3] = r_opD;

inImmediateVec[0] = r_immA;
inImmediateVec[1] = r_immB;
inImmediateVec[2] = r_immC;
inImmediateVec[3] = r_immD;

inRTVec[0] = r_rtA;
inRTVec[1] = r_rtB;
inRTVec[2] = r_rtC;
inRTVec[3] = r_rtD;

inRSVec[0] = r_rsA;
inRSVec[1] = r_rsB;
inRSVec[2] = r_rsC;
inRSVec[3] = r_rsD;

inRDVec[0] = r_rdA;
inRDVec[1] = r_rdB;
inRDVec[2] = r_rdC;
inRDVec[3] = r_rdD;

inQueueVec[0] = (rob_full ? 2'b00: r_queueA);
inQueueVec[1] = (rob_full ? 2'b00: r_queueB);
inQueueVec[2] = (rob_full ? 2'b00: r_queueC);
inQueueVec[3] = (rob_full ? 2'b00: r_queueD);

inROBVec[0] = rob_slot0;
inROBVec[1] = rob_slot1;
inROBVec[2] = rob_slot2;
inROBVec[3] = rob_slot3;

inUImmVec[0] = r_usesImmA;
inUImmVec[1] = r_usesImmB;
inUImmVec[2] = r_usesImmC;
inUImmVec[3] = r_usesImmD;


aluQueue.inOperation=inOperationVec;
aluQueue.inImmediate=inImmediateVec;
aluQueue.inRT=inRTVec;
aluQueue.inRS=inRSVec;
aluQueue.inRD=inRDVec;
aluQueue.inQueue=inQueueVec;
aluQueue.inROB=inROBVec;
aluQueue.inUImm=inUImmVec;


i_opA=aluQueue.moutOperation0;
i_immA=aluQueue.moutImmediate0;
i_rtA=aluQueue.moutRT0;
i_rsA=aluQueue.moutRS0;
i_rdA=aluQueue.moutRD0;
i_roba=aluQueue.moutROB0;
i_usesImmA=aluQueue.moutUImm0;
//i_readyA=aluQueue.moutReadyFlag0;

i_opB=aluQueue.moutOperation1;
i_immB=aluQueue.moutImmediate1;
i_rtB=aluQueue.moutRT1;
i_rsB=aluQueue.moutRS1;
i_rdB=aluQueue.moutRD1;
i_robb=aluQueue.moutROB1;
i_usesImmB=aluQueue.moutUImm1;
//i_readyB=aluQueue.moutReadyFlag1;

aluNumIssued=aluQueue.mnumIssued;

ldstQueue.fullFlush=fullFlush;
ldstQueue.maxIssue=2'b01;
ldstQueue.queueNum=2'b11;
ldstQueue.readyFlags=readyList;

ldstQueue.inOperation=inOperationVec;
ldstQueue.inImmediate=inImmediateVec;
ldstQueue.inRT=inRTVec;
ldstQueue.inRS=inRSVec;
ldstQueue.inRD=inRDVec;
ldstQueue.inQueue=inQueueVec;
ldstQueue.inROB=inROBVec;
ldstQueue.inUImm=inUImmVec;

i_opC=ldstQueue.moutOperation0;
i_immC=ldstQueue.moutImmediate0;
i_rtC=ldstQueue.moutRT0;
i_rsC=ldstQueue.moutRS0;
i_rdC=ldstQueue.moutRD0;
i_robc=ldstQueue.moutROB0;
i_usesImmC=ldstQueue.moutUImm0;
i_readyC=ldstQueue.moutReadyFlag0;

ldstNumIssued=ldstQueue.mnumIssued;

brjrQueue.fullFlush=fullFlush;
brjrQueue.maxIssue=2'b01;
brjrQueue.queueNum=2'b11;
brjrQueue.readyFlags=readyList;

brjrQueue.inOperation=inOperationVec;
brjrQueue.inImmediate=inImmediateVec;
brjrQueue.inRT=inRTVec;
brjrQueue.inRS=inRSVec;
brjrQueue.inRD=inRDVec;
brjrQueue.inQueue=inQueueVec;
brjrQueue.inROB=inROBVec;
brjrQueue.inUImm=inUImmVec;

i_opD=brjrQueue.moutOperation0;
i_immD=brjrQueue.moutImmediate0;
i_rtD=brjrQueue.moutRT0;
i_rsD=brjrQueue.moutRS0;
i_rdD=brjrQueue.moutRD0;
i_robd=brjrQueue.moutROB0;
i_usesImmD=brjrQueue.moutUImm0;
i_readyD=brjrQueue.moutReadyFlag0;

brjrNumIssued=brjrQueue.mnumIssued;


Word iv_rsA=rf.readValue(i_rsA, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);
Word iv_rsB=rf.readValue(i_rsB, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);
Word iv_rsC=rf.readValue(i_rsC, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);
Word iv_rsD=rf.readValue(i_rsD, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);
Word iv_rtA=rf.readValue(i_rtA, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);
Word iv_rtB=rf.readValue(i_rtB, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);
Word iv_rtD=rf.readValue(i_rtD, alu0_we, ex_rdA, exv_rdA, alu1_we, ex_rdB, exv_rdB,
                                                 link_we, link_reg, link_value, (!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we, load_reg, pre_load_data);


ir_opA<=i_opA;
ir_opB<=i_opB;
ir_opC<=i_opC;
ir_opD<=i_opD;
ir_rsA<=i_rsA;
ir_rsB<=i_rsB;
ir_rsC<=i_rsC;
ir_rsD<=i_rsD;
ir_rtA<=i_rtA;
ir_rtB<=i_rtB;
ir_rtC<=i_rtC;
ir_rtD<=i_rtD;
ir_rdA<=i_rdA;
ir_rdB<=i_rdB;
ir_rdC<=i_rdC;
ir_rdD<=i_rdD;
irv_rsA<=iv_rsA;
irv_rsB<=iv_rsB;
irv_rsC<=iv_rsC;
irv_rsD<=iv_rsD;
irv_rtA<=iv_rtA;
irv_rtB<=iv_rtB;
irv_rtD<=iv_rtD;
ir_usesImmA<=i_usesImmA;
ir_usesImmB<=i_usesImmB;
ir_usesImmC<=i_usesImmC;
ir_usesImmD<=i_usesImmD;
ir_immA<=i_immA;
ir_immB<=i_immB;
ir_immC<=i_immC;
ir_immD<=i_immD;
ir_roba<=i_roba;
ir_robb<=i_robb;
ir_robc<=i_robc;
ir_robd<=i_robd;
ir_ALUNumIssued<=aluNumIssued;
ir_LDSTNumIssued<=ldstNumIssued;
ir_BRJRNumIssued<=brjrNumIssued;


Word alu0_rs_v=moutValue(ir_rsA, ex_rdA, ex_rdB, load_reg, link_reg, irv_rsA, exv_rdA, exv_rdB, cacheOut, link_value);
Word alu0_rt_v=moutValue(ir_rtA, ex_rdA, ex_rdB, load_reg, link_reg, irv_rtA, exv_rdA, exv_rdB, cacheOut, link_value);
Word alu1_rs_v=moutValue(ir_rsB, ex_rdA, ex_rdB, load_reg, link_reg, irv_rsB, exv_rdA, exv_rdB, cacheOut, link_value);
Word alu1_rt_v=moutValue(ir_rtB, ex_rdA, ex_rdB, load_reg, link_reg, irv_rtB, exv_rdA, exv_rdB, cacheOut, link_value);
Word ldst_rs_v=moutValue(ir_rsC, ex_rdA, ex_rdB, load_reg, link_reg, irv_rsC, exv_rdA, exv_rdB, cacheOut, link_value);
Word brjr_rs_v=moutValue(ir_rsD, ex_rdA, ex_rdB, load_reg, link_reg, irv_rsD, exv_rdA, exv_rdB, cacheOut, link_value);
Word brjr_rt_v=moutValue(ir_rtD, ex_rdA, ex_rdB, load_reg, link_reg, irv_rtD, exv_rdA, exv_rdB, cacheOut, link_value);


Word alu0_out=alu0.maluOut(alu0_rs_v, alu0_rt_v, ir_immA, ir_usesImmA, ir_opA);
Word alu1_out=alu1.maluOut(alu1_rs_v, alu1_rt_v, ir_immB, ir_usesImmB, ir_opB);
Word effAddr = ldst_rs_v + ir_immC;
Word brjr_target=bcomp.mtarget(brjr_rs_v, brjr_rt_v, ir_opD, ir_immD);
Bool brjr_taken=bcomp.mtaken(brjr_rs_v, brjr_rt_v, ir_opD, ir_immD);

ex_rdA<=ir_rdA;
ex_rdB<=ir_rdB;
exv_rdA<=alu0_out;
exv_rdB<=alu1_out;

if(ir_ALUNumIssued==2) begin
        alu0_we<=True;
        alu1_we<=True;
end
else if(ir_ALUNumIssued==1) begin
        alu0_we<=True;
        alu1_we<=False;
end
else begin
        alu0_we<=False;
        alu1_we<=False;
end

gotFlushed<=fullFlushed;
ldst_done<=(ir_LDSTNumIssued==1);
brjr_done<=(ir_BRJRNumIssued==1);
ex_brjr_taken<=brjr_taken;
ex_effAddr<=effAddr;
ex_brjr_target<=brjr_target;
ex_roba<=ir_roba;
ex_robb<=ir_robb;
ex_robc<=ir_robc;
ex_robd<=ir_robd;


rf.writeValue0=exv_rdA;
rf.writeValue1=exv_rdB;
rf.writeValue2=link_value;
rf.writeValue3=pre_load_data;

rf.writeAddr0=ex_rdA;
rf.writeAddr1=ex_rdB;
rf.writeAddr2=link_reg;
rf.writeAddr3=load_reg;

rf.writeEnable0=alu0_we;
rf.writeEnable1=alu1_we;
rf.writeEnable2=link_we;
rf.writeEnable3=(!fullFlush && !loadDone && isValid(dCache.data))||pre_load_we;


endrule

method Bool getPc = fullFlush;
endmodule
