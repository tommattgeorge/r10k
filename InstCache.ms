import ProcTypes;

import CacheTypes;
import CacheHelpers;
import MainMemory2;

// RStatus (defined here not in CacheTypes.ms) is used to keep track of the state of the current request

typedef enum {
    Ready,         // The cache is ready for a new request
    Lookup,        // Issued a lookup to tag/data arrays
    Fill           // In main memory access for requested data
} RStatus;

//typedef struct {
//    MemOp    op;
//    LineAddr lineAddr;
//    Line     data;
//} LineReq;

//typedef struct {
//    MemOp op;
//    Word addr;
//    Word data;
//} MemReq;
//
// Possible flows:
//   HIT: Ready -> Lookup -> Ready
//   MISS, line is clean: Ready -> Lookup -> Fill
//   MISS, line is dirty: Ready -> Lookup -> Writeback -> Fill

// Cache SRAM Synonyms (defined in CacheTypes.ms)
// You may find the following type synonyms helpful to access the tag/data/status arrays
// typedef SRAMReq#(logCacheSets, CacheTag) TagReq;
// typedef SRAMReq#(logCacheSets, Line) DataReq;
// typedef SRAMReq#(logCacheSets, CacheStatus) StatusReq;

// TODO: Complete the implementation of TwoWayCache
// NOTE: Implementing this module requires about 20 new lines of code from DirectMappedCache
module InstCache(MainMemory2 mainMem);
// SRAM arrays, one element per way (e.g., dataArrays[0] is the data array of way 0).
Vector#(2, SRAM2#(logCacheSets, Line)) dataArrays;
Vector#(2, SRAM2#(logCacheSets, CacheTag)) tagArrays;
Vector#(2, SRAM2#(logCacheSets, CacheStatus)) statusArrays;

// LRU bits, one per set. We implement it as registers instead of an SRAM
// array, because with small caches this is just a few bits (e.g., 64), and
// SRAMs make sense only for larger memories. This also makes the code
// simpler, and will make the cache easier to pipeline in the future.
Vector#(cacheSets, RegU#(Bit#(1))) lru;

// Registers for holding the current state of the cache and how far along
// it is in processing a request.
RegU#(MemReq) curReq1;
RegU#(MemReq) curReq2;
Reg#(RStatus) state(Ready);

// Hit/miss counters
Reg#(Word) hits(0);
Reg#(Word) misses(0);

Line dline=newVector();

input Maybe#(MemReq) req1 default = Invalid;
input Maybe#(MemReq) req2 default = Invalid;

//TODO return True if the cache can accept a new request
method Bool reqEnabled = (state==Ready) || (state==Lookup && isHit1[1]==1 && isHit2[1]==1);

// TODO return True if the cache is in lookup and it is a hit
function Bit#(2) isHit1;
        let tag=getTag(curReq1.addr);
        Bit#(2) hit=0;
        for(Integer i=0;i<2;i=i+1) begin
                hit[i]=(isValid(statusArrays[i].data1)&&isValid(tagArrays[i].data1)&&tag==fromMaybe(?,tagArrays[i].data1)
                &&fromMaybe(?,statusArrays[i].data1)!=NotValid)?1:0;
        end
        return  {hit[1]|hit[0],hit[1]};
endfunction

function Bit#(2) isHit2;
        let tag=getTag(curReq2.addr);
        Bit#(2) hit=0;
        for(Integer i=0;i<2;i=i+1) begin
                hit[i]=(isValid(statusArrays[i].data2)&&isValid(tagArrays[i].data2)&&tag==fromMaybe(?,tagArrays[i].data2)
                &&fromMaybe(?,statusArrays[i].data2)!=NotValid)?1:0;
        end
        return  {hit[1]|hit[0],hit[1]};
endfunction

rule tick;
  if (state == Ready && isValid(req1)) begin
        state <= Lookup;
        curReq1 <= fromMaybe(?,req1);
        curReq2 <= fromMaybe(?,req2);
        let cur1=fromMaybe(?,req1);
        let cur2=fromMaybe(?,req2);
        let ind1=getIndex(cur1.addr);
        let ind2=getIndex(cur2.addr);
        for(Integer i=0;i<2;i=i+1) begin
                StatusReq sr1=StatusReq{addr:ind1,write:False,data:Clean};
                StatusReq sr2=StatusReq{addr:ind2,write:False,data:Clean};
                statusArrays[i].req1=Valid(sr1);
                statusArrays[i].req2=Valid(sr2);
                TagReq tr1=TagReq{addr:ind1,write:False,data:0};
                TagReq tr2=TagReq{addr:ind2,write:False,data:0};
                tagArrays[i].req1=Valid(tr1);
                tagArrays[i].req2=Valid(tr2);
                DataReq dr1=DataReq{addr:ind1,write:False,data:dline};
                DataReq dr2=DataReq{addr:ind2,write:False,data:dline};
                dataArrays[i].req1=Valid(dr1);
                dataArrays[i].req2=Valid(dr2);
        end
  end else if (state == Lookup) begin
        let ind1=getIndex(curReq1.addr);
        let ind2=getIndex(curReq2.addr);
        //let cs=(isValid(statusArrays[lru[ind]].data))?fromMaybe(?,statusArrays[lru[ind]].data):NotValid;
        let hbit1=isHit1;
        let hbit2=isHit2;

        if(hbit1[1]==1 && hbit2[1]==1) begin
                hits<=hits+1;
                if(isValid(req1)) begin
                        curReq1 <= fromMaybe(?,req1);
                        curReq2 <= fromMaybe(?,req2);
                        let cur1=fromMaybe(?,req1);
                        let cur2=fromMaybe(?,req2);
                        let way1=hbit1[0];
                        let way2=hbit2[0];
                        if(ind1==ind2) begin
                                lru[ind1] <= ~way1;
                        end
                        else begin
                                lru[ind1] <= ~way1;
                                lru[ind2] <= ~way2;
                        end
                        let idx1=getIndex(cur1.addr);
                        let idx2=getIndex(cur2.addr);
                        for(Integer i=0;i<2;i=i+1) begin
                                StatusReq sr1=StatusReq{addr:idx1,write:False,data:Clean};
                                StatusReq sr2=StatusReq{addr:idx2,write:False,data:Clean};
                                statusArrays[i].req1=Valid(sr1);
                                statusArrays[i].req2=Valid(sr2);
                                TagReq tr1=TagReq{addr:idx1,write:False,data:0};
                                TagReq tr2=TagReq{addr:idx2,write:False,data:0};
                                tagArrays[i].req1=Valid(tr1);
                                tagArrays[i].req2=Valid(tr2);
                                DataReq dr1=DataReq{addr:idx1,write:False,data:dline};
                                DataReq dr2=DataReq{addr:idx2,write:False,data:dline};
                                dataArrays[i].req1=Valid(dr1);
                                dataArrays[i].req2=Valid(dr2);
                        end
                end
                else begin
                        state <= Ready;
                        let way1=hbit1[0];
                        let way2=hbit2[0];
                        if(ind1==ind2) begin
                                lru[ind1] <= ~way1;
                        end
                        else begin
                                lru[ind1] <= ~way1;
                                lru[ind2] <= ~way2;
                        end
                end
        end
        else begin
                misses<=misses+1;
                LineReq lr1=LineReq{op: Ld, lineAddr: getLineAddr(curReq1.addr),data: dline};
                LineReq lr2=LineReq{op: Ld, lineAddr: getLineAddr(curReq2.addr),data: dline};
                mainMem.req1=Valid(lr1);
                mainMem.req2=Valid(lr2);
                state<=Fill;

        end
  end else if (state == Fill && isValid(mainMem.data1)) begin
        let ind1=getIndex(curReq1.addr);
        let ind2=getIndex(curReq2.addr);
        let lru1=(ind1!=ind2)?(~lru[ind1]):lru[ind1];//when ind1 and ind2 are different, this usually means ind1 is already cached, so use ~lru
        let writeline1=fromMaybe(?,mainMem.data1);
        let writeline2=fromMaybe(?,mainMem.data2);
        DataReq dr1=DataReq{addr:ind1,write: True,data: writeline1};
        DataReq dr2=DataReq{addr:ind2,write: True,data: writeline2};
        dataArrays[lru1].req1=Valid(dr1);
        dataArrays[lru[ind2]].req2=Valid(dr2);
        TagReq tr1=TagReq{addr: ind1,write:True,data: getTag(curReq1.addr)};
        TagReq tr2=TagReq{addr: ind2,write:True,data: getTag(curReq2.addr)};
        tagArrays[lru1].req1=Valid(tr1);
        tagArrays[lru[ind2]].req2=Valid(tr2);
        StatusReq sr1=StatusReq{addr: ind1,write:True,data:Clean};
        StatusReq sr2=StatusReq{addr: ind2,write:True,data:Clean};
        statusArrays[lru1].req1=Valid(sr1);
        statusArrays[lru[ind2]].req2=Valid(sr2);
        state<=Ready;
        if(ind1==ind2) begin
                lru[ind1] <= ~lru[ind1];
        end
        else begin
                lru[ind2] <= ~lru[ind2];
        end
  end
endrule

method Maybe#(Vector#(2, Line)) data;
// This method should return a Valid output in only two cases:
// 1. On a load hit (it is a hit, and curReq.op == Ld).
// 2. On a fill for a load request (we're in the Fill state,
//    mainMem.data is valid, and curReq.op == Ld).
// In all other cases, the output should be Invalid
//
// NOTE: You should be checking the above conditions explicitly in
//    THIS method so you can return data as soon as possible.
//    DO NOT place your output into a register in the rule and then
//    simply return that register here.

// This function should take about 4-8 lines of code to implement.
// TODO Your code here.

                let hbit1=isHit1;
                let hbit2=isHit2;

                if(state==Lookup) begin
                        Vector#(2, Line) ret=newVector();
                        if(hbit1[1]==1) begin
                                ret[0]=fromMaybe(?,dataArrays[hbit1[0]].data1);
                        end
                        if(hbit2[1]==1) begin
                                ret[1]=fromMaybe(?,dataArrays[hbit2[0]].data2);
                        end
                        return Valid(ret);
                end

                else if (state==Fill) begin
                        Vector#(2, Line) ret=newVector();
                        if(isValid(mainMem.data1)) begin
                                ret[0]=fromMaybe(?,mainMem.data1);
                        end
                        if(isValid(mainMem.data2)) begin
                                ret[1]=fromMaybe(?,mainMem.data2);
                        end
                        return Valid(ret);
                end

                else return Invalid;
endmethod

method Bit#(32) getHits = hits;
method Bit#(32) getMisses = misses;
endmodule


