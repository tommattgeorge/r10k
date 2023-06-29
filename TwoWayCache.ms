import CacheTypes;
import CacheHelpers;
import MainMemory;

// ReqStatus (defined in CacheTypes.ms) is used to keep track of the state of the current request
//typedef enum {
//    Ready,         // The cache is ready for a new request
//    Lookup,        // Issued a lookup to tag/data arrays
//    Writeback,     // In main memory access for dirty writeback
//    Fill           // In main memory access for requested data
//} ReqStatus;
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
module TwoWayCache(MainMemory mainMem);
// SRAM arrays, one element per way (e.g., dataArrays[0] is the data array of way 0).
Vector#(2, SRAM#(logCacheSets, Line)) dataArrays;
Vector#(2, SRAM#(logCacheSets, CacheTag)) tagArrays;
Vector#(2, SRAM#(logCacheSets, CacheStatus)) statusArrays;

// LRU bits, one per set. We implement it as registers instead of an SRAM
// array, because with small caches this is just a few bits (e.g., 64), and
// SRAMs make sense only for larger memories. This also makes the code
// simpler, and will make the cache easier to pipeline in the future.
Vector#(cacheSets, RegU#(Bit#(1))) lru;

// Registers for holding the current state of the cache and how far along
// it is in processing a request.
RegU#(MemReq) curReq;
Reg#(ReqStatus) state(Ready);

// Hit/miss counters
Reg#(Word) hits(0);
Reg#(Word) misses(0);

Line dline=newVector();

input Maybe#(MemReq) req default = Invalid;

//TODO return True if the cache can accept a new request
method Bool reqEnabled = (state==Ready) || (state==Lookup && curReq.op==Ld && isHit[1]==1);

method MemOp curOp = curReq.op;

// TODO return True if the cache is in lookup and it is a hit
function Bit#(2) isHit;
        let tag=getTag(curReq.addr);
        Bit#(2) hit=0;
        for(Integer i=0;i<2;i=i+1) begin
                hit[i]=(isValid(statusArrays[i].data)&&isValid(tagArrays[i].data)&&tag==fromMaybe(?,tagArrays[i].data)
                &&fromMaybe(?,statusArrays[i].data)!=NotValid)?1:0;
        end
        return  {hit[1]|hit[0],hit[1]};
endfunction

rule tick;
  if (state == Ready && isValid(req)) begin
        state <= Lookup;
        curReq <= fromMaybe(?,req);
        let cur=fromMaybe(?,req);
        let ind=getIndex(cur.addr);
        for(Integer i=0;i<2;i=i+1) begin
                StatusReq sr=StatusReq{addr:ind,write:False,data:Clean};
                statusArrays[i].req=Valid(sr);
                TagReq tr=TagReq{addr:ind,write:False,data:0};
                tagArrays[i].req=Valid(tr);
                DataReq dr=DataReq{addr:ind,write:False,data:dline};
                dataArrays[i].req=Valid(dr);
        end
  end else if (state == Lookup) begin
        let ind=getIndex(curReq.addr);
        let cs=(isValid(statusArrays[lru[ind]].data))?fromMaybe(?,statusArrays[lru[ind]].data):NotValid;
        let hbit=isHit;
        if(hbit[1]==1) begin
                hits<=hits+1;
                if(curReq.op==Ld && isValid(req)) begin
                        curReq <= fromMaybe(?,req);
                        let cur=fromMaybe(?,req);
                        let way=hbit[0];
                        lru[ind] <= ~way;
                        let ind2=getIndex(cur.addr);
                        for(Integer i=0;i<2;i=i+1) begin
                                StatusReq sr=StatusReq{addr:ind2,write:False,data:Clean};
                                statusArrays[i].req=Valid(sr);
                                TagReq tr=TagReq{addr:ind2,write:False,data:0};
                                tagArrays[i].req=Valid(tr);
                                DataReq dr=DataReq{addr:ind2,write:False,data:dline};
                                dataArrays[i].req=Valid(dr);
                        end
                end
                else begin
                        state <= Ready;
                        let way=hbit[0];
                        lru[ind] <= ~way;
                        curReq <= MemReq{op:St,addr:0,data:0};
                        if(curReq.op==St) begin
                                Line writeline=fromMaybe(?,dataArrays[way].data);
                                writeline[getWordOffset(curReq.addr)]=curReq.data;
                                DataReq dr=DataReq{addr:ind,write:True,data:writeline};
                                dataArrays[way].req=Valid(dr);
                                StatusReq sr=StatusReq{addr:ind,write:True,data:Dirty};
                                statusArrays[way].req=Valid(sr);
                        end
                end
        end
        else begin
                misses<=misses+1;
                if(cs==Clean||cs==NotValid) begin
                        LineReq lr=LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr),data: dline};
                        mainMem.req=Valid(lr);
                        state<=Fill;
                end
                if(cs==Dirty) begin
                        Line writeline=fromMaybe(?,dataArrays[lru[ind]].data);
                        LineReq lr=LineReq{op: St, lineAddr: {fromMaybe(?,tagArrays[lru[ind]].data),ind},data: writeline};
                        mainMem.req=Valid(lr);
                        state<=Writeback;
                end
        end
  end else if (state == Writeback && mainMem.reqEnabled) begin
         LineReq lr=LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr),data: dline};
         mainMem.req=Valid(lr);
         state<=Fill;
  end else if (state == Fill && isValid(mainMem.data)) begin
        let ind=getIndex(curReq.addr);
        let writeline=fromMaybe(?,mainMem.data);
        if(curReq.op==St) writeline[getWordOffset(curReq.addr)]=curReq.data;
        DataReq dr=DataReq{addr:ind,write: True,data: writeline};
        dataArrays[lru[ind]].req=Valid(dr);
        TagReq tr=TagReq{addr: ind,write:True,data: getTag(curReq.addr)};
        tagArrays[lru[ind]].req=Valid(tr);
        StatusReq sr=StatusReq{addr: ind,write:True,data:(curReq.op==St?Dirty:Clean)};
        statusArrays[lru[ind]].req=Valid(sr);
        state<=Ready;
        curReq<=MemReq{op:St,addr:0,data:0};
        lru[ind]<=~lru[ind];
  end
endrule

method Maybe#(Word) data;
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
  if(curReq.op==Ld) begin
        if(state==Lookup) begin
                let hbit=isHit;
                if(hbit[1]==1) begin
                        return Valid(fromMaybe(?,dataArrays[hbit[0]].data)[getWordOffset(curReq.addr)]);
                end
                else begin
                        return Invalid;
                end
        end
        else if(state==Fill && isValid(mainMem.data)) begin
                return Valid(fromMaybe(?,mainMem.data)[getWordOffset(curReq.addr)]);
        end
        else begin
                return Invalid;
        end
  end
  else begin
        return Invalid;
  end
endmethod

method Bit#(32) getHits = hits;
method Bit#(32) getMisses = misses;
endmodule



