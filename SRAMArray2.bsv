// BSV glue code for single-ported, non-loaded/loaded BRAM memories
import BRAMCore::*;

typedef BRAM_DUAL_PORT#(Bit#(addrSz), dataT) SRAMArray2#(numeric type addrSz, type dataT);

module mkSRAMArray2(SRAMArray2#(addrSz, dataT) ) provisos (Bits#(dataT, dataSz));
    Integer memSz = valueOf(TExp#(addrSz));
    Bool hasOutputRegister = False;
    BRAM_DUAL_PORT#(Bit#(addrSz), dataT) bram <- mkBRAMCore2(memSz, hasOutputRegister);
    return bram;
endmodule

typedef BRAM_DUAL_PORT#(Bit#(addrSz), dataT) SRAMArrayLoad2#(numeric type addrSz, type dataT);

module mkSRAMArrayLoad2#(String file)(SRAMArrayLoad2#(addrSz, dataT)) provisos (Bits#(dataT, dataSz));
    Integer memSz = valueOf(TExp#(addrSz));
    Bool hasOutputRegister = False;
    BRAM_DUAL_PORT#(Bit#(addrSz), dataT) bram <- mkBRAMCore2Load(memSz, hasOutputRegister, file, False);
    return bram;
endmodule
