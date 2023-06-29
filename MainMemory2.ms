import ProcTypes;
import CacheTypes;
import SRAM2;
bsvimport Assert;

module /*msc_pragma:nosynth*/ WordMem2;
    Integer memBytes = 1 << 17;  // 128 KB
    Integer memWords = memBytes / 4;
    Integer addrBits = log2(memWords);
    SRAMLoad2#(addrBits, Word) ram("mem.vmh");

    input Maybe#(MemReq) req1 default = Invalid;
    input Maybe#(MemReq) req2 default = Invalid;

    method Maybe#(Word) data1 = ram.data1;
    method Maybe#(Word) data2 = ram.data2;

    rule tick;
        if (isValid(req1)) begin
            let r = fromMaybe(?, req1);
            ram.req1 = Valid(SRAMReq#(addrBits, Word){
                addr: truncate(r.addr >> 2), write: False, data: r.data
            });
        end
        if (isValid(req2)) begin
            let r = fromMaybe(?, req2);
            ram.req2 = Valid(SRAMReq#(addrBits, Word){
                addr: truncate(r.addr >> 2), write: False, data: r.data
            });
        end
    endrule
endmodule

// To emulate DRAM technology, MainMemory uses a word-based memory and adds some delay
module /*msc_pragma:nosynth*/ MainMemory2;//dual port
    WordMem2 wordMem;
    Integer latency = wordsPerLine + 16;

    Reg#(Bit#(log2(latency) + 1)) cyclesLeft(0);
    //RegU#(MemOp) curOp;
    RegU#(Word) curAddr1;
    RegU#(Word) curAddr2;
    Reg#(Bool) validOut(False);
    Vector#(wordsPerLine, RegU#(Word)) dataRegs1;
    Vector#(wordsPerLine, RegU#(Word)) dataRegs2;

    method Bool reqEnabled = (cyclesLeft == 0);
    input Maybe#(LineReq) req1 default = Invalid;
    input Maybe#(LineReq) req2 default = Invalid;

    method Maybe#(Line) data1;
        Line res;
        for (Integer i = 0; i < wordsPerLine; i = i + 1)
            res[i] = dataRegs1[i];
        return validOut? Valid(res) : Invalid;
    endmethod

    method Maybe#(Line) data2;
        Line res;
        for (Integer i = 0; i < wordsPerLine; i = i + 1)
            res[i] = dataRegs2[i];
        return validOut? Valid(res) : Invalid;
    endmethod

    rule tick;
        // dsm: Check that wordsPerLine is a reasonable value
        if (wordsPerLine != 4 && wordsPerLine != 8 && wordsPerLine != 16) begin
            $display("ERROR: MainMemory requires wordsPerLine to be 4, 8, or 16");
            $finish;
        end

        dynamicAssert(!((cyclesLeft != 0) && (isValid(req1) || isValid(req2)) ), "MainMemory received request while not ready!\n\n");
        if (cyclesLeft != 0) cyclesLeft <= cyclesLeft - 1;
        if (cyclesLeft == 0 && (isValid(req1)||isValid(req2))) begin
            cyclesLeft <= latency;
            let r1 = fromMaybe(?, req1);
            let r2 = fromMaybe(?, req2);
            curAddr1 <= {r1.lineAddr, 0};
            curAddr2 <= {r2.lineAddr, 0};
            //curOp <= r.op;
            for (Integer i = 0; i < wordsPerLine; i = i + 1)
                dataRegs1[i] <= r1.data[i];
            for (Integer i = 0; i < wordsPerLine; i = i + 1)
                dataRegs2[i] <= r2.data[i];
            wordMem.req1 = Valid(MemReq{addr: {r1.lineAddr, 0}, op: Ld, data: ?});
            wordMem.req2 = Valid(MemReq{addr: {r2.lineAddr, 0}, op: Ld, data: ?});
        end else if (cyclesLeft > latency - wordsPerLine) begin
            Bit#(logWordsPerLine) idx1 = truncate(curAddr1 >> 2);
            Bit#(logWordsPerLine) idx2 = truncate(curAddr2 >> 2);
            curAddr1 <= curAddr1 + 4;
            curAddr2 <= curAddr2 + 4;
            dataRegs1[idx1] <= fromMaybe(?, wordMem.data1);
            dataRegs2[idx2] <= fromMaybe(?, wordMem.data2);
            wordMem.req1 = Valid(MemReq{addr: curAddr1 + 4, op: Ld, data: ?});
            wordMem.req2 = Valid(MemReq{addr: curAddr2 + 4, op: Ld, data: ?});
        end
        validOut <= (cyclesLeft == 1);
    endrule
endmodule

// Single-cycle word memory, used as ideal memory by the tests
module /*msc_pragma:nosynth*/ SingleCycleMemory2;
    WordMem wordMem;

    Reg#(Bit#(64)) cycles(0);

    input Maybe#(MemReq) req default = Invalid;
    method Maybe#(Word) data = wordMem.data;

    // For detecting timeouts
    rule doCycle;
        cycles <= cycles + 1;
        if (cycles > 10000000) begin
            $display("FAILED: Your processor timed out");
            $finish;
        end
    endrule

    rule tick;
        if (isValid(req)) begin
            let r = fromMaybe(?, req);

            // MMIO and program termination
            if (r.op == St) begin
                if (r.addr == 'h4000_0000) begin
                    // Write character to stdout
                    $write("%c", r.data[7:0]);
                end else if (r.addr == 'h4000_0004) begin
                    // Write integer to stdout
                    $write("%0d", r.data);
                end else if (r.addr == 'h4000_1000) begin
                    // Exit simulation
                    $display("Total Clock Cycles = %d\n", cycles);
                    if (r.data == 0) begin
                        $display("PASSED");
                    end else begin
                        $display("FAILED %0d", r.data);
                    end
                    $finish;
                end
            end
        end
        wordMem.req = req;
    endrule
endmodule

module CacheWrapper2#(type T)(MainMemory mainMem);
    T cache(mainMem);

    Reg#(Bit#(64)) cycles(0);

    input Maybe#(MemReq) req default = Invalid;
    method Maybe#(Word) data = cache.data;

    method Bool reqEnabled = cache.reqEnabled;

    // For detecting timeouts
    rule doCycle;
        cycles <= cycles + 1;
        if (cycles > 10000000) begin
            $display("FAILED: Your processor timed out");
            $finish;
        end
    endrule

    rule tick;
        if (isValid(req)) begin
            // MMIO and program termination
            let curReq = fromMaybe(?, req);
            if (curReq.op == St) begin
                if (curReq.addr == 'h4000_0000) begin
                    // Write character to stdout
                    $write("%c", curReq.data[7:0]);
                end else if (curReq.addr == 'h4000_0004) begin
                    // Write integer to stdout
                    $write("%0d", curReq.data);
                end else if (curReq.addr == 'h4000_1000) begin
                    // Exit simulation
                    $display("Total Clock Cycles = %d\n", cycles);
                    if (curReq.data == 0) begin
                        $display("PASSED");
                    end else begin
                        $display("FAILED %0d", curReq.data);
                    end
                    $finish;
                end
            end
        end
        cache.req = req;
    endrule
endmodule

