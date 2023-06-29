bsvimport SRAMArray2;
bsvimport BRAMCore;

/*
typedef struct {
    Bit#(addrSz) addr;
    Bool write;
    DataT data;
} SRAMReq#(Integer addrSz, type DataT);
*/

module SRAM2#(Integer addrSz, type DataT);
    SRAMArray2#(addrSz, DataT) array;  // BSV array
    Reg#(Bool) arrayHasData1(False);
    Reg#(Bool) arrayHasData2(False);

    input Maybe#(SRAMReq#(addrSz, DataT)) req1 default = Invalid;
    input Maybe#(SRAMReq#(addrSz, DataT)) req2 default=Invalid;

    rule tick;
        if (isValid(req1)) begin
            let r1 = fromMaybe(?, req1);
            array.a.put(r1.write, r1.addr, r1.data);
            arrayHasData1 <= !r1.write;
        end else arrayHasData1 <= False;
        if (isValid(req2)) begin
            let r2=fromMaybe(?, req2);
            array.b.put(r2.write, r2.addr, r2.data);
            arrayHasData2 <= !r2.write;
        end else arrayHasData2 <= False;
    endrule

    method Maybe#(DataT) data1 = arrayHasData1? Valid(array.a.read) : Invalid;
    method Maybe#(DataT) data2 = arrayHasData2? Valid(array.b.read) : Invalid;
endmodule

module SRAMLoad2#(Integer addrSz, type DataT)(String file);
    SRAMArrayLoad2#(addrSz, DataT) array(file);  // BSV array
    Reg#(Bool) arrayHasData1(False);
    Reg#(Bool) arrayHasData2(False);

    input Maybe#(SRAMReq#(addrSz, DataT)) req1 default = Invalid;
    input Maybe#(SRAMReq#(addrSz, DataT)) req2 default=Invalid;

    rule tick;
        if (isValid(req1)) begin
            let r1 = fromMaybe(?, req1);
            array.a.put(r1.write, r1.addr, r1.data);
            arrayHasData1 <= !r1.write;
        end else arrayHasData1 <= False;
        if (isValid(req2)) begin
            let r2=fromMaybe(?, req2);
            array.b.put(r2.write, r2.addr, r2.data);
            arrayHasData2 <= !r2.write;
        end else arrayHasData2 <= False;
    endrule

    method Maybe#(DataT) data1 = arrayHasData1? Valid(array.a.read) : Invalid;
    method Maybe#(DataT) data2 = arrayHasData2? Valid(array.b.read) : Invalid;
endmodule
