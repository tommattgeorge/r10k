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
//typedef SRAMReq#(logCacheSets, CacheStatus) StatusReq;

//TODO: Complete the implementation of DirectMappedCache
//NOTE: Implementing this module requires about 50 lines of additional code
//(~40 lines in rule tick, ~5-10 lines in method data, 1 line in method reqEnabled, 1 line in function isHit)
module DirectMappedCache(MainMemory mainMem);
 // SRAM arrays. Note that, for a direct-mapped cache,
 // number of cache sets == number of cache lines
 SRAM#(logCacheSets, Line) dataArray;
 SRAM#(logCacheSets, CacheTag) tagArray;
 SRAM#(logCacheSets, CacheStatus) statusArray;
 // Registers for holding the current state of the cache and how far along
 // it is in processing a request.
 RegU#(MemReq) curReq;
 Reg#(ReqStatus) state(Ready);

 Line dline=newVector();
 // Hit/miss counters
 Reg#(Word) hits(0);
 Reg#(Word) misses(0);
 input Maybe#(MemReq) req default = Invalid;

 // TODO return True if the cache can accept a new request
 method Bool reqEnabled = (state==Ready);

 // TODO return True if the cache is in lookup and it is a hit
 function Bool isHit;
        let tag=getTag(curReq.addr);
        return (isValid(statusArray.data)&&isValid(tagArray.data)&&tag==fromMaybe(?,tagArray.data)
                        &&fromMaybe(?,statusArray.data)!=NotValid);
 endfunction

 rule tick;
     if (state == Ready && isValid(req)) begin
        state <= Lookup;
        curReq <= fromMaybe(?,req);
        let cur=fromMaybe(?,req);
        let ind=getIndex(cur.addr);
        StatusReq sr=StatusReq{addr:ind,write:False,data:Clean};
                statusArray.req=Valid(sr);
                TagReq tr=TagReq{addr:ind,write:False,data:0};
                tagArray.req=Valid(tr);
                DataReq dr=DataReq{addr:ind,write:False,data:dline};
                dataArray.req=Valid(dr);
     end else if (state == Lookup) begin
        let ind=getIndex(curReq.addr);
                let cs=(isValid(statusArray.data))?fromMaybe(?,statusArray.data):NotValid;
        if(isHit) begin
                hits<=hits+1;
                state <= Ready;
                $display(fshow(curReq));
                if(curReq.op==St) begin
                        Line writeline=fromMaybe(?,dataArray.data);
                        writeline[getWordOffset(curReq.addr)]=curReq.data;
                        DataReq dr=DataReq{addr:ind,write:True,data:writeline};
                        dataArray.req=Valid(dr);
                                StatusReq sr=StatusReq{addr:ind,write:True,data:Dirty};
                                statusArray.req=Valid(sr);
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
                                Line writeline=fromMaybe(?,dataArray.data);
                        LineReq lr=LineReq{op: St, lineAddr: {fromMaybe(?,tagArray.data),ind},data: writeline};
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
                dataArray.req=Valid(dr);
                TagReq tr=TagReq{addr: ind,write:True,data: getTag(curReq.addr)};
                tagArray.req=Valid(tr);
                StatusReq sr=StatusReq{addr: ind,write:True,data:(curReq.op==St?Dirty:Clean)};
                statusArray.req=Valid(sr);
                state<=Ready;
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
                if(isHit) begin
                        return Valid(fromMaybe(?,dataArray.data)[getWordOffset(curReq.addr)]);
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


